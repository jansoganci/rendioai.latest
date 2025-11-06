-- =====================================================
-- VERIFICATION SCRIPT: Check Foreign Key Constraints
-- =====================================================
-- This is NOT a migration - it's a verification script
-- Purpose: Verify that video_jobs.model_id has ON DELETE RESTRICT
-- Run this in Supabase SQL Editor to verify constraints
-- =====================================================

-- Check all foreign key constraints on video_jobs table
SELECT
    tc.constraint_name AS "Constraint Name",
    kcu.column_name AS "Column",
    ccu.table_name AS "References Table",
    ccu.column_name AS "References Column",
    rc.delete_rule AS "On Delete Rule",
    rc.update_rule AS "On Update Rule"
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
JOIN information_schema.referential_constraints AS rc
  ON rc.constraint_name = tc.constraint_name
  AND rc.constraint_schema = tc.table_schema
WHERE tc.table_name = 'video_jobs'
  AND tc.constraint_type = 'FOREIGN KEY'
ORDER BY kcu.column_name;

-- =====================================================
-- Expected Output:
-- =====================================================
-- Should show 2 foreign keys:
--
-- 1. model_id → models(id)
--    - On Delete Rule: RESTRICT ✅ (correct)
--    - On Update Rule: NO ACTION
--
-- 2. user_id → users(id)
--    - On Delete Rule: CASCADE ✅ (correct - if user deleted, delete their jobs)
--    - On Update Rule: NO ACTION
-- =====================================================

-- Additional check: Show a summary
SELECT
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM information_schema.referential_constraints rc
            JOIN information_schema.key_column_usage kcu
              ON rc.constraint_name = kcu.constraint_name
            WHERE kcu.table_name = 'video_jobs'
              AND kcu.column_name = 'model_id'
              AND rc.delete_rule = 'RESTRICT'
        ) THEN '✅ CORRECT: model_id has ON DELETE RESTRICT'
        ELSE '❌ WRONG: model_id does NOT have ON DELETE RESTRICT'
    END AS "model_id Foreign Key Check",

    CASE
        WHEN EXISTS (
            SELECT 1
            FROM information_schema.referential_constraints rc
            JOIN information_schema.key_column_usage kcu
              ON rc.constraint_name = kcu.constraint_name
            WHERE kcu.table_name = 'video_jobs'
              AND kcu.column_name = 'user_id'
              AND rc.delete_rule = 'CASCADE'
        ) THEN '✅ CORRECT: user_id has ON DELETE CASCADE'
        ELSE '❌ WRONG: user_id does NOT have ON DELETE CASCADE'
    END AS "user_id Foreign Key Check";
