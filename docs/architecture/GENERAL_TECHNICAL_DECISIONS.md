# 🔧 Technical Decisions & Placeholders

**Purpose:** Track all technical decisions, placeholders, and MVP trade-offs that need attention before production.

**Last Updated:** 2025-11-06

---

## 📋 Current Status Overview

| Category | Status | Notes |
|----------|--------|-------|
| **Credit System** | ✅ Fully Implemented | Atomic operations, rollback, audit trail |
| **Model Settings** | ✅ Implemented (Defaults) | Resolution/aspect/duration supported, using defaults for MVP |
| **Video Storage** | ⚠️ Placeholder (Option B) | Using FalAI URLs - must migrate to Supabase Storage before production |
| **Thumbnails** | ⚠️ Not Implemented | Will be null - add in Phase 3 |
| **Video Viewing** | ✅ Works | iOS AVPlayer handles HTTP/HTTPS URLs directly |
| **Image Upload Storage** | ⚠️ Temporary Solution | RLS policy allows anonymous uploads - must implement proper auth before production |

---

## 1. Credit System ✅

### Status: **FULLY IMPLEMENTED**

**Implementation:**
- ✅ Atomic stored procedures (`deduct_credits`, `add_credits`)
- ✅ Race condition protection (FOR UPDATE locks)
- ✅ Audit trail (`quota_log` table with `balance_after`)
- ✅ Duplicate transaction prevention (IAP)
- ✅ Rollback logic (refund on failure)

**Where Used:**
- `device-check` endpoint: Initial 10 credit grant
- `update-credits` endpoint: IAP purchases
- `generate-video` endpoint: Credit deduction + rollback on failure

**Testing:**
- ✅ Phase 0 & Phase 1 audited and tested
- ⏳ Phase 2 integration testing pending

**Production Ready:** ✅ Yes

---

## 2. Model Settings (Resolution, Aspect Ratio, Duration) ✅

### Status: **IMPLEMENTED (Using Defaults for MVP)**

**Backend Support:**
- ✅ `falai-adapter.ts` accepts all settings
- ✅ `generate-video` endpoint accepts settings in request body
- ✅ Settings passed to FalAI API correctly

**Current Defaults (Phase 2):**
```typescript
{
  resolution: "auto",
  aspect_ratio: "auto",
  duration: 4
}
```

**Why Defaults:**
- Faster MVP implementation
- FalAI handles optimal settings automatically
- Can be changed easily later

**To Change Later:**
1. Update iOS `VideoSettings` model (if needed)
2. Pass settings from iOS to backend
3. **No backend changes needed** - already supports all parameters

**Production Ready:** ✅ Yes (but using defaults for now)

---

## 3. Video Storage Strategy ⚠️

### Status: **PLACEHOLDER - Must Update Before Production**

**Current Implementation (Option B):**
- Videos stored in FalAI's storage
- Video URLs returned directly from FalAI
- iOS AVPlayer plays URLs directly
- No download/upload needed

**Why This Works for MVP:**
- ✅ Simpler implementation
- ✅ Faster to ship
- ✅ Works perfectly with iOS AVPlayer
- ✅ No additional storage costs

**Why This is a Placeholder:**
- ❌ No control over video lifecycle
- ❌ Dependent on FalAI hosting
- ❌ Can't set expiration policies
- ❌ Can't delete videos from our side
- ❌ Potential vendor lock-in

**Migration Plan (Before Production):**
1. **Option A: Supabase Storage** (Recommended)
   - Download video from FalAI when completed
   - Upload to Supabase Storage bucket `videos`
   - Update `video_jobs.video_url` with Supabase URL
   - Set RLS policies for secure access
   - Add cleanup job (delete videos older than 90 days)

**When to Migrate:**
- Before production launch
- Or when you need more control over videos
- Or when FalAI URLs become unreliable

**Implementation:**
- Add download/upload logic in `get-video-status` endpoint
- Update when status changes to "completed"
- Store in Supabase Storage with proper permissions

**Files to Update:**
- `supabase/functions/get-video-status/index.ts`
- Add `_shared/storage-utils.ts` for Supabase Storage helpers

**Production Ready:** ⚠️ No - Must migrate to Option A

---

## 4. Thumbnails ⚠️

### Status: **NOT IMPLEMENTED (Phase 2)**

**Current Behavior:**
- `thumbnail_url` will be `null` in database
- `get-video-status` returns `thumbnail_url: null`
- History view shows placeholder or first frame

**Impact:**
- History view: No thumbnails in video list
- ResultView: Doesn't need thumbnails (shows video directly)
- User experience: Slightly less polished, but functional

**Implementation Plan (Phase 3):**
1. Option A: Extract first frame from video
   - Download video from FalAI
   - Extract first frame using FFmpeg or similar
   - Upload thumbnail to Supabase Storage `thumbnails` bucket
   - Update `video_jobs.thumbnail_url`

2. Option B: FalAI provides thumbnail
   - Check if FalAI API returns thumbnail
   - Use if available (unlikely for Sora 2)

**When to Add:**
- Phase 3 (History & User Management)
- Or when polishing UI/UX

**Production Ready:** ⚠️ Not critical, but add before production

---

## 5. Video Viewing (How Users See Videos) ✅

### Status: **FULLY WORKING**

**How It Works:**
1. Backend receives video URL from FalAI
2. Backend stores URL in `video_jobs.video_url`
3. iOS app calls `get-video-status` endpoint
4. iOS receives `video_url` in response
5. iOS `ResultViewModel` sets `videoURL: URL?`
6. `VideoPlayerView` receives `videoURL`
7. `AVPlayer` plays the HTTPS URL directly

