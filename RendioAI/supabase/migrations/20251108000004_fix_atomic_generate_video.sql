-- Migration: Fix Atomic Video Generation Procedure
-- Version: 1.1 (Hotfix)
-- Date: 2025-11-08
-- Phase: 5.5 - Performance Optimization (Hotfix)
-- Purpose: Fix critical bugs in generate_video_atomic procedure
--
-- FIXES:
-- 1. RETURNING clause: id → job_id (Issue #2A)
-- 2. Idempotency insert: Add missing NOT NULL columns (Issue #2B)
--    - job_id (FK to video_jobs)
--    - operation_type (TEXT NOT NULL)
--    - response_data (JSONB NOT NULL)
--    - status_code (INTEGER NOT NULL)

-- =====================================================
-- Step 1: Replace Atomic Video Generation Function
-- =====================================================

CREATE OR REPLACE FUNCTION generate_video_atomic(
  p_user_id UUID,
  p_model_id UUID,
  p_prompt TEXT,
  p_settings JSONB,
  p_idempotency_key UUID
)
RETURNS JSONB AS $$
DECLARE
  v_credits_cost INTEGER;
  v_user_credits INTEGER;
  v_job_id UUID;
BEGIN
  -- 1. Lock user row for credit deduction (prevents race conditions)
  SELECT credits_remaining INTO v_user_credits
  FROM users
  WHERE id = p_user_id
  FOR UPDATE;

  -- 2. Calculate cost from model table
  SELECT cost_per_generation INTO v_credits_cost
  FROM models
  WHERE id = p_model_id;

  -- Validate cost exists
  IF v_credits_cost IS NULL THEN
    RAISE EXCEPTION 'Model not found or missing cost' USING ERRCODE = 'P0002';
  END IF;

  -- 3. Check if user has sufficient credits
  IF v_user_credits < v_credits_cost THEN
    RAISE EXCEPTION 'Insufficient credits' USING ERRCODE = 'P0001';
  END IF;

  -- 4. Deduct credits atomically
  UPDATE users
  SET credits_remaining = credits_remaining - v_credits_cost
  WHERE id = p_user_id;

  -- 5. Create video job
  -- FIX #1: Changed RETURNING id → job_id (correct column name)
  INSERT INTO video_jobs (user_id, model_id, prompt, settings, credits_used, status)
  VALUES (p_user_id, p_model_id, p_prompt, p_settings, v_credits_cost, 'pending')
  RETURNING job_id INTO v_job_id;

  -- 6. Insert idempotency record
  -- FIX #2: Added missing NOT NULL columns:
  --   - job_id (FK reference)
  --   - operation_type (required for tracking)
  --   - response_data (required for idempotent replay)
  --   - status_code (required for HTTP response)
  INSERT INTO idempotency_log (
    idempotency_key,
    user_id,
    job_id,
    operation_type,
    response_data,
    status_code,
    created_at,
    expires_at
  )
  VALUES (
    p_idempotency_key,
    p_user_id,
    v_job_id,
    'generate_video',
    jsonb_build_object(
      'job_id', v_job_id,
      'credits_used', v_credits_cost,
      'status', 'pending'
    ),
    200,
    NOW(),
    NOW() + INTERVAL '24 hours'
  );

  -- 7. Return job details as JSON
  RETURN jsonb_build_object(
    'job_id', v_job_id,
    'credits_used', v_credits_cost,
    'status', 'pending'
  );
EXCEPTION
  WHEN OTHERS THEN
    -- Log error and rollback entire transaction
    RAISE NOTICE 'Transaction rolled back: %', SQLERRM;
    RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Step 2: Verify Function Updated
-- =====================================================

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_proc
        WHERE proname = 'generate_video_atomic'
    ) THEN
        RAISE NOTICE '✅ generate_video_atomic function updated successfully';
        RAISE NOTICE '';
        RAISE NOTICE '📋 Hotfix Details:';
        RAISE NOTICE '   Fix #1: RETURNING id → RETURNING job_id';
        RAISE NOTICE '   Fix #2: Added missing idempotency columns:';
        RAISE NOTICE '      - job_id (UUID FK)';
        RAISE NOTICE '      - operation_type (TEXT = ''generate_video'')';
        RAISE NOTICE '      - response_data (JSONB with job details)';
        RAISE NOTICE '      - status_code (INTEGER = 200)';
        RAISE NOTICE '';
        RAISE NOTICE '🔒 Atomicity Guarantees (unchanged):';
        RAISE NOTICE '   ✓ Credits deducted and job created in single transaction';
        RAISE NOTICE '   ✓ User row locked (FOR UPDATE) to prevent race conditions';
        RAISE NOTICE '   ✓ Automatic rollback on any error';
        RAISE NOTICE '   ✓ No partial updates possible';
        RAISE NOTICE '';
        RAISE NOTICE '✅ Video generation should now work correctly';
    ELSE
        RAISE EXCEPTION '❌ Failed to update generate_video_atomic function';
    END IF;
END $$;

-- =====================================================
-- Step 3: Test the Fixed Function (Optional)
-- =====================================================

-- To manually test after migration:
-- SELECT generate_video_atomic(
--     'user-uuid'::uuid,
--     'model-uuid'::uuid,
--     'test prompt',
--     '{}'::jsonb,
--     gen_random_uuid()
-- );

-- Expected result:
-- {
--   "job_id": "newly-generated-uuid",
--   "credits_used": 4,
--   "status": "pending"
-- }

-- Verify idempotency_log record:
-- SELECT * FROM idempotency_log ORDER BY created_at DESC LIMIT 1;
-- Expected columns populated:
--   - idempotency_key ✓
--   - user_id ✓
--   - job_id ✓ (NEW - was missing)
--   - operation_type ✓ (NEW - was missing)
--   - response_data ✓ (NEW - was missing)
--   - status_code ✓ (NEW - was missing)

-- =====================================================
-- Success Summary
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '✅ HOTFIX COMPLETE: Atomic Video Generation Fixed';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Next Steps:';
    RAISE NOTICE '   1. Test video generation end-to-end';
    RAISE NOTICE '   2. Verify job_id returned correctly';
    RAISE NOTICE '   3. Verify idempotency_log has all required columns';
    RAISE NOTICE '   4. Monitor backend logs for successful completions';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  Still Pending:';
    RAISE NOTICE '   - Fix Realtime filter bug (ResultService.swift)';
    RAISE NOTICE '   - Add fallback mechanism (ResultViewModel.swift)';
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
END $$;
