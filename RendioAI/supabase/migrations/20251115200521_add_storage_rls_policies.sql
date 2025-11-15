-- Add proper Storage RLS policies for videos and thumbnails buckets
-- These policies require authenticated users and match folder structure with auth.uid()

-- NOTE: This migration must be run with service role permissions
-- Run with: supabase db push OR supabase migration up
-- DO NOT run in SQL Editor (it doesn't have permission to modify storage.objects)

-- First, let's ensure the buckets exist with proper settings
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('videos', 'videos', true, 524288000, '{"video/mp4", "video/mpeg", "video/quicktime", "video/webm"}'),  -- 500MB limit
  ('thumbnails', 'thumbnails', true, 10485760, '{"image/jpeg", "image/jpg", "image/png", "image/webp", "image/gif"}')  -- 10MB limit
ON CONFLICT (id) DO UPDATE
SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Drop existing policies if they exist (clean slate)
DO $$
BEGIN
  -- Drop old policies if they exist
  DROP POLICY IF EXISTS "Authenticated users can upload videos" ON storage.objects;
  DROP POLICY IF EXISTS "Authenticated users can update videos" ON storage.objects;
  DROP POLICY IF EXISTS "Authenticated users can delete videos" ON storage.objects;
  DROP POLICY IF EXISTS "Anyone can view videos" ON storage.objects;
  DROP POLICY IF EXISTS "Authenticated users can upload thumbnails" ON storage.objects;
  DROP POLICY IF EXISTS "Authenticated users can update thumbnails" ON storage.objects;
  DROP POLICY IF EXISTS "Authenticated users can delete thumbnails" ON storage.objects;
  DROP POLICY IF EXISTS "Anyone can view thumbnails" ON storage.objects;

  -- Drop new policies if they exist (for idempotency)
  DROP POLICY IF EXISTS "Auth users upload own videos" ON storage.objects;
  DROP POLICY IF EXISTS "Auth users update own videos" ON storage.objects;
  DROP POLICY IF EXISTS "Auth users delete own videos" ON storage.objects;
  DROP POLICY IF EXISTS "Public read videos" ON storage.objects;
  DROP POLICY IF EXISTS "Auth users upload own thumbnails" ON storage.objects;
  DROP POLICY IF EXISTS "Auth users update own thumbnails" ON storage.objects;
  DROP POLICY IF EXISTS "Auth users delete own thumbnails" ON storage.objects;
  DROP POLICY IF EXISTS "Public read thumbnails" ON storage.objects;
EXCEPTION
  WHEN undefined_table THEN
    NULL; -- Ignore if table doesn't exist
  WHEN undefined_object THEN
    NULL; -- Ignore if policies don't exist
END $$;

-- Videos bucket policies
-- Path structure: videos/{auth.uid()}/{YYYY-MM}/{filename}

-- Policy: Authenticated users can upload videos to their folder
CREATE POLICY "Auth users upload own videos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'videos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Authenticated users can update their own videos
CREATE POLICY "Auth users update own videos"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'videos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Authenticated users can delete their own videos
CREATE POLICY "Auth users delete own videos"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'videos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Public read access for videos (since bucket is public)
CREATE POLICY "Public read videos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'videos');

-- Thumbnails bucket policies
-- Path structure: thumbnails/{auth.uid()}/{YYYY-MM}/{filename}

-- Policy: Authenticated users can upload thumbnails to their folder
CREATE POLICY "Auth users upload own thumbnails"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'thumbnails'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Authenticated users can update their own thumbnails
CREATE POLICY "Auth users update own thumbnails"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'thumbnails'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Authenticated users can delete their own thumbnails
CREATE POLICY "Auth users delete own thumbnails"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'thumbnails'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Public read access for thumbnails (since bucket is public)
CREATE POLICY "Public read thumbnails"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'thumbnails');

-- Note: These policies work with Supabase auth sessions
-- The device-check endpoint must be updated to create anonymous auth sessions
-- iOS app must use the session token for Storage operations
