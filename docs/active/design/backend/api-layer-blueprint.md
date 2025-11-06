⸻

# 🌐 API Layer Blueprint — Video App

**Version:** 2.1 (Production-Ready)

**Date:** 2025-11-05

**Author:** [You]

**Status:** ✅ Updated with Smart MVP features (idempotency, rollback, anonymous auth)

**Purpose:** Define the backend interface (Supabase Edge Functions) for video generation, job management, and credit handling.

**Reference:** Aligns with `backend-building-plan.md` Version 2.1 (Smart MVP Edition)

⸻

## 🧩 Overview

```
Frontend (SwiftUI) → Supabase Edge Functions (API Layer) → Model Providers (FalAI, Runway, Pika)
```

The API layer acts as a universal broker — it doesn't know specific model logic.

Each model defines its own provider info inside the models table.

The API simply reads that metadata and routes the request correctly.

⸻

## 📡 Endpoints

### 1. POST /generate-video

**Purpose:** Create a new generation job and trigger the selected model.

**🔑 CRITICAL: Requires Idempotency-Key Header**

**Request Headers:**
```
Idempotency-Key: <uuid>  ← REQUIRED to prevent duplicate charges
Authorization: Bearer <jwt_token>  ← Guest or Apple Sign-In JWT
```

**Flow:**

1. **Check idempotency** (prevent duplicate if retry)
2. Validate user credits
3. Fetch model details from models
4. **Deduct credits atomically** (via stored procedure)
5. Create video_jobs entry (status: "pending")
6. **Store idempotency record** (cache response)
7. Forward request to provider (FalAI, Pika, etc.)
8. Update job with provider_job_id
9. Return job_id

**Request JSON:**

```json
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

**Response JSON:**

```json
{
  "job_id": "uuid",
  "status": "pending",
  "credits_used": 4
}
```

**If Idempotent Replay (duplicate request):**
```json
{
  "job_id": "uuid-from-first-request",
  "status": "pending",
  "credits_used": 4
}
```
Response headers include: `X-Idempotent-Replay: true`

⸻

### 2. GET /get-video-status?job_id={id}

**Purpose:** Poll video generation progress.

**Response JSON:**

```json
{
  "job_id": "uuid",
  "status": "completed",
  "video_url": "https://cdn.app/videos/123.mp4",
  "thumbnail_url": "https://cdn.app/videos/123_thumb.jpg"
}
```

If status = completed, frontend navigates to ResultView.

⸻

### 3. GET /get-video-jobs?user_id={id}

**Purpose:** Return user's video history for HistoryView.

**Response JSON:**

```json
{
  "jobs": [
    {
      "job_id": "uuid",
      "prompt": "Ocean waves at sunset",
      "model_name": "FalAI v1",
      "credits_used": 4,
      "status": "completed",
      "thumbnail_url": "https://cdn.app/videos/thumb1.jpg",
      "created_at": "2025-11-05T19:00:00Z"
    }
  ]
}
```

⸻

### 4. GET /get-user-credits?user_id={id}

**Purpose:** Show remaining credits (for header + paywall).

**Response JSON:**

```json
{ "credits_remaining": 8 }
```

⸻

### 5. POST /update-credits

**Purpose:** Add or deduct credits (generation, purchase, or bonus).

**Request JSON:**

```json
{
  "user_id": "uuid",
  "change": -4,
  "reason": "generation"
}
```

**Response JSON:**

```json
{
  "credits_remaining": 6,
  "success": true
}
```

⸻

## 🧠 Model Integration Logic

Each model provider has its own "adapter" function defined in `/models_providers/` folder:

| Provider | Adapter File | Description |
|----------|--------------|-------------|
| FalAI | falai_adapter.ts | POST request to FalAI API endpoint |
| Pika | pika_adapter.ts | Converts settings to their API format |
| Runway | runway_adapter.ts | Auth header + webhook listener |
| OpenAI (future) | openai_adapter.ts | text-to-video extensions |

All adapters follow the same interface:

```typescript
interface VideoModelAdapter {
  generate(input: {
    prompt: string;
    settings: Record<string, any>;
    modelInfo: any;
  }): Promise<{ job_id: string; provider_status: string }>;
}
```

This pattern allows adding new models without changing any endpoint.

⸻

## 🔒 Security

- All endpoints require:
  - Valid device_id or user_id
  - Optional JWT for logged-in users
- Edge Functions enforce RLS (row-level security).
- No API key exposure in frontend (server-side secrets).
- DeviceCheck validation on /generate-video for guest users.

⸻

## 🔁 Credit Deduction Flow (Atomic Operations)

**⚠️ CRITICAL:** Use stored procedures to prevent race conditions.

**Flow:**

1. generate-video request arrives
2. **Check idempotency** (return cached response if duplicate)
3. Fetch model cost from `models` table (NEVER trust client)
4. **Call stored procedure:** `deduct_credits(user_id, cost, 'video_generation')`
   - ✅ Atomically checks balance and deducts
   - ✅ Logs transaction in `quota_log`
   - ✅ Updates `users.credits_remaining`
   - ✅ Returns success/failure + new balance
5. If insufficient credits → **Return HTTP 402 Payment Required**
6. If success:
   - Create job in `video_jobs` (status: "pending")
   - Call provider API
   - **Store idempotency record** (24-hour cache)
   - Return { job_id }
7. If provider fails → **Rollback credits** (see below)

**Example Edge Function Code:**

```typescript
// WRONG ❌ - Race condition possible
const { data: user } = await supabase
  .from('users')
  .select('credits_remaining')
  .eq('id', user_id)
  .single()

