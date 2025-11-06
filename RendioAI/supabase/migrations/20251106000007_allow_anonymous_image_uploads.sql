-- Migration: Allow Anonymous Image Uploads (Temporary for Demo)
-- Version: 1.0
-- Date: 2025-11-06
-- Purpose: Update RLS policy to allow anonymous users to upload images to thumbnails bucket
-- Status: ⚠️ TEMPORARY - Must revert before production (see GENERAL_TECHNICAL_DECISIONS.md)
--
-- This is a temporary solution to allow image uploads for demo purposes.
-- Before production, implement proper authentication (Option A or B from technical decisions).
--
-- Related: GENERAL_TECHNICAL_DECISIONS.md - Section 6: Image Upload Storage (RLS Policy)

-- =====================================================
-- Update Storage Policy: thumbnails bucket
-- =====================================================

-- Drop existing policy that requires authentication
DROP POLICY IF EXISTS "Authenticated users can upload thumbnails" ON storage.objects;

-- Create new policy that allows anonymous users to upload
-- ⚠️ WARNING: This is less secure - allows anyone with anon key to upload
-- TODO: Revert this before production and implement proper auth
CREATE POLICY "Anyone can upload thumbnails (temporary)"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'thumbnails');

-- =====================================================
-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Storage policy updated successfully!';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  WARNING: This is a TEMPORARY solution for demo purposes';
    RAISE NOTICE '   - Anonymous users can now upload images';
    RAISE NOTICE '   - This is less secure than authenticated uploads';
    RAISE NOTICE '   - Must revert before production launch';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Next Steps (Before Production):';
    RAISE NOTICE '   1. Implement proper auth (Option A or B)';
    RAISE NOTICE '   2. Revert this policy to require authentication';
    RAISE NOTICE '   3. Update ImageUploadService to use session tokens';
    RAISE NOTICE '';
    RAISE NOTICE '📄 See: GENERAL_TECHNICAL_DECISIONS.md - Section 6';
END $$;

