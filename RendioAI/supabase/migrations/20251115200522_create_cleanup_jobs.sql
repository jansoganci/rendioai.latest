-- Create cleanup jobs using pg_cron
-- These jobs help maintain database and storage hygiene

-- Enable pg_cron extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Grant usage to postgres user (required for Supabase)
GRANT USAGE ON SCHEMA cron TO postgres;

-- ============================================================================
-- Job 1: Delete old videos (>90 days)
-- ============================================================================

-- Create function to delete old video jobs
CREATE OR REPLACE FUNCTION cleanup_old_videos()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  deleted_count INTEGER;
  old_video RECORD;
BEGIN
  deleted_count := 0;

  -- Find and delete video jobs older than 90 days
  FOR old_video IN
    SELECT job_id, user_id, video_url
    FROM public.video_jobs
    WHERE created_at < NOW() - INTERVAL '90 days'
    AND status IN ('completed', 'failed')
  LOOP
    -- Delete the video job record
    DELETE FROM public.video_jobs
    WHERE job_id = old_video.job_id;

    deleted_count := deleted_count + 1;

    -- Log the deletion
    INSERT INTO public.audit_log (action, details, created_at)
    VALUES (
      'video_job_deleted',
      jsonb_build_object(
        'job_id', old_video.job_id,
        'user_id', old_video.user_id,
        'reason', 'older_than_90_days'
      ),
      NOW()
    );
  END LOOP;

  -- Log summary
  IF deleted_count > 0 THEN
    RAISE NOTICE 'Deleted % old video jobs', deleted_count;
  END IF;
END;
$$;

-- Schedule the cleanup job to run daily at 2 AM UTC
SELECT cron.schedule(
  'cleanup-old-videos',
  '0 2 * * *',  -- Daily at 2 AM UTC
  'SELECT cleanup_old_videos();'
);

-- ============================================================================
-- Job 2: Delete old idempotency keys (>24 hours)
-- ============================================================================

-- Create function to cleanup idempotency keys
CREATE OR REPLACE FUNCTION cleanup_idempotency_keys()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  -- Delete idempotency keys older than 24 hours
  DELETE FROM public.idempotency_keys
  WHERE created_at < NOW() - INTERVAL '24 hours';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;

  -- Log the cleanup
  IF deleted_count > 0 THEN
    INSERT INTO public.audit_log (action, details, created_at)
    VALUES (
      'idempotency_keys_cleaned',
      jsonb_build_object(
        'deleted_count', deleted_count,
        'older_than_hours', 24
      ),
      NOW()
    );

    RAISE NOTICE 'Deleted % old idempotency keys', deleted_count;
  END IF;
END;
$$;

-- Schedule the cleanup job to run every 6 hours
SELECT cron.schedule(
  'cleanup-idempotency-keys',
  '0 */6 * * *',  -- Every 6 hours
  'SELECT cleanup_idempotency_keys();'
);

-- ============================================================================
-- Job 3: Delete inactive anonymous users (90 days no activity)
-- ============================================================================

-- Create function to cleanup inactive anonymous users
CREATE OR REPLACE FUNCTION cleanup_inactive_anonymous_users()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  deleted_count INTEGER;
  inactive_user RECORD;
BEGIN
  deleted_count := 0;

  -- Find inactive anonymous users
  FOR inactive_user IN
    SELECT u.id, u.device_id, u.auth_user_id, u.created_at
    FROM public.users u
    WHERE u.is_guest = true
    AND u.created_at < NOW() - INTERVAL '90 days'
    AND NOT EXISTS (
      -- Check for recent video jobs
      SELECT 1 FROM public.video_jobs v
      WHERE v.user_id = u.id
      AND v.created_at > NOW() - INTERVAL '90 days'
    )
    AND NOT EXISTS (
      -- Check for recent credit transactions
      SELECT 1 FROM public.quota_log q
      WHERE q.user_id = u.id
      AND q.created_at > NOW() - INTERVAL '90 days'
    )
  LOOP
    -- Delete related data first (cascade)
    DELETE FROM public.video_jobs WHERE user_id = inactive_user.id;
    DELETE FROM public.quota_log WHERE user_id = inactive_user.id;
    DELETE FROM public.transactions WHERE user_id = inactive_user.id;

    -- Delete the user
    DELETE FROM public.users WHERE id = inactive_user.id;

    -- If user has auth_user_id, also delete from auth.users
    IF inactive_user.auth_user_id IS NOT NULL THEN
      DELETE FROM auth.users WHERE id = inactive_user.auth_user_id;
    END IF;

    deleted_count := deleted_count + 1;
  END LOOP;

  -- Log the cleanup
  IF deleted_count > 0 THEN
    INSERT INTO public.audit_log (action, details, created_at)
    VALUES (
      'inactive_users_cleaned',
      jsonb_build_object(
        'deleted_count', deleted_count,
        'inactive_days', 90,
        'user_type', 'anonymous'
      ),
      NOW()
    );

    RAISE NOTICE 'Deleted % inactive anonymous users', deleted_count;
  END IF;