if (user.credits_remaining < cost) {
  return new Response('Insufficient credits', { status: 402 })
}

await supabase
  .from('users')
  .update({ credits_remaining: user.credits_remaining - cost })
  .eq('id', user_id)
// ❌ If two requests happen simultaneously, both might pass the check

// CORRECT ✅ - Atomic operation
const { data: result } = await supabase.rpc('deduct_credits', {
  p_user_id: user_id,
  p_amount: cost,
  p_reason: 'video_generation'
})

if (!result.success) {
  return new Response(
    JSON.stringify({ error: result.error }),
    { status: 402 }
  )
}
// ✅ Database ensures only one request succeeds
```

⸻

## 🔑 Idempotency Protection

**Purpose:** Prevent duplicate charges if user's network drops and iOS retries the request.

**How It Works:**

1. iOS client generates unique UUID for each video generation
2. Client sends UUID in `Idempotency-Key` header
3. Backend checks `idempotency_log` table for existing record
4. If found → return cached response (no charge)
5. If new → process request, store result in `idempotency_log`

**Implementation:**

```typescript
// At start of /generate-video endpoint
const idempotencyKey = req.headers.get('Idempotency-Key')

if (!idempotencyKey) {
  return new Response(
    JSON.stringify({ error: 'Idempotency-Key header required' }),
    { status: 400 }
  )
}

// Check for existing record
const { data: existing } = await supabase
  .from('idempotency_log')
  .select('job_id, response_data, status_code')
  .eq('idempotency_key', idempotencyKey)
  .eq('user_id', user_id)
  .gt('expires_at', new Date().toISOString())
  .single()

if (existing) {
  // Return cached response (idempotent replay)
  return new Response(
    JSON.stringify(existing.response_data),
    {
      status: existing.status_code,
      headers: {
        'Content-Type': 'application/json',
        'X-Idempotent-Replay': 'true'
      }
    }
  )
}

// ... proceed with normal flow ...

