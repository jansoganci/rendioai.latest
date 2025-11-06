-- Migration: Create stored procedures for credit management
-- Version: 1.0
-- Date: 2025-11-05

-- =====================================================
-- Function: deduct_credits
-- Purpose: Atomically deduct credits from user account
-- Returns: JSONB with success status and remaining credits
-- =====================================================

CREATE OR REPLACE FUNCTION deduct_credits(
    p_user_id UUID,
    p_amount INTEGER,
    p_reason TEXT DEFAULT 'video_generation'
) RETURNS JSONB AS $$
DECLARE
    current_credits INTEGER;
    new_balance INTEGER;
BEGIN
    -- Lock row to prevent race conditions (FOR UPDATE ensures atomic operation)
    SELECT credits_remaining INTO current_credits
    FROM users
    WHERE id = p_user_id
    FOR UPDATE;

    -- Check if user exists
    IF current_credits IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User not found'
        );
    END IF;

    -- Check if user has enough credits
    IF current_credits < p_amount THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Insufficient credits',
            'current_credits', current_credits,
            'required_credits', p_amount
        );
    END IF;

    -- Deduct credits
    UPDATE users
    SET credits_remaining = credits_remaining - p_amount,
        updated_at = now()
    WHERE id = p_user_id
    RETURNING credits_remaining INTO new_balance;

    -- Log transaction with balance_after for audit trail
    INSERT INTO quota_log (user_id, change, reason, balance_after)
    VALUES (p_user_id, -p_amount, p_reason, new_balance);

    -- Return success with new balance
    RETURN jsonb_build_object(
        'success', true,
        'credits_remaining', new_balance
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Function: add_credits
-- Purpose: Atomically add credits to user account
-- Returns: JSONB with success status and credit info
-- =====================================================

CREATE OR REPLACE FUNCTION add_credits(
    p_user_id UUID,
    p_amount INTEGER,
    p_reason TEXT,
    p_transaction_id TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    new_balance INTEGER;
    existing_transaction BOOLEAN;
BEGIN
    -- Check for duplicate transaction (prevents double IAP credit grants)
    IF p_transaction_id IS NOT NULL THEN
        SELECT EXISTS(
            SELECT 1 FROM quota_log
            WHERE transaction_id = p_transaction_id
        ) INTO existing_transaction;

        IF existing_transaction THEN
            RETURN jsonb_build_object(
                'success', false,
                'error', 'Transaction already processed'
            );
        END IF;
    END IF;

    -- Add credits (both remaining and total for lifetime tracking)
    UPDATE users
    SET credits_remaining = credits_remaining + p_amount,
        credits_total = credits_total + p_amount,
        updated_at = now()
    WHERE id = p_user_id
    RETURNING credits_remaining INTO new_balance;

    -- Check if user exists
    IF new_balance IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User not found'
        );
    END IF;

    -- Log transaction with balance_after for audit trail
    INSERT INTO quota_log (
        user_id,
        change,
        reason,
        balance_after,
        transaction_id
    ) VALUES (
        p_user_id,
        p_amount,
        p_reason,
        new_balance,
        p_transaction_id
    );

    -- Return success with credit info
    RETURN jsonb_build_object(
        'success', true,
        'credits_added', p_amount,
        'credits_remaining', new_balance
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Test the functions (optional - can be commented out)
-- =====================================================

-- Uncomment below to test the functions after creation:
-- DO $$
-- DECLARE
--     test_user_id UUID;
--     result JSONB;
-- BEGIN
--     -- Create a test user
--     INSERT INTO users (email, is_guest, credits_remaining, credits_total)
--     VALUES ('test@example.com', false, 10, 10)
--     RETURNING id INTO test_user_id;
--
--     -- Test deduct_credits
--     SELECT deduct_credits(test_user_id, 4, 'test_deduction') INTO result;
--     RAISE NOTICE 'Deduct test: %', result;
--
--     -- Test add_credits
--     SELECT add_credits(test_user_id, 5, 'test_addition', 'test_tx_001') INTO result;
--     RAISE NOTICE 'Add test: %', result;
--
--     -- Test duplicate transaction prevention
--     SELECT add_credits(test_user_id, 5, 'test_addition', 'test_tx_001') INTO result;
--     RAISE NOTICE 'Duplicate test: %', result;
--
--     -- Cleanup test user
--     DELETE FROM users WHERE id = test_user_id;
-- END $$;

-- =====================================================
-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Stored procedures created successfully!';
    RAISE NOTICE '   - deduct_credits(user_id, amount, reason)';
    RAISE NOTICE '   - add_credits(user_id, amount, reason, transaction_id)';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 Security: Both functions use SECURITY DEFINER for atomic operations';
    RAISE NOTICE '🛡️ Protection: add_credits prevents duplicate transactions';
    RAISE NOTICE '📊 Audit: All transactions logged to quota_log with balance_after';
END $$;
