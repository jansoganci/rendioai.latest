-- Add rate limiting functionality
-- Implements minimum viable rate limiting: 10 videos/hour per user

-- ============================================================================
-- Rate limiting stored procedure
-- ============================================================================

CREATE OR REPLACE FUNCTION check_rate_limit(
  p_user_id UUID,
  p_action TEXT,
  p_max_per_hour INTEGER DEFAULT 10
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_count INTEGER;
  v_window_start TIMESTAMP WITH TIME ZONE;
  v_is_allowed BOOLEAN;
  v_remaining INTEGER;
  v_reset_at TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Calculate the start of the current hour window
  v_window_start := NOW() - INTERVAL '1 hour';
  v_reset_at := date_trunc('hour', NOW()) + INTERVAL '1 hour';

  -- Count recent requests for this action by this user
  SELECT COUNT(*)
  INTO v_current_count
  FROM public.video_jobs
  WHERE user_id = p_user_id
  AND created_at > v_window_start
  AND status != 'failed';  -- Don't count failed attempts

  -- Check if user is within rate limit
  v_is_allowed := v_current_count < p_max_per_hour;
  v_remaining := GREATEST(0, p_max_per_hour - v_current_count);

  -- Log rate limit check
  INSERT INTO public.audit_log (action, details, created_at)
  VALUES (
    'rate_limit_check',
    jsonb_build_object(
      'user_id', p_user_id,
      'action', p_action,
      'current_count', v_current_count,
      'max_allowed', p_max_per_hour,
      'is_allowed', v_is_allowed,
      'remaining', v_remaining
    ),
    NOW()
  );

  -- Return result
  RETURN jsonb_build_object(
    'allowed', v_is_allowed,
    'current_count', v_current_count,
    'limit', p_max_per_hour,
    'remaining', v_remaining,
    'reset_at', v_reset_at
  );
END;
$$;

-- ============================================================================
-- Enhanced rate limiting with different tiers
-- ============================================================================

CREATE OR REPLACE FUNCTION get_user_rate_limit(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_user_tier TEXT;
  v_limit INTEGER;
BEGIN
  -- Get user tier
  SELECT tier INTO v_user_tier
  FROM public.users
  WHERE id = p_user_id;

  -- Set limits based on tier
  CASE v_user_tier
    WHEN 'free' THEN v_limit := 10;      -- 10 videos/hour for free users
    WHEN 'pro' THEN v_limit := 50;       -- 50 videos/hour for pro users
    WHEN 'enterprise' THEN v_limit := 200; -- 200 videos/hour for enterprise
    ELSE v_limit := 10;                  -- Default to free tier limit
  END CASE;

  RETURN v_limit;
END;
$$;

-- ============================================================================
-- Rate limit with dynamic tier-based limits
-- ============================================================================

CREATE OR REPLACE FUNCTION check_rate_limit_dynamic(
  p_user_id UUID,
  p_action TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_max_per_hour INTEGER;
BEGIN
  -- Get user's rate limit based on tier
  v_max_per_hour := get_user_rate_limit(p_user_id);

  -- Use the base rate limit check with dynamic limit
  RETURN check_rate_limit(p_user_id, p_action, v_max_per_hour);
END;
$$;

-- ============================================================================
-- Create rate_limit_violations table for tracking
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.rate_limit_violations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  attempted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  current_count INTEGER NOT NULL,
  limit_exceeded_by INTEGER NOT NULL,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_rate_limit_violations_user_id
ON public.rate_limit_violations(user_id);

CREATE INDEX IF NOT EXISTS idx_rate_limit_violations_created_at
ON public.rate_limit_violations(created_at DESC);

-- ============================================================================
-- Function to log rate limit violations
-- ============================================================================

CREATE OR REPLACE FUNCTION log_rate_limit_violation(
  p_user_id UUID,
  p_action TEXT,
  p_current_count INTEGER,
  p_limit INTEGER,
  p_ip_address INET DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.rate_limit_violations (
    user_id,
    action,
    current_count,
    limit_exceeded_by,
    ip_address,
    user_agent,
    attempted_at
  )
  VALUES (
    p_user_id,
    p_action,
    p_current_count,
    p_current_count - p_limit + 1,
    p_ip_address,
    p_user_agent,
    NOW()
  );

  -- Alert if user has multiple violations in the last hour
  IF (
    SELECT COUNT(*)
    FROM public.rate_limit_violations
    WHERE user_id = p_user_id
    AND attempted_at > NOW() - INTERVAL '1 hour'
  ) >= 5 THEN
    INSERT INTO public.audit_log (action, details, created_at)
    VALUES (
      'excessive_rate_limit_violations',
      jsonb_build_object(
        'user_id', p_user_id,
        'violations_in_hour', 5,
        'action', p_action
      ),
      NOW()
    );
  END IF;
END;
$$;

-- ============================================================================
-- Helper function to get rate limit status for a user
-- ============================================================================

CREATE OR REPLACE FUNCTION get_rate_limit_status(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_result JSONB;
BEGIN
  -- Get current rate limit status for video generation
  v_result := check_rate_limit_dynamic(p_user_id, 'generate_video');

  -- Add recent violations count
  v_result := v_result || jsonb_build_object(
    'recent_violations', (
      SELECT COUNT(*)
      FROM public.rate_limit_violations
      WHERE user_id = p_user_id
      AND attempted_at > NOW() - INTERVAL '24 hours'
    )
  );

  RETURN v_result;
END;
$$;

-- ============================================================================
-- Cleanup job for old rate limit violations
-- ============================================================================

CREATE OR REPLACE FUNCTION cleanup_rate_limit_violations()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  -- Delete violations older than 30 days
  DELETE FROM public.rate_limit_violations
  WHERE created_at < NOW() - INTERVAL '30 days';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;

  IF deleted_count > 0 THEN
    INSERT INTO public.audit_log (action, details, created_at)
    VALUES (
      'rate_limit_violations_cleaned',
      jsonb_build_object(
        'deleted_count', deleted_count,
        'older_than_days', 30
      ),
      NOW()
    );
  END IF;
END;
$$;

-- Schedule cleanup job to run weekly
SELECT cron.schedule(
  'cleanup-rate-limit-violations',
  '0 4 * * 1',  -- Weekly on Monday at 4 AM UTC
  'SELECT cleanup_rate_limit_violations();'
)
WHERE NOT EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'cleanup-rate-limit-violations'
);

-- ============================================================================
-- Grant permissions
-- ============================================================================

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION check_rate_limit TO authenticated;
GRANT EXECUTE ON FUNCTION check_rate_limit_dynamic TO authenticated;
GRANT EXECUTE ON FUNCTION get_rate_limit_status TO authenticated;

-- ============================================================================
-- Comments for documentation
-- ============================================================================

COMMENT ON FUNCTION check_rate_limit IS
'Checks if a user action is within rate limits. Returns allowed status and remaining quota.';

COMMENT ON FUNCTION check_rate_limit_dynamic IS
'Checks rate limit with dynamic limits based on user tier.';

COMMENT ON FUNCTION get_user_rate_limit IS
'Returns the rate limit for a user based on their tier.';

COMMENT ON FUNCTION log_rate_limit_violation IS
'Logs a rate limit violation for tracking and analysis.';

COMMENT ON FUNCTION get_rate_limit_status IS
'Returns comprehensive rate limit status for a user.';

COMMENT ON TABLE rate_limit_violations IS
'Tracks rate limit violations for security monitoring and abuse prevention.';