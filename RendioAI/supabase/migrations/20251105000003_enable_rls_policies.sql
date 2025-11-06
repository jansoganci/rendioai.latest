-- Migration: Enable Row Level Security (RLS) policies
-- Version: 1.0
-- Date: 2025-11-05
-- Purpose: Ensure users can only access their own data

-- =====================================================
-- Enable RLS on all tables
-- =====================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE models ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE quota_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE idempotency_log ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- Users Table Policies
-- =====================================================

-- Policy: Users can view own profile
CREATE POLICY "Users can view own profile"
ON users FOR SELECT
USING (auth.uid() = id);

-- Policy: Users can update own profile
CREATE POLICY "Users can update own profile"
ON users FOR UPDATE
USING (auth.uid() = id);

-- Policy: Users can insert own profile (for guest onboarding)
CREATE POLICY "Users can insert own profile"
ON users FOR INSERT
WITH CHECK (auth.uid() = id);

-- =====================================================
-- Models Table Policies
-- =====================================================

-- Policy: Anyone can view available models
CREATE POLICY "Anyone can view available models"
ON models FOR SELECT
USING (is_available = true);

-- Note: Only backend (service_role) can modify models
-- No INSERT/UPDATE/DELETE policies needed for users

-- =====================================================
-- Video Jobs Table Policies
-- =====================================================

-- Policy: Users can view own jobs
CREATE POLICY "Users can view own jobs"
ON video_jobs FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can insert own jobs
CREATE POLICY "Users can insert own jobs"
ON video_jobs FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update own jobs (for status changes)
CREATE POLICY "Users can update own jobs"
ON video_jobs FOR UPDATE
USING (auth.uid() = user_id);

-- Policy: Users can delete own jobs
CREATE POLICY "Users can delete own jobs"
ON video_jobs FOR DELETE
USING (auth.uid() = user_id);

-- =====================================================
-- Quota Log Table Policies
-- =====================================================

-- Policy: Users can view own transactions
CREATE POLICY "Users can view own transactions"
ON quota_log FOR SELECT
USING (auth.uid() = user_id);

-- Note: Only stored procedures (SECURITY DEFINER) insert into quota_log
-- No INSERT policy needed for users (they can't directly insert)

-- =====================================================
-- Idempotency Log Table Policies
-- =====================================================

-- Policy: Users can view own idempotency records
CREATE POLICY "Users can view own idempotency records"
ON idempotency_log FOR SELECT
USING (auth.uid() = user_id);

-- Note: Only backend (service_role) inserts into idempotency_log
-- No INSERT policy needed for users

-- =====================================================
-- Grant necessary permissions
-- =====================================================

-- Grant usage on schema to authenticated and anon users
GRANT USAGE ON SCHEMA public TO authenticated, anon;

-- Grant access to tables
GRANT SELECT, INSERT, UPDATE ON users TO authenticated, anon;
GRANT SELECT ON models TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON video_jobs TO authenticated, anon;
GRANT SELECT ON quota_log TO authenticated, anon;
GRANT SELECT ON idempotency_log TO authenticated, anon;

-- Grant execute on stored procedures
GRANT EXECUTE ON FUNCTION deduct_credits(UUID, INTEGER, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION add_credits(UUID, INTEGER, TEXT, TEXT) TO authenticated, anon;

-- =====================================================
-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ RLS policies enabled successfully!';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 Security Summary:';
    RAISE NOTICE '   - users: Can view/update own profile';
    RAISE NOTICE '   - models: Anyone can view available models only';
    RAISE NOTICE '   - video_jobs: Full CRUD access to own jobs';
    RAISE NOTICE '   - quota_log: View own transactions only';
    RAISE NOTICE '   - idempotency_log: View own records only';
    RAISE NOTICE '';
    RAISE NOTICE '✨ All users are isolated - they can only access their own data!';
    RAISE NOTICE '🛡️ Anonymous users (guests) are supported via auth.uid()';
END $$;
