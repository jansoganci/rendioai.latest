-- =====================================================
-- VERIFICATION SCRIPT: Check Storage Bucket Policies
-- =====================================================
-- This is NOT a migration - it's a verification script
-- Purpose: Verify all storage policies were created correctly
-- Run this in Supabase SQL Editor to verify policies
-- =====================================================

-- First, check if storage buckets exist
SELECT
    id AS "Bucket ID",
    name AS "Bucket Name",
    public AS "Is Public",
    file_size_limit AS "Max File Size (bytes)",
    CASE
        WHEN file_size_limit = 524288000 THEN '500 MB ✅'
        WHEN file_size_limit = 10485760 THEN '10 MB ✅'
        ELSE file_size_limit::text
    END AS "Size Limit",
    allowed_mime_types AS "Allowed MIME Types",
    CASE
        WHEN id = 'videos' AND file_size_limit = 524288000 THEN '✅ Correct'
        WHEN id = 'thumbnails' AND file_size_limit = 10485760 THEN '✅ Correct'
        ELSE '❌ Check config'
    END AS "Status"
FROM storage.buckets
WHERE id IN ('videos', 'thumbnails')
ORDER BY id;

-- Check storage.objects RLS policies (these are the actual storage policies)
SELECT
    schemaname AS "Schema",
    tablename AS "Table",
    policyname AS "Policy Name",
    cmd AS "Command",
    CASE
        WHEN cmd = 'SELECT' THEN '👁️ Read'
        WHEN cmd = 'INSERT' THEN '➕ Create'
        WHEN cmd = 'UPDATE' THEN '✏️ Update'
        WHEN cmd = 'DELETE' THEN '🗑️ Delete'
        WHEN cmd = 'ALL' THEN '🔓 All Operations'
    END AS "Type",
    roles AS "Roles",
    qual AS "USING Expression"
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
ORDER BY policyname;

-- =====================================================
-- Expected Output:
-- =====================================================
-- BUCKETS: Should show 2 buckets with correct configuration
-- POLICIES: Should show 8 RLS policies on storage.objects
--
-- Expected policies (created via Supabase Dashboard):
-- 1. Anyone can view videos (SELECT, bucket_id = 'videos')
-- 2. Authenticated users can upload videos (INSERT, bucket_id = 'videos')
-- 3. Users can update own videos (UPDATE, bucket_id = 'videos')
-- 4. Users can delete own videos (DELETE, bucket_id = 'videos')
-- 5. Anyone can view thumbnails (SELECT, bucket_id = 'thumbnails')
-- 6. Authenticated users can upload thumbnails (INSERT, bucket_id = 'thumbnails')
-- 7. Users can update own thumbnails (UPDATE, bucket_id = 'thumbnails')
-- 8. Users can delete own thumbnails (DELETE, bucket_id = 'thumbnails')
-- =====================================================

-- Summary: Count total policies
SELECT
    COUNT(*) AS "Total Storage Policies",
    CASE
        WHEN COUNT(*) >= 8 THEN '✅ At least 8 policies exist'
        WHEN COUNT(*) = 0 THEN '❌ NO POLICIES FOUND - Need to create via Dashboard'
        ELSE '⚠️ Only ' || COUNT(*)::text || ' policies found - Expected 8'
    END AS "Status"
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects';

-- Detailed summary: Check coverage
SELECT
    'Buckets Created' AS "Check",
    CASE
        WHEN (SELECT COUNT(*) FROM storage.buckets WHERE id IN ('videos', 'thumbnails')) = 2
        THEN '✅ Both buckets exist (videos, thumbnails)'
        ELSE '❌ Missing buckets - Expected: videos, thumbnails'
    END AS "Result"
UNION ALL
SELECT
    'Buckets are Public' AS "Check",
    CASE
        WHEN (SELECT COUNT(*) FROM storage.buckets WHERE id IN ('videos', 'thumbnails') AND public = true) = 2
        THEN '✅ Both buckets are public'
        ELSE '❌ Some buckets are not public'
    END AS "Result"
UNION ALL
SELECT
    'Storage Policies Exist' AS "Check",
    CASE
        WHEN (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects') >= 8
        THEN '✅ At least 8 policies configured'
        WHEN (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects') = 0
        THEN '❌ NO POLICIES - Need to create via Dashboard'
        ELSE '⚠️ Only ' || (SELECT COUNT(*)::text FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects') || ' policies'
    END AS "Result"
UNION ALL
SELECT
    'Videos File Size Limit' AS "Check",
    CASE
        WHEN (SELECT file_size_limit FROM storage.buckets WHERE id = 'videos') = 524288000
        THEN '✅ 500 MB (correct)'
        ELSE '❌ Incorrect size: ' || (SELECT file_size_limit::text FROM storage.buckets WHERE id = 'videos')
    END AS "Result"
UNION ALL
SELECT
    'Thumbnails File Size Limit' AS "Check",
    CASE
        WHEN (SELECT file_size_limit FROM storage.buckets WHERE id = 'thumbnails') = 10485760
        THEN '✅ 10 MB (correct)'
        ELSE '❌ Incorrect size: ' || (SELECT file_size_limit::text FROM storage.buckets WHERE id = 'thumbnails')
    END AS "Result";

-- =====================================================
-- FINAL SUMMARY
-- =====================================================
SELECT
    '==================================' AS "FINAL SUMMARY",
    '' AS " ";

SELECT
    CASE
        WHEN (SELECT COUNT(*) FROM storage.buckets WHERE id IN ('videos', 'thumbnails')) = 2
            AND (SELECT COUNT(*) FROM storage.buckets WHERE id IN ('videos', 'thumbnails') AND public = true) = 2
            AND (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects') >= 8
            AND (SELECT file_size_limit FROM storage.buckets WHERE id = 'videos') = 524288000
            AND (SELECT file_size_limit FROM storage.buckets WHERE id = 'thumbnails') = 10485760
        THEN '🎉 ✅ ALL STORAGE CHECKS PASSED! Ready for Phase 1!'
        WHEN (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects') = 0
        THEN '⚠️ NO STORAGE POLICIES FOUND - You need to create them via Supabase Dashboard'
        ELSE '⚠️ SOME CHECKS FAILED - Review results above'
    END AS "Overall Status";
-- =====================================================
