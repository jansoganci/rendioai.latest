# 📋 Phase 3: History & User Management - Implementation Plan

**Date:** 2025-01-XX  
**Status:** ✅ **COMPLETE**  
**Estimated Time:** 2 days  
**Priority:** P1 (High)  
**Completed:** 2025-01-XX

---

## 🎯 Goal

Build 4 backend endpoints for history and user management, then update iOS services to use them.

---

## 📊 Current State Analysis

### ✅ What's Already Done
- **Phase 0:** Database schema complete (tables: `users`, `video_jobs`, `models`, `quota_log`)
- **Phase 1:** Core APIs working (`device-check`, `update-credits`, `get-user-credits`)
- **Phase 2:** Video generation working (`generate-video`, `get-video-status`)
- **iOS Services:** Mock implementations exist, ready to be replaced

### ✅ What's Complete (Phase 3)
1. **Backend Endpoints (4 total):** ✅ **ALL DONE**
   - ✅ `get-video-jobs` - Fetch user's video history
   - ✅ `delete-video-job` - Delete a video job
   - ✅ `get-models` - Fetch available models (replaced REST API)
   - ✅ `get-user-profile` - Fetch user profile data

2. **iOS Service Updates (3 services):** ✅ **ALL DONE**
   - ✅ `HistoryService` - Replaced mock with real API calls
   - ✅ `ModelService` - Switched from REST API to Edge Function
   - ✅ `UserService` - Replaced mock with real API calls

---

## 📝 Step-by-Step Implementation Plan

### **Step 1: Create `get-video-jobs` Endpoint** ✅ **DONE** (30 min)

**File:** `RendioAI/supabase/functions/get-video-jobs/index.ts`

**Requirements:**
- Accept `user_id` as query parameter (required)
- Accept `limit` and `offset` for pagination (optional, defaults: 20, 0)
- Query `video_jobs` table with join to `models` table
- Return jobs ordered by `created_at DESC` (newest first)
- Transform response to match iOS `VideoJob` model

**Response Format:**
```json
{
  "jobs": [
    {
      "job_id": "uuid",
      "prompt": "string",
      "model_name": "string",
      "credits_used": 4,
      "status": "completed",
      "video_url": "string|null",
      "thumbnail_url": "string|null",
      "created_at": "2025-01-XXT00:00:00Z"
    }
  ]
}
```

**iOS Model Mapping:**
- `job_id` → `job_id` ✅
- `prompt` → `prompt` ✅
- `model_name` → `model_name` ✅ (from `models.name` join)
- `credits_used` → `credits_used` ✅
- `status` → `status` ✅ (must be: "pending", "processing", "completed", "failed")
- `video_url` → `video_url` ✅ (nullable)
- `thumbnail_url` → `thumbnail_url` ✅ (nullable)
- `created_at` → `created_at` ✅ (ISO8601 format)

**Database Query:**
```sql
SELECT 
  job_id,
  prompt,
  status,
  video_url,
  thumbnail_url,
  credits_used,
  created_at,
  models.name as model_name
FROM video_jobs
JOIN models ON video_jobs.model_id = models.id
WHERE video_jobs.user_id = $1
ORDER BY created_at DESC
LIMIT $2 OFFSET $3
```

---

### **Step 2: Create `delete-video-job` Endpoint** ✅ **DONE** (30 min)

**File:** `RendioAI/supabase/functions/delete-video-job/index.ts`

