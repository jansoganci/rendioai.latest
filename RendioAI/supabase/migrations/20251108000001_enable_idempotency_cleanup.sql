-- Migration: Enable Automatic Idempotency Log Cleanup
-- Version: 1.0
-- Date: 2025-11-08
-- Phase: 5.3 - Performance Optimization
-- Purpose: Automatically delete expired idempotency records to prevent database bloat

-- =====================================================
-- Step 1: Enable pg_cron Extension
-- =====================================================

-- Enable pg_cron extension (PostgreSQL cron job scheduler)
-- This allows us to schedule automated cleanup tasks
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Verify extension is enabled
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_extension WHERE extname = 'pg_cron'
    ) THEN
        RAISE NOTICE '✅ pg_cron extension enabled successfully';
    ELSE
        RAISE EXCEPTION '❌ Failed to enable pg_cron extension';
    END IF;
END $$;

-- =====================================================
-- Step 2: Schedule Daily Cleanup Job
-- =====================================================

-- Schedule cleanup to run daily at 2:00 AM UTC
-- This time is chosen to minimize impact during low-traffic hours
SELECT cron.schedule(
    'cleanup-expired-idempotency-records',  -- Job name
    '0 2 * * *',                             -- Cron expression: Daily at 2:00 AM UTC
    $$DELETE FROM idempotency_log WHERE expires_at < now()$$  -- SQL command
);

-- =====================================================
-- Step 3: Verify Job Scheduled
-- =====================================================

-- Query to show the scheduled job details
DO $$
DECLARE
    job_count INTEGER;
    job_record RECORD;
BEGIN
    -- Check if job exists
    SELECT COUNT(*) INTO job_count
    FROM cron.job
    WHERE jobname = 'cleanup-expired-idempotency-records';

    IF job_count = 0 THEN
        RAISE EXCEPTION '❌ Cleanup job was not scheduled correctly';
    ELSE
        -- Get job details
        SELECT * INTO job_record
        FROM cron.job
        WHERE jobname = 'cleanup-expired-idempotency-records';

        RAISE NOTICE '✅ Cleanup job scheduled successfully!';
        RAISE NOTICE '';
        RAISE NOTICE '📋 Job Details:';
        RAISE NOTICE '   Name: %', job_record.jobname;
        RAISE NOTICE '   Schedule: % (Daily at 2:00 AM UTC)', job_record.schedule;
        RAISE NOTICE '   Command: %', job_record.command;
        RAISE NOTICE '   Database: %', job_record.database;
        RAISE NOTICE '   Active: %', job_record.active;
        RAISE NOTICE '';
        RAISE NOTICE '🗑️  This job will automatically delete expired idempotency records.';
        RAISE NOTICE '⏰ Records expire 24 hours after creation (see idempotency_log.expires_at).';
        RAISE NOTICE '';
        RAISE NOTICE '📊 Expected Impact:';
        RAISE NOTICE '   - Without cleanup: ~360K rows/year (1000 videos/day × 365 days)';
        RAISE NOTICE '   - With cleanup: Max ~1000 rows (24-hour retention)';
        RAISE NOTICE '   - Database size reduction: 99.7%%';
    END IF;
END $$;

-- =====================================================
-- Step 4: Manual Cleanup (Optional - Run Once)
-- =====================================================

-- Optional: Clean up existing expired records immediately
-- This is safe to run and will be done automatically going forward
DO $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Delete expired records
    DELETE FROM idempotency_log
    WHERE expires_at < now();

    GET DIAGNOSTICS deleted_count = ROW_COUNT;

    IF deleted_count > 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE '🧹 Initial Cleanup Complete:';
        RAISE NOTICE '   Deleted % expired idempotency records', deleted_count;
    ELSE
        RAISE NOTICE '';
        RAISE NOTICE '✨ No expired records to clean up (database is clean!)';
    END IF;
END $$;

-- =====================================================
-- Step 5: View Scheduled Jobs (Query Reference)
-- =====================================================

-- To view all scheduled cron jobs, run:
-- SELECT * FROM cron.job;

-- To view job run history, run:
-- SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10;

-- To manually trigger the cleanup job (for testing), run:
-- DELETE FROM idempotency_log WHERE expires_at < now();

-- =====================================================
-- Success Summary
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '✅ MIGRATION COMPLETE: Idempotency Cleanup Enabled';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '';
    RAISE NOTICE '📅 Next Run: Tomorrow at 2:00 AM UTC';
    RAISE NOTICE '🔄 Frequency: Daily';
    RAISE NOTICE '🗑️  Action: Delete records where expires_at < now()';
    RAISE NOTICE '';
    RAISE NOTICE '🔍 To verify:';
    RAISE NOTICE '   SELECT * FROM cron.job WHERE jobname = ''cleanup-expired-idempotency-records'';';
    RAISE NOTICE '';
    RAISE NOTICE '🧪 To test manually:';
    RAISE NOTICE '   DELETE FROM idempotency_log WHERE expires_at < now();';
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
END $$;
