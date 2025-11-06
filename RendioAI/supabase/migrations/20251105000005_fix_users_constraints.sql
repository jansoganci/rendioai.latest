-- Migration: Fix missing constraints on users table
-- Version: 1.0
-- Date: 2025-11-05
-- Purpose: Ensure data integrity - users must have either email OR device_id

-- =====================================================
-- Add CHECK constraint: email OR device_id must exist
-- =====================================================

ALTER TABLE users
ADD CONSTRAINT users_identity_check
CHECK (
    (email IS NOT NULL) OR (device_id IS NOT NULL)
);

-- =====================================================
-- Add comment explaining the constraint
-- =====================================================

COMMENT ON CONSTRAINT users_identity_check ON users IS
'Ensures every user has at least one identity: email (for registered users) OR device_id (for guest users)';

-- =====================================================
-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Users table constraint fixed!';
    RAISE NOTICE '   - Added CHECK: email OR device_id must be NOT NULL';
    RAISE NOTICE '   - This prevents orphaned users with no identity';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 Data Integrity: Users must have at least one identifier';
END $$;
