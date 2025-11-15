# Credit System Architecture

## Overview

A production-grade credit system requires atomic operations, audit trails, and rollback capabilities to prevent race conditions and ensure data integrity.

---

## System Requirements

### Must-Haves
1. **Atomic operations** - No race conditions
2. **Audit trail** - Track every credit transaction
3. **Rollback capability** - Refund credits on failures
4. **Idempotency** - Prevent duplicate charges
5. **Balance verification** - Detect tampering

---

## Database Schema

### users table

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email TEXT,
    device_id TEXT,
    credits_remaining INTEGER NOT NULL DEFAULT 0,
    credits_total INTEGER NOT NULL DEFAULT 0,  -- Lifetime credits (audit)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_users_device_id ON users(device_id);
```

### quota_log table (Audit Trail)

```sql
CREATE TABLE quota_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    job_id UUID REFERENCES video_jobs(job_id) ON DELETE SET NULL,
    change INTEGER NOT NULL,  -- +10 (purchase) or -4 (generation)
    reason TEXT NOT NULL,     -- 'generation', 'purchase', 'initial_grant', 'refund'
    balance_after INTEGER NOT NULL,  -- Balance after this transaction
    transaction_id TEXT UNIQUE,  -- Apple IAP transaction ID (prevents duplicates)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_quota_log_user ON quota_log(user_id, created_at DESC);
CREATE INDEX idx_quota_log_transaction ON quota_log(transaction_id);
```

**Key Points:**
- `change`: Positive for credits added, negative for deducted
- `balance_after`: Point-in-time balance for verification
- `transaction_id`: Prevents duplicate IAP credit grants
- `job_id`: Nullable (not all transactions relate to video jobs)

---

## Stored Procedures

### Why Stored Procedures?

❌ **Bad** - Race Condition:
```typescript
// Request 1: Check balance (10 credits)
const user = await db.from('users').select('credits_remaining').eq('id', userId).single()

// Request 2: Check balance (10 credits) ← SIMULTANEOUS REQUEST
const user2 = await db.from('users').select('credits_remaining').eq('id', userId).single()

// Both see 10 credits available
if (user.credits_remaining >= 4) {
    // Request 1: Deduct 4 credits (balance becomes 6)
    await db.from('users').update({ credits_remaining: 6 }).eq('id', userId)
}

if (user2.credits_remaining >= 4) {
    // Request 2: Deduct 4 credits (balance becomes 6 again!) ❌
    await db.from('users').update({ credits_remaining: 6 }).eq('id', userId)
}

// User charged twice but only debited once!
```

✅ **Good** - Atomic Operation:
```typescript
// Both requests call stored procedure
const result = await db.rpc('deduct_credits', {
    p_user_id: userId,
    p_amount: 4
})

