# 🔍 UserService Implementation Audit Report

**Date:** 2025-11-15  
**Status:** ⚠️ Issues Found - Needs Fixes  
**Overall Grade:** B+ (Good, but has critical issues)

---

## 📊 Summary

| Component | Status | Issues | Priority |
|-----------|--------|--------|----------|
| `merge-guest-user` Edge Function | ✅ Good | 2 issues | 🟡 Medium |
| `delete-account` Edge Function | ✅ Excellent | 0 issues | ✅ None |
| `updateUserSettings` iOS | ✅ Excellent | 0 issues | ✅ None |
| `mergeGuestToUser` iOS | ✅ Good | 1 issue | 🔴 Critical |
| `deleteAccount` iOS | ✅ Excellent | 0 issues | ✅ None |
| **AuthService Integration** | ❌ **BROKEN** | 1 issue | 🔴 **CRITICAL** |

---

## 🔴 CRITICAL ISSUE #1: AuthService Still Mocked

### Problem

`ProfileViewModel.signInWithApple()` calls `authService.mergeGuestToUser()`, but `AuthService.mergeGuestToUser()` is **still mocked**!

**File:** `RendioAI/RendioAI/Core/Networking/AuthService.swift:64-99`

```swift
func mergeGuestToUser(...) async throws -> User {
    // Phase 2: Replace with actual Supabase Edge Function call
    // Currently using mock data for development
    
    try await Task.sleep(for: .seconds(1.5))  // ← STILL MOCKED!
    
    // Mock response - merged user
    let mergedUser = User(...)  // ← FAKE USER!
    return mergedUser
}
```

**But `ProfileViewModel` calls:**
```swift
let mergedUser = try await authService.mergeGuestToUser(...)  // ← Calls AuthService, not UserService!
```

### Impact

- ❌ Merge flow **won't work** - still returns fake user
- ❌ Credits **won't be preserved** during sign-in
- ❌ User experience **broken**

### Fix Required

**Option A: Update AuthService to call UserService** (Recommended)

```swift
// AuthService.swift:64-99
func mergeGuestToUser(
    deviceId: String,
    appleSub: String,
    identityToken: Data?,
    authorizationCode: Data?
) async throws -> User {
    // Delegate to UserService (which has the real implementation)
    return try await UserService.shared.mergeGuestToUser(
        deviceId: deviceId,
        appleSub: appleSub
    )
}
```

**Option B: Update ProfileViewModel to call UserService directly**

```swift
// ProfileViewModel.swift:224
let mergedUser = try await userService.mergeGuestToUser(
    deviceId: deviceId,
    appleSub: appleAuthResult.appleSub
)
```

**Recommendation:** Option A (keeps AuthService as the interface)

---

## 🟡 ISSUE #2: Race Condition in merge-guest-user

### Problem

**File:** `RendioAI/supabase/functions/merge-guest-user/index.ts:67-96`

The function finds or creates Apple user, but there's a potential race condition:

```typescript
// 2. Find or create Apple user
let { data: appleUser } = await supabase
  .from('users')
  .select('*')
  .eq('apple_sub', apple_sub)
  .single()

if (!appleUser) {
  // Create new Apple user
  const { data: newUser, error: createError } = await supabase
    .from('users')
    .insert({...})
```

**Issue:** If two requests try to merge the same guest at the same time:
1. Request A: Finds no Apple user, starts creating
2. Request B: Finds no Apple user, starts creating
3. Both try to insert → **Unique constraint violation** on `apple_sub`

### Impact

- ⚠️ Concurrent merge attempts will fail
- ⚠️ User sees error during sign-in
- ⚠️ Low probability but possible

### Fix Required

**Option A: Handle unique constraint error** (Simple)

```typescript
if (!appleUser) {
  const { data: newUser, error: createError } = await supabase
    .from('users')
    .insert({...})
    .select()
    .single()

  if (createError) {
    // If unique constraint violation, user was created by another request
    if (createError.code === '23505') {  // PostgreSQL unique violation
      // Retry: fetch the user that was just created
      const { data: existingUser } = await supabase
        .from('users')
        .select('*')
        .eq('apple_sub', apple_sub)
        .single()
      appleUser = existingUser
    } else {
      throw createError
    }
  } else {
    appleUser = newUser
  }
}
```

