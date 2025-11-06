# ✅ MVP Backend Finalization - Confirmation Report

**Date:** 2025-11-05  
**Purpose:** Confirm all items before finalizing MVP for testing

---

## 1. ✅ Apple IAP Verification & DeviceCheck

### Status: Mocked for Phase 1 → Phase 0.5

**File References:**
- DeviceCheck: `supabase/functions/device-check/index.ts:61-73`
- Apple IAP: `supabase/functions/update-credits/index.ts:187-211`

**Current Implementation:**
```typescript
// device-check/index.ts:65
if (!device_token || device_token.length < 10) {
  return new Response({ error: 'Invalid device token' }, { status: 400 })
}
// ✅ Basic validation only - real DeviceCheck API in Phase 0.5

// update-credits/index.ts:187-211
async function verifyWithApple(transactionId: string) {
  // Mock validation - always succeeds for Phase 1
  return { valid: true, product_id: 'com.rendio.credits.10' }
}
// ✅ Mock verification - real Apple API in Phase 0.5
```

**Security Risk for Local Testing:**
- ✅ **NO SECURITY RISK** - Mocks are intentional
- ✅ Safe for local testing (no real payments processed)
- ✅ Real verification will be implemented in Phase 0.5

**Confirmation:** ✅ **Safe for local testing**

---

## 2. 📦 ProductConfig - Hardcoded Explanation

### What "Hardcoded" Means:

**Hardcoded = Values written directly in code, not stored in database**

**Current Implementation (Hardcoded):**

**File:** `supabase/functions/update-credits/index.ts`  
**Lines:** 87-91

```typescript
// 2. Get product configuration (NEVER trust client - always use server-side config)
const productConfig: Record<string, number> = {
  'com.rendio.credits.10': 10,
  'com.rendio.credits.50': 50,
  'com.rendio.credits.100': 100
}
```

**What This Means:**
- ✅ Values (`10`, `50`, `100`) are directly in the code
- ✅ To change product prices, you must edit code
- ✅ Requires redeployment to update

### Future Implementation (In Database):

**Proposed Schema:**
```sql
-- New table: products
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id TEXT UNIQUE NOT NULL,        -- 'com.rendio.credits.10'
    credits INTEGER NOT NULL,               -- 10
    price_usd DECIMAL(10, 2),              -- 2.99 (for reference)
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_products_active ON products(is_active) WHERE is_active = true;

-- Example data
INSERT INTO products (product_id, credits, price_usd) VALUES
    ('com.rendio.credits.10', 10, 2.99),
    ('com.rendio.credits.50', 50, 9.99),
    ('com.rendio.credits.100', 100, 29.99);
```

**Updated Code (Future):**
```typescript
// update-credits/index.ts (Future)
const { data: product, error } = await supabaseClient
  .from('products')
  .select('credits')
  .eq('product_id', verification.product_id)
  .eq('is_active', true)
  .single()

if (error || !product) {
  return new Response({ error: 'Unknown product' }, { status: 400 })
}

const creditsToAdd = product.credits  // ← From database, not hardcoded
```

**Current Safety:**
- ✅ Server-side config (not client-provided)
- ✅ Can update via deployment
- ✅ Safe for MVP

**Confirmation:** ✅ **Safe to keep hardcoded for MVP**

---

## 3. ⚠️ get-video-status Refund Logic

### Status: MISSING - Confirmed

**Current Code:**

**File:** `supabase/functions/get-video-status/index.ts`  
**Lines:** 177-211

```typescript
// 7. Handle failed status
if (providerStatus.status === 'FAILED') {
  const { error: updateError } = await supabaseClient
    .from('video_jobs')
    .update({
      status: 'failed',
      error_message: providerStatus.error || 'Video generation failed'
    })
    .eq('job_id', job_id)

  logEvent('video_generation_failed', {
    job_id,
    provider_job_id: job.provider_job_id,
    error: providerStatus.error
  })

  // Line 199: Comment says "we could refund here if needed"
  // Note: Credits already deducted, but we could refund here if needed
  // For now, we'll handle refunds in Phase 6 (retry logic)
  // ❌ NO REFUND HAPPENS HERE

  return new Response(
    JSON.stringify({
      job_id: job.job_id,
      status: 'failed',
      error_message: providerStatus.error || 'Video generation failed'
    }),
    { headers: { 'Content-Type': 'application/json' } }
  )
}
```

**Issue:**
- ❌ Credits are **NOT refunded** when provider fails after job creation
- ❌ User loses credits if FalAI fails (but we already charged them)

**Where to Add (Phase 3):**

**Location:** `supabase/functions/get-video-status/index.ts`  
**After Line:** 197 (after `logEvent`, before `return` statement)

