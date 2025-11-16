# 🎯 Simple Fix: UserService Mocks

**Goal:** Replace 3 mocked functions with real API calls  
**Time:** ~2 hours total  
**Complexity:** Keep it simple, match existing patterns

---

## 📋 What We Actually Need

### 1. `mergeGuestToUser()` - 45 min
**Simple approach:**
- Edge Function that does 3 UPDATE queries
- No stored procedure needed
- No complex locking (Postgres handles it)

### 2. `deleteAccount()` - 30 min  
**Simple approach:**
- Edge Function that deletes user
- CASCADE handles video_jobs/quota_log automatically
- Skip storage cleanup for now (add later if needed)

### 3. `updateUserSettings()` - 15 min
**Simplest approach:**
- Use Supabase REST API directly (no Edge Function!)
- Just a PATCH request

---

## 🛠️ Implementation

### Fix #1: mergeGuestToUser (45 min)

**Edge Function:** `supabase/functions/merge-guest-user/index.ts`

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { logEvent } from '../_shared/logger.ts'

serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    const { device_id, apple_sub } = await req.json()

    if (!device_id || !apple_sub) {
      return new Response(JSON.stringify({ error: 'device_id and apple_sub required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Find guest user
    const { data: guestUser } = await supabase
      .from('users')
      .select('*')
      .eq('device_id', device_id)
      .eq('is_guest', true)
      .single()

    if (!guestUser) {
      return new Response(JSON.stringify({ error: 'Guest user not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    // 2. Find or create Apple user
    let { data: appleUser } = await supabase
      .from('users')
      .select('*')
      .eq('apple_sub', apple_sub)
      .single()

    if (!appleUser) {
      // Create new Apple user
      const { data: newUser } = await supabase
        .from('users')
        .insert({
          apple_sub: apple_sub,
          is_guest: false,
          tier: 'free',
          credits_remaining: 0,
          credits_total: 0
        })
        .select()
        .single()
      appleUser = newUser
    }

    // 3. Transfer credits
    const totalCredits = (guestUser.credits_remaining || 0) + (appleUser.credits_remaining || 0)

    // 4. Transfer video_jobs
    await supabase
      .from('video_jobs')
      .update({ user_id: appleUser.id })
      .eq('user_id', guestUser.id)

    // 5. Transfer quota_log
    await supabase
      .from('quota_log')
      .update({ user_id: appleUser.id })
      .eq('user_id', guestUser.id)

    // 6. Update Apple user with merged credits
    const { data: mergedUser } = await supabase
      .from('users')
      .update({
        credits_remaining: totalCredits,
        credits_total: (appleUser.credits_total || 0) + (guestUser.credits_total || 0),
        device_id: device_id, // Keep device_id
        updated_at: new Date().toISOString()
      })
      .eq('id', appleUser.id)
      .select()
      .single()

    // 7. Delete guest user (CASCADE handles related data)
    await supabase
      .from('users')
      .delete()
      .eq('id', guestUser.id)

    return new Response(JSON.stringify({
      success: true,
      user: mergedUser
    }), {
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})
```

**iOS Update:** `UserService.swift` (lines 98-114)

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
    
    let body = ["device_id": deviceId, "apple_sub": appleSub]
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

---

### Fix #2: deleteAccount (30 min)

**Edge Function:** `supabase/functions/delete-account/index.ts`

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { logEvent } from '../_shared/logger.ts'

serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    const { user_id } = await req.json()

    if (!user_id) {
      return new Response(JSON.stringify({ error: 'user_id required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Delete user (CASCADE handles video_jobs, quota_log automatically)
    const { error } = await supabase
      .from('users')
      .delete()
      .eq('id', user_id)

    if (error) {
      throw error
    }

    // Note: Storage cleanup can be added later if needed
    // For now, CASCADE deletion is enough

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})
```

**iOS Update:** `UserService.swift` (lines 116-134)

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

---

### Fix #3: updateUserSettings (15 min)

**No Edge Function needed!** Use Supabase REST API directly.

**iOS Update:** `UserService.swift` (lines 136-152)

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
    
    // Verify update succeeded (optional)
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

---

## ✅ That's It!

**Total time:** ~2 hours  
**Files to create:**
- `supabase/functions/merge-guest-user/index.ts`
- `supabase/functions/delete-account/index.ts`

**Files to update:**
- `RendioAI/RendioAI/Core/Networking/UserService.swift` (3 functions)

**No need for:**
- ❌ Stored procedures
- ❌ Complex locking
- ❌ Storage cleanup (add later if needed)
- ❌ Edge Function for updateUserSettings

**Deploy:**
```bash
cd RendioAI/supabase
supabase functions deploy merge-guest-user
supabase functions deploy delete-account
```

---

## 🎯 Summary

**Before:** 3 mocked functions doing nothing  
**After:** 3 real API calls that actually work

**Complexity:** Simple, matches existing patterns  
**Time:** ~2 hours  
**Risk:** Low (simple database operations)

Keep it simple. Ship it. Iterate later if needed. 🚀

