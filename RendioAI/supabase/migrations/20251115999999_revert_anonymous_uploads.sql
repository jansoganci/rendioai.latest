-- IMPORTANT: DO NOT DEPLOY THIS MIGRATION UNTIL iOS APP IS UPDATED
-- This migration reverts the temporary anonymous upload policy
-- Deploy only AFTER iOS app is updated to use JWT tokens from device-check endpoint

-- Drop the temporary anonymous upload policy
DROP POLICY IF EXISTS "Anyone can upload thumbnails (temporary)" ON storage.objects;

-- Reinstate the secure policy that requires authentication
CREATE POLICY "Authenticated users can upload thumbnails"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'thumbnails'
  AND auth.role() = 'authenticated'
);

-- Add comment explaining the change
COMMENT ON POLICY "Authenticated users can upload thumbnails" ON storage.objects IS
'Secure policy requiring authentication for uploads. iOS app must use JWT token from device-check endpoint.';

-- Log the policy change for audit
INSERT INTO public.audit_log (action, details, created_at)
VALUES (
  'storage_policy_reverted',
  jsonb_build_object(
    'policy', 'anonymous_uploads',
    'bucket', 'thumbnails',
    'reason', 'Security vulnerability closed after iOS app update'
  ),
  NOW()
)
ON CONFLICT DO NOTHING;  -- In case audit_log table doesn't exist

-- Verify the policy is correctly applied
DO $$
BEGIN
  -- Check that the secure policy exists
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
    AND tablename = 'objects'
    AND policyname = 'Authenticated users can upload thumbnails'
  ) THEN
    RAISE EXCEPTION 'Failed to create secure upload policy';
  END IF;

  -- Check that the anonymous policy is removed
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
    AND tablename = 'objects'
    AND policyname = 'Anyone can upload thumbnails (temporary)'
  ) THEN
    RAISE EXCEPTION 'Failed to remove anonymous upload policy';
  END IF;
END $$;