# 🎬 Phase 2: Video Generation API - Implementation Plan

**Status:** 📋 Planning  
**Estimated Time:** 4-5 days  
**Goal:** Build video generation workflow with idempotency, rollback, and FalAI integration

---

## 📊 Overview

Phase 2 implements the core video generation feature:
- **Generate Video Endpoint** - Creates jobs, deducts credits, calls FalAI
- **Get Video Status Endpoint** - Polls generation progress and updates job status
- **FalAI Integration** - Provider adapter for video generation
- **Video Storage** - Strategy for storing generated videos
- **iOS Integration** - Update client to use real endpoints with idempotency

---

## 🎯 What We're Building

### 1. `generate-video` Edge Function
**File:** `supabase/functions/generate-video/index.ts`

**Purpose:** Create video generation job with idempotency protection

**Flow:**
1. Check idempotency key (prevent duplicate charges)
2. Validate user credits
3. Fetch model details from `models` table
4. Deduct credits atomically (via stored procedure)
5. Create `video_jobs` entry (status: "pending")
6. Call FalAI API to start generation
7. Update job with `provider_job_id`
8. Store idempotency record
9. Return `job_id` to iOS client

**Request:**
```json
POST /functions/v1/generate-video
Headers:
  Idempotency-Key: <uuid>
  Authorization: Bearer <jwt_token>

Body:
{
  "user_id": "uuid",
  "model_id": "uuid",
  "prompt": "A glowing cityscape at night",
  "settings": {
    "duration": 15,
    "resolution": "720p",
    "fps": 30
  }
}
```

**Response:**
```json
{
  "job_id": "uuid",
  "status": "pending",
  "credits_used": 4
}
```

**Idempotent Replay Response:**
```json
{
  "job_id": "uuid-from-first-request",
  "status": "pending",
  "credits_used": 4
}
```
Headers: `X-Idempotent-Replay: true`

---

### 2. `get-video-status` Edge Function
**File:** `supabase/functions/get-video-status/index.ts`

**Purpose:** Poll video generation progress and update job status

**Flow:**
1. Get `job_id` from query params
2. Fetch job from database
3. If status is "pending" or "processing":
   - Check FalAI status
   - If completed: Download video, upload to Supabase Storage, update job
   - If failed: Update job status
4. Return current job status

**Request:**
```
GET /functions/v1/get-video-status?job_id=<uuid>
```

**Response:**
```json
{
  "job_id": "uuid",
  "status": "completed",
  "video_url": "https://cdn.app/videos/123.mp4",
  "thumbnail_url": "https://cdn.app/videos/123_thumb.jpg"
}
```

---

## 📁 File Structure

```
supabase/functions/
├── generate-video/
│   └── index.ts              ← Main generation endpoint
├── get-video-status/
│   └── index.ts              ← Status polling endpoint
├── _shared/
│   ├── logger.ts             ← Already exists (Phase 1)
│   └── falai-adapter.ts      ← NEW: FalAI API client
└── _shared/
    └── storage-utils.ts      ← NEW: Supabase Storage helpers (optional)
```

---

## 🔌 FalAI Integration Details

### Model: Sora 2 Image-to-Video (`fal-ai/sora-2/image-to-video`)

**API Structure:** Uses FalAI Queue API (async pattern)

**Request:**
```typescript
POST https://queue.fal.run/fal-ai/sora-2/image-to-video
Headers:
  Authorization: Key <FALAI_API_KEY>
  Content-Type: application/json

Body:
{
  "prompt": "A glowing cityscape at night",
  "image_url": "https://example.com/image.png",
  "resolution": "auto",
  "aspect_ratio": "auto",
  "duration": 4
}
```

**Response (Submit):**
```json
{
  "request_id": "764cabcf-b745-4b3e-ae38-1200304cf45b",
  "status": "IN_QUEUE"
}
```

**Status Check:**
```
GET https://queue.fal.run/fal-ai/sora-2/image-to-video/requests/{request_id}
```

