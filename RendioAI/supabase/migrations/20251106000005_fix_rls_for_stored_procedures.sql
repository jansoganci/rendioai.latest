-- Migration: Fix RLS for stored procedures
-- Version: 1.0
-- Date: 2025-11-06
-- Purpose: Ensure stored procedures can access users table when called via service_role

-- =====================================================
-- Understanding the Issue
-- =====================================================
-- 
-- Problem:
-- - Stored procedures use SECURITY DEFINER (run as function owner)
-- - Function owner should bypass RLS, but sometimes RLS still applies
-- - Edge Functions use service_role key (which already bypasses RLS)
-- 
-- Solution:
-- - Explicitly allow service_role to read users table
-- - This is safe because service_role already bypasses RLS by default
-- - But being explicit ensures stored procedures work correctly
--

-- =====================================================
-- Allow service_role to read users table
-- =====================================================

-- This policy allows service_role to read users table
-- Note: service_role already bypasses RLS, but this makes it explicit
-- This is safe because:
-- 1. service_role is only used server-side (Edge Functions)
-- 2. service_role already has full database access
-- 3. This policy doesn't grant any additional permissions

-- Drop policy if it exists (to allow re-running this migration)
DROP POLICY IF EXISTS "Service role can read users for credit operations" ON users;

-- Create the policy
CREATE POLICY "Service role can read users for credit operations"
ON users FOR SELECT
TO service_role
USING (true);

-- =====================================================
-- Verify stored procedure permissions
-- =====================================================

-- Ensure stored procedures are owned by postgres (or service_role)
-- This ensures SECURITY DEFINER functions run with proper privileges
DO $$
BEGIN
    -- Check function ownership
    IF EXISTS (
        SELECT 1 
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public' 
        AND p.proname = 'deduct_credits'
        AND p.prosecdef = true  -- SECURITY DEFINER
    ) THEN
        RAISE NOTICE '✅ deduct_credits function uses SECURITY DEFINER';
    ELSE
        RAISE WARNING '⚠️  deduct_credits function does not use SECURITY DEFINER';
    END IF;
END $$;

-- =====================================================
-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ RLS policy for service_role created successfully!';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 Security Notes:';
    RAISE NOTICE '   - service_role already bypasses RLS by default';
    RAISE NOTICE '   - This policy is explicit and redundant (but safe)';
    RAISE NOTICE '   - Stored procedures use SECURITY DEFINER (run as owner)';
    RAISE NOTICE '   - Edge Functions use service_role (server-side only)';
    RAISE NOTICE '';
    RAISE NOTICE '✅ This should fix the credit reading issue in Edge Functions';
END $$;

