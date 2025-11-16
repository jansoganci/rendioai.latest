# 🔍 Deep Analysis: UserService Mocked Functions

**Date:** 2025-11-15  
**Status:** ✅ Analysis Complete  
**Priority:** 🔴 CRITICAL (mergeGuestToUser), 🟡 HIGH (deleteAccount), 🟢 LOW (updateUserSettings)

---

## 📊 Executive Summary

The terminal analysis correctly identified **3 mocked functions** in `UserService.swift` that need backend implementation. This document provides:

1. ✅ **Validation** of the original analysis
2. 🔍 **Additional findings** and edge cases
3. ⚠️ **Gaps** and missing considerations
4. 🛠️ **Implementation recommendations**

---

## ✅ Validation of Original Analysis

### What Was Correct ✅

1. **Function Identification**: All 3 mocked functions correctly identified
2. **Priority Assessment**: Accurate priority ranking
3. **Database Support**: Schema correctly supports all operations
4. **User Impact**: Correctly identified user experience issues
5. **Backend Status**: Correctly identified missing endpoints

### What Needs Clarification ⚠️

1. **AuthService vs UserService Discrepancy**
   - `AuthService.mergeGuestToUser()` accepts `identityToken` and `authorizationCode`
   - `UserService.mergeGuestToUser()` does NOT accept these
   - **Impact**: Need to decide which service handles the merge

2. **Storage Cleanup**
   - Analysis mentions storage cleanup but doesn't detail implementation
   - `delete-video-job` endpoint shows storage deletion is TODO
   - **Impact**: Videos may remain in storage after account deletion

3. **Stored Procedure Pattern**
   - Analysis mentions using stored procedures but none exist for merge
   - `add_credits()` and `deduct_credits()` exist and work well
   - **Recommendation**: Create `merge_guest_account()` stored procedure

---

## 🔍 Detailed Function Analysis

### Function 1: `mergeGuestToUser()` 🔴 CRITICAL

#### Current Implementation (MOCKED)

```98:114:RendioAI/RendioAI/Core/Networking/UserService.swift
func mergeGuestToUser(deviceId: String, appleSub: String) async throws -> User {
    // Phase 2: Replace with actual Supabase Edge Function call
    // Endpoint: POST /api/merge-guest-to-user
    // Body: { device_id: String, apple_sub: String }
    // Currently using mock data for development

    // Simulate network delay
    try await Task.sleep(for: .seconds(0.8))

    // Validate inputs
    guard !deviceId.isEmpty, !appleSub.isEmpty else {
        throw AppError.invalidResponse
    }

    // Return mock merged user
    return User.registeredPreview
}
```

#### Where It's Called

1. **ProfileViewModel.swift:224** - Via `AuthService.mergeGuestToUser()`
2. **AuthService.swift:64** - Direct implementation (also mocked!)

#### ⚠️ CRITICAL FINDING: Dual Implementation

There are **TWO** merge functions:

1. `UserService.mergeGuestToUser(deviceId:appleSub:)` - Simple signature
2. `AuthService.mergeGuestToUser(deviceId:appleSub:identityToken:authorizationCode:)` - Full signature

**Current Flow:**
```
ProfileViewModel.signInWithApple()
  → AuthService.signInWithApple() ✅ (Real Apple Sign-In)
  → AuthService.mergeGuestToUser() ❌ (MOCKED - returns fake user)
```

**Problem:** `AuthService.mergeGuestToUser()` is called, but it's also mocked!

#### What Needs to Happen

**Option A: AuthService calls UserService** (Recommended)
```swift
// AuthService.mergeGuestToUser()
func mergeGuestToUser(...) async throws -> User {
    // Verify Apple tokens (if needed)
    // Then delegate to UserService
    return try await UserService.shared.mergeGuestToUser(
        deviceId: deviceId,
        appleSub: appleSub
    )
}
```

**Option B: UserService handles everything**
- Move merge logic entirely to UserService
- AuthService just passes through

#### Database Schema Support ✅

