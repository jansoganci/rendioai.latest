# Storage RLS Policies Setup Guide

**Problem:** SQL Editor doesn't have permission to create Storage policies.

**Solution:** Use Supabase Dashboard to set up Storage policies manually.

---

## Step 1: Enable RLS on Storage Buckets

Go to: **Supabase Dashboard → Storage → Configuration → Policies**

Enable RLS for both buckets if not already enabled.

---

## Step 2: Videos Bucket Policies

### Policy 1: Auth users upload own videos

- **Operation:** INSERT
- **Target roles:** authenticated
- **Policy name:** Auth users upload own videos
- **WITH CHECK expression:**
```sql
(bucket_id = 'videos'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text)
```

### Policy 2: Auth users update own videos

- **Operation:** UPDATE
- **Target roles:** authenticated
- **Policy name:** Auth users update own videos
- **USING expression:**
```sql
(bucket_id = 'videos'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text)
```

### Policy 3: Auth users delete own videos

- **Operation:** DELETE
- **Target roles:** authenticated
- **Policy name:** Auth users delete own videos
- **USING expression:**
```sql
(bucket_id = 'videos'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text)
```

### Policy 4: Public read videos

- **Operation:** SELECT
- **Target roles:** public
- **Policy name:** Public read videos
- **USING expression:**
```sql
bucket_id = 'videos'::text
```

---

## Step 3: Thumbnails Bucket Policies

### Policy 1: Auth users upload own thumbnails

- **Operation:** INSERT
- **Target roles:** authenticated
- **Policy name:** Auth users upload own thumbnails
- **WITH CHECK expression:**
```sql
(bucket_id = 'thumbnails'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text)
```

### Policy 2: Auth users update own thumbnails

- **Operation:** UPDATE
- **Target roles:** authenticated
- **Policy name:** Auth users update own thumbnails
- **USING expression:**
```sql
(bucket_id = 'thumbnails'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text)
```

### Policy 3: Auth users delete own thumbnails

- **Operation:** DELETE
- **Target roles:** authenticated
- **Policy name:** Auth users delete own thumbnails
- **USING expression:**
```sql
(bucket_id = 'thumbnails'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text)
```

### Policy 4: Public read thumbnails

- **Operation:** SELECT
- **Target roles:** public
- **Policy name:** Public read thumbnails
- **USING expression:**
```sql
bucket_id = 'thumbnails'::text
```

---

## Verification

After setting up all policies, verify by running this query in SQL Editor:

```sql
-- Check that policies exist
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'objects'
  AND schemaname = 'storage'
ORDER BY policyname;
```

You should see 8 policies total (4 for videos, 4 for thumbnails).

---

## Path Structure

Both buckets use this structure:
```
{bucket_name}/{auth.uid()}/{YYYY-MM}/{filename}

Examples:
- videos/a1b2c3d4-e5f6-7890-abcd-ef1234567890/2025-01/video123.mp4
- thumbnails/a1b2c3d4-e5f6-7890-abcd-ef1234567890/2025-01/image456.jpg
```

The policies check that `(storage.foldername(name))[1]` (first folder level) matches the user's `auth.uid()`.

---

## Important Notes

1. **These policies require authenticated users** - Anonymous access is removed
2. **device-check endpoint must create auth sessions** - See migration 20251115200520
3. **iOS app must use JWT tokens** - Update ImageUploadService to use session tokens
4. **Public read access** - Anyone can view videos/thumbnails, but only owners can upload/modify/delete

---

## Alternative: Use Supabase CLI (If You Have Database Password)

If you have your database password, you can run the migration via CLI:

```bash
cd /Users/jans./Downloads/RendioAI/RendioAI

# Set database password
export SUPABASE_DB_PASSWORD="your_password_here"

# Run migration
supabase db push

# Or link to your project first
supabase link --project-ref ojcnjxzctnwbmupggoxq
supabase db push
```

Get your database password from: **Supabase Dashboard → Settings → Database → Database Password**

If you forgot it, you need to reset it from the dashboard.
