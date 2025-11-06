# 🔍 Frontend-Backend Communication Analysis

**Date:** 2025-11-05  
**Purpose:** Analyze 6 known problems and provide exact fixes  
**Backend Status:** ✅ Verified against backend-building-plan.md

---

## Step 1: Backend Verification

### ✅ Backend is correct. It follows the plan.

**Verification Results:**

| Component | Plan Requirement | Implementation | Status |
|-----------|------------------|----------------|--------|
| **Phase 0** | Database schema, stored procedures | ✅ Implemented | ✅ Match |
| **Phase 1** | device-check, get-user-credits, update-credits | ✅ All 3 endpoints exist | ✅ Match |
| **Phase 2** | generate-video, get-video-status | ✅ Both endpoints exist | ✅ Match |
| **Request Format** | `{user_id, model_id, prompt, image_url?, settings?}` | ✅ Exact match | ✅ Match |
| **Response Format** | `{job_id, status, credits_used}` | ✅ Exact match | ✅ Match |
| **Settings Format** | `{resolution?, aspect_ratio?, duration?}` | ✅ Exact match | ✅ Match |

**Backend Endpoints (All Deployed):**
- ✅ `POST /functions/v1/device-check` → Returns `{user_id, credits_remaining, is_new}`
- ✅ `GET /functions/v1/get-user-credits?user_id={uuid}` → Returns `{credits_remaining}`
- ✅ `POST /functions/v1/generate-video` → Expects `{user_id, model_id, prompt, image_url?, settings: {resolution?, aspect_ratio?, duration?}}`
- ✅ `GET /functions/v1/get-video-status?job_id={uuid}` → Returns `{job_id, status, video_url, thumbnail_url, error_message}`
- ✅ `POST /functions/v1/update-credits` → (Phase 1 - exists)

**Conclusion:** Backend matches plan 100%. No backend changes needed.

---

## Step 2: Frontend Problems Analysis

### Problem 1: Frontend Still Uses Mock Data

**File:** `RendioAI/RendioAI/Core/Networking/ModelService.swift`  
**Function:** `fetchModels()` (line 20-68)  
**Function:** `fetchModelDetail(id:)` (line 71-103)

**What Backend Expects:**
- Backend has `models` table with UUIDs
- No endpoint exists to fetch models (Phase 3 feature)
- **Workaround:** Query database directly OR create models in database with matching UUIDs

**What Frontend Currently Does:**
- Returns hardcoded array with IDs: `"1"`, `"2"`, `"3"`, etc.
- Never calls backend

**Exact Minimal Fix:**
Since backend doesn't have a models endpoint yet, we have two options:

**Option A (Quick Fix):** Query Supabase database directly
```swift
// In ModelService.swift
private let baseURL = "https://ojcnjxzctnwbmupggoxq.supabase.co"
private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

func fetchModels() async throws -> [ModelPreview] {
    guard let url = URL(string: "\(baseURL)/rest/v1/models?is_available=eq.true&select=id,name,category,thumbnail_url,is_featured") else {
        throw AppError.invalidResponse
    }
    
    var request = URLRequest(url: url)
    request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
    request.setValue(anonKey, forHTTPHeaderField: "apikey")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode([ModelPreview].self, from: data)
}
```

**Option B (Proper Fix):** Create backend endpoint `/functions/v1/get-models` (Phase 3)

**Validation:** Check console for actual model UUIDs from database

---

### Problem 2: CreditService Doesn't Call Real Backend

**File:** `RendioAI/RendioAI/Core/Networking/CreditService.swift`  
**Function:** `fetchCredits()` (line 21-28)  
**Function:** `updateCredits(change:reason:)` (line 30-38)

**What Backend Expects:**
- `GET /functions/v1/get-user-credits?user_id={uuid}` → Returns `{credits_remaining: Int}`
- `POST /functions/v1/update-credits` → (if needed for manual updates)

**What Frontend Currently Does:**
- `fetchCredits()` → Returns hardcoded `10`
- `updateCredits()` → Returns `max(0, 10 + change)` (mock calculation)

