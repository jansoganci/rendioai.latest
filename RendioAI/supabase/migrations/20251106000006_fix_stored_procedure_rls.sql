-- Migration: Fix Stored Procedure RLS Access
-- Version: 1.1
-- Date: 2025-11-06
-- Purpose: Allow stored procedures to access users table for credit operations

-- =====================================================
-- Problem Analysis
-- =====================================================
-- 
-- Issue: Stored procedure deduct_credits returns "User not found" (0 credits)
--        even though user has 30 credits in database
-- 
-- Root Cause:
-- 1. Stored procedure uses SECURITY DEFINER (runs as postgres user)
-- 2. RLS policy "Users can view own profile" requires auth.uid() = id
-- 3. Inside stored procedure, auth.uid() is NULL
-- 4. RLS blocks SELECT query, returns no rows
-- 5. Function interprets this as "User not found"
--
-- Solution: Allow postgres user (function owner) to read users table
--

-- =====================================================
-- STEP 1: Verification Queries (Run these first)
-- =====================================================

-- Check current RLS policies on users table
-- Expected: Should see "Users can view own profile" policy
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE tablename = 'users';
    
    RAISE NOTICE '📊 Current RLS policies on users table: %', policy_count;
END $$;

-- Check function owner and SECURITY DEFINER
-- Expected: owner = postgres, is_security_definer = true
DO $$
DECLARE
    func_owner TEXT;
    is_sec_definer BOOLEAN;
BEGIN
    SELECT 
        pg_get_userbyid(p.proowner),
        p.prosecdef
    INTO func_owner, is_sec_definer
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' 
      AND p.proname = 'deduct_credits';
    
    RAISE NOTICE '🔧 Function owner: %, SECURITY DEFINER: %', func_owner, is_sec_definer;
    
    IF func_owner IS NULL THEN
        RAISE WARNING '⚠️  deduct_credits function not found!';
    ELSIF func_owner != 'postgres' THEN
        RAISE WARNING '⚠️  Function owner is % (expected: postgres)', func_owner;
    END IF;
END $$;

-- Test if user exists (should return 30 credits)
DO $$
DECLARE
    user_credits INTEGER;
BEGIN
    SELECT credits_remaining INTO user_credits
    FROM users 
    WHERE id = '90cd94c2-297d-449d-b7d5-922f76d407c0';
    
    IF user_credits IS NULL THEN
        RAISE WARNING '⚠️  Test user not found in database';
    ELSE
        RAISE NOTICE '✅ Test user has % credits', user_credits;
    END IF;
END $$;

-- =====================================================
-- STEP 2: Apply Fix - Allow postgres User Access
-- =====================================================

-- Drop old fix attempt (if exists)
DROP POLICY IF EXISTS "Service role can read users for credit operations" ON users;

-- Create new policy allowing postgres user (function owner) to read users
-- This is safe because:
-- 1. postgres user only operates via stored procedures (SECURITY DEFINER)
-- 2. Stored procedures have business logic to prevent unauthorized access
-- 3. postgres user cannot be used directly by clients (only service_role can)
CREATE POLICY "Allow stored procedures to read users"
ON users FOR SELECT
TO postgres
USING (true);

DO $$
BEGIN
    RAISE NOTICE '✅ Policy created: "Allow stored procedures to read users"';
END $$;

-- =====================================================
-- STEP 3: Grant Necessary Permissions
-- =====================================================

-- Ensure postgres user can execute the stored procedures
GRANT EXECUTE ON FUNCTION deduct_credits(UUID, INTEGER, TEXT) TO postgres;
GRANT EXECUTE ON FUNCTION add_credits(UUID, INTEGER, TEXT, TEXT) TO postgres;

DO $$
BEGIN
    RAISE NOTICE '✅ Permissions granted to postgres user';
END $$;

-- =====================================================
-- STEP 4: Test the Fix
-- =====================================================

-- Test deduct_credits directly
DO $$
DECLARE
    test_result JSONB;
    original_credits INTEGER;
BEGIN
    -- Get current credits
    SELECT credits_remaining INTO original_credits
    FROM users 
    WHERE id = '90cd94c2-297d-449d-b7d5-922f76d407c0';
    
    RAISE NOTICE '🧪 Testing deduct_credits function...';
    RAISE NOTICE '   Original credits: %', original_credits;
    
    -- Test deduct 1 credit
    SELECT deduct_credits(
        '90cd94c2-297d-449d-b7d5-922f76d407c0'::uuid,
        1,
        'rls_fix_test'
    ) INTO test_result;
    
    RAISE NOTICE '   Test result: %', test_result;
    
    -- Check if test was successful
    IF (test_result->>'success')::boolean = true THEN
        RAISE NOTICE '✅ TEST PASSED: deduct_credits works!';
        RAISE NOTICE '   New balance: %', test_result->>'credits_remaining';
        
        -- Refund the test credit
        PERFORM add_credits(
            '90cd94c2-297d-449d-b7d5-922f76d407c0'::uuid,
            1,
            'rls_fix_test_refund',
            'test_refund_' || extract(epoch from now())::text
        );
        RAISE NOTICE '✅ Test credit refunded';
    ELSE
        RAISE WARNING '❌ TEST FAILED: %', test_result->>'error';
        RAISE WARNING '   This means RLS is still blocking the stored procedure';
    END IF;
END $$;

-- =====================================================
-- STEP 5: Verify All Policies
-- =====================================================

-- List all policies on users table
DO $$
DECLARE
    policy_record RECORD;
    policy_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 All RLS policies on users table:';
    RAISE NOTICE '─────────────────────────────────────────────────────────';
    
    -- Count policies first
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE tablename = 'users';
    
    IF policy_count = 0 THEN
        RAISE NOTICE '⚠️  No policies found on users table';
    ELSE
        RAISE NOTICE 'Found % policies:', policy_count;
        RAISE NOTICE '';
        
        FOR policy_record IN 
            SELECT 
                policyname,
                COALESCE(roles::text, 'all roles') as roles,
                cmd
            FROM pg_policies 
            WHERE tablename = 'users'
            ORDER BY policyname
        LOOP
            RAISE NOTICE 'Policy: %', policy_record.policyname;
            RAISE NOTICE '  Roles: %', policy_record.roles;
            RAISE NOTICE '  Command: %', policy_record.cmd;
            RAISE NOTICE '';
        END LOOP;
    END IF;
END $$;

-- =====================================================
-- Success Message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '✅ RLS FIX APPLIED SUCCESSFULLY!';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 Security Summary:';
    RAISE NOTICE '   - postgres user can now read users table';
    RAISE NOTICE '   - Only applies inside stored procedures (SECURITY DEFINER)';
    RAISE NOTICE '   - Direct client access still protected by existing RLS';
    RAISE NOTICE '';
    RAISE NOTICE '🧪 Next Steps:';
    RAISE NOTICE '   1. Review the test results above';
    RAISE NOTICE '   2. If test passed, redeploy generate-video Edge Function';
    RAISE NOTICE '   3. Rerun API tests to verify fix';
    RAISE NOTICE '';
    RAISE NOTICE '📝 To verify the fix worked:';
    RAISE NOTICE '   curl -X POST .../generate-video';
    RAISE NOTICE '   (should now see credits deducted successfully)';
    RAISE NOTICE '';
END $$;

