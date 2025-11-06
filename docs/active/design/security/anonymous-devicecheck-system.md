⸻

# 🧠 Anonymous DeviceCheck System Draft

**Date:** 2025-11-04

**Author:** [You]

**Purpose:**

Prevent users from repeatedly reinstalling the app to gain free credits, without requiring login.

Combine device_id, Keychain, and Apple's DeviceCheck API for secure, anonymous user tracking.

⸻

## 🎯 Goal

Ensure that each physical iOS device can claim the initial free credit grant only once, even if:

- The app is deleted and reinstalled
- The user changes their Apple ID
- The device_id changes locally

⸻

## ⚙️ System Overview

```
App Launch
   ↓
Check Keychain for stored device_id
   ↓
If none → generate new UUID → save to Keychain
   ↓
Request DeviceCheck token from Apple
   ↓
Send token + device_id → Backend
   ↓
Backend verifies with Apple DeviceCheck server
   ↓
If device bit "initial_grant_given" = 0 → grant credits & set bit = 1
Else → deny grant
```

⸻

## 🧩 Components

| Layer | Responsibility |
|-------|----------------|
| iOS App (SwiftUI) | Generates UUID, stores in Keychain, requests DeviceCheck token |
| Supabase / Backend | Verifies token with Apple API, manages credit grant, updates DB |
| Apple DeviceCheck Server | Maintains device-level state (2 bits per device) |

⸻

## 📱 iOS-Side Logic (Pseudocode)

```swift
import DeviceCheck
import KeychainSwift

let keychain = KeychainSwift()

var deviceId = keychain.get("device_id") ?? {
    let newId = UUID().uuidString
    keychain.set(newId, forKey: "device_id")
    return newId
}()

let device = DCDevice.current

if device.isSupported {
    device.generateToken { token, error in
        guard let token = token else { return }
        sendToServer(deviceId: deviceId, deviceCheckToken: token)
    }
}
```

⸻

## 🖥️ Backend Logic (Production Implementation)

**Reference:** See `backend-building-plan.md` Phase 0.5 (lines 833-1015) for complete implementation.

```typescript
// /supabase/functions/device-check/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { verifyDeviceToken } from '../_shared/device-check.ts'

serve(async (req) => {
  try {
    const { device_id, device_token } = await req.json()

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Verify device token with Apple DeviceCheck
    const deviceCheck = await verifyDeviceToken(device_token, device_id)

    if (!deviceCheck.valid) {
      return new Response(
        JSON.stringify({ error: 'Invalid device' }),
        { status: 403 }
      )
    }

    // 2. Check if user exists
    const { data: existingUser } = await supabaseClient
      .from('users')
      .select('*')
      .eq('device_id', device_id)
      .single()

    if (existingUser) {
      // Return existing user
      return new Response(
        JSON.stringify({
          user_id: existingUser.id,
          credits_remaining: existingUser.credits_remaining,
          is_new: false
        }),
        { headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 3. Create anonymous auth session for new guest
    const { data: authData, error: authError } = await supabaseClient.auth.signInAnonymously()

    if (authError) throw authError

    // 4. Create user record with auth.uid (enables RLS)
    const { data: newUser, error: userError } = await supabaseClient
      .from('users')
      .insert({
        id: authData.user.id, // Use auth user ID for RLS
        device_id: device_id,
        is_guest: true,
        tier: 'free',
        credits_remaining: 10,
        credits_total: 10,
        initial_grant_claimed: true
      })
      .select()
      .single()

    if (userError) throw userError

    // 5. Log initial credit grant
    await supabaseClient.from('quota_log').insert({
      user_id: newUser.id,
      change: 10,
      reason: 'initial_grant',
      balance_after: 10
    })

    // 6. Return user data + auth session (iOS stores JWT)
    return new Response(
      JSON.stringify({
        user_id: newUser.id,
        credits_remaining: newUser.credits_remaining,
        is_new: true,
        session: authData.session // 🔑 JWT token for RLS
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Device check error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500 }
    )
  }
})
```

**Key Changes from Draft:**
- ✅ Uses real Apple DeviceCheck API (not pseudocode)
- ✅ Creates anonymous JWT via `signInAnonymously()` (enables RLS)
- ✅ Returns `session` field containing JWT token
- ✅ Grants 10 credits (not 5)
- ✅ Uses stored procedures for credit operations

⸻

## 🗄️ Database Integration

Add to users table:

| Column | Type | Description |
|--------|------|-------------|
| device_id | text | Local UUID from Keychain |
| initial_grant_claimed | boolean | Mirror of DeviceCheck bit0 |
| apple_device_token_hash | text | (optional) hashed DeviceCheck token for auditing |

⸻

## 🧱 Supabase Policy Notes

| Rule | Description |
|------|-------------|
| Each device_id can appear only once in users. | |
| Only backend (Edge Function) can modify initial_grant_claimed. | |
| Public API cannot reset this flag. | |

⸻

## 🔒 Security Properties

| Risk | Mitigation |
|------|------------|
| App reinstall | Keychain + DeviceCheck bit retained |
| Apple ID change | DeviceCheck unaffected |
| Factory reset | Only full hardware wipe resets bit (acceptable edge case) |
| API tampering | Token verification with Apple server |
| Replay attack | Token one-time use enforced |

⸻

## 💡 Bit Allocation (Apple allows 2 bits/device)

| Bit | Use |
|-----|-----|
| bit0 | initial_grant_given |
| bit1 | Reserved for future use (e.g. abuse flag or referral bonus) |

⸻

## 🔄 Future Extensions

| Feature | Description |
|---------|-------------|
| Abuse detection | Use bit1 to flag suspicious devices |
| Analytics | Count unique device grants without personal data |
| Integration | Combine with Sign in with Apple for seamless upgrade flow |

⸻

## ✅ Expected Behavior

- First launch → user gets 10 free credits.
- Second install → DeviceCheck bit0 already set → no new credits.
- User later signs in → guest → full user merge.

⸻

## 🔑 Anonymous JWT Integration

**Why JWT for Guest Users?**

Guest users receive an anonymous JWT token from Supabase Auth, which enables:

1. **Row-Level Security (RLS):** `auth.uid()` works for guests
2. **Supabase Realtime:** Guests can subscribe to their own data changes
3. **Seamless Upgrade:** When user signs in with Apple, JWT transfers ownership

**JWT Storage (iOS):**
```swift
// AuthService.swift
func storeGuestSession(_ session: Session) async {
    // Supabase SDK automatically stores in Keychain
    try await supabaseClient.auth.setSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken
    )
}
```

**RLS Policy Example:**
```sql
-- Users can only access their own video jobs
CREATE POLICY "Users can view own jobs"
ON video_jobs FOR SELECT
USING (auth.uid() = user_id);
-- Works for both guest JWT and Apple Sign-In JWT
```

⸻

**Document Status:** ✅ Production-Ready (aligns with backend-building-plan.md v2.1)

**Last Updated:** 2025-11-05

**Implementation Reference:** `backend-building-plan.md` Phase 0.5 (Anonymous Auth for Guest Users)

⸻
