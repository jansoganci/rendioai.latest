# 🔍 Edge Functions Response Audit

**Date:** 2025-01-XX  
**Purpose:** Document what data each edge function returns

---

## 📋 Summary Table

| Endpoint | Method | Returns | Key Fields |
|----------|--------|--------|------------|
| `/device-check` | POST | User onboarding data | `user_id`, `credits_remaining`, `is_new` |
| `/get-user-credits` | GET | Credit balance | `credits_remaining` |
| `/update-credits` | POST | Credit purchase result | `success`, `credits_added`, `credits_remaining` |
| `/generate-video` | POST | Video job creation | `job_id`, `status`, `credits_used` |
| `/get-video-status` | GET | Single video job status | `job_id`, `status`, `prompt`, `model_name`, `credits_used`, `video_url`, `thumbnail_url`, `created_at` |
| `/get-video-jobs` | GET | **User's video history** | `jobs[]` with `job_id`, `prompt`, `model_name`, `status`, `video_url`, etc. |

---

## 1. `/device-check` Endpoint

**File:** `supabase/functions/device-check/index.ts`  
**Method:** POST  
**Purpose:** Guest user onboarding

### Response Format:

**Existing User:**
```json
{
  "user_id": "uuid",
  "credits_remaining": 10,
  "is_new": false
}
```

**New User:**
```json
{
  "user_id": "uuid",
  "credits_remaining": 10,
  "is_new": true
}
```

**Error (Credit Grant Failed):**
```json
{
  "user_id": "uuid",
  "credits_remaining": 0,
  "is_new": true,
  "warning": "Initial credit grant failed"
}
```

---

## 2. `/get-user-credits` Endpoint

**File:** `supabase/functions/get-user-credits/index.ts`  
**Method:** GET  
**Purpose:** Get user's credit balance

### Response Format:

**Success:**
```json
{
  "credits_remaining": 10
}
```

**Error (User Not Found):**
```json
{
  "error": "User not found"
}
```

---

## 3. `/update-credits` Endpoint

**File:** `supabase/functions/update-credits/index.ts`  
**Method:** POST  
**Purpose:** Process Apple IAP purchases

### Response Format:

**Success:**
```json
{
  "success": true,
  "credits_added": 50,
  "credits_remaining": 60
}
```

**Error (Invalid Transaction):**
```json
{
  "error": "Invalid transaction"
}
```

**Error (Unknown Product):**
```json
{
  "error": "Unknown product"
}
```

**Error (Duplicate Transaction):**
```json
{
  "error": "Transaction already processed"
}
```

---

## 4. `/generate-video` Endpoint

**File:** `supabase/functions/generate-video/index.ts`  
**Method:** POST  
**Purpose:** Create video generation job

### Response Format:

**Success:**
```json
{
  "job_id": "uuid",
  "status": "pending",
  "credits_used": 4
}
```

**Idempotent Replay (Duplicate Request):**
```json
{
  "job_id": "uuid",
  "status": "pending",
  "credits_used": 4
}
```
*Note: Includes `X-Idempotent-Replay: true` header*

**Error (Insufficient Credits):**
```json
{
  "error": "Insufficient credits",
  "credits_remaining": 2,
  "required_credits": 4
}
```

---

## 5. `/get-video-status` Endpoint ⚠️

**File:** `supabase/functions/get-video-status/index.ts`  
**Method:** GET  
**Purpose:** Poll single video job status

### Response Format:

**Completed Job:**
```json
{
  "job_id": "uuid",
  "status": "completed",
  "prompt": "string",
  "model_name": "string",
  "credits_used": 4,
  "video_url": "https://...",
  "thumbnail_url": "https://...",
  "created_at": "2025-01-XXT00:00:00Z"
}
```

**Pending/Processing Job:**
```json
{
  "job_id": "uuid",
  "status": "pending",
  "prompt": "string",
  "model_name": "string",
  "credits_used": 4,
  "video_url": null,
  "thumbnail_url": null,
  "created_at": "2025-01-XXT00:00:00Z"
}
```

**Failed Job:**
```json
{
  "job_id": "uuid",
  "status": "failed",
  "prompt": "string",
  "model_name": "string",
  "credits_used": 4,
  "error_message": "string",
  "created_at": "2025-01-XXT00:00:00Z"
}
```