// Database ensures only one succeeds
// Second request sees updated balance (6 credits)
```

---

### deduct_credits() - Atomic Deduction

```sql
CREATE OR REPLACE FUNCTION deduct_credits(
    p_user_id UUID,
    p_amount INTEGER,
    p_reason TEXT DEFAULT 'video_generation',
    p_job_id UUID DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    current_credits INTEGER;
    new_balance INTEGER;
BEGIN
    -- Lock row to prevent concurrent modifications
    SELECT credits_remaining INTO current_credits
    FROM users
    WHERE id = p_user_id
    FOR UPDATE;  -- ← This is critical!

    -- User not found
    IF current_credits IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User not found'
        );
    END IF;

    -- Insufficient credits
    IF current_credits < p_amount THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Insufficient credits',
            'current_credits', current_credits,
            'required_credits', p_amount
        );
    END IF;

    -- Deduct credits
    UPDATE users
    SET credits_remaining = credits_remaining - p_amount,
        updated_at = NOW()
    WHERE id = p_user_id
    RETURNING credits_remaining INTO new_balance;

    -- Log transaction (audit trail)
    INSERT INTO quota_log (
        user_id,
        job_id,
        change,
        reason,
        balance_after
    ) VALUES (
        p_user_id,
        p_job_id,
        -p_amount,  -- Negative for deduction
        p_reason,
        new_balance
    );

    RETURN jsonb_build_object(
        'success', true,
        'credits_remaining', new_balance
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Key Mechanisms:**
1. `FOR UPDATE` - Locks the user row until transaction commits
2. Transaction scope - All operations succeed or all fail
3. `SECURITY DEFINER` - Runs with elevated permissions

---

### add_credits() - Atomic Addition

```sql
CREATE OR REPLACE FUNCTION add_credits(
    p_user_id UUID,
    p_amount INTEGER,
    p_reason TEXT,
    p_transaction_id TEXT DEFAULT NULL,
    p_job_id UUID DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    new_balance INTEGER;
    existing_transaction BOOLEAN;
BEGIN
    -- Check for duplicate transaction (IAP replay attack)
    IF p_transaction_id IS NOT NULL THEN
        SELECT EXISTS(
            SELECT 1 FROM quota_log
            WHERE transaction_id = p_transaction_id
        ) INTO existing_transaction;

        IF existing_transaction THEN
            RETURN jsonb_build_object(
                'success', false,
                'error', 'Transaction already processed',
                'transaction_id', p_transaction_id
            );
        END IF;
    END IF;

    -- Add credits
    UPDATE users
    SET credits_remaining = credits_remaining + p_amount,
        credits_total = credits_total + p_amount,  -- Lifetime total
        updated_at = NOW()
    WHERE id = p_user_id
    RETURNING credits_remaining INTO new_balance;

    -- Log transaction
    INSERT INTO quota_log (
        user_id,
        job_id,
        change,
        reason,
        balance_after,
        transaction_id
    ) VALUES (
        p_user_id,
        p_job_id,
        p_amount,  -- Positive for addition
        p_reason,
        new_balance,
        p_transaction_id
    );

    RETURN jsonb_build_object(
        'success', true,
        'credits_added', p_amount,
        'credits_remaining', new_balance
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Duplicate Transaction Prevention:**
- `transaction_id` UNIQUE constraint in `quota_log`
- Check before processing prevents double credit grant
- Critical for In-App Purchases

---

## Edge Function Integration

### /generate-video endpoint

```typescript
// generate-video/index.ts

import { createClient } from '@supabase/supabase-js'

Deno.serve(async (req) => {
    const supabase = createClient(
        Deno.env.get('SUPABASE_URL')!,
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const { user_id, model_id, prompt, settings } = await req.json()

    // 1. Get model cost (NEVER trust client)
    const { data: model } = await supabase
        .from('models')
        .select('cost_per_generation')
        .eq('id', model_id)
        .single()

    const cost = model.cost_per_generation

    // 2. Deduct credits atomically
    const { data: deductResult } = await supabase.rpc('deduct_credits', {
        p_user_id: user_id,
        p_amount: cost,
        p_reason: 'video_generation'
    })

    if (!deductResult.success) {
        return new Response(
            JSON.stringify({ error: deductResult.error }),
            { status: 402 }  // Payment Required
        )
    }

    // 3. Create video job
    const { data: job, error: jobError } = await supabase
        .from('video_jobs')
        .insert({
            user_id,
            model_id,
            prompt,
            settings,
            status: 'pending',
            credits_used: cost
        })
        .select()
        .single()

    if (jobError) {
        // ROLLBACK: Refund credits
        await supabase.rpc('add_credits', {
            p_user_id: user_id,
            p_amount: cost,
            p_reason: 'generation_failed_refund'
        })

        throw new Error('Failed to create job')
    }

    // 4. Call video provider (FalAI, etc.)
    try {
        const providerResult = await callVideoProvider(prompt, settings)

        // Update job with provider ID
        await supabase
            .from('video_jobs')
            .update({ provider_job_id: providerResult.job_id })
            .eq('job_id', job.job_id)

    } catch (providerError) {
        // ROLLBACK: Mark job failed and refund credits
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
            p_reason: 'generation_failed_refund',
            p_job_id: job.job_id
        })

        throw providerError
    }

    // Success
    return new Response(
        JSON.stringify({
            job_id: job.job_id,
            status: 'pending',
            credits_used: cost,
            credits_remaining: deductResult.credits_remaining
        }),
        { status: 200 }
    )
})
```

**Rollback Points:**
1. Job creation fails → refund
2. Provider API fails → refund + mark job failed
3. Provider timeout → refund + mark job failed

---

## iOS Integration

### CreditService

```swift
// Core/Networking/CreditService.swift

protocol CreditServiceProtocol {
    func getCredits() async throws -> Int
    func refreshCredits() async throws -> Int
}

class CreditService: CreditServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func getCredits() async throws -> Int {
        struct Response: Codable {
            let creditsRemaining: Int

            enum CodingKeys: String, CodingKey {
                case creditsRemaining = "credits_remaining"
            }
        }

        let response: Response = try await apiClient.request(
            endpoint: "get-user-credits",
            method: .GET
        )

        return response.creditsRemaining
    }

    func refreshCredits() async throws -> Int {
        // Re-fetch from backend (don't trust local state)
        return try await getCredits()
    }
}
```

### Real-time Credit Updates (Supabase Realtime)

```swift
// Core/Services/CreditMonitorService.swift

import Supabase

class CreditMonitorService: ObservableObject {
    @Published var currentCredits: Int = 0

    private let supabase = SupabaseClient(...)
    private var subscription: RealtimeChannel?

    func startMonitoring(userId: String) {
        subscription = supabase
            .channel("credits:\(userId)")
            .on(
                .postgresChanges,
                filter: "user_id=eq.\(userId)",
                table: "users"
            ) { [weak self] payload in
                if let credits = payload.new?["credits_remaining"] as? Int {
                    DispatchQueue.main.async {
                        self?.currentCredits = credits
                    }
                }
            }
            .subscribe()
    }

    func stopMonitoring() {
        subscription?.unsubscribe()
    }
}
```

---

## In-App Purchase Integration

### Apple IAP Flow with Credits

```swift
// Core/Services/StoreKitManager.swift

import StoreKit