**Proposed Implementation:**
```typescript
// After Line 197, add:
// Check if already refunded (prevent duplicate refunds)
const { data: existingRefund } = await supabaseClient
  .from('quota_log')
  .select('id')
  .eq('user_id', job.user_id)
  .eq('job_id', job_id)
  .eq('reason', 'generation_failed_refund')
  .maybeSingle()

if (!existingRefund) {
  // Refund credits
  await supabaseClient.rpc('add_credits', {
    p_user_id: job.user_id,
    p_amount: job.credits_used,
    p_reason: 'generation_failed_refund',
    p_transaction_id: null
  })
  
  logEvent('video_generation_refunded', {
    job_id,
    user_id: job.user_id,
    credits_refunded: job.credits_used
  })
}
```

**Action Item:** 📋 **Add to Phase 3 TODO list**

---

## 4. 🔍 Refund Duplicate Control

### Current Status: NOT FULLY PROTECTED

**Analysis:**

**Current Refund Locations:**
1. `generate-video/index.ts:199` - Job creation fails
2. `generate-video/index.ts:274` - Provider API fails  
3. `get-video-status/index.ts:199` - Provider fails later (missing)

**Protection Check:**

**Stored Procedure (`add_credits`):**
```sql
-- supabase/migrations/20251105000002_create_stored_procedures.sql:80-91
-- Check for duplicate transaction (prevents double IAP credit grants)
IF p_transaction_id IS NOT NULL THEN
    SELECT EXISTS(
        SELECT 1 FROM quota_log
        WHERE transaction_id = p_transaction_id
    ) INTO existing_transaction;

    IF existing_transaction THEN
        RETURN jsonb_build_object('success', false, 'error', 'Transaction already processed');
    END IF;
END IF;
```

**Problem:**
- ✅ `add_credits()` checks `transaction_id` duplicates (for IAP)
- ❌ Refunds use `transaction_id: null` (bypasses duplicate check)
- ❌ No check if job already refunded

**Test Scenario:**
```typescript
// If get-video-status is called multiple times for same failed job:
// Call 1: Refund credits ✅
// Call 2: Refund credits again ❌ (duplicate refund - no protection!)
```

**Proposed Fix (Minimal, Production-Safe):**

**Add duplicate refund check before each refund:**

**Location 1:** `generate-video/index.ts:199` (before refund on job creation failure)
```typescript
// Before Line 199, add:
// Check if already refunded
const { data: existingRefund } = await supabaseClient
  .from('quota_log')
  .select('id')
  .eq('user_id', user_id)
  .eq('job_id', job.job_id)  // ← Use job_id if available, or check recent refunds
  .eq('reason', 'generation_failed_refund')
  .maybeSingle()

if (!existingRefund) {
  // Safe to refund
  await supabaseClient.rpc('add_credits', {
    p_user_id: user_id,
    p_amount: model.cost_per_generation,
    p_reason: 'generation_failed_refund',
    p_transaction_id: null
  })
}
```

**Location 2:** `generate-video/index.ts:274` (before refund on provider error)
```typescript
// Before Line 274, add same check:
// Check if already refunded
const { data: existingRefund } = await supabaseClient
  .from('quota_log')
  .select('id')
  .eq('user_id', user_id)
  .eq('job_id', job.job_id)
  .eq('reason', 'generation_failed_refund')
  .maybeSingle()

if (!existingRefund) {
  // Safe to refund
  await supabaseClient.rpc('add_credits', { ... })
}
```

**Location 3:** `get-video-status/index.ts:197` (after logEvent, before return)
```typescript
// After Line 197, add same check (as shown in Section 3)
```

**Confirmation:**
- ⚠️ **Current code does NOT prevent duplicate refunds**
- ✅ **Proposed fix:** Check `quota_log` for existing refund with same `job_id` and `reason`
- ✅ **Production-safe:** Minimal change, prevents duplicate refunds

**Action:** ⚠️ **Add duplicate refund check** (can be done now or Phase 3, before production)

---

## 5. 💰 Cost-per-Second Pricing

### Status: DEFERRED - Not Implemented

**Current Implementation:**
- ✅ **Static pricing:** Each model has fixed `cost_per_generation` (integer)
- ✅ **Stored in database:** `models.cost_per_generation`
- ✅ **Works correctly:** All models use static pricing

**Example:**
```sql
-- Sora 2: 4 credits per generation (regardless of duration)
INSERT INTO models (name, cost_per_generation, provider_model_id)
VALUES ('Sora 2', 4, 'fal-ai/sora-2/image-to-video');

-- Veo 3.1: 6 credits per generation (regardless of duration)  
INSERT INTO models (name, cost_per_generation, provider_model_id)
VALUES ('Veo 3.1', 6, 'fal-ai/veo3.1');
```

**How It Works:**
```typescript
// generate-video/index.ts:110
const { data: model } = await supabaseClient
  .from('models')
  .select('cost_per_generation, ...')  // ← Fetched from database
  .eq('id', model_id)
  .single()

// Line 154: Used for deduction
p_amount: model.cost_per_generation  // ← Fixed cost (not per-second)
```