**Exact Minimal Fix:**
```swift
// In CreditService.swift
private let baseURL = "https://ojcnjxzctnwbmupggoxq.supabase.co"
private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
private let session: URLSession = .shared

func fetchCredits() async throws -> Int {
    guard let userId = UserDefaultsManager.shared.currentUserId else {
        throw AppError.invalidResponse
    }
    
    guard let url = URL(string: "\(baseURL)/functions/v1/get-user-credits?user_id=\(userId)") else {
        throw AppError.invalidResponse
    }
    
    var request = URLRequest(url: url)
    request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
    request.setValue(anonKey, forHTTPHeaderField: "apikey")
    
    let (data, response) = try await session.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw AppError.networkFailure
    }
    
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let responseObj = try decoder.decode([String: Int].self, from: data)
    return responseObj["credits_remaining"] ?? 0
}
```

**Validation:** Check console for actual credit balance from backend

---

### Problem 3: ResultService Doesn't Call get-video-status

**File:** `RendioAI/RendioAI/Core/Networking/ResultService.swift`  
**Function:** `fetchVideoJob(jobId:)` (line 34-64)

**What Backend Expects:**
- `GET /functions/v1/get-video-status?job_id={uuid}`
- Returns: `{job_id, status, video_url, thumbnail_url, error_message}`

**What Frontend Currently Does:**
- Returns mock `VideoJob` with fake video URLs
- Never calls backend

**Exact Minimal Fix:**
```swift
// In ResultService.swift
private let baseURL = "https://ojcnjxzctnwbmupggoxq.supabase.co"
private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
private let session: URLSession = .shared

func fetchVideoJob(jobId: String) async throws -> VideoJob {
    guard let url = URL(string: "\(baseURL)/functions/v1/get-video-status?job_id=\(jobId)") else {
        throw AppError.invalidResponse
    }
    
    var request = URLRequest(url: url)
    request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
    request.setValue(anonKey, forHTTPHeaderField: "apikey")
    
    let (data, response) = try await session.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw AppError.networkFailure
    }
    
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    // Backend returns: {job_id, status, video_url, thumbnail_url, error_message}
    // Frontend expects: VideoJob with more fields (prompt, model_name, credits_used, created_at)
    // Need to map backend response to VideoJob
    struct BackendResponse: Codable {
        let job_id: String
        let status: String
        let video_url: String?
        let thumbnail_url: String?
        let error_message: String?
    }
    
    let backendResponse = try decoder.decode(BackendResponse.self, from: data)
    
    // Map to VideoJob (will need to fetch additional fields or use defaults)
    return VideoJob(
        job_id: backendResponse.job_id,
        prompt: "", // Backend doesn't return this - will need to fetch separately or store locally
        model_name: "", // Backend doesn't return this
        credits_used: 0, // Backend doesn't return this
        status: VideoJob.JobStatus(rawValue: backendResponse.status) ?? .pending,
        video_url: backendResponse.video_url,
        thumbnail_url: backendResponse.thumbnail_url,
        created_at: Date()
    )
}
```

**Note:** Backend response is missing `prompt`, `model_name`, `credits_used`, `created_at`. These need to be fetched from database separately or stored locally after generation.

**Validation:** Check console for real job status from backend

---

### Problem 4: VideoSettings Missing aspect_ratio

**File:** `RendioAI/RendioAI/Core/Models/VideoSettings.swift`  
**Line:** Missing `aspect_ratio` field

**What Backend Expects:**
```typescript
settings?: {
  resolution?: 'auto' | '720p'
  aspect_ratio?: 'auto' | '9:16' | '16:9'  // ← Missing in frontend
  duration?: 4 | 8 | 12
}
```

**What Frontend Currently Does:**
```swift
struct VideoSettings {
    let duration: Int?      // ✅ Has this
    let resolution: String? // ⚠️ Has "720p"|"1080p" but backend expects "auto"|"720p"
    let fps: Int?          // ❌ Backend doesn't use this
    // ❌ Missing: aspect_ratio
}
```

**Exact Minimal Fix:**
```swift
// In VideoSettings.swift
struct VideoSettings: Codable {
    let duration: Int?
    let resolution: String?
    let aspect_ratio: String?  // ADD THIS
    let fps: Int?  // Keep for frontend UI, but don't send to backend
    
    enum CodingKeys: String, CodingKey {
        case duration
        case resolution
        case aspect_ratio  // ADD THIS
        case fps
    }
}
```