**Option B: Use database transaction** (More robust, but more complex)

**Recommendation:** Option A (simple, handles the edge case)

---

## 🟡 ISSUE #3: Missing Error Handling in merge-guest-user

### Problem

**File:** `RendioAI/supabase/functions/merge-guest-user/index.ts:108-128`

The function continues even if video_jobs or quota_log transfer fails:

```typescript
// 4. Transfer video_jobs
const { error: jobsError } = await supabase
  .from('video_jobs')
  .update({ user_id: appleUser.id })
  .eq('user_id', guestUser.id)

if (jobsError) {
  logEvent('merge_guest_user_jobs_error', { error: jobsError.message }, 'warn')
  // Continue anyway - not critical  // ← Is this safe?
}
```

**Issue:** If transfer fails, user loses video history but merge succeeds. This might be intentional, but should be documented.

### Impact

- ⚠️ User might lose video history silently
- ⚠️ No rollback if critical step fails

### Fix Required

**Option A: Make it fail-safe** (Current approach is fine, but document it)

Add comment explaining why we continue:
```typescript
if (jobsError) {
  logEvent('merge_guest_user_jobs_error', { error: jobsError.message }, 'warn')
  // Continue anyway - video history loss is acceptable for merge operation
  // User still has credits and account, which are more critical
}
```

**Option B: Fail the merge if transfer fails** (More strict)

```typescript
if (jobsError) {
  throw new Error(`Failed to transfer video_jobs: ${jobsError.message}`)
}
```

**Recommendation:** Option A (current approach is reasonable - credits are more important than history)

---

## ✅ What's Working Well

### 1. delete-account Edge Function ✅

**File:** `RendioAI/supabase/functions/delete-account/index.ts`

- ✅ Proper validation
- ✅ User existence check before deletion
- ✅ Good error handling
- ✅ Proper logging
- ✅ CASCADE handles related data correctly

**Grade:** A

### 2. deleteAccount iOS Function ✅

**File:** `RendioAI/RendioAI/Core/Networking/UserService.swift:187-254`

- ✅ Proper error handling
- ✅ Good validation
- ✅ Clear logging
- ✅ Handles 404 correctly

**Grade:** A

### 3. updateUserSettings iOS Function ✅

**File:** `RendioAI/RendioAI/Core/Networking/UserService.swift:256-325`

- ✅ Smart use of REST API (no Edge Function needed)
- ✅ Proper validation
- ✅ Verifies update succeeded
- ✅ Good error handling

**Grade:** A

### 4. mergeGuestToUser iOS Function ✅

**File:** `RendioAI/RendioAI/Core/Networking/UserService.swift:98-185`

- ✅ Proper error handling
- ✅ Good validation
- ✅ Correct date parsing (matches existing pattern)
- ✅ Clear logging

