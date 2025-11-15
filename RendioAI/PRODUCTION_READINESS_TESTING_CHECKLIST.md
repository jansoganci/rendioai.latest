# Production Readiness Testing Checklist

**Purpose:** Verify all production readiness fixes are working correctly.

**Date:** 2025-01-15

---

## ✅ What You Already Tested

- [x] **Video Generation Works** - You generated a video successfully
- [x] **Video Playback Works** - You watched the video in your app

Good! Basic functionality is working. Now let's test the production readiness features.

---

## 🧪 Testing Checklist

### 1. Anonymous Auth Session Creation ✅

**What we fixed:** device-check endpoint now creates Supabase auth sessions.

**How to test:**

1. **Run this SQL query in Supabase SQL Editor:**
```sql
-- Check if auth sessions are being created
SELECT
  u.id as user_id,
  u.device_id,
  u.auth_user_id,
  au.email,
  au.created_at as auth_created_at
FROM public.users u
LEFT JOIN auth.users au ON u.auth_user_id = au.id
ORDER BY u.created_at DESC
LIMIT 5;
```

**Expected Result:**
- You should see `auth_user_id` column populated (not NULL)
- This means anonymous auth sessions are being created ✅

**If `auth_user_id` is NULL:**
- ❌ device-check endpoint is not creating auth sessions
- Need to check if migration `20251115200520_add_auth_user_id_to_users.sql` ran
- Need to redeploy device-check Edge Function

---

### 2. Rate Limiting ✅

**What we fixed:** 10 videos/hour rate limit to prevent abuse.

**How to test:**

1. **Check your current usage:**
```sql
-- Check how many videos you generated in the last hour
SELECT
  user_id,
  COUNT(*) as videos_in_last_hour
FROM public.video_jobs
WHERE created_at > NOW() - INTERVAL '1 hour'
  AND status != 'failed'
GROUP BY user_id;
```

2. **Test rate limit function:**
```sql
-- Replace with your actual user_id from the query above
SELECT check_rate_limit(
  'your-user-id-here'::uuid,
  'generate_video',
  10
);
```

**Expected Result:**
```json
{
  "allowed": true,
  "current_count": 1,
  "limit": 10,
  "remaining": 9,
  "reset_at": "2025-01-15T21:00:00Z"
}
```