**Requirements:**
- Accept `job_id` and `user_id` in request body (POST)
- Verify ownership (user_id matches job's user_id)
- Delete video from storage (if `video_url` exists) - TODO for now
- Delete job record from `video_jobs` table
- Return success response

**Request Format:**
```json
{
  "job_id": "uuid",
  "user_id": "uuid"
}
```

**Response Format:**
```json
{
  "success": true
}
```

**Security:**
- Must verify `user_id` matches job owner before deletion
- Return 404 if job not found or unauthorized

**Storage Deletion (Future):**
- Extract path from `video_url` (Supabase Storage URL)
- Delete from `videos` bucket
- Delete thumbnail from `thumbnails` bucket (if exists)

---

### **Step 3: Create `get-models` Endpoint** ✅ **DONE** (20 min)

**File:** `RendioAI/supabase/functions/get-models/index.ts`

**Requirements:**
- No authentication required (public endpoint)
- Query `models` table where `is_available = true`
- Order by `is_featured DESC, name ASC`
- Return all model fields

**Response Format:**
```json
{
  "models": [
    {
      "id": "uuid",
      "name": "string",
      "category": "string",
      "thumbnail_url": "string|null",
      "is_featured": true
    }
  ]
}
```

**iOS Model Mapping:**
- `id` → `id` ✅
- `name` → `name` ✅
- `category` → `category` ✅
- `thumbnail_url` → `thumbnailURL` ✅ (nullable, snake_case → camelCase)
- `is_featured` → `isFeatured` ✅ (snake_case → camelCase)

**Note:** iOS `ModelService` currently uses direct REST API. This endpoint provides:
- Better error handling
- Consistent API pattern
- Future: Can add caching, rate limiting, etc.

---

### **Step 4: Create `get-user-profile` Endpoint** ✅ **DONE** (20 min)

**File:** `RendioAI/supabase/functions/get-user-profile/index.ts`

**Requirements:**
- Accept `user_id` as query parameter (required)
- Query `users` table
- Return all user fields

**Response Format:**
```json
{
  "id": "uuid",
  "email": "string|null",
  "device_id": "string|null",
  "apple_sub": "string|null",
  "is_guest": true,
  "tier": "free",
  "credits_remaining": 10,
  "credits_total": 10,
  "initial_grant_claimed": true,
  "language": "en",
  "theme_preference": "system",
  "created_at": "2025-01-XXT00:00:00Z",
  "updated_at": "2025-01-XXT00:00:00Z"
}
```

**iOS Model Mapping:**
- All fields match iOS `User` model with snake_case keys ✅
- iOS uses `CodingKeys` to map snake_case → camelCase

---

### **Step 5: Update iOS `HistoryService`** ✅ **DONE** (45 min)

**File:** `RendioAI/RendioAI/Core/Networking/HistoryService.swift`

**Changes Needed:**

1. **Update `fetchVideoJobs()`:**
   ```swift
   func fetchVideoJobs(userId: String?) async throws -> [VideoJob] {
       guard let userId = userId else {
           throw AppError.invalidResponse
       }
       
       // Build URL with query parameters
       var components = URLComponents(string: "\(baseURL)/functions/v1/get-video-jobs")
       components?.queryItems = [
           URLQueryItem(name: "user_id", value: userId),
           URLQueryItem(name: "limit", value: "20"),
           URLQueryItem(name: "offset", value: "0")
       ]
       
       guard let url = components?.url else {
           throw AppError.invalidURL
       }
       
       // Make GET request
       var request = URLRequest(url: url)
       request.httpMethod = "GET"
       request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
       request.setValue(anonKey, forHTTPHeaderField: "apikey")
       
       let (data, response) = try await session.data(for: request)
       
       // Handle response...
       struct JobsResponse: Codable {
           let jobs: [VideoJob]
       }
       
       let decoder = JSONDecoder()
       decoder.keyDecodingStrategy = .convertFromSnakeCase
       decoder.dateDecodingStrategy = .iso8601
       
       let jobsResponse = try decoder.decode(JobsResponse.self, from: data)
       return jobsResponse.jobs
   }
   ```

2. **Update `deleteVideoJob()`:**
   ```swift
   func deleteVideoJob(jobId: String) async throws {
       guard let userId = UserDefaultsManager.shared.currentUserId else {
           throw AppError.invalidResponse
       }
       
       guard let url = URL(string: "\(baseURL)/functions/v1/delete-video-job") else {
           throw AppError.invalidURL
       }
       
       var request = URLRequest(url: url)
       request.httpMethod = "POST"
       request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
       request.setValue(anonKey, forHTTPHeaderField: "apikey")
       request.setValue("application/json", forHTTPHeaderField: "Content-Type")
       
       struct DeleteRequest: Codable {
           let job_id: String
           let user_id: String
       }
       
       let body = DeleteRequest(job_id: jobId, user_id: userId)
       request.httpBody = try JSONEncoder().encode(body)
       
       let (data, response) = try await session.data(for: request)
       
       // Handle response...
       struct DeleteResponse: Codable {
           let success: Bool
       }
       
       let deleteResponse = try JSONDecoder().decode(DeleteResponse.self, from: data)
       guard deleteResponse.success else {
           throw AppError.invalidResponse
       }
   }
   ```

**Dependencies:**
- Need `baseURL` and `anonKey` (check how `CreditService` does it)
- Need `UserDefaultsManager.shared.currentUserId`

---

### **Step 6: Update iOS `ModelService`** ✅ **DONE** (30 min)

**File:** `RendioAI/RendioAI/Core/Networking/ModelService.swift`

**Changes Needed:**

**Update `fetchModels()`:**
```swift
func fetchModels() async throws -> [ModelPreview] {
    // Switch from REST API to Edge Function
    guard let url = URL(string: "\(baseURL)/functions/v1/get-models") else {
        throw AppError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
    request.setValue(anonKey, forHTTPHeaderField: "apikey")
    
    let (data, response) = try await session.data(for: request)
    
    // Handle response...
    struct ModelsResponse: Codable {
        let models: [ModelPreview]
    }
    
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    let modelsResponse = try decoder.decode(ModelsResponse.self, from: data)
    return modelsResponse.models
}
```

**Note:** Keep `fetchModelDetail()` and `fetchActiveModel()` using REST API for now (can be Phase 4 enhancement).

---

### **Step 7: Update iOS `UserService`** ✅ **DONE** (30 min)

**File:** `RendioAI/RendioAI/Core/Networking/UserService.swift`

**Changes Needed:**

**Update `fetchUserProfile()`:**
```swift
func fetchUserProfile(userId: String) async throws -> User {
    guard let url = URL(string: "\(baseURL)/functions/v1/get-user-profile?user_id=\(userId)") else {
        throw AppError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
    request.setValue(anonKey, forHTTPHeaderField: "apikey")
    
    let (data, response) = try await session.data(for: request)
    
    // Handle response...
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601
    
    let user = try decoder.decode(User.self, from: data)
    return user
}
```

**Note:** Keep other methods (`mergeGuestToUser`, `deleteAccount`, `updateUserSettings`) as mock for now (future phases).

---

## 🧪 Testing Checklist

### Backend Endpoints

- [ ] **`get-video-jobs`:**
  - [ ] Returns jobs for valid `user_id`
  - [ ] Returns empty array for user with no jobs
  - [ ] Returns 400 for missing `user_id`
  - [ ] Pagination works (limit/offset)
  - [ ] Jobs ordered by `created_at DESC`
  - [ ] `model_name` correctly joined from `models` table

- [ ] **`delete-video-job`:**
  - [ ] Deletes job for valid `job_id` and `user_id`
  - [ ] Returns 404 for non-existent job
  - [ ] Returns 404 for unauthorized user (wrong `user_id`)
  - [ ] Returns success response

- [ ] **`get-models`:**
  - [ ] Returns only available models (`is_available = true`)
  - [ ] Models ordered by `is_featured DESC, name ASC`
  - [ ] Returns all required fields

- [ ] **`get-user-profile`:**
  - [ ] Returns user for valid `user_id`
  - [ ] Returns 400 for missing `user_id`
  - [ ] Returns 404 for non-existent user
  - [ ] Returns all user fields

### iOS Integration

- [ ] **HistoryService:**
  - [ ] `fetchVideoJobs()` loads real data
  - [ ] `deleteVideoJob()` deletes successfully
  - [ ] Error handling works (network errors, 404, etc.)
  - [ ] Loading states work correctly

- [ ] **ModelService:**
  - [ ] `fetchModels()` loads from Edge Function
  - [ ] Models display correctly in UI
  - [ ] Error handling works

- [ ] **UserService:**
  - [ ] `fetchUserProfile()` loads real data
  - [ ] Profile screen displays correct user info
  - [ ] Error handling works

### End-to-End Flows

- [ ] **History Flow:**
  - [ ] User generates video → appears in history
  - [ ] User deletes video → removed from history
  - [ ] History loads on app launch

- [ ] **Profile Flow:**
  - [ ] Profile screen loads user data
  - [ ] Credits display correctly
  - [ ] User info displays correctly

---

## 📋 Implementation Order

**Recommended Sequence:**

1. ✅ **Backend First (Day 1):** ✅ **COMPLETE**
   - ✅ Step 1: `get-video-jobs` endpoint
   - ✅ Step 2: `delete-video-job` endpoint
   - ✅ Step 3: `get-models` endpoint
   - ✅ Step 4: `get-user-profile` endpoint
   - ⚠️ Test all endpoints with Postman/curl (TODO: Manual testing)

2. ✅ **iOS Integration (Day 2):** ✅ **COMPLETE**
   - ✅ Step 5: Update `HistoryService`
   - ✅ Step 6: Update `ModelService`
   - ✅ Step 7: Update `UserService`
   - ⚠️ Test all flows in iOS app (TODO: End-to-end testing)

---

## 🔍 Key Considerations

### Response Format Consistency

**All endpoints must return:**
- Consistent error format: `{ "error": "message" }`
- Consistent success format: `{ "data": {...} }` or `{ "jobs": [...] }`
- ISO8601 date format: `"2025-01-XXT00:00:00Z"`

### Error Handling

**Backend:**
- 400: Bad request (missing required params)
- 404: Not found (user/job doesn't exist)
- 500: Internal server error

**iOS:**
- Map HTTP status codes to `AppError` enum
- Show user-friendly error messages
- Handle network failures gracefully

### Security

- All endpoints use `SERVICE_ROLE_KEY` (bypasses RLS)
- `delete-video-job` verifies ownership before deletion
- `get-video-jobs` filters by `user_id` (no cross-user access)

### Performance

- `get-video-jobs` uses pagination (limit 20)
- Database queries use indexes (`idx_video_jobs_user`)
- No N+1 queries (use JOIN for `model_name`)

---

## 📚 References

- **Backend Plan:** `docs/active/backend/implementation/backend-building-plan.md` (Lines 1842-2068)
- **General Rulebook:** `docs/active/design/general-rulebook.md`
- **API Context:** `.cursor/_context-backend-apis.md`
- **iOS Models:**
  - `VideoJob.swift` - History response format
  - `User.swift` - Profile response format
  - `ModelPreview.swift` - Models response format

---

## ✅ Success Criteria

**Phase 3 Status:**
- ✅ All 4 endpoints created
- ✅ All 3 iOS services updated
- ⚠️ History screen loads real data (needs testing)
- ⚠️ Profile screen loads real data (needs testing)
- ⚠️ Models load from Edge Function (needs testing)
- ⚠️ Delete video works end-to-end (needs testing)
- ✅ No mock data in production code

---

**✅ Phase 3 Implementation Complete!**

**Next Steps:**
- ⚠️ Manual testing of all endpoints
- ⚠️ End-to-end testing in iOS app
- ⚠️ Deploy Edge Functions to Supabase production