**Grade:** A (but won't work until AuthService is fixed)

### 5. merge-guest-user Edge Function (Overall) ✅

**File:** `RendioAI/supabase/functions/merge-guest-user/index.ts`

**Good things:**
- ✅ Proper validation
- ✅ Good logging
- ✅ Transfers credits correctly
- ✅ Transfers video_jobs and quota_log
- ✅ Preserves device_id
- ✅ Handles guest user not found
- ✅ Creates Apple user if needed

**Grade:** B+ (minor issues with race condition and error handling)

---

## 🔧 Required Fixes

### Fix #1: Update AuthService.mergeGuestToUser() 🔴 CRITICAL

**File:** `RendioAI/RendioAI/Core/Networking/AuthService.swift:64-99`

**Replace:**
```swift
func mergeGuestToUser(...) async throws -> User {
    // Phase 2: Replace with actual Supabase Edge Function call
    try await Task.sleep(for: .seconds(1.5))
    // Mock response...
    return mergedUser
}
```

**With:**
```swift
func mergeGuestToUser(
    deviceId: String,
    appleSub: String,
    identityToken: Data?,
    authorizationCode: Data?
) async throws -> User {
    // Delegate to UserService which has the real implementation
    return try await UserService.shared.mergeGuestToUser(
        deviceId: deviceId,
        appleSub: appleSub
    )
}
```

**Time:** 2 minutes  
**Priority:** 🔴 CRITICAL

---

### Fix #2: Handle Race Condition in merge-guest-user 🟡 MEDIUM

**File:** `RendioAI/supabase/functions/merge-guest-user/index.ts:73-96`

**Replace:**
```typescript
if (!appleUser) {
  const { data: newUser, error: createError } = await supabase
    .from('users')
    .insert({...})
    .select()
    .single()

  if (createError) {
    throw createError
  }

  appleUser = newUser
}
```

**With:**
```typescript
if (!appleUser) {
  const { data: newUser, error: createError } = await supabase
    .from('users')
    .insert({
      apple_sub: apple_sub,
      is_guest: false,
      tier: 'free',
      credits_remaining: 0,
      credits_total: 0,
      language: guestUser.language || 'en',
      theme_preference: guestUser.theme_preference || 'system'
    })
    .select()
    .single()

  if (createError) {
    // Handle unique constraint violation (race condition)
    if (createError.code === '23505') {
      // Another request created the user - fetch it
      logEvent('merge_guest_user_race_condition', { apple_sub }, 'info')
      const { data: existingUser } = await supabase
        .from('users')
        .select('*')
        .eq('apple_sub', apple_sub)
        .single()
      
      if (!existingUser) {
        throw new Error('Failed to create or find Apple user')
      }
      appleUser = existingUser
    } else {
      throw createError
    }
  } else {
    appleUser = newUser
  }
}
```

**Time:** 5 minutes  
**Priority:** 🟡 MEDIUM

---

### Fix #3: Document Error Handling (Optional) 🟢 LOW

**File:** `RendioAI/supabase/functions/merge-guest-user/index.ts:114-128`

**Add comment:**
```typescript
if (jobsError) {
  logEvent('merge_guest_user_jobs_error', { error: jobsError.message }, 'warn')
  // Continue anyway - video history loss is acceptable for merge operation
  // Credits and account merge are more critical than preserving video history
}
```

**Time:** 1 minute  
**Priority:** 🟢 LOW

---

## 📋 Testing Checklist

### mergeGuestToUser

- [ ] Guest with credits → Merge → Credits preserved
- [ ] Guest with videos → Merge → Videos accessible
- [ ] Guest with no activity → Merge → Account created
- [ ] Apple user already exists → Merge into existing
- [ ] Concurrent merge attempts → Only one succeeds (after Fix #2)
- [ ] Network failure → Proper error handling
- [ ] Invalid device_id → 404 error
- [ ] Invalid apple_sub → Creates new user

### deleteAccount

- [ ] User with videos → Delete → All data removed
- [ ] User with credits → Delete → All data removed
- [ ] User doesn't exist → 404 error
- [ ] Network failure → Proper error handling

### updateUserSettings

- [ ] Change language → Syncs to backend
- [ ] Change theme → Syncs to backend
- [ ] Invalid user_id → 404 error
- [ ] Network failure → Proper error handling

---

## 🎯 Overall Assessment

### Strengths ✅

1. **Code Quality:** Clean, readable, follows existing patterns
2. **Error Handling:** Good error handling in most places
3. **Logging:** Proper logging throughout
4. **Validation:** Input validation is good
5. **Simplicity:** Kept it simple, no over-engineering

### Weaknesses ⚠️

1. **AuthService Integration:** Critical - still mocked
2. **Race Condition:** Medium - concurrent merges might fail
3. **Error Handling:** Low - some edge cases not fully handled

### Grade: B+ → A (after fixes)

**Current:** B+ (Good implementation, but has critical integration issue)  
**After Fixes:** A (Excellent, production-ready)

---

## 🚀 Next Steps

1. **Fix AuthService.mergeGuestToUser()** (2 min) - 🔴 CRITICAL
2. **Fix race condition** (5 min) - 🟡 MEDIUM
3. **Test merge flow** (15 min)
4. **Deploy and verify** (10 min)

**Total time to fix:** ~30 minutes

---

## ✅ Conclusion

**Good news:** The implementation is solid! Code quality is high, follows patterns well.

**Bad news:** One critical integration issue - `AuthService` still mocked.

**Action required:** Fix `AuthService.mergeGuestToUser()` to call `UserService`, then you're good to go!

**After fixes:** This will be production-ready! 🚀

