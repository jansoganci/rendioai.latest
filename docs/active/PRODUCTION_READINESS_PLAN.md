# 🎯 Production Readiness Plan (REVISED)

**Date:** 2025-01-27  
**Status:** Planning Phase - Updated with Critical Gaps  
**Priority:** Critical Issues Before Production

---

## 📊 Current Situation Analysis

### ✅ What's Working (Production Ready)
1. **Credit System** - Fully implemented with atomic operations
2. **Model Settings** - Backend supports all parameters (using defaults)
3. **Video Viewing** - AVPlayer streams URLs correctly

### ⚠️ Critical Issues (NOT Production Ready)

#### 1. Video Storage - Using FalAI URLs Directly
- **Current:** Videos stored as FalAI URLs in database
- **Problem:** No control, vendor lock-in, videos can disappear
- **Risk:** High - Reliability issue
- **⚠️ NEW GAP:** Edge Function timeout risk (60s limit), storage costs, RLS policies missing

#### 2. Image Upload Security - Anonymous Access Enabled
- **Current:** RLS policy allows anonymous uploads
- **Problem:** Anyone with anon key can upload images
- **Risk:** Critical - Security vulnerability
- **⚠️ NEW GAP:** Backend changes needed (device-check endpoint must create auth session)

#### 3. Rate Limiting - Not Implemented
- **Status:** Skipped for now (will do later)
- **Risk:** Medium - Can be abused
- **⚠️ NOTE:** User requested to skip for now

#### 4. Video RLS Policies - Missing
- **Current:** Videos bucket has public read access
- **Problem:** Anyone with URL can access any user's videos
- **Risk:** Critical - Security issue

#### 5. Storage Costs & Cleanup - Not Addressed
- **Current:** No cleanup policies
- **Problem:** Videos accumulate, storage costs grow
- **Risk:** High - Cost explosion (1GB free tier = ~33 videos)

#### 6. Monitoring & Logging - Missing
- **Current:** Basic logging exists
- **Problem:** No visibility into failures, storage usage, errors
- **Risk:** Medium - Can't detect issues

---

## 🎯 Implementation Plan

### Phase 1: Fix Image Upload Security (CRITICAL)

#### Current Flow:
```
iOS App → ImageUploadService → Supabase Storage (anon key) → ✅ Works but insecure
```

#### Problem:
- Using anon key directly (no JWT token)
- RLS policy allows anonymous uploads (temporary migration)
- No user authentication verification

#### Solution: Option A - Supabase Anonymous Auth (Recommended)

**Why This Approach:**
- ✅ Works with existing DeviceCheck flow
- ✅ Proper security with JWT tokens
- ⚠️ **REQUIRES BACKEND CHANGES** (device-check endpoint)

**Implementation Steps:**

1. **Update Backend: device-check Endpoint** ⚠️ CRITICAL GAP
   - **File:** `supabase/functions/device-check/index.ts`
   - After creating custom user record, create anonymous Supabase auth session
   - Link anonymous auth UID to custom user_id in users table
   - Return both: `user_id` (custom) AND `session.access_token` (auth)
   - Add migration: Add `auth_user_id` column to users table

2. **Update iOS: OnboardingService**
   - **File:** `RendioAI/RendioAI/Core/Services/OnboardingService.swift`
   - Receive `session.access_token` from device-check response
   - Store JWT token in Keychain (secure storage)
   - Use token for all authenticated requests

3. **Update iOS: ImageUploadService**
   - **File:** `RendioAI/RendioAI/Core/Networking/ImageUploadService.swift`
   - Get JWT token from Keychain (instead of anon key)
   - Use JWT token in Authorization header
   - Fallback to anon key if token missing (backward compatibility)

4. **Revert RLS Policy**
   - **File:** Create new migration: `revert_anonymous_uploads_require_auth.sql`
   - Drop temporary policy: "Anyone can upload thumbnails (temporary)"
   - Restore original policy: "Authenticated users can upload thumbnails"
   - Policy checks: `auth.role() = 'authenticated'`

**Files to Modify:**
- `supabase/functions/device-check/index.ts` - **NEW: Create auth session**
- `supabase/migrations/YYYYMMDDHHMMSS_add_auth_user_id_to_users.sql` - **NEW: Add column**
- `RendioAI/RendioAI/Core/Networking/ImageUploadService.swift` - Use JWT token
- `RendioAI/RendioAI/Core/Services/OnboardingService.swift` - Store token
- Create new migration: `revert_anonymous_uploads_require_auth.sql`

