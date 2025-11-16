# ✅ Edge Functions Deployment - Update

**Date:** 2025-01-27  
**Status:** ✅ **DEPLOYED**

---

## 🚀 Deployed Functions

### 1. delete-account ✅
**Status:** ✅ **DEPLOYED**  
**URL:** `https://ojcnjxzctnwbmupggoxq.supabase.co/functions/v1/delete-account`

**Purpose:**
- Delete user account and all associated data
- CASCADE deletion handles:
  - `video_jobs` (ON DELETE CASCADE)
  - `quota_log` (ON DELETE CASCADE)

**Request:**
```json
POST /delete-account
{
  "user_id": "uuid"
}
```

**Response:**
```json
{
  "success": true
}
```

---

### 2. merge-guest-user ✅
**Status:** ✅ **DEPLOYED**  
**URL:** `https://ojcnjxzctnwbmupggoxq.supabase.co/functions/v1/merge-guest-user`

**Purpose:**
- Merge guest account with authenticated Apple user
- Transfers credits, video_jobs, and quota_log
- Preserves device_id

**Request:**
```json
POST /merge-guest-user
{
  "device_id": "device-uuid",
  "apple_sub": "apple-sub-id"
}
```

**Response:**
```json
{
  "success": true,
  "user": { /* User object with merged credits */ }
}
```

**Features:**
- Handles race conditions (concurrent merge requests)
- Transfers video_jobs to Apple user
- Transfers quota_log to Apple user
- Merges credits (guest + Apple)
- Deletes guest user after merge

---

## 📊 Deployment Details

**Project:** `ojcnjxzctnwbmupggoxq`  
**Dashboard:** https://supabase.com/dashboard/project/ojcnjxzctnwbmupggoxq/functions

**Deployed Assets:**
- `delete-account/index.ts`
- `merge-guest-user/index.ts`
- Shared dependencies:
  - `_shared/logger.ts`
  - `_shared/telegram.ts`
  - `_shared/sentry.ts`

---

## ✅ Status

**Both functions:** ✅ **DEPLOYED SUCCESSFULLY**

---

**Next Steps:**
- Test `delete-account` endpoint
- Test `merge-guest-user` endpoint
- Verify CASCADE deletion works correctly