class StoreKitManager: ObservableObject {
    func purchase(productId: String) async throws -> Int {
        // 1. Purchase from Apple
        let product = try await Product.products(for: [productId]).first!
        let result = try await product.purchase()

        guard case .success(let verification) = result else {
            throw AppError.purchaseFailed
        }

        let transaction = try verification.payloadValue

        // 2. Verify with backend and grant credits
        let credits = try await verifyAndGrantCredits(transaction: transaction)

        // 3. Finish transaction
        await transaction.finish()

        return credits
    }

    private func verifyAndGrantCredits(transaction: Transaction) async throws -> Int {
        struct Request: Codable {
            let transactionId: String
            let productId: String
            let receipt: String

            enum CodingKeys: String, CodingKey {
                case transactionId = "transaction_id"
                case productId = "product_id"
                case receipt
            }
        }

        struct Response: Codable {
            let creditsAdded: Int
            let creditsRemaining: Int

            enum CodingKeys: String, CodingKey {
                case creditsAdded = "credits_added"
                case creditsRemaining = "credits_remaining"
            }
        }

        let request = Request(
            transactionId: String(transaction.id),
            productId: transaction.productID,
            receipt: transaction.jsonRepresentation.base64EncodedString()
        )

        let response: Response = try await APIClient.shared.request(
            endpoint: "update-credits",
            method: .POST,
            body: request
        )

        return response.creditsRemaining
    }
}
```

### Backend IAP Verification

```typescript
// update-credits/index.ts

import { createClient } from '@supabase/supabase-js'

Deno.serve(async (req) => {
    const supabase = createClient(...)
    const { transaction_id, product_id, receipt } = await req.json()

    // 1. Verify with Apple
    const isValid = await verifyAppleReceipt(receipt)
    if (!isValid) {
        return new Response(
            JSON.stringify({ error: 'Invalid receipt' }),
            { status: 400 }
        )
    }

    // 2. Determine credit amount from product ID
    const creditMap = {
        'com.rendio.credits.10': 10,
        'com.rendio.credits.25': 25,
        'com.rendio.credits.50': 50,
        'com.rendio.credits.100': 100,
        'com.rendio.credits.250': 250,
    }

    const credits = creditMap[product_id]
    if (!credits) {
        return new Response(
            JSON.stringify({ error: 'Unknown product' }),
            { status: 400 }
        )
    }

    // 3. Grant credits (atomic + duplicate prevention)
    const { data: result } = await supabase.rpc('add_credits', {
        p_user_id: user_id,
        p_amount: credits,
        p_reason: 'iap_purchase',
        p_transaction_id: transaction_id  // Prevents duplicates
    })

    if (!result.success) {
        if (result.error.includes('already processed')) {
            // Transaction already processed, return cached result
            return new Response(
                JSON.stringify({
                    credits_added: 0,
                    credits_remaining: result.credits_remaining,
                    message: 'Transaction already processed'
                }),
                { status: 200 }
            )
        }

        return new Response(
            JSON.stringify({ error: result.error }),
            { status: 500 }
        )
    }

    return new Response(
        JSON.stringify({
            credits_added: credits,
            credits_remaining: result.credits_remaining
        }),
        { status: 200 }
    )
})
```

---

## Monitoring & Analytics

### Quota Log Queries

```sql
-- User's credit history
SELECT
    created_at,
    change,
    reason,
    balance_after,
    transaction_id
FROM quota_log
WHERE user_id = 'user-uuid'
ORDER BY created_at DESC
LIMIT 50;

-- Total credits granted vs. spent
SELECT
    SUM(CASE WHEN change > 0 THEN change ELSE 0 END) as total_granted,
    SUM(CASE WHEN change < 0 THEN ABS(change) ELSE 0 END) as total_spent
FROM quota_log
WHERE user_id = 'user-uuid';

-- Detect balance tampering
SELECT
    user_id,
    credits_remaining,
    (
        SELECT COALESCE(SUM(change), 0)
        FROM quota_log
        WHERE quota_log.user_id = users.id
    ) as expected_balance
FROM users
WHERE credits_remaining != (
    SELECT COALESCE(SUM(change), 0)
    FROM quota_log
    WHERE quota_log.user_id = users.id
);
```

---

## Best Practices

### ✅ Do This

1. **Always use stored procedures for credit operations**
2. **Lock rows with `FOR UPDATE`**
3. **Log every transaction in quota_log**
4. **Store transaction IDs for IAP**
5. **Refund credits on operation failure**
6. **Never trust client-side balance**
7. **Verify receipts on backend**

### ❌ Don't Do This

1. **Don't check balance and update in separate queries**
2. **Don't trust cost values from client**
3. **Don't skip audit logging**
4. **Don't process duplicate transaction IDs**
5. **Don't forget to rollback on failures**

---

## Summary

| Component | Purpose |
|-----------|---------|
| **Stored Procedures** | Atomic, race-condition-free operations |
| **quota_log** | Complete audit trail |
| **transaction_id** | Prevent duplicate IAP charges |
| **balance_after** | Detect tampering |
| **Rollback logic** | Refund on failures |

**Next:** [Idempotency →](07-Idempotency.md)