**Confirmation:**
- ✅ **Static pricing works correctly** for all models
- ✅ **Cost-per-second is deferred** (future feature)
- ✅ **No changes needed** for MVP

---

## 📊 Summary Report

### ✅ **Deferred to Phase 0.5 (Security - Before Production):**

| Item | Location | Status | Risk for Local Testing |
|------|----------|--------|------------------------|
| **Apple IAP Verification** | `update-credits/index.ts:187-211` | Mocked | ✅ None (no real payments) |
| **DeviceCheck Verification** | `device-check/index.ts:61-73` | Mocked | ✅ None (local testing only) |

**Action:** Implement real Apple App Store Server API v2 and DeviceCheck API before production.

---

### ⚠️ **Deferred to Phase 3 (Refund Logic):**

| Item | Location | Status | Impact |
|------|----------|--------|--------|
| **get-video-status Refund** | `get-video-status/index.ts:177-211` | Missing | ⚠️ Users lose credits if FalAI fails after job creation |

**Action:** Add refund logic in Phase 3 when building History & User Management endpoints.

**Implementation Location:**
- File: `supabase/functions/get-video-status/index.ts`
- After Line: 197 (after logEvent, before return statement)

---

### ✅ **Safe to Keep Hardcoded (MVP):**

| Item | Location | Current Value | Justification |
|------|----------|---------------|---------------|
| **ProductConfig** | `update-credits/index.ts:87-91` | `{10: 10, 50: 50, 100: 100}` | ✅ Server-side, can update via deployment |
| **Initial Grant** | `device-check/index.ts:137` | `10` credits | ✅ Standard onboarding grant |

**Action:** Move ProductConfig to database in Phase 3 or Phase 9 (Admin Tools).

---

### ⚠️ **Needs Re-Audit Now (Refund Duplicate Control):**

| Item | Location | Status | Risk |
|------|----------|--------|------|
| **Duplicate Refund Prevention** | `generate-video/index.ts:199, 274`<br>`get-video-status/index.ts:197` | ⚠️ Not protected | Medium (automatic refunds, but could be called multiple times) |

**Current Protection:**
- ❌ No check if job already refunded
- ❌ Multiple refunds possible for same job

**Proposed Fix:**
- ✅ Check `quota_log` for existing refund before adding credits
- ✅ Add check in 3 locations (generate-video:199, 274, get-video-status:197)

**Action:** ⚠️ **Add duplicate refund check** (can be done now or Phase 3, before production)

---

## 📋 Action Plan Summary

### **Phase 0.5 (Security - Before Production):**
- [ ] Implement real Apple IAP verification (App Store Server API v2)
- [ ] Implement real DeviceCheck verification

### **Phase 3 (Refund Logic):**
- [ ] Add refund logic in `get-video-status` when provider fails
- [ ] Add duplicate refund prevention check (3 locations)

### **Phase 3 or Phase 9 (ProductConfig):**
- [ ] Create `products` table in database
- [ ] Move product config from code to database
- [ ] Update `update-credits` to query database

### **Before Production (Refund Duplicate Control):**
- [ ] Add duplicate refund check in `generate-video` (Lines 199, 274)
- [ ] Add duplicate refund check in `get-video-status` (Line 197)

---

## ✅ Final Confirmation

### **Safe for Local Testing:**
- ✅ Apple IAP verification (mocked) - **NO RISK** for local testing
- ✅ DeviceCheck verification (mocked) - **NO RISK** for local testing
- ✅ ProductConfig hardcoded - **SAFE** for MVP
- ✅ Static pricing - **WORKS CORRECTLY**

### **Needs Attention:**
- ⚠️ Missing refund in `get-video-status` - **Add in Phase 3**
- ⚠️ Duplicate refund prevention - **Add before production** (can be done now or Phase 3)

### **Ready for Testing:**
- ✅ **MVP backend is ready for local testing**
- ✅ All critical paths work correctly
- ✅ Security mocks are acceptable for local testing
- ⚠️ One refund path missing (Phase 3 fix)

---

## 🧩 File References Summary

| Item | File | Lines | Status |
|------|------|-------|--------|
| **DeviceCheck Mock** | `device-check/index.ts` | 61-73 | ✅ Safe for MVP |
| **Apple IAP Mock** | `update-credits/index.ts` | 187-211 | ✅ Safe for MVP |
| **ProductConfig** | `update-credits/index.ts` | 87-91 | ✅ Safe for MVP |
| **Missing Refund** | `get-video-status/index.ts` | 197 | ⚠️ Phase 3 |
| **Duplicate Refund Check** | `generate-video/index.ts` | 199, 274 | ⚠️ Before Production |
| **Duplicate Refund Check** | `get-video-status/index.ts` | 197 | ⚠️ Before Production |

---

**Document Status:** ✅ Complete  
**Ready for Testing:** ✅ Yes (with known limitations documented)