**Technical Details:**
```swift
// ResultView.swift
VideoPlayerView(
    videoURL: viewModel.videoURL,  // ← HTTPS URL from FalAI
    isProcessing: viewModel.isProcessing,
    hasFailed: viewModel.hasFailed
)

// VideoPlayerView uses AVPlayer
VideoPlayer(player: AVPlayer(url: videoURL))
```

**User Experience:**
- ✅ Video plays directly in app
- ✅ No download needed
- ✅ Works with any HTTP/HTTPS URL
- ✅ Supports fullscreen playback

**No Changes Needed:**
- AVPlayer handles streaming automatically
- Works with FalAI URLs
- Will work with Supabase Storage URLs (after migration)

**Production Ready:** ✅ Yes

---

## 6. Image Upload Storage (RLS Policy) ⚠️

### Status: **TEMPORARY SOLUTION - Must Update Before Production**

**Date:** 2025-11-06  
**Reason:** Demo needed ASAP for customer presentation

**Current Implementation (Temporary):**
- RLS policy allows anonymous users to upload images to `thumbnails` bucket
- Using anon key directly for Storage uploads
- Works for demo purposes

**The Problem:**
- Original RLS policy required `auth.role() = 'authenticated'`
- App uses anonymous auth via DeviceCheck
- `ImageUploadService` uses anon key without JWT token
- Result: `403 Unauthorized - new row violates row-level security policy`

**The Decision:**
- **Option 2 chosen:** Updated RLS policy to allow anonymous uploads
- Changed policy from `auth.role() = 'authenticated'` to allow anonymous users
- This is a temporary solution for demo purposes

**Why This is Temporary:**
- ❌ Less secure (anyone with anon key can upload)
- ❌ No user-specific access control
- ❌ Doesn't align with proper authentication flow
- ✅ But works immediately for demo

**What Needs to Change (Before Production):**

**Option A: Use Supabase Auth Session Token (Recommended)**
- Integrate Supabase Swift SDK for auth
- Get JWT token from authenticated session (anonymous or Apple Sign-In)
- Use session token instead of anon key for Storage uploads
- Revert RLS policy to require `auth.role() = 'authenticated'`

**Option B: Edge Function for Uploads (Most Secure)**
- Create `upload-image` Edge Function
- Client sends image to Edge Function
- Edge Function uses service role key to upload to Storage
- Most secure but requires backend changes

**Migration Plan:**
1. Before production: Implement Option A or B
2. Revert RLS policy to require authentication
3. Update `ImageUploadService` to use session tokens
4. Test with both anonymous and authenticated users

**Files Affected:**
- `supabase/migrations/20251105000004_create_storage_buckets.sql` (RLS policy)
- `RendioAI/RendioAI/Core/Networking/ImageUploadService.swift` (upload logic)

**Production Ready:** ⚠️ No - Must implement proper auth before production

---

## 7. Other Placeholders & Technical Debt

### A. Error Handling (Phase 2 vs Phase 7)

**Current (Phase 2):**
- Basic error messages
- Generic error responses
- Rollback on failure

**Future (Phase 7):**
- Standardized error codes (ERR_4xxx, ERR_5xxx, ERR_6xxx)
- Internationalized error messages (en/tr/es)
- Structured error responses

**Status:** ✅ Basic handling works, enhance in Phase 7

---

### B. Retry Logic (Phase 2 vs Phase 6)

**Current (Phase 2):**
- No automatic retry
- Manual retry by user

**Future (Phase 6):**
- Exponential backoff (2s → 4s → 8s → 30s max)
- Automatic retry on transient failures
- Timeout handling

**Status:** ✅ Basic handling works, enhance in Phase 6

---

### C. Status Polling (Phase 2 vs Phase 5)

**Current (Phase 2):**
- Client-side polling every 5 seconds
- Fixed interval

**Future (Phase 5):**
- Webhooks from FalAI
- Supabase Realtime subscriptions
- Push notifications (APNs)

**Status:** ✅ Works for MVP, optimize in Phase 5

---

### D. Rate Limiting (Phase 2 vs Phase 8)

**Current (Phase 2):**
- No rate limiting
- Credits provide natural limit

**Future (Phase 8):**
- IP-based rate limiting
- 10 videos/hour per user
- Auto-cleanup of old logs

**Status:** ⚠️ Add before production (Phase 8)

---

## 📝 Summary Checklist

### ✅ Production Ready
- [x] Credit system (atomic operations, rollback)
- [x] Model settings (implemented, using defaults)
- [x] Video viewing (AVPlayer handles URLs)

### ⚠️ Placeholders (Must Update Before Production)
- [ ] Video storage (migrate to Supabase Storage)
- [ ] Image upload storage (implement proper auth, revert RLS policy)
- [ ] Rate limiting (add in Phase 8)
- [ ] Thumbnails (add in Phase 3 - nice to have)

### 🔮 Enhancements (Can Add Later)
- [ ] Error handling i18n (Phase 7)
- [ ] Retry logic (Phase 6)
- [ ] Webhooks/realtime (Phase 5)

---

## 🎯 Action Items

### Before Production Launch:
1. **Migrate video storage to Supabase Storage** (Critical)
2. **Implement proper auth for image uploads** (Critical - revert RLS policy)
3. **Add rate limiting** (Critical)
4. **Add thumbnails** (Nice to have)

### After Launch (Phases 5-7):
4. Implement webhooks (Phase 5)
5. Add retry logic (Phase 6)
6. Enhance error handling (Phase 7)

---

## 📚 Related Documents

- **Phase 2 Implementation:** `PHASE_2_IMPLEMENTATION_SUMMARY.md`
- **Backend Building Plan:** `backend-building-plan.md`
- **Video Storage Migration:** See Phase 3 section in building plan

---

**Remember:** This document should be updated whenever technical decisions are made or placeholders are addressed.