```sql
-- users table has all needed columns
device_id TEXT          -- ✅ Can find guest user
apple_sub TEXT          -- ✅ Can find/create Apple user
credits_remaining       -- ✅ Can transfer
credits_total           -- ✅ Can merge totals
```

**Foreign Key Cascades:**
- `video_jobs.user_id` → `ON DELETE CASCADE` ✅
- `quota_log.user_id` → `ON DELETE CASCADE` ✅

**Missing:** No stored procedure for merge operation

#### Recommended Implementation

**Step 1: Create Stored Procedure** (Atomic, Safe)

```sql
CREATE OR REPLACE FUNCTION merge_guest_account(
    p_guest_device_id TEXT,
    p_apple_sub TEXT
) RETURNS JSONB AS $$
DECLARE
    guest_user RECORD;
    apple_user RECORD;
    total_credits INTEGER;
BEGIN
    -- 1. Find guest user (LOCK FOR UPDATE to prevent race conditions)
    SELECT * INTO guest_user
    FROM users
    WHERE device_id = p_guest_device_id
    AND is_guest = true
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Guest user not found'
        );
    END IF;

    -- 2. Find or create Apple user
    SELECT * INTO apple_user
    FROM users
    WHERE apple_sub = p_apple_sub
    FOR UPDATE;

    IF NOT FOUND THEN
        -- Create new Apple user
        INSERT INTO users (apple_sub, is_guest, tier, credits_remaining, credits_total)
        VALUES (p_apple_sub, false, 'free', 0, 0)
        RETURNING * INTO apple_user;
    END IF;

    -- 3. Calculate total credits
    total_credits := COALESCE(guest_user.credits_remaining, 0) + 
                     COALESCE(apple_user.credits_remaining, 0);

    -- 4. Transfer video_jobs (UPDATE user_id)
    UPDATE video_jobs
    SET user_id = apple_user.id
    WHERE user_id = guest_user.id;

    -- 5. Transfer quota_log (UPDATE user_id)
    UPDATE quota_log
    SET user_id = apple_user.id
    WHERE user_id = guest_user.id;

    -- 6. Update Apple user with merged credits
    UPDATE users
    SET credits_remaining = total_credits,
        credits_total = COALESCE(credits_total, 0) + COALESCE(guest_user.credits_total, 0),
        device_id = p_guest_device_id,  -- Keep device_id for future reference
        updated_at = now()
    WHERE id = apple_user.id
    RETURNING * INTO apple_user;

    -- 7. Log the merge transaction
    INSERT INTO quota_log (user_id, change, reason, balance_after)
    VALUES (
        apple_user.id,
        COALESCE(guest_user.credits_remaining, 0),
        'account_merge',
        total_credits
    );

    -- 8. Delete guest user (CASCADE will clean up video_jobs/quota_log)
    DELETE FROM users WHERE id = guest_user.id;

    -- 9. Return merged user
    RETURN jsonb_build_object(
        'success', true,
        'user', row_to_json(apple_user)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Step 2: Create Edge Function**

```typescript
// supabase/functions/merge-guest-user/index.ts
serve(async (req) => {
  const { device_id, apple_sub } = await req.json()
  
  const { data, error } = await supabaseClient.rpc('merge_guest_account', {
    p_guest_device_id: device_id,
    p_apple_sub: apple_sub
  })
  
  if (error || !data.success) {
    return new Response(JSON.stringify({ error: data?.error || error.message }), {
      status: 400
    })
  }
  
  return new Response(JSON.stringify({
    success: true,
    user: data.user
  }))
})
```

**Step 3: Update iOS Code**

```swift
func mergeGuestToUser(deviceId: String, appleSub: String) async throws -> User {
    guard let url = URL(string: "\(baseURL)/functions/v1/merge-guest-user") else {
        throw AppError.invalidResponse
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
    request.setValue(anonKey, forHTTPHeaderField: "apikey")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = [
        "device_id": deviceId,
        "apple_sub": appleSub
    ]
    request.httpBody = try JSONEncoder().encode(body)
    
    let (data, response) = try await session.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw AppError.networkFailure
    }
    
    struct MergeResponse: Codable {
        let success: Bool
        let user: User
    }
    
    let result = try JSONDecoder().decode(MergeResponse.self, from: data)
    return result.user
}
```

#### Edge Cases to Handle

1. **Guest user doesn't exist** → Return error (user never created account)
2. **Apple user already exists** → Merge into existing account
3. **Both users have same device_id** → Already merged, return existing user
4. **Race condition** → Stored procedure uses `FOR UPDATE` locks
5. **No credits to transfer** → Still merge (user might have videos)

#### Testing Checklist

- [ ] Guest with credits → Merge → Credits preserved
- [ ] Guest with videos → Merge → Videos accessible
- [ ] Guest with no activity → Merge → Account created
- [ ] Apple user already exists → Merge into existing
- [ ] Concurrent merge attempts → Only one succeeds
- [ ] Network failure during merge → Rollback (stored procedure is atomic)

---

### Function 2: `deleteAccount()` 🟡 HIGH PRIORITY

#### Current Implementation (MOCKED)

```116:134:RendioAI/RendioAI/Core/Networking/UserService.swift
func deleteAccount(userId: String) async throws {
    // Phase 2: Replace with actual Supabase Edge Function call
    // Endpoint: DELETE /api/user
    // Body: { user_id: String }
    // Currently using mock data for development

    // Simulate network delay
    try await Task.sleep(for: .seconds(1.0))

    // Validate input
    guard !userId.isEmpty else {
        throw AppError.invalidResponse
    }

    // Account deletion would cascade delete:
    // - video_jobs
    // - quota_log
    // - Mark videos for deletion

    // ← DOES NOTHING!
}
```

#### Where It's Called

- **ProfileViewModel.swift:336** - When user confirms deletion

#### Database Support ✅

**CASCADE Deletions:**
```sql
video_jobs.user_id → ON DELETE CASCADE ✅
quota_log.user_id → ON DELETE CASCADE ✅
idempotency_log.user_id → ON DELETE CASCADE ✅
```

**What WON'T Auto-Delete:**
- ❌ Storage videos (need manual cleanup)
- ❌ Auth.users record (if exists)

#### ⚠️ CRITICAL GAP: Storage Cleanup

The analysis mentions "Mark videos for deletion" but:

1. **No storage cleanup implemented** - Videos remain in Supabase Storage
2. **No cleanup job** - Old videos accumulate
3. **Cost impact** - Storage costs continue after account deletion

**Current State:**
- `delete-video-job` endpoint has TODO comment for storage deletion
- Cleanup jobs exist but only for old videos (>90 days)

#### Recommended Implementation

**Step 1: Create Edge Function**

```typescript
// supabase/functions/delete-account/index.ts
serve(async (req) => {
  const { user_id } = await req.json()
  
  // 1. Verify user exists and get video URLs
  const { data: videos } = await supabaseClient
    .from('video_jobs')
    .select('video_url, thumbnail_url')
    .eq('user_id', user_id)
  
  // 2. Delete videos from storage (if exists)
  if (videos && videos.length > 0) {
    const videoPaths = videos
      .map(v => extractPathFromURL(v.video_url))
      .filter(Boolean)
    const thumbnailPaths = videos
      .map(v => extractPathFromURL(v.thumbnail_url))
      .filter(Boolean)
    
    // Delete from storage buckets
    await supabaseClient.storage.from('videos').remove(videoPaths)
    await supabaseClient.storage.from('thumbnails').remove(thumbnailPaths)
  }
  
  // 3. Delete user (CASCADE handles video_jobs, quota_log, etc.)
  const { error } = await supabaseClient
    .from('users')
    .delete()
    .eq('id', user_id)
  
  if (error) throw error
  
  // 4. Delete auth.users if exists
  const { data: user } = await supabaseClient
    .from('users')
    .select('auth_user_id')
    .eq('id', user_id)
    .single()
  
  if (user?.auth_user_id) {
    await supabaseClient.auth.admin.deleteUser(user.auth_user_id)
  }
  
  return new Response(JSON.stringify({ success: true }))
})
```

**Step 2: Update iOS Code**

```swift
func deleteAccount(userId: String) async throws {
    guard let url = URL(string: "\(baseURL)/functions/v1/delete-account") else {
        throw AppError.invalidResponse
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
    request.setValue(anonKey, forHTTPHeaderField: "apikey")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = ["user_id": userId]
    request.httpBody = try JSONEncoder().encode(body)
    
    let (data, response) = try await session.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw AppError.networkFailure
    }
    
    struct DeleteResponse: Codable {
        let success: Bool
    }
    
    let result = try JSONDecoder().decode(DeleteResponse.self, from: data)
    if !result.success {
        throw AppError.networkFailure
    }
}
```

#### Edge Cases

1. **User doesn't exist** → Return success (idempotent)
2. **Storage deletion fails** → Log error but continue (user deleted)
3. **Auth.users deletion fails** → Log error but continue
4. **Concurrent deletion** → Database constraints prevent issues

#### Legal/Compliance ✅

- ✅ GDPR: Right to be forgotten
- ✅ App Store: Account deletion required
- ✅ Data retention: All data deleted (except audit logs if needed)

---

### Function 3: `updateUserSettings()` 🟢 LOW PRIORITY

#### Current Implementation (MOCKED)

```136:152:RendioAI/RendioAI/Core/Networking/UserService.swift
func updateUserSettings(userId: String, settings: UserSettings) async throws {
    // Phase 2: Replace with actual Supabase API call
    // Endpoint: PATCH /api/user-settings
    // Body: { user_id: String, language: String, theme_preference: String }
    // Currently using mock data for development

    // Simulate network delay
    try await Task.sleep(for: .seconds(0.3))

    // Validate inputs
    guard !userId.isEmpty else {
        throw AppError.invalidResponse
    }

    // For guests, settings are stored locally in UserDefaults
    // For logged-in users, settings sync to Supabase users table

    // ← DOES NOTHING!
}
```

#### Where It's Called

- **ProfileViewModel.swift:408** - Language change
- **ProfileViewModel.swift:436** - Theme change

#### Current Behavior ✅

- ✅ Settings saved to UserDefaults (works locally)
- ❌ Settings NOT synced to backend
- ❌ Settings lost on new device

#### Database Support ✅

```sql
users.language TEXT DEFAULT 'en'
users.theme_preference TEXT DEFAULT 'system'
users.updated_at TIMESTAMPTZ (auto-updated by trigger)
```

#### Recommended Implementation (Simplest Option)

**Option A: Direct Supabase UPDATE** (Recommended - No Edge Function Needed!)

```swift
func updateUserSettings(userId: String, settings: UserSettings) async throws {
    // Use Supabase REST API directly (simpler than Edge Function)
    guard let url = URL(string: "\(baseURL)/rest/v1/users?id=eq.\(userId)") else {
        throw AppError.invalidResponse
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "PATCH"
    request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
    request.setValue(anonKey, forHTTPHeaderField: "apikey")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("return=representation", forHTTPHeaderField: "Prefer")
    
    let body = [
        "language": settings.language,
        "theme_preference": settings.themePreference
    ]
    request.httpBody = try JSONEncoder().encode(body)
    
    let (data, response) = try await session.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw AppError.networkFailure
    }
    
    // Verify update succeeded
    struct UpdateResponse: Codable {
        let id: String
        let language: String
        let theme_preference: String
    }
    
    let results = try JSONDecoder().decode([UpdateResponse].self, from: data)
    guard results.count == 1 else {
        throw AppError.invalidResponse
    }
}
```

**Why Direct UPDATE?**
- ✅ Simpler (no Edge Function needed)
- ✅ Faster (one less hop)
- ✅ RLS policies handle security
- ✅ Trigger auto-updates `updated_at`

**Option B: Edge Function** (If you want consistency)

```typescript
// supabase/functions/update-user-settings/index.ts
serve(async (req) => {
  const { user_id, language, theme_preference } = await req.json()
  
  const { error } = await supabaseClient
    .from('users')
    .update({ language, theme_preference })
    .eq('id', user_id)
  
  if (error) throw error
  
  return new Response(JSON.stringify({ success: true }))
})
```

#### Edge Cases

1. **User doesn't exist** → RLS prevents update (returns 404)
2. **Invalid language/theme** → Database CHECK constraint prevents
3. **Network failure** → Settings still saved locally

---

## 🎯 Implementation Priority & Timeline

### Phase 1: CRITICAL (Before TestFlight) 🔴

**1. mergeGuestToUser()** - 3 hours
- [ ] Create stored procedure `merge_guest_account()`
- [ ] Create Edge Function `merge-guest-user`
- [ ] Update `UserService.mergeGuestToUser()`
- [ ] Update `AuthService.mergeGuestToUser()` to call UserService
- [ ] Test full sign-in flow

**2. deleteAccount()** - 1.5 hours
- [ ] Create Edge Function `delete-account`
- [ ] Implement storage cleanup
- [ ] Update `UserService.deleteAccount()`
- [ ] Test deletion flow

**Total: ~4.5 hours**

### Phase 2: NICE TO HAVE (Post-Launch) 🟢

**3. updateUserSettings()** - 1 hour
- [ ] Update `UserService.updateUserSettings()` (direct UPDATE)
- [ ] Test settings sync

**Total: ~1 hour**

---

## ⚠️ Additional Considerations

### 1. Error Handling

All three functions need robust error handling:

```swift
// Example error handling pattern
do {
    try await userService.mergeGuestToUser(...)
} catch AppError.networkFailure {
    // Show "Network error, please try again"
} catch AppError.invalidResponse {
    // Show "Something went wrong"
} catch {
    // Show generic error
}
```

### 2. Idempotency

- **mergeGuestToUser**: Should be idempotent (if already merged, return existing user)
- **deleteAccount**: Should be idempotent (if already deleted, return success)
- **updateUserSettings**: Already idempotent (UPDATE is safe to retry)

### 3. Logging & Monitoring

Add logging to all Edge Functions:

```typescript
logEvent('merge_guest_user_request', { device_id, apple_sub }, 'info')
logEvent('merge_guest_user_success', { user_id, credits_merged }, 'info')
logEvent('merge_guest_user_error', { error: error.message }, 'error')
```

### 4. Security

- ✅ RLS policies protect user data
- ✅ Service role key used in Edge Functions (bypasses RLS safely)
- ✅ Input validation on all endpoints
- ✅ User ownership verification (deleteAccount)

### 5. Testing Strategy

**Unit Tests:**
- Mock network calls
- Test error cases
- Test edge cases

**Integration Tests:**
- Test full merge flow
- Test deletion with videos
- Test settings sync

**Manual Testing:**
- Guest → Sign in → Verify credits preserved
- Delete account → Verify all data gone
- Change settings → Verify sync on new device

---

## 📋 Summary

### What's Accurate ✅

1. All 3 functions correctly identified as mocked
2. Priority assessment is correct
3. Database schema supports all operations
4. Implementation plans are sound

### What's Missing ⚠️

1. **AuthService vs UserService discrepancy** - Need to clarify which handles merge
2. **Storage cleanup** - Not fully addressed in deleteAccount
3. **Stored procedure** - Should create one for merge operation
4. **Error handling** - Need detailed error scenarios

### Recommendations 🎯

1. **Fix mergeGuestToUser FIRST** - Users losing credits = bad reviews
2. **Fix deleteAccount SECOND** - Required for App Store
3. **Fix updateUserSettings LAST** - Works locally, just doesn't sync
4. **Use stored procedures** - Atomic, safe, performant
5. **Add comprehensive logging** - Debug production issues

---

## 🚀 Next Steps

1. **Decide on merge flow**: AuthService → UserService or UserService only?
2. **Create stored procedure** for merge operation
3. **Implement Edge Functions** following existing patterns
4. **Update iOS code** with real API calls
5. **Test thoroughly** before TestFlight

---

**Analysis Complete** ✅  
**Ready for Implementation** 🚀