**Alternative: Option B - Edge Function (More Secure)**
- Create `upload-image` Edge Function
- Client sends image to Edge Function
- Edge Function validates user_id and uploads with service role key
- More secure but requires backend changes

---

### Phase 2: Migrate Video Storage to Supabase (CRITICAL)

#### Current Flow:
```
FalAI → Video URL → Store in DB → iOS plays URL directly
```

#### Problem:
- No control over video lifecycle
- FalAI can delete/change URLs
- Vendor lock-in

#### Solution: Download & Store in Supabase Storage (With Timeout Handling)

**⚠️ CRITICAL GAP:** Edge Functions have 60-second timeout. Videos are 10-50MB, download+upload could take 30-60 seconds.

**Strategy: Hybrid Approach (Recommended for MVP)**
- Try synchronous migration with 30s timeout
- If succeeds: Update database with Supabase URL
- If fails/timeout: Keep FalAI URL, queue background retry
- Background job retries later (async)

**Implementation Steps:**

1. **Create Storage Utility**
   - **File:** `supabase/functions/_shared/storage-utils.ts` (NEW)
   - Functions: `downloadVideoFromUrl()`, `uploadVideoToStorage()`, `getPublicUrl()`
   - Add timeout handling (30s max for download+upload)

2. **Update get-video-status Endpoint**
   - **File:** `supabase/functions/get-video-status/status-handlers.ts`
   - When status becomes "completed" and video URL is found:
     - Try quick migration (30s timeout)
     - If succeeds: Update `video_url` with Supabase URL
     - If fails: Log error, keep FalAI URL, queue background retry
     - Return FalAI URL immediately (don't block response)

3. **Storage Path Structure**
   ```
   videos/{auth_user_id}/{job_id}.mp4
   ```
   - Use `auth_user_id` (from Supabase Auth) for RLS policies
   - Map custom `user_id` to `auth_user_id` if needed

4. **Error Handling & Timeout**
   - Download timeout: 15s
   - Upload timeout: 15s
   - Total max: 30s (leaves 30s buffer for Edge Function)
   - If timeout: Log error, keep FalAI URL, queue retry
   - Background job retries up to 3 times

5. **Add Video RLS Policy** ⚠️ CRITICAL GAP
   - **File:** Create migration: `add_video_rls_policy.sql`
   - Policy: Users can only read their own videos
   - Update storage path to use `auth.uid()` for RLS
   - OR: Map custom `user_id` to `auth_user_id` in policy

6. **Add Storage Cleanup Policy** ⚠️ CRITICAL GAP
   - **File:** Create migration: `create_video_cleanup_job.sql`
   - Use pg_cron extension for scheduled cleanup
   - Delete videos older than 90 days (configurable)
   - Calculate: 1GB free tier = ~33 videos (30MB avg)
   - Monitor storage usage, alert when >80% full

**Files to Create/Modify:**
- `supabase/functions/_shared/storage-utils.ts` - NEW (with timeout handling)
- `supabase/functions/get-video-status/status-handlers.ts` - Update `handleCompletedStatus()`
- `supabase/migrations/YYYYMMDDHHMMSS_add_video_rls_policy.sql` - NEW
- `supabase/migrations/YYYYMMDDHHMMSS_create_video_cleanup_job.sql` - NEW
- `supabase/functions/get-video-status/index.ts` - No changes needed

**Storage Bucket:**
- Already exists: `videos` bucket (500MB limit, public read)
- ⚠️ **RLS policies NOT properly set up** - Need user-specific access control

---

## 📋 Detailed Implementation Steps

### Step 1: Image Upload Security Fix

#### 1.1 Update Backend: device-check Endpoint ⚠️ CRITICAL

**File:** `supabase/functions/device-check/index.ts`

**Changes:**
- After creating custom user record, create anonymous Supabase auth session
- Link anonymous auth UID to custom user_id
- Return both `user_id` and `session.access_token`

**Code Structure:**
```typescript
// After creating custom user:
// 1. Create anonymous Supabase auth session
const { data: authData, error: authError } = await supabaseClient.auth.signInAnonymously()

if (authError) {
  // Log error but don't fail - user can still use app
  console.error('Failed to create auth session:', authError)
} else {
  // 2. Link auth UID to custom user_id
  await supabaseClient
    .from('users')
    .update({ auth_user_id: authData.user.id })
    .eq('id', newUser.id)
  
  // 3. Return session token to iOS
  return {
    user_id: newUser.id,
    credits_remaining: creditResult.credits_remaining,
    is_new: true,
    session_token: authData.session.access_token  // NEW
  }
}
```

#### 1.2 Add Migration: auth_user_id Column

**File:** `supabase/migrations/YYYYMMDDHHMMSS_add_auth_user_id_to_users.sql` (NEW)

**Changes:**
- Add `auth_user_id UUID` column to users table
- Link to `auth.users(id)` for referential integrity
- Add index for fast lookups

#### 1.3 Update iOS: OnboardingService

**File:** `RendioAI/RendioAI/Core/Services/OnboardingService.swift`

**Changes:**
- Receive `session_token` from device-check response
- Store JWT token in Keychain (secure storage)
- Update `OnboardingResponse` model to include `session_token`

**Code Structure:**
```swift
// After DeviceCheck succeeds:
// 1. Receive session_token from backend
// 2. Store in Keychain using KeychainManager
// 3. Use for all authenticated requests
```

#### 1.2 Update ImageUploadService to Use JWT Token

**File:** `RendioAI/RendioAI/Core/Networking/ImageUploadService.swift`

**Changes:**
- Get JWT token from Keychain (instead of anon key)
- Use token in Authorization header
- Fallback to anon key if token missing (backward compatibility)

#### 1.3 Revert RLS Policy

**File:** Create new migration: `supabase/migrations/YYYYMMDDHHMMSS_revert_anonymous_uploads_require_auth.sql`

**Changes:**
- Drop temporary policy: "Anyone can upload thumbnails (temporary)"
- Restore original policy: "Authenticated users can upload thumbnails"
- Policy checks: `auth.role() = 'authenticated'`

---

### Step 2: Video Storage Migration

#### 2.1 Create Storage Utilities

**File:** `supabase/functions/_shared/storage-utils.ts` (NEW)

**Functions:**
```typescript
// Download video from external URL
async function downloadVideoFromUrl(url: string): Promise<Uint8Array>

// Upload video to Supabase Storage
async function uploadVideoToStorage(
  videoData: Uint8Array,
  userId: string,
  jobId: string
): Promise<string> // Returns public URL

// Get public URL for video
function getPublicUrl(bucket: string, path: string): string
```

#### 2.2 Update Status Handler

**File:** `supabase/functions/get-video-status/status-handlers.ts`

**Changes in `handleCompletedStatus()`:**
```typescript
// After fetching video URL from FalAI:
if (videoUrl) {
  // NEW: Download and migrate to Supabase Storage
  try {
    const supabaseUrl = await migrateVideoToStorage(
      videoUrl,
      job.user_id,
      job.job_id,
      supabaseClient
    )
    
    // Update database with Supabase URL
    videoUrl = supabaseUrl
  } catch (error) {
    // Log error but continue with FalAI URL (graceful degradation)
    console.error('Video migration failed:', error)
    // Keep FalAI URL as fallback
  }
  
  // Continue with existing update logic...
}
```

#### 2.3 Add Migration Helper Function

**File:** `supabase/functions/get-video-status/status-handlers.ts`

**New Function:**
```typescript
async function migrateVideoToStorage(
  falaiUrl: string,
  userId: string,
  jobId: string,
  supabaseClient: ReturnType<typeof createClient>
): Promise<string> {
  // 1. Download video from FalAI
  // 2. Upload to Supabase Storage
  // 3. Return Supabase public URL
  // 4. Handle errors gracefully
}
```

---

## 🔄 Migration Strategy

### Image Upload Security (Zero Downtime)

1. **Phase 1:** Deploy new code with JWT token support (backward compatible)
2. **Phase 2:** Test with new auth flow
3. **Phase 3:** Revert RLS policy (requires app update)
4. **Phase 4:** Remove anon key fallback

### Video Storage (Gradual Migration)

1. **Phase 1:** Deploy migration code (downloads & stores in Supabase)
2. **Phase 2:** New videos automatically migrate
3. **Phase 3:** Existing videos keep FalAI URLs (backward compatible)
4. **Phase 4:** Optional: Batch migration for old videos

---

## ⚠️ Risks & Mitigation

### Image Upload Security
- **Risk:** Breaking existing uploads during migration
- **Mitigation:** Keep anon key fallback temporarily, gradual rollout

### Video Storage Migration
- **Risk:** Download/upload failures
- **Mitigation:** Graceful degradation (keep FalAI URL if migration fails)
- **Risk:** Storage costs increase
- **Mitigation:** Monitor usage, set cleanup policies

---

## 📊 Success Criteria

### Image Upload Security
- ✅ RLS policy requires authentication
- ✅ ImageUploadService uses JWT tokens
- ✅ Anonymous users can still upload (via anonymous auth)
- ✅ No security vulnerabilities

### Video Storage Migration
- ✅ New videos stored in Supabase Storage
- ✅ Video URLs point to Supabase (not FalAI)
- ✅ Videos play correctly in iOS app
- ✅ Graceful fallback if migration fails

---

## 🚀 Next Steps

1. **Review this plan** - Confirm approach
2. **Start with Image Upload Security** - Higher priority
3. **Then Video Storage Migration** - Critical but less urgent
4. **Test thoroughly** - Both features before production

---

## 📝 Additional Critical Items

### 7. Anonymous Auth Cleanup - Not Addressed

**Problem:**
- Anonymous auth users accumulate over time
- No cleanup strategy for abandoned accounts
- Supabase Auth will fill up with unused accounts

**Solution:**
- Add cleanup job for inactive anonymous users (no activity for 90 days)
- Link anonymous auth users to device_id for tracking
- **File:** Create migration: `create_anonymous_auth_cleanup_job.sql`

### 8. Monitoring & Logging - Missing

**Problem:**
- No visibility into:
  - Video migration failures
  - Storage usage
  - User errors
  - Credit transaction issues

**Solution:**
- Add structured logging to critical paths:
  - Video generation requests
  - Video migration success/failure (with timing)
  - Storage usage (track bucket size)
  - Credit transactions
- Use Supabase Dashboard → Logs
- Set up alerts for critical errors (via Supabase or external service)

**Files to Update:**
- `supabase/functions/_shared/logger.ts` - Enhance with metrics
- Add logging to all Edge Functions
- Create monitoring dashboard queries

---

## 🎯 Revised Priority List

### 🔴 Critical (Must Do Before Production)

1. **Image Upload Security** ✅ Plan + Backend Changes
   - Update device-check endpoint (create auth session)
   - Add auth_user_id column migration
   - Update ImageUploadService to use JWT
   - Revert RLS policy

2. **Video Storage RLS Policy** ⚠️ Security Risk
   - Add user-specific RLS policy for videos bucket
   - Update storage path to use auth.uid()
   - Migration: `add_video_rls_policy.sql`

3. **Video Storage Migration** ✅ Plan + Timeout Handling
   - Implement hybrid approach (sync with timeout, async retry)
   - Add storage utilities with timeout handling
   - Update status handler

4. **Storage Cleanup Policy** ⚠️ Cost Management
   - Create cleanup job (pg_cron)
   - Delete videos older than 90 days
   - Monitor storage usage

5. **Monitoring & Logging** ⚠️ Visibility
   - Add structured logging
   - Track critical metrics
   - Set up error alerts

### 🟡 High Priority (Should Do Soon)

6. **Anonymous Auth Cleanup** - Long-term maintenance
7. **Rate Limiting** - User requested to skip for now

### 🟢 Nice to Have (Can Wait)

8. Thumbnails (Phase 3)
9. Enhanced error handling (Phase 7)
10. Webhooks/realtime (Phase 5)

---

## ⏱️ Estimated Time to Address

| Task | Time | Priority |
|------|------|----------|
| Rate limiting (simple) | 10 min | Skipped |
| Storage RLS policy | 15 min | Critical |
| Storage cleanup job | 30 min | Critical |
| Backend auth changes | 1 hour | Critical |
| Video migration timeout handling | 1-2 hours | Critical |
| Monitoring/logging | 30 min | Critical |
| Anonymous auth cleanup | 30 min | High |
| **Total** | **~4 hours** | |

---

## 📝 Notes

- Rate limiting skipped for now (user requested)
- Thumbnails can wait (Phase 3)
- All fixes are backward compatible
- No breaking changes to existing functionality
- **NEW:** Must address timeout handling, RLS policies, cleanup, and monitoring

