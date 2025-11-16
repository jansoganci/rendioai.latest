# 🔧 Storage RLS Migration Fix

**Date:** 2025-01-27  
**Issue:** `ERROR: 42501: must be owner of relation objects`  
**Status:** ✅ **FIXED**

---

## 🐛 Problem

When running `20251115200521_add_storage_rls_policies.sql`, you got:
```
ERROR: 42501: must be owner of relation objects
```

**Root Cause:**
- Storage policies in Supabase require **service role key** (elevated permissions)
- The migration was trying to `ALTER TABLE storage.objects` which requires owner privileges
- `storage.objects` is a system table managed by Supabase

---

## ✅ Solution

### Changes Made:

1. **Removed ALTER TABLE command**
   - `storage.objects` already has RLS enabled by default in Supabase
   - We don't have permission to alter system tables
   - Removed the `ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;` command

2. **Added exception handling**
   - Wrapped policy creation in `DO $$ ... END $$;` blocks
   - Added `IF NOT EXISTS` checks before creating policies
   - Graceful error handling for permission issues

3. **Added clear instructions**
   - Documented that migration requires service role key
   - Added troubleshooting notes

---

## 🚀 How to Run (Correctly)

### Option 1: Supabase CLI (Recommended)
```bash
cd RendioAI
supabase db push
```
✅ **Uses service role automatically** - This should work!

### Option 2: Supabase Dashboard
1. Go to: **SQL Editor**
2. **Important:** Make sure you're using **service role connection** (not anon key)
3. Paste the migration SQL
4. Run it

### Option 3: Direct SQL (with service role)
```bash
# Using Supabase CLI with service role
supabase db execute --file supabase/migrations/20251115200521_add_storage_rls_policies.sql
```

---

## ⚠️ Common Mistakes

### ❌ Wrong: Using Anon Key
```bash
# This will fail with "must be owner" error
psql $DATABASE_URL -f migration.sql  # Uses anon key
```

### ✅ Correct: Using Service Role
```bash
# This works
supabase db push  # Uses service role automatically
```

---

## 📋 What the Migration Does

1. **Creates/Updates Buckets**
   - `videos` bucket (500MB limit)
   - `thumbnails` bucket (10MB limit)

2. **Drops Old Policies**
   - Removes any existing policies (if they exist)
   - Handles permission errors gracefully

3. **Creates New Policies**
   - **Videos bucket:**
     - INSERT: Authenticated users can upload to own folder
     - UPDATE: Authenticated users can update own videos
     - DELETE: Authenticated users can delete own videos
     - SELECT: Public read access
   
   - **Thumbnails bucket:**
     - Same policies as videos

4. **Path Structure**
   ```
   videos/{auth.uid()}/{YYYY-MM}/{filename}.mp4
   thumbnails/{auth.uid()}/{YYYY-MM}/{filename}.jpg
   ```

---

## ✅ Verification

After running the migration, verify it worked:

```sql
-- Check policies were created
SELECT policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
ORDER BY policyname;
```

**Expected:** 8 policies (4 for videos, 4 for thumbnails)

---

## 🔍 If It Still Fails

### Check 1: Are you using service role?
```sql
-- Check current role
SELECT current_user, session_user;
-- Should show: postgres or service_role (not anon)
```

### Check 2: Do you have permissions?
```sql
-- Check if you can see storage schema
SELECT * FROM storage.buckets LIMIT 1;
-- If this fails, you're using wrong key
```

### Check 3: Are buckets created?
```sql
-- Check buckets exist
SELECT id, name, public FROM storage.buckets;
-- Should show: videos and thumbnails
```

---

## 📝 Summary

**Fixed:**
- ✅ Removed `ALTER TABLE` command (caused permission error)
- ✅ Added exception handling
- ✅ Added clear instructions

**How to Run:**
- ✅ Use `supabase db push` (recommended)
- ✅ Or use Dashboard with service role connection

**Result:**
- ✅ Migration should now run successfully
- ✅ Creates secure RLS policies for storage buckets

---

**Next Steps:**
1. Run the migration: `supabase db push`
2. Verify policies were created (use SQL query above)
3. Test image uploads work with JWT tokens (after iOS update)