**Then in VideoGenerationService.swift:**
```swift
let backendSettings: [String: Any] = [
    "resolution": request.settings.resolution ?? "720p",
    "aspect_ratio": request.settings.aspect_ratio ?? "auto",  // ADD THIS
    "duration": backendDuration
]
```

**Validation:** Check backend logs to see aspect_ratio is sent

---

### Problem 5: VideoGenerationRequest Missing image_url

**File:** `RendioAI/RendioAI/Core/Models/VideoGenerationRequest.swift`  
**Line:** Missing `image_url` field

**What Backend Expects:**
```typescript
{
  user_id: string
  model_id: string
  prompt: string
  image_url?: string  // Required for Sora 2 (fal-ai/sora-2/image-to-video)
  settings?: {...}
}
```

**What Frontend Currently Does:**
```swift
struct VideoGenerationRequest {
    let user_id: String
    let model_id: String
    let prompt: String
    let settings: VideoSettings
    // ❌ Missing: image_url
}
```

**Exact Minimal Fix:**
```swift
// In VideoGenerationRequest.swift
struct VideoGenerationRequest: Codable {
    let user_id: String
    let model_id: String
    let prompt: String
    let image_url: String?  // ADD THIS
    let settings: VideoSettings
    
    enum CodingKeys: String, CodingKey {
        case user_id
        case model_id
        case prompt
        case image_url  // ADD THIS
        case settings
    }
}
```

**Then in VideoGenerationService.swift:**
```swift
let requestBody: [String: Any] = [
    "user_id": request.user_id,
    "model_id": modelIdUUID,
    "prompt": request.prompt,
    "image_url": request.image_url,  // ADD THIS (nil is fine for non-Sora-2 models)
    "settings": backendSettings
]
```

**Validation:** For Sora 2 model, backend should receive image_url (or error if missing)

---

### Problem 6: user_id Not Always Saved After Onboarding

**File:** `RendioAI/RendioAI/Core/Services/OnboardingService.swift`  
**Function:** `checkDevice(token:)` (line 35-98)

**What Backend Returns:**
- `{user_id: "uuid", credits_remaining: 10, is_new: true}`

**What Frontend Currently Does:**
- Decodes response to `OnboardingResponse`
- Returns `OnboardingResponse` to caller
- **Missing:** Saving `user_id` to `UserDefaultsManager.shared.currentUserId`

**Where It IS Saved:**
- `OnboardingViewModel.swift` line 93: `UserDefaultsManager.shared.currentUserId = response.user_id`
- But only if onboarding goes through ViewModel

**Exact Minimal Fix:**
```swift
// In OnboardingService.swift, after decoding response (line 87)
do {
    let onboardingResponse = try decoder.decode(OnboardingResponse.self, from: data)
    
    // SAVE user_id immediately after successful decode
    UserDefaultsManager.shared.currentUserId = onboardingResponse.user_id
    print("✅ Saved user_id: \(onboardingResponse.user_id)")
    
    print("✅ Device check successful: \(onboardingResponse.isExistingUser ? "Existing" : "New") user")
    return onboardingResponse
} catch {
    // ... existing error handling
}
```

**Validation:** After onboarding, check `UserDefaultsManager.shared.currentUserId` is not nil

---

## Summary Table

| Problem | File | Fix Location | Lines to Change |
|---------|------|--------------|-----------------|
| 1. Mock Models | `ModelService.swift` | `fetchModels()` | Replace entire function (~50 lines) |
| 2. Mock Credits | `CreditService.swift` | `fetchCredits()` | Replace function (~20 lines) |
| 3. Mock Results | `ResultService.swift` | `fetchVideoJob()` | Replace function (~30 lines) |
| 4. Missing aspect_ratio | `VideoSettings.swift` | Add field | Add 1 field + CodingKey |
| 5. Missing image_url | `VideoGenerationRequest.swift` | Add field | Add 1 field + CodingKey |
| 6. user_id not saved | `OnboardingService.swift` | After decode | Add 2 lines |

**Total Files to Modify:** 6  
**Total Lines of Code:** ~110 lines

---

## Validation Checklist

After implementing fixes:

- [ ] ModelService returns real UUIDs from database
- [ ] CreditService shows actual credit balance
- [ ] ResultService shows real job status
- [ ] Backend receives aspect_ratio in settings
- [ ] Backend receives image_url for Sora 2
- [ ] user_id is saved after every onboarding

