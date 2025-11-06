# 🔐 Security Context — Rendio AI

**Purpose:** Quick reference for security implementation — RLS, DeviceCheck, privacy, data flow.

**Sources:** `design/security/security-policies.md`, `design/security/anonymous-devicecheck-system.md`, `design/database/data-schema-final.md`

---

## 🔒 Access Layers

| Type | Description | Features |
|------|-------------|----------|
| **Anonymous** | Guest users (no login) | 10 free credits, video generation, 7-day history |
| **Authenticated** | Apple Sign-in users | Persistent credits, IAP, full history |
| **Admin** | Internal only | Supabase panel access |

---

## 🛡️ Row-Level Security (RLS)

**Enabled Tables:** `users`, `video_jobs`, `quota_log`

**Rules:**
- Users can only access their own rows: `auth.uid() = id`
- History/credit logs: `auth.uid() = user_id`
- `models` table: **public read-only** (RLS disabled)

**Implementation:**
```sql
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can access own data" 
ON public.users FOR SELECT 
USING (auth.uid() = id) 
WITH CHECK (auth.uid() = id);
```

---

## 🔑 API Key & Client Security

| Component | Rule |
|-----------|------|
| **FAL_KEY** | Server-side only (Supabase Edge Function) |
| **Supabase anon key** | Read-only client access, writes via Edge Functions |
| **Server functions** | All sensitive operations (credit deduction, video jobs) via Edge Functions |

**Never store API keys in iOS app** → use Keychain for tokens, Info.plist for non-sensitive config.

---

## 📱 DeviceCheck Integration

**Purpose:** Anonymous device verification to prevent credit abuse.

**Flow:**
1. App launch → `DeviceCheck.generateToken()`
2. Backend validates token → checks `initial_grant_claimed` flag
3. If `false` → grant 10 credits, set `initial_grant_claimed = true`
4. If `true` → fetch existing user data

**Implementation:**
```swift
// Silent retry (max 3 attempts)
Task {
    try? await Task.sleep(for: .seconds(2))
    try await performDeviceCheck()
}
```

**UserDefaults flag:**
- `hasSeenWelcomeBanner` → local flag (shown once only)

---

## 👤 User Data Privacy

| Data Type | Storage | Access |
|-----------|---------|--------|
| `credits_remaining` | Supabase `users` table | Private (own row only) |
| `device_id` | Keychain + Supabase | Private (DeviceCheck verified) |
| `video_url` | Supabase Storage (private bucket) | Private (signed URLs for sharing) |
| `models` metadata | Public table | Public (all users) |

**Rules:**
- No personal data collection without Apple Sign-in
- Videos auto-deleted after 7 days
- No user profiling, no ads, no tracking SDKs
- GDPR-ready

---

## 🔄 Data Flow Security

1. **Video Generation:**
   - Client sends `prompt + settings` → Supabase Edge Function
   - Edge Function calls FalAI (API key server-side)
   - Response stored in `video_jobs` (RLS protected)

2. **Download & Share:**
   - Videos in Supabase private bucket
   - Share links use expiring signed URLs

3. **Credit System:**
   - Deduction happens server-side only
   - Logged in `quota_log` for audit

---

## 📚 References

- Security policies: `design/security/security-policies.md`
- DeviceCheck system: `design/security/anonymous-devicecheck-system.md`
- Data schema: `design/database/data-schema-final.md`