**To test the limit:**
- Try generating 11 videos in one hour
- The 11th request should fail with a 429 error
- (Don't actually do this unless you want to waste credits 😄)

---

### 3. Cleanup Jobs Scheduled ✅

**What we fixed:** Automatic cleanup of old videos, idempotency keys, and inactive users.

**How to test:**

```sql
-- Check all scheduled cleanup jobs
SELECT
  jobid,
  jobname,
  schedule,
  command,
  active
FROM cron.job
ORDER BY jobid;
```

**Expected Result:** You should see **5 jobs**:

| Job ID | Job Name | Schedule | What It Does |
|--------|----------|----------|--------------|
| 6-9 | cleanup-old-videos | `0 2 * * *` | Deletes videos >90 days (daily at 2 AM) |
| 6-9 | cleanup-idempotency-keys | `0 */6 * * *` | Deletes old keys >24h (every 6 hours) |
| 6-9 | cleanup-inactive-users | `0 3 * * 0` | Deletes inactive users >90 days (weekly Sunday) |
| 6-9 | update-storage-usage | `0 * * * *` | Updates storage stats (hourly) |
| 10 | cleanup-rate-limit-violations | `0 4 * * 1` | Deletes old violations >30 days (weekly Monday) |

All should have `active = true` ✅

---

### 4. Storage Usage Monitoring ✅

**What we fixed:** Track storage usage to prevent cost explosion.

**How to test:**

```sql
-- Check current storage usage
SELECT
  bucket_name,
  used_bytes,
  total_bytes,
  file_count,
  ROUND((used_bytes::NUMERIC / total_bytes) * 100, 2) as usage_percent,
  updated_at
FROM public.storage_usage
ORDER BY bucket_name;
```

**Expected Result:**
```
bucket_name | used_bytes | total_bytes | file_count | usage_percent | updated_at
------------|------------|-------------|------------|---------------|------------
videos      | 15728640   | 1073741824  | 1          | 1.46          | 2025-01-15 19:30:00
thumbnails  | 524288     | 1073741824  | 1          | 0.05          | 2025-01-15 19:30:00
```

**What to check:**
- ✅ `used_bytes` should be > 0 (if you generated videos)
- ✅ `usage_percent` should be low (< 80%)
- ✅ `updated_at` should be recent (within last hour)

---

### 5. Video Storage Migration ⚠️

**What we fixed:** Videos <10MB migrate from FalAI to Supabase Storage.

**How to test:**

```sql
-- Check where your videos are stored
SELECT
  job_id,
  status,
  video_url,
  created_at,
  CASE
    WHEN video_url LIKE '%supabase%' THEN 'Supabase Storage ✅'
    WHEN video_url LIKE '%fal.media%' THEN 'FalAI (not migrated)'
    ELSE 'Unknown'
  END as storage_location
FROM public.video_jobs
WHERE status = 'completed'
ORDER BY created_at DESC
LIMIT 5;
```

**Expected Result:**
- If video is small (<10MB): `storage_location` should be "Supabase Storage ✅"
- If video is large (>10MB): `storage_location` might be "FalAI (not migrated)" (this is OK - graceful fallback)

**If all videos show FalAI:**
- ❌ Video migration is not working
- Check `get-video-status` Edge Function was deployed
- Check `storage-utils.ts` file exists

---

### 6. Audit Logs ✅

**What we fixed:** Track all important events for debugging.

**How to test:**

```sql
-- Check recent audit logs
SELECT
  action,
  details,
  created_at
FROM public.audit_log
ORDER BY created_at DESC
LIMIT 10;
```

**Expected Result:** You should see logs like:
- `rate_limit_check` - When you generate a video
- `video_job_created` - When video generation starts
- `credit_deducted` - When credits are used
- `video_job_completed` - When video finishes

**If no logs:**
- ⚠️ Audit logging might not be working
- Edge Functions might not be deployed with updated code

---

### 7. Image Upload (Still Temporary) ⚠️

**What we fixed:** Created auth infrastructure, but still using temporary policy.

**How to test:**

```sql
-- Check Storage RLS policies
SELECT
  policyname,
  tablename,
  cmd,
  roles
FROM pg_policies
WHERE tablename = 'objects'
  AND schemaname = 'storage'
ORDER BY policyname;
```

**Expected Result:**
You should see policies for `thumbnails` bucket. One of them might be:
- "Anyone can upload thumbnails (temporary)" - ⚠️ This is the insecure policy (OK for development)

**For production:** You'll need to update iOS app to use JWT tokens and remove this policy.

---

## 🎯 Quick Test Summary

Run these 3 queries to get a quick health check:

### Query 1: Overall System Health
```sql
SELECT
  'Users' as table_name,
  COUNT(*) as count,
  COUNT(auth_user_id) as with_auth_session
FROM public.users
UNION ALL
SELECT
  'Video Jobs (Last Hour)' as table_name,
  COUNT(*) as count,
  COUNT(*) FILTER (WHERE status = 'completed') as completed
FROM public.video_jobs
WHERE created_at > NOW() - INTERVAL '1 hour'
UNION ALL
SELECT
  'Scheduled Jobs' as table_name,
  COUNT(*) as count,
  COUNT(*) FILTER (WHERE active = true) as active
FROM cron.job;
```

**Expected:**
- Users: `with_auth_session` should equal `count` (all users have auth sessions)
- Video Jobs: Some completed videos
- Scheduled Jobs: 5 total, all active

---

### Query 2: Storage Health
```sql
SELECT
  bucket_name,
  file_count,
  ROUND(used_bytes / 1024.0 / 1024.0, 2) as used_mb,
  ROUND(total_bytes / 1024.0 / 1024.0, 2) as total_mb,
  ROUND((used_bytes::NUMERIC / total_bytes) * 100, 2) as usage_percent
FROM public.storage_usage
ORDER BY bucket_name;
```

**Expected:**
- Both buckets exist
- `usage_percent` < 80% (no alerts)
- `file_count` > 0 (if you generated videos)

---

### Query 3: Rate Limit Status (Replace user_id)
```sql
SELECT get_rate_limit_status('your-user-id-here'::uuid);
```

**Expected:**
```json
{
  "allowed": true,
  "current_count": 1,
  "limit": 10,
  "remaining": 9,
  "reset_at": "...",
  "recent_violations": 0
}
```

---

## 🚨 What's NOT Fixed Yet (Need Manual Steps)

### 1. Storage RLS Policies (Videos/Thumbnails)

**Issue:** Can't create via SQL Editor (permission error).

**Solution:** Use Supabase Dashboard to create policies manually.

**See:** `STORAGE_POLICY_SETUP_GUIDE.md` for step-by-step instructions.

**Priority:**
- For development: Low (temporary policy works)
- For production: **HIGH** (security vulnerability)

---

### 2. Sentry Error Tracking

**Issue:** Sentry DSN not configured.

**Solution:**
1. Create Sentry project at sentry.io
2. Get DSN
3. Add to Supabase Edge Functions environment variables

**How to check if configured:**
```sql
-- This won't work in SQL, need to check Edge Function env vars
-- Go to Supabase Dashboard → Edge Functions → Settings
```

**Priority:** Medium (helpful for production debugging)

---

### 3. Telegram Alerts

**Issue:** Telegram bot not configured.

**Solution:**
1. Create bot via @BotFather
2. Get bot token and chat ID
3. Add to Edge Functions environment variables

**Priority:** Medium (helpful for production monitoring)

---

## ✅ Production Readiness Score

Based on what you've deployed:

| Feature | Status | Critical? |
|---------|--------|-----------|
| Video Generation | ✅ Working | Yes |
| Video Playback | ✅ Working | Yes |
| Anonymous Auth Sessions | ✅ Fixed | Yes |
| Rate Limiting | ✅ Implemented | Yes |
| Cleanup Jobs | ✅ Scheduled | Yes |
| Storage Monitoring | ✅ Active | Yes |
| Video Migration | ✅ Hybrid Approach | Yes |
| Audit Logging | ✅ Active | No |
| Storage RLS Policies | ⚠️ Manual Setup Needed | Yes (for production) |
| Sentry Monitoring | ⚠️ Not Configured | No (nice to have) |
| Telegram Alerts | ⚠️ Not Configured | No (nice to have) |

**Current Score: 8/11 (73%)** ✅

**For Production: Need to reach 10/11 (91%)** - Fix Storage RLS Policies before release.

---

## 🚀 Next Steps

### Before App Store Submission:

1. **Set up Storage RLS Policies** (Critical)
   - Follow `STORAGE_POLICY_SETUP_GUIDE.md`
   - Test image uploads with JWT tokens

2. **Configure Sentry** (Recommended)
   - Get free account at sentry.io
   - Add DSN to environment variables

3. **Configure Telegram Alerts** (Optional)
   - Create bot via @BotFather
   - Add credentials to environment variables

4. **Load Test** (Recommended)
   - Generate 10 videos in one hour
   - Verify rate limiting works
   - Check storage usage updates

5. **Update GENERAL_TECHNICAL_DECISIONS.md**
   - Mark fixes as completed
   - Document what's still pending

---

## 📞 Need Help?

If any of the tests above fail, let me know which one and I'll help you debug it!