**Response (Completed):**
```json
{
  "video": {
    "url": "https://storage.googleapis.com/falserverless/example_outputs/sora_2_i2v_output.mp4",
    "content_type": "video/mp4",
    "width": 1280,
    "height": 720,
    "fps": 24,
    "duration": 4.2
  },
  "video_id": "video_123"
}
```

### Video Settings (Phase 2 - Defaults)
- **Resolution:** `"auto"` (default)
- **Aspect Ratio:** `"auto"` (default)
- **Duration:** `4` seconds (default)

**Note:** These can be easily changed later by updating the `VideoSettings` model and the backend mapping. For now, we'll use defaults to ship faster.

---

## 💾 Video Storage Strategy

### Option A: Store in Supabase Storage (Recommended)
**Pros:**
- Full control over video lifecycle
- Better performance (CDN)
- Can set expiration policies
- Secure access via RLS

**Cons:**
- Need to download from FalAI first
- Additional storage costs
- More complex (download → upload flow)

**Flow:**
1. FalAI completes → returns video URL
2. Download video from FalAI URL
3. Upload to Supabase Storage bucket `videos`
4. Generate thumbnail (optional)
5. Update `video_jobs` with Supabase Storage URLs
6. Delete from FalAI (optional, if temporary)

### Option B: Keep FalAI URLs (Simpler)
**Pros:**
- Simpler implementation
- No download/upload overhead
- Faster to implement

**Cons:**
- Dependent on FalAI hosting
- Less control over video access
- Can't set expiration policies easily

**Flow:**
1. FalAI completes → returns video URL
2. Update `video_jobs` with FalAI URL directly
3. Generate thumbnail from video (optional)

### Decision: ✅ **Option B - FalAI URLs (MVP)**

**What users see in ResultView:**
- `VideoPlayerView` receives `videoURL: URL?` from FalAI
- AVPlayer can play any HTTP/HTTPS URL directly
- No download/upload needed - simpler and faster
- Users see the video directly from FalAI's CDN

**Pros:**
- Simpler implementation (no download/upload flow)
- Faster to ship
- Works perfectly with iOS AVPlayer

**Note:** Can migrate to Option A (Supabase Storage) later in Phase 3 if needed for more control.

---

## 🎨 Thumbnail Generation

### Options:
1. **FalAI Provides Thumbnail** - Use if available
2. **Generate from Video** - Extract first frame (requires video download)
3. **Skip for MVP** - Add later in Phase 3

### Decision: ✅ **Skip Thumbnails for Phase 2**

**Reason:** Add in Phase 3 when we have more time to implement thumbnail generation from video.

**For now:**
- `thumbnail_url` will be `null` in database
- History view can show a placeholder or first frame of video
- ResultView doesn't need thumbnails (shows video directly)

---

## 📱 iOS Integration Changes

### Update `VideoGenerationService.swift`

**Current (Mock):**
```swift
func generateVideo(request: VideoGenerationRequest) async throws -> VideoGenerationResponse {
    // Mock implementation
}
```

**New (Real API):**
```swift
func generateVideo(request: VideoGenerationRequest) async throws -> VideoGenerationResponse {
    // 1. Generate idempotency key
    let idempotencyKey = UUID().uuidString
    
    // 2. Call Supabase Edge Function
    let response: VideoGenerationResponse = try await APIClient.shared.request(
        endpoint: "generate-video",
        method: .POST,
        body: request,
        headers: [
            "Idempotency-Key": idempotencyKey
        ]
    )
    
    return response
}
```

### Update `ModelDetailViewModel.swift`

**Current Issue:**
- Line 128-131: Manually deducts credits after generation
- **Problem:** Credits are already deducted by backend!

**Fix:**
```swift
// Remove manual credit deduction (lines 128-131)
// Backend already deducts credits atomically

// Just update UI with new credits from response
let newCredits = try await creditService.getUserCredits(userId: userId)
creditsRemaining = newCredits
```

### Create Status Polling Service

**New File:** `VideoStatusService.swift`
```swift
class VideoStatusService {
    func pollStatus(jobId: String) async throws -> VideoStatusResponse {
        // Poll get-video-status endpoint
        // Return status, video_url, thumbnail_url
    }
}
```

---

