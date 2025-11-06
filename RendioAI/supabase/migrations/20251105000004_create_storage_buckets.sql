-- Migration: Create storage buckets for videos and thumbnails
-- Version: 1.0
-- Date: 2025-11-05
-- Purpose: Store generated videos and thumbnail images
-- Status: ✅ COMPLETED VIA SUPABASE DASHBOARD UI (CLI had issues)
--
-- This file documents what was created. The actual setup was done via:
-- https://ojcnjxzctnwbmupggoxq.supabase.co/project/ojcnjxzctnwbmupggoxq/storage
--
-- CREATED:
-- - Bucket: videos (public, 500MB limit, video/* mime types)
-- - Bucket: thumbnails (public, 10MB limit, image/* mime types)
-- - 4 policies per bucket (SELECT, INSERT, UPDATE, DELETE)
--
-- NOTE: Storage bucket creation via SQL migrations is not well-supported by Supabase CLI.
-- Dashboard UI is the recommended approach for storage setup.

-- =====================================================
-- Create Storage Buckets
-- =====================================================

-- Bucket: videos
-- Purpose: Store generated video files
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'videos',
    'videos',
    true,  -- Public bucket (files accessible via URL)
    524288000,  -- 500 MB file size limit
    ARRAY['video/mp4', 'video/quicktime', 'video/webm']  -- Allowed video formats
)
ON CONFLICT (id) DO NOTHING;

-- Bucket: thumbnails
-- Purpose: Store video thumbnail/preview images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'thumbnails',
    'thumbnails',
    true,  -- Public bucket (images accessible via URL)
    10485760,  -- 10 MB file size limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']  -- Allowed image formats
)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- Storage Policies: videos bucket
-- =====================================================

-- Policy: Anyone can view videos
CREATE POLICY "Anyone can view videos"
ON storage.objects FOR SELECT
USING (bucket_id = 'videos');

-- Policy: Authenticated users can upload videos
CREATE POLICY "Authenticated users can upload videos"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'videos' AND
    auth.role() = 'authenticated'
);

-- Policy: Users can update own videos
CREATE POLICY "Users can update own videos"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'videos' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Users can delete own videos
CREATE POLICY "Users can delete own videos"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'videos' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- =====================================================
-- Storage Policies: thumbnails bucket
-- =====================================================

-- Policy: Anyone can view thumbnails
CREATE POLICY "Anyone can view thumbnails"
ON storage.objects FOR SELECT
USING (bucket_id = 'thumbnails');

-- Policy: Authenticated users can upload thumbnails
CREATE POLICY "Authenticated users can upload thumbnails"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'thumbnails' AND
    auth.role() = 'authenticated'
);

-- Policy: Users can update own thumbnails
CREATE POLICY "Users can update own thumbnails"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'thumbnails' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Users can delete own thumbnails
CREATE POLICY "Users can delete own thumbnails"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'thumbnails' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- =====================================================
-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Storage buckets created successfully!';
    RAISE NOTICE '';
    RAISE NOTICE '📦 Buckets:';
    RAISE NOTICE '   - videos (public, 500MB limit, MP4/MOV/WEBM)';
    RAISE NOTICE '   - thumbnails (public, 10MB limit, JPEG/PNG/WEBP/GIF)';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 Storage Security:';
    RAISE NOTICE '   - Public read access (anyone can view)';
    RAISE NOTICE '   - Authenticated write access (logged-in users)';
    RAISE NOTICE '   - Users can only modify/delete own files';
    RAISE NOTICE '';
    RAISE NOTICE '📁 File Structure: {bucket}/{user_id}/{filename}';
    RAISE NOTICE '   Example: videos/abc-123-def/video-001.mp4';
END $$;