// After successful generation, store idempotency record
await supabase.from('idempotency_log').insert({
  idempotency_key: idempotencyKey,
  user_id: user_id,
  job_id: job.job_id,
  operation_type: 'video_generation',
  response_data: { job_id: job.job_id, status: 'pending', credits_used: cost },
  status_code: 200,
  expires_at: new Date(Date.now() + 24 * 3600 * 1000).toISOString() // 24h
})
```

**iOS Client Example:**

```swift
// In VideoGenerationService.swift
func generateVideo(...) async throws -> VideoGenerationResponse {
    let idempotencyKey = UUID().uuidString // Generate once per generation

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

**Benefits:**
- ✅ User never charged twice for same video
- ✅ Network retry safe
- ✅ App crash recovery (if user reopens app, same idempotency key = no charge)

⸻

## 🔙 Rollback Logic (Error Recovery)

**Purpose:** Refund credits if video generation fails after deduction.

**Failure Points:**

1. **Job creation fails** → Refund credits immediately
2. **Provider API fails** → Mark job as failed, refund credits
3. **Provider timeout** → Mark job as failed, refund credits

**Implementation:**

```typescript
// In /generate-video endpoint

// 1. Credits already deducted
const { data: deductResult } = await supabase.rpc('deduct_credits', {
  p_user_id: user_id,
  p_amount: cost,
  p_reason: 'video_generation'
})

if (!deductResult.success) {
  return new Response(JSON.stringify({ error: 'Insufficient credits' }), { status: 402 })
}

// 2. Create video job
const { data: job, error: jobError } = await supabase
  .from('video_jobs')
  .insert({
    user_id: user_id,
    model_id: model_id,
    prompt: prompt,
    settings: settings,
    status: 'pending',
    credits_used: cost
  })
  .select()
  .single()

if (jobError) {
  // ROLLBACK: Refund credits if job creation failed
  await supabase.rpc('add_credits', {
    p_user_id: user_id,
    p_amount: cost,
    p_reason: 'generation_failed_refund'
  })

  throw new Error('Failed to create job')
}

// 3. Call provider API
try {
  const providerResult = await callProviderAPI(model.provider, prompt, settings)

  // Update job with provider_job_id
  await supabase
    .from('video_jobs')
    .update({ provider_job_id: providerResult.job_id })
    .eq('job_id', job.job_id)

} catch (providerError) {
  // ROLLBACK: Refund credits if provider API failed
  await supabase
    .from('video_jobs')
    .update({
      status: 'failed',
      error_message: providerError.message
    })
    .eq('job_id', job.job_id)

  await supabase.rpc('add_credits', {
    p_user_id: user_id,
    p_amount: cost,
    p_reason: 'generation_failed_refund'
  })

  throw providerError
}

// Success - return job_id
return new Response(JSON.stringify({
  job_id: job.job_id,
  status: 'pending',
  credits_used: cost
}))
```

**Stored Procedures Used:**

Both stored procedures are defined in `backend-building-plan.md` Phase 0:

```sql
-- Add credits (refund)
SELECT * FROM add_credits(
  p_user_id := 'user-uuid',
  p_amount := 4,
  p_reason := 'generation_failed_refund'
);

-- Returns: { success: true, credits_remaining: 14 }
```

**iOS Handling:**

If generation fails, iOS receives error response but credits already refunded server-side. No client action needed.

⸻

## 🔐 Anonymous Auth Integration (Guest Users)

**Purpose:** Guest users get JWT tokens to enable RLS policies and Realtime subscriptions.

**Flow:**

1. User opens app for first time
2. iOS requests DeviceCheck token from Apple
3. iOS calls POST `/device/check` with `device_id` + `device_token`
4. Backend verifies with Apple DeviceCheck API
5. Backend creates **anonymous JWT** via `supabaseClient.auth.signInAnonymously()`
6. Backend creates user record with `auth.uid()` as primary key
7. Backend returns `{ user_id, credits_remaining, session }`
8. iOS stores `session` (JWT token) in Keychain via Supabase SDK

**Why JWT for Guests?**

- ✅ **RLS works:** `auth.uid()` in policies matches guest user ID
- ✅ **Realtime works:** Guests can subscribe to their own video status updates
- ✅ **Seamless upgrade:** When user signs in with Apple, JWT transfers ownership

**Backend Implementation (device/check endpoint):**

```typescript
// 3. Create anonymous auth session for new guest
const { data: authData, error: authError } = await supabaseClient.auth.signInAnonymously()

if (authError) throw authError

// 4. Create user record with auth.uid (enables RLS)
const { data: newUser, error: userError } = await supabaseClient
  .from('users')
  .insert({
    id: authData.user.id, // ← Use auth user ID as primary key
    device_id: device_id,
    is_guest: true,
    tier: 'free',
    credits_remaining: 10,
    credits_total: 10,
    initial_grant_claimed: true
  })
  .select()
  .single()

// 5. Return session to iOS
return new Response(
  JSON.stringify({
    user_id: newUser.id,
    credits_remaining: 10,
    is_new: true,
    session: authData.session // 🔑 JWT token
  })
)
```

**iOS Storage (AuthService.swift):**

```swift
// Store anonymous JWT in Keychain
let onboardingResponse = try await OnboardingService.shared.checkDevice(...)

if let session = onboardingResponse.session {
    try await supabaseClient.auth.setSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken
    )
}

// All subsequent API calls automatically include:
// Authorization: Bearer <jwt_token>
```

**RLS Policy Example:**

```sql
-- Users can only access their own video jobs
CREATE POLICY "Users can view own jobs"
ON video_jobs FOR SELECT
USING (auth.uid() = user_id);

-- Works for both:
-- 1. Guest users (anonymous JWT)
-- 2. Signed-in users (Apple Sign-In JWT)
```

**Token Refresh:**

- Anonymous JWT expires after 1 hour
- Supabase SDK auto-refreshes using refresh token
- If refresh fails, user sees "Session expired" → re-run DeviceCheck flow

**Reference:** See `anonymous-devicecheck-system.md` for complete DeviceCheck integration.

⸻

## 🔮 Future Scalability

- Add "webhooks" for providers that support async notifications.
- Add GET /get-models endpoint for dynamic model lists.
- Extend credit system with subscriptions (users.tier = 'premium').

⸻

## 🧱 Folder Structure

```
/supabase/functions/
│
├── generate-video.ts
├── get-video-status.ts
├── get-video-jobs.ts
├── get-user-credits.ts
├── update-credits.ts
└── models_providers/
    ├── falai_adapter.ts
    ├── pika_adapter.ts
    ├── runway_adapter.ts
    └── openai_adapter.ts
```

⸻

## ✅ Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Centralized generate-video endpoint | Keeps API consistent regardless of provider |
| Model adapters per provider | Isolates API logic from vendor implementation |
| JSONB settings field | Allows flexible options per model |
| Supabase storage for videos | Secure, per-user access control |
| RLS policies | Prevents cross-user data leaks |

⸻

**Document Status:** ✅ Production-Ready

**Last Updated:** 2025-11-05

**What's New in v2.1:**
- ✅ Added Idempotency Protection section (prevent duplicate charges)
- ✅ Added Stored Procedure Usage (atomic credit operations)
- ✅ Added Rollback Logic (credit refunds on failure)
- ✅ Added Anonymous Auth Integration (JWT for guest users)
- ✅ Updated all table names (video_jobs, quota_log)
- ✅ Added request header requirements (Idempotency-Key, Authorization)

**Implementation Reference:**
- See `backend-building-plan.md` Phase 0-2 for complete implementation code
- See `anonymous-devicecheck-system.md` for DeviceCheck integration details
- See `backend-integration-rulebook.md` for iOS client patterns

**End of Document**

This blueprint defines the structure for your Supabase Edge Functions and model adapter system. Each function is reusable, minimal, provider-agnostic, and production-grade.

⸻
