-- =====================================================
-- DeviceCheck Backend Hardening Migration
-- =====================================================

-- 1. Create device_check_devices table
CREATE TABLE IF NOT EXISTS device_check_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Device & User linking
    device_id TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Apple DeviceCheck state
    dc_bit0 INTEGER CHECK (dc_bit0 IN (0, 1)),
    dc_bit1 INTEGER CHECK (dc_bit1 IN (0, 1)),
    dc_last_update_time TIMESTAMPTZ,
    dc_last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Query tracking
    dc_query_success_count INTEGER DEFAULT 0,
    dc_query_fail_count INTEGER DEFAULT 0,
    dc_last_query_at TIMESTAMPTZ,

    -- Fraud signals
    fraud_flags TEXT[], -- Array of flags: 'dc_query_fail_spike', 'multi_account_risk', 'bit_flapping_suspected'
    risk_score INTEGER DEFAULT 0 CHECK (risk_score >= 0 AND risk_score <= 100),

    -- Rate limiting
    request_count_1h INTEGER DEFAULT 0,
    request_window_start TIMESTAMPTZ DEFAULT NOW(),

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Create indexes
CREATE INDEX idx_device_check_devices_device_id ON device_check_devices(device_id);
CREATE INDEX idx_device_check_devices_user_id ON device_check_devices(user_id);
CREATE INDEX idx_device_check_devices_updated_at ON device_check_devices(updated_at DESC);
CREATE INDEX idx_device_check_devices_fraud_flags ON device_check_devices USING GIN(fraud_flags);

-- 3. Enable RLS
ALTER TABLE device_check_devices ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
-- Users can only see their own device records
CREATE POLICY "Users can view their own device records"
    ON device_check_devices
    FOR SELECT
    USING (auth.uid() = user_id);

-- Service role can do everything
CREATE POLICY "Service role has full access"
    ON device_check_devices
    FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