## 🔄 Status Polling Strategy

### Option A: Client-Side Polling (Phase 2)
- iOS app polls every 5-10 seconds
- Simple to implement
- Works for MVP

### Option B: Supabase Realtime (Phase 5)
- Server pushes updates when status changes
- Better UX (instant updates)
- More complex (database triggers)

### Phase 2 Decision:
**Use Option A (Client-Side Polling)** for MVP
- Implement exponential backoff (5s → 10s → 20s)
- Stop polling after 5 minutes (timeout)
- Can upgrade to Realtime in Phase 5

---

## ✅ Implementation Checklist

### Backend Tasks:
- [ ] Create `generate-video/index.ts` endpoint
- [ ] Create `get-video-status/index.ts` endpoint
- [ ] Create `_shared/falai-adapter.ts` utility
- [ ] Implement idempotency check logic
- [ ] Implement credit deduction with rollback
- [ ] Implement FalAI API integration
- [ ] Implement status polling logic
- [ ] Implement video storage (Option A or B)
- [ ] Add comprehensive error handling
- [ ] Add structured logging
- [ ] Test all error scenarios

### iOS Tasks:
- [ ] Update `VideoGenerationService.swift` to call real API
- [ ] Add idempotency key generation
- [ ] Remove manual credit deduction from `ModelDetailViewModel`
- [ ] Create `VideoStatusService.swift` for polling
- [ ] Update `ResultView` to poll status
- [ ] Handle idempotent replay responses
- [ ] Test error handling

### Testing Tasks:
- [ ] Test successful video generation
- [ ] Test idempotency (duplicate requests)
- [ ] Test insufficient credits scenario
- [ ] Test FalAI API errors
- [ ] Test status polling (pending → completed)
- [ ] Test failed generation (rollback credits)
- [ ] Test video storage/URL handling

---

## 🚨 Critical Questions

Before we start implementation, please confirm:

### 1. FalAI Configuration
- **Model IDs:** Which models are you using? (e.g., `fal-ai/veo3.1`)
- **API Documentation:** Do you have current FalAI API docs? (URLs may have changed)
- **Settings Mapping:** Confirm `VideoSettings` → FalAI parameters mapping

### 2. Video Storage
- **Storage Strategy:** Option A (Supabase Storage) or Option B (FalAI URLs)?
- **Thumbnails:** Include in Phase 2 or skip for now?

### 3. Status Polling
- **Polling Interval:** 5 seconds okay? (with exponential backoff)
- **Timeout:** 5 minutes max polling time?

### 4. Error Handling ✅ **Already Planned**

**From `backend-building-plan.md`:**
- **Phase 2 (Current):** Basic error handling with rollback
  - If FalAI fails → Refund credits immediately
  - Mark job as "failed" in database
  - Return error to iOS client
- **Phase 6 (Future):** Exponential backoff retry logic
- **Phase 7 (Future):** Standardized error codes with i18n

**For Phase 2:** We'll implement basic rollback + error handling. Advanced retry logic comes in Phase 6.

### 5. Implementation Order ✅ **Backend First**

**Strategy:**
1. ✅ Backend implementation (generate-video + get-video-status)
2. ✅ Test with curl/Postman
3. ✅ iOS integration after backend is verified

**Benefits:**
- Catch API issues early
- Easier debugging
- Can test edge cases before iOS integration

---

## 📝 Next Steps

1. **Answer the questions above** ✅
2. **Review FalAI API docs** (if needed)
3. **Start backend implementation** (generate-video endpoint)
4. **Test with curl/Postman**
5. **Implement get-video-status endpoint**
6. **Update iOS client**
7. **End-to-end testing**

---

## 🎯 Success Criteria

Phase 2 is complete when:
- ✅ User can generate video from iOS app
- ✅ Credits are deducted atomically
- ✅ Idempotency prevents duplicate charges
- ✅ Status polling works (pending → completed)
- ✅ Videos are accessible (via storage or FalAI URL)
- ✅ Error handling works (rollback credits on failure)
- ✅ All edge cases tested

---

**Ready to start?** Please answer the questions above, and we'll begin implementation! 🚀

