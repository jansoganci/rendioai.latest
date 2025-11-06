-- Migration: Add identity check constraint to users table
-- Version: 1.0
-- Date: 2025-11-05
-- Purpose: Ensure users always have either email or device_id (data integrity)

-- =====================================================
-- Add Identity Check Constraint
-- =====================================================

-- Ensure users always have at least one identifier (email OR device_id)
ALTER TABLE users ADD CONSTRAINT users_identity_check 
CHECK ((email IS NOT NULL) OR (device_id IS NOT NULL));

-- =====================================================
-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Identity check constraint added successfully!';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 Data Integrity:';
    RAISE NOTICE '   - Users must have either email OR device_id';
    RAISE NOTICE '   - Prevents orphaned user records';
END $$;