-- 5. Function to upsert device state (called by Edge Function with service role)
CREATE OR REPLACE FUNCTION upsert_device_check_state(
    p_device_id TEXT,
    p_user_id UUID,
    p_bit0 INTEGER,
    p_bit1 INTEGER,
    p_last_update_time TIMESTAMPTZ,
    p_query_success BOOLEAN,
    p_fraud_flags TEXT[] DEFAULT ARRAY[]::TEXT[]
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_device_record device_check_devices%ROWTYPE;
    v_risk_score INTEGER := 0;
    v_new_flags TEXT[] := p_fraud_flags;
    v_request_count INTEGER := 0;
BEGIN
    -- Check if device exists
    SELECT * INTO v_device_record
    FROM device_check_devices
    WHERE device_id = p_device_id
    FOR UPDATE;

    IF FOUND THEN
        -- Update existing device

        -- Check for multi-account risk
        IF v_device_record.user_id != p_user_id THEN
            v_new_flags := array_append(v_new_flags, 'multi_account_risk');
        END IF;

        -- Check for bit flapping (bits changed in < 24 hours)
        IF v_device_record.dc_bit0 IS NOT NULL AND v_device_record.dc_bit1 IS NOT NULL THEN
            IF (v_device_record.dc_bit0 != p_bit0 OR v_device_record.dc_bit1 != p_bit1)
               AND v_device_record.dc_last_update_time > NOW() - INTERVAL '24 hours' THEN
                v_new_flags := array_append(v_new_flags, 'bit_flapping_suspected');
            END IF;
        END IF;

        -- Reset rate limit window if expired
        IF v_device_record.request_window_start < NOW() - INTERVAL '1 hour' THEN
            v_request_count := 1;
        ELSE
            v_request_count := v_device_record.request_count_1h + 1;
        END IF;

        UPDATE device_check_devices
        SET
            user_id = p_user_id,
            dc_bit0 = p_bit0,
            dc_bit1 = p_bit1,
            dc_last_update_time = p_last_update_time,
            dc_last_seen_at = NOW(),
            dc_query_success_count = CASE WHEN p_query_success THEN dc_query_success_count + 1 ELSE dc_query_success_count END,
            dc_query_fail_count = CASE WHEN NOT p_query_success THEN dc_query_fail_count + 1 ELSE dc_query_fail_count END,
            dc_last_query_at = NOW(),
            fraud_flags = v_new_flags,
            risk_score = calculate_device_risk_score(dc_query_fail_count, v_new_flags),
            request_count_1h = v_request_count,
            request_window_start = CASE WHEN v_device_record.request_window_start < NOW() - INTERVAL '1 hour' THEN NOW() ELSE v_device_record.request_window_start END,
            updated_at = NOW()
        WHERE device_id = p_device_id
        RETURNING * INTO v_device_record;
    ELSE
        -- Insert new device
        INSERT INTO device_check_devices (
            device_id,
            user_id,
            dc_bit0,
            dc_bit1,
            dc_last_update_time,
            dc_query_success_count,
            dc_query_fail_count,
            dc_last_query_at,
            fraud_flags,
            risk_score,
            request_count_1h,
            request_window_start
        ) VALUES (
            p_device_id,
            p_user_id,
            p_bit0,
            p_bit1,
            p_last_update_time,
            CASE WHEN p_query_success THEN 1 ELSE 0 END,
            CASE WHEN NOT p_query_success THEN 1 ELSE 0 END,
            NOW(),
            v_new_flags,
            0,
            1,
            NOW()
        )
        RETURNING * INTO v_device_record;
    END IF;

    -- Return device state
    RETURN json_build_object(
        'success', TRUE,
        'device_id', v_device_record.device_id,
        'risk_score', v_device_record.risk_score,
        'fraud_flags', v_device_record.fraud_flags,
        'request_count_1h', v_device_record.request_count_1h
    );
END;
$$;

-- 6. Helper function to calculate risk score
CREATE OR REPLACE FUNCTION calculate_device_risk_score(
    p_fail_count INTEGER,
    p_fraud_flags TEXT[]
)
RETURNS INTEGER
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    v_score INTEGER := 0;
BEGIN
    -- Base score from failure count
    v_score := LEAST(p_fail_count * 10, 50);

    -- Add points for fraud flags
    IF 'dc_query_fail_spike' = ANY(p_fraud_flags) THEN
        v_score := v_score + 20;
    END IF;

    IF 'multi_account_risk' = ANY(p_fraud_flags) THEN
        v_score := v_score + 30;
    END IF;

    IF 'bit_flapping_suspected' = ANY(p_fraud_flags) THEN
        v_score := v_score + 15;
    END IF;

    -- Cap at 100
    RETURN LEAST(v_score, 100);
END;
$$;

-- 7. Function to check rate limit
CREATE OR REPLACE FUNCTION check_device_rate_limit(
    p_device_id TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_device device_check_devices%ROWTYPE;
    v_limit_exceeded BOOLEAN := FALSE;
BEGIN
    SELECT * INTO v_device
    FROM device_check_devices
    WHERE device_id = p_device_id;

    IF FOUND THEN
        -- Check if rate limit exceeded (10 requests per hour)
        IF v_device.request_window_start > NOW() - INTERVAL '1 hour'
           AND v_device.request_count_1h >= 10 THEN
            v_limit_exceeded := TRUE;
        END IF;
    END IF;

    RETURN json_build_object(
        'limit_exceeded', v_limit_exceeded,
        'request_count', COALESCE(v_device.request_count_1h, 0),
        'window_reset_at', COALESCE(v_device.request_window_start + INTERVAL '1 hour', NOW())
    );
END;
$$;

-- 8. Grant execute permissions
GRANT EXECUTE ON FUNCTION upsert_device_check_state TO service_role;
GRANT EXECUTE ON FUNCTION calculate_device_risk_score TO service_role;
GRANT EXECUTE ON FUNCTION check_device_rate_limit TO service_role;

-- 9. Add comment
COMMENT ON TABLE device_check_devices IS 'Stores Apple DeviceCheck verification state and fraud signals';