**Error (Job Not Found):**
```json
{
  "error": "Job not found"
}
```

---

## 6. `/get-video-jobs` Endpoint ✅ NEW

**File:** `supabase/functions/get-video-jobs/index.ts`  
**Method:** GET  
**Purpose:** Get user's video history (all jobs)

### Response Format:

**Success:**
```json
{
  "jobs": [
    {
      "job_id": "uuid",
      "prompt": "string",
      "model_name": "string",
      "credits_used": 4,
      "status": "completed",
      "video_url": "https://...",
      "thumbnail_url": "https://...",
      "created_at": "2025-01-XXT00:00:00Z"
    },
    {
      "job_id": "uuid",
      "prompt": "string",
      "model_name": "string",
      "credits_used": 4,
      "status": "pending",
      "video_url": null,
      "thumbnail_url": null,
      "created_at": "2025-01-XXT00:00:00Z"
    }
  ]
}
```

**Empty History:**
```json
{
  "jobs": []
}
```

**Error (Missing user_id):**
```json
{
  "error": "user_id query parameter is required"
}
```

**Error (Invalid Pagination):**
```json
{
  "error": "limit must be between 1 and 100"
}
```

---

## 🔍 Key Differences

### `/get-video-status` vs `/get-video-jobs`

| Feature | `/get-video-status` | `/get-video-jobs` |
|---------|---------------------|-------------------|
| **Purpose** | Get **single** job status | Get **all** user's jobs |
| **Input** | `job_id` (query param) | `user_id` (query param) |
| **Output** | Single job object | Array of jobs (`jobs[]`) |
| **Use Case** | Polling job progress | History screen |
| **Pagination** | No | Yes (limit/offset) |
| **Ordering** | N/A | `created_at DESC` |

### Response Structure Comparison

**`/get-video-status` (Single Job):**
```json
{
  "job_id": "...",
  "status": "...",
  "prompt": "...",
  ...
}
```

**`/get-video-jobs` (Multiple Jobs):**
```json
{
  "jobs": [
    { "job_id": "...", "status": "...", ... },
    { "job_id": "...", "status": "...", ... }
  ]
}
```

---

## 📊 Which Endpoint Returns What?

### If you're seeing **video job data**:

**Single job with status:**
- ✅ `/get-video-status?job_id={id}` - Returns ONE job

**Multiple jobs (history):**
- ✅ `/get-video-jobs?user_id={id}` - Returns ARRAY of jobs

### If you're seeing **user data**:

**Credit balance only:**
- ✅ `/get-user-credits?user_id={id}` - Returns `credits_remaining`

**Full user profile:**
- ⚠️ `/get-user-profile?user_id={id}` - **NOT YET IMPLEMENTED** (Phase 3 Step 4)

**Onboarding data:**
- ✅ `/device-check` - Returns `user_id`, `credits_remaining`, `is_new`

### If you're seeing **credit purchase data**:

- ✅ `/update-credits` - Returns `success`, `credits_added`, `credits_remaining`

---

## 🎯 Common Use Cases

### History Screen
**Use:** `/get-video-jobs?user_id={id}&limit=20&offset=0`
- Returns array of all user's jobs
- Ordered newest first
- Supports pagination

### Result Screen (Polling)
**Use:** `/get-video-status?job_id={id}`
- Returns single job status
- Used for polling progress
- Updates when job completes

### Profile Screen
**Use:** `/get-user-credits?user_id={id}` (for credits)
- Returns credit balance
- Simple read-only endpoint

**Future:** `/get-user-profile?user_id={id}` (for full profile)
- Will return all user fields
- Phase 3 Step 4

---

## ✅ Summary

**Currently Implemented:**
- ✅ `/device-check` - User onboarding
- ✅ `/get-user-credits` - Credit balance
- ✅ `/update-credits` - Credit purchases
- ✅ `/generate-video` - Create video job
- ✅ `/get-video-status` - Single job status
- ✅ `/get-video-jobs` - **History (just created)**

**Not Yet Implemented (Phase 3):**
- ❌ `/delete-video-job` - Delete job
- ❌ `/get-models` - Get available models
- ❌ `/get-user-profile` - Get full user profile

---

**If you're seeing video job data, it's likely from:**
- `/get-video-status` - Single job (for polling)
- `/get-video-jobs` - Multiple jobs (for history) ✅ **Just created!**