END;
$$;

-- Schedule the cleanup job to run weekly on Sunday at 3 AM UTC
SELECT cron.schedule(
  'cleanup-inactive-users',
  '0 3 * * 0',  -- Weekly on Sunday at 3 AM UTC
  'SELECT cleanup_inactive_anonymous_users();'
);

-- ============================================================================
-- Job 4: Update storage usage statistics (for monitoring)
-- ============================================================================

-- Create table to track storage usage
CREATE TABLE IF NOT EXISTS public.storage_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bucket_name TEXT NOT NULL,
  used_bytes BIGINT NOT NULL DEFAULT 0,
  total_bytes BIGINT NOT NULL DEFAULT 1073741824, -- 1GB default
  file_count INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert initial records for our buckets
INSERT INTO public.storage_usage (bucket_name, total_bytes)
VALUES
  ('videos', 1073741824),      -- 1GB
  ('thumbnails', 1073741824)   -- 1GB
ON CONFLICT DO NOTHING;

-- Create function to update storage statistics
CREATE OR REPLACE FUNCTION update_storage_usage()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  bucket RECORD;
  total_size BIGINT;
  total_count INTEGER;
BEGIN
  -- Update usage for each bucket
  FOR bucket IN SELECT DISTINCT bucket_id FROM storage.objects
  LOOP
    -- Calculate total size and count for the bucket
    SELECT
      COALESCE(SUM((metadata->>'size')::BIGINT), 0),
      COUNT(*)
    INTO total_size, total_count
    FROM storage.objects
    WHERE bucket_id = bucket.bucket_id;

    -- Update or insert the usage record
    INSERT INTO public.storage_usage (bucket_name, used_bytes, file_count, updated_at)
    VALUES (bucket.bucket_id, total_size, total_count, NOW())
    ON CONFLICT (bucket_name) DO UPDATE
    SET
      used_bytes = EXCLUDED.used_bytes,
      file_count = EXCLUDED.file_count,
      updated_at = NOW();
  END LOOP;

  -- Log high usage
  FOR bucket IN
    SELECT bucket_name, used_bytes, total_bytes,
           ROUND((used_bytes::NUMERIC / total_bytes) * 100, 2) as usage_percent
    FROM public.storage_usage
    WHERE (used_bytes::NUMERIC / total_bytes) > 0.8
  LOOP
    INSERT INTO public.audit_log (action, details, created_at)
    VALUES (
      'high_storage_usage',
      jsonb_build_object(
        'bucket', bucket.bucket_name,
        'used_bytes', bucket.used_bytes,
        'total_bytes', bucket.total_bytes,
        'usage_percent', bucket.usage_percent
      ),
      NOW()
    );
  END LOOP;
END;
$$;

-- Schedule the storage usage update to run every hour
SELECT cron.schedule(
  'update-storage-usage',
  '0 * * * *',  -- Every hour
  'SELECT update_storage_usage();'
);

-- ============================================================================
-- Create audit_log table if it doesn't exist
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  action TEXT NOT NULL,
  details JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for efficient queries
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON public.audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON public.audit_log(created_at DESC);

-- ============================================================================
-- Comments for documentation
-- ============================================================================

COMMENT ON FUNCTION cleanup_old_videos() IS
'Deletes video_jobs records older than 90 days. Runs daily at 2 AM UTC.';

COMMENT ON FUNCTION cleanup_idempotency_keys() IS
'Deletes idempotency_keys older than 24 hours. Runs every 6 hours.';

COMMENT ON FUNCTION cleanup_inactive_anonymous_users() IS
'Deletes anonymous users with no activity in the last 90 days. Runs weekly on Sunday at 3 AM UTC.';

COMMENT ON FUNCTION update_storage_usage() IS
'Updates storage usage statistics for monitoring. Runs every hour.';

-- ============================================================================
-- Verification
-- ============================================================================

-- Verify jobs are scheduled
DO $$
DECLARE
  job_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO job_count FROM cron.job;

  IF job_count < 4 THEN
    RAISE WARNING 'Expected 4 cleanup jobs, but found %', job_count;
  ELSE
    RAISE NOTICE 'Successfully scheduled % cleanup jobs', job_count;
  END IF;
END $$;