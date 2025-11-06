# 🏗️ Backend Building Plan - Rendio AI (Complete Edition)

**Version:** 3.0 - MVP + Production Features Edition
**Date:** 2025-11-05
**Status:** Comprehensive implementation plan with all production features
**Purpose:** Complete backend plan from MVP (Phases 0-4) to Production Features (Phases 5-9)
**Scope:**
- **Phases 0-4:** Smart MVP with security essentials (16-20 days)
- **Phases 5-9:** Production features - webhooks, retry logic, error i18n, rate limiting, admin tools (12-16 days)
- **Total:** 28-36 days for production-ready backend

---

## 📋 Table of Contents

1. [Understanding Your Backend Architecture](#understanding-your-backend-architecture)
2. [System Workflows](#system-workflows)
3. [Backend Building Plan](#backend-building-plan)
4. [Implementation Phases](#implementation-phases)
   - [Phase 0: Setup & Infrastructure](#phase-0-setup--infrastructure-2-3-days)
   - [Phase 0.5: Security Essentials](#phase-05-security-essentials-2-days-)
   - [Phase 1: Core Database & API Setup](#phase-1-core-database--api-setup-3-4-days)
   - [Phase 2: Video Generation API](#phase-2-video-generation-api-4-5-days)
   - [Phase 3: History & User Management](#phase-3-history--user-management-2-days)
   - [Phase 4: Integration & Testing](#phase-4-integration--testing-3-4-days)
   - [Phase 5: Webhook System (Replace Polling)](#phase-5-webhook-system-replace-polling-3-4-days-)
   - [Phase 6: Retry Logic for External APIs](#phase-6-retry-logic-for-external-apis-2-3-days-)
   - [Phase 7: Error Handling with i18n](#phase-7-error-handling-with-i18n-2-3-days-)
   - [Phase 8: IP-Based Rate Limiting](#phase-8-ip-based-rate-limiting-2-days-)
   - [Phase 9: Admin Tools](#phase-9-admin-tools-3-4-days-)
5. [Implementation Timeline](#-implementation-timeline-smart-mvp--production-features)
6. [Known Limitations (MVP Trade-offs)](#known-limitations-mvp-trade-offs)
7. [Production Readiness Checklist](#production-readiness-checklist)

---

## 🎯 Understanding Your Backend Architecture

### The Big Picture

Your app has **3 layers**:

```
┌─────────────────────────────────────────┐
│   iOS App (SwiftUI) - Frontend          │  ← You have this ✅
│   (Views, ViewModels, Services)         │
└──────────────┬──────────────────────────┘
               │ HTTP Requests
               ▼
┌─────────────────────────────────────────┐
│   Supabase Backend                      │  ← You need to build this ⚠️
│   ┌─────────────────────────────────┐   │
│   │  Edge Functions (API Layer)     │   │  ← API endpoints
│   │  - generate-video               │   │
│   │  - get-video-status             │   │
│   │  - get-video-jobs               │   │
│   │  - update-credits               │   │
│   │  - device/check                 │   │
│   └───────────┬─────────────────────┘   │
│               │                          │
│   ┌───────────▼─────────────────────┐   │
│   │  Database (PostgreSQL)          │   │  ← Data storage
│   │  - users                        │   │
│   │  - video_jobs                   │   │
│   │  - models                       │   │
│   │  - quota_log                    │   │
│   │  - idempotency_log              │   │  ← NEW: Prevent duplicates
│   └───────────┬─────────────────────┘   │
│               │                          │
│   ┌───────────▼─────────────────────┐   │
│   │  Storage (Supabase Storage)     │   │  ← Video files
│   │  - Generated videos             │   │
│   │  - Thumbnails                   │   │
│   └─────────────────────────────────┘   │
└──────────────┬──────────────────────────┘
               │ API Calls
               ▼
┌─────────────────────────────────────────┐
│   External AI Providers                 │  ← You connect to these
│   - FalAI (Veo 3.1, Sora 2)            │
│   - Runway (future)                     │
│   - Pika (future)                       │
└─────────────────────────────────────────┘
```

### Key Components

1. **Database (Supabase PostgreSQL)**
   - Stores: Users, video jobs, models, credit transactions
   - Security: Row-Level Security (RLS) policies
   - **NEW:** Atomic operations via stored procedures
   - Location: Supabase Cloud (or self-hosted)

2. **API Layer (Supabase Edge Functions)**
   - TypeScript/Deno functions that handle business logic
   - Act as bridge between iOS app and database/providers
   - Handle authentication, credit deduction, video generation
   - **NEW:** Idempotency protection, rollback on failure

3. **Storage (Supabase Storage)**
   - Stores generated video files
   - Stores thumbnails
   - Secure, per-user access

4. **External AI Providers**
   - FalAI, Runway, Pika (video generation APIs)
   - Your backend calls these and returns results to iOS app

---

## 🔄 System Workflows

### Workflow 1: New User Onboarding (Guest)

```
┌─────────┐         ┌──────────┐         ┌──────────┐         ┌──────────┐
│ iOS App │         │ DeviceCheck│       │ Supabase │         │ Database │
│         │         │ (Apple)   │         │ Edge Fn  │         │          │
└────┬────┘         └────┬──────┘         └────┬─────┘         └────┬─────┘
     │                   │                      │                    │
     │ 1. Generate       │                      │                    │
     │    device_id      │                      │                    │
     ├──────────────────►│                      │                    │
     │                   │                      │                    │
     │ 2. Request        │                      │                    │
     │    DeviceCheck    │                      │                    │
     │    token          │                      │                    │
     ├──────────────────►│                      │                    │
     │                   │                      │                    │
     │ 3. Return token   │                      │                    │
     │◄──────────────────┤                      │                    │
     │                   │                      │                    │
     │ 4. POST /device/check                    │                    │
     │    {device_id, token}                    │                    │
     ├─────────────────────────────────────────►│                    │
     │                   │                      │                    │
     │                   │                      │ 5. Verify token    │
     │                   │                      ├───────────────────►│
     │                   │                      │                    │
     │                   │                      │ 6. Check if user   │
     │                   │                      │    exists          │
     │                   │                      ├───────────────────►│
     │                   │                      │                    │
     │                   │                      │ 7. Create new user │
     │                   │                      │    OR return       │
     │                   │                      │    existing user   │
     │                   │                      ├───────────────────►│
     │                   │                      │                    │
     │                   │                      │ 8. Grant 10 credits│
     │                   │                      │    (if new user)   │
     │                   │                      ├───────────────────►│
     │                   │                      │                    │
     │ 9. Response:                              │                    │
     │    {user_id, credits_remaining: 10}      │                    │
     │◄─────────────────────────────────────────┤                    │
     │                   │                      │                    │
```

**What happens:**
1. iOS generates a unique `device_id` (UUID)
2. iOS requests Apple DeviceCheck token
3. iOS sends both to `/device/check` endpoint
4. Backend verifies token with Apple
5. Backend checks if user exists (by device_id)
6. If new: Creates user in database, grants 10 credits
7. If existing: Returns existing user data
8. iOS receives user_id and credits

---

### Workflow 2: Video Generation (With Idempotency)

```
┌─────────┐         ┌──────────┐         ┌──────────┐         ┌──────────┐
│ iOS App │         │ Supabase │         │ Database │         │ FalAI    │
│         │         │ Edge Fn  │         │          │         │          │
└────┬────┘         └────┬─────┘         └────┬─────┘         └────┬─────┘
     │                   │                     │                    │
     │ 1. User taps      │                     │                    │
     │    "Generate"     │                     │                    │
     │    Generate UUID  │                     │                    │
     │    (idempotency)  │                     │                    │
     │                   │                     │                    │
     │ 2. POST /generate-video                 │                    │
     │    Header: Idempotency-Key: <uuid>      │                    │
     │    {user_id, model_id, prompt}          │                    │
     ├──────────────────►│                     │                    │
     │                   │                     │                    │
     │                   │ 3. Check idempotency│                    │
     │                   │    (duplicate?)     │                    │
     │                   ├────────────────────►│                    │
     │                   │                     │                    │
     │                   │◄────────────────────┤                    │
     │                   │    {new: true}      │                    │
     │                   │                     │                    │
     │                   │ 4. Fetch model      │                    │
     │                   │    cost & provider  │                    │
     │                   ├────────────────────►│                    │
     │                   │                     │                    │
     │                   │◄────────────────────┤                    │
     │                   │    {cost: 4,        │                    │
     │                   │     provider: "fal"}│                    │
     │                   │                     │                    │
     │                   │ 5. Deduct credits   │                    │
     │                   │    (stored proc)    │                    │
     │                   ├────────────────────►│                    │
     │                   │                     │                    │
     │                   │◄────────────────────┤                    │
     │                   │    {success: true,  │                    │
     │                   │     remaining: 6}   │                    │
     │                   │                     │                    │
     │                   │ 6. Create video_job │                    │
     │                   │    (status: pending)│                    │
     │                   ├────────────────────►│                    │
     │                   │                     │                    │
     │                   │◄────────────────────┤                    │
     │                   │    {job_id: "..."}  │                    │
     │                   │                     │                    │
     │                   │ 7. Store idempotency│                    │
     │                   │    (prevent retry)  │                    │
     │                   ├────────────────────►│                    │
     │                   │                     │                    │
     │                   │ 8. Call FalAI API   │                    │
     │                   ├─────────────────────────────────────────►│
     │                   │                     │                    │
     │                   │                     │ 9. Process video   │
     │                   │                     │    generation      │
     │                   │                     │                    │
     │                   │◄─────────────────────────────────────────┤
     │                   │    {provider_job_id: "fal-123"}         │
     │                   │                     │                    │
     │                   │ 10. Update job with │                    │
     │                   │     provider_job_id │                    │
     │                   ├────────────────────►│                    │
     │                   │                     │                    │
     │ 11. Response:     │                     │                    │
     │     {job_id, status: "pending"}         │                    │
     │◄──────────────────┤                     │                    │
     │                   │                     │                    │
     │ 12. Poll /get-video-status              │                    │
     │     (every 2-4 seconds)                 │                    │
     │     ├──────────────────────────────────►│                    │
     │     │                                   │                    │
     │     │ 13. Check job status              │                    │
     │     │     ├────────────────────────────►│                    │
     │     │     │                             │                    │
     │     │     │ 14. Check FalAI status      │                    │
     │     │     │     ├───────────────────────────────────────────►│
     │     │     │     │                       │                    │
     │     │     │     │◄───────────────────────────────────────────┤
     │     │     │     │     {status: "completed", video_url: "..."}│
     │     │     │     │                       │                    │
     │     │     │ 15. Update video_job        │                    │
     │     │     │     ├──────────────────────►│                    │
     │     │     │     │                       │                    │
     │     │◄────┘     │                       │                    │
     │     │           │                       │                    │
     │◄────┘           │                       │                    │
     │     {status: "completed", video_url}    │                    │
     │                   │                     │                    │
     │ 16. Navigate to ResultView              │                    │
     │                   │                     │                    │
```

**What happens:**
1. User taps "Generate" in iOS app
2. iOS generates unique idempotency key (UUID)
3. iOS sends request with idempotency key in header
4. Backend checks if this key was already processed (prevents double-charge if retry)
5. Backend fetches model cost (e.g., 4 credits)
6. Backend deducts credits using atomic stored procedure
7. Backend creates `video_job` record (status: "pending")
8. Backend stores idempotency key (prevents future duplicates)
9. Backend calls FalAI API to start generation
10. FalAI returns provider_job_id
11. Backend updates job with provider_job_id
12. Backend returns job_id to iOS
13. iOS polls `/get-video-status` every 2-4 seconds
14. Backend checks database for job status
15. Backend checks FalAI for completion
16. Backend updates database when video is ready
17. iOS receives completion and shows video

**Key Improvement:** If user's network drops and iOS retries, the idempotency key prevents double-charging.

---

### Workflow 3: Credit Purchase (Apple IAP)

```
┌─────────┐         ┌──────────┐         ┌──────────┐         ┌──────────┐
│ iOS App │         │ Apple    │         │ Supabase │         │ Database │
│         │         │ StoreKit │         │ Edge Fn  │         │          │
└────┬────┘         └────┬─────┘         └────┬─────┘         └────┬─────┘
     │                   │                     │                    │
     │ 1. User taps      │                     │                    │
     │    "Buy Credits"  │                     │                    │
     │                   │                     │                    │
     │ 2. Request        │                     │                    │
     │    purchase       │                     │                    │
     ├──────────────────►│                     │                    │
     │                   │                     │                    │
     │                   │ 3. Process payment  │                    │
     │                   │                     │                    │
     │                   │◄────────────────────┤                    │
     │ 4. Purchase       │                     │                    │
     │    completed      │                     │                    │
     │◄──────────────────┤                     │                    │
     │                   │                     │                    │
     │ 5. POST /update-credits                 │                    │
     │    {user_id, transaction_id: "abc123"}  │                    │
     ├─────────────────────────────────────────►│                    │
     │                   │                     │                    │
     │                   │ 6. Verify with Apple│                    │
     │                   │    (NEW API method) │                    │
     │                   ├────────────────────►│                    │
     │                   │                     │                    │
     │                   │◄────────────────────┤                    │
     │                   │    {valid: true,    │                    │
     │                   │     product: "10"}  │                    │
     │                   │                     │                    │
     │                   │ 7. Check duplicate  │                    │
     │                   │    transaction      │                    │
     │                   ├────────────────────►│                    │
     │                   │                     │                    │
     │                   │◄────────────────────┤                    │
     │                   │    {not_used: true} │                    │
     │                   │                     │                    │
     │                   │ 8. Add credits      │                    │
     │                   │    (stored proc)    │                    │
     │                   ├────────────────────►│                    │
     │                   │                     │                    │
     │ 9. Response:                              │                    │
     │    {credits_remaining: 16}               │                    │
     │◄─────────────────────────────────────────┤                    │
     │                   │                     │                    │
     │ 10. Update UI     │                     │                    │
     │                   │                     │                    │
```

**What happens:**
1. User taps "Buy Credits" in iOS
2. iOS requests purchase from Apple StoreKit
3. Apple processes payment
4. iOS receives purchase confirmation with transaction_id
5. iOS sends transaction to `/update-credits`
6. Backend verifies with Apple's NEW App Store Server API (not deprecated verifyReceipt)
7. Backend checks transaction not already processed
8. Backend adds credits using atomic stored procedure
9. Backend logs transaction in `quota_log` table
10. iOS receives updated credit balance
11. iOS updates UI to show new credits

**Key Improvement:** Uses modern Apple API and prevents duplicate credit grants if user tries to reuse transaction_id.

---

### Workflow 4: User Signs In with Apple

```
┌─────────┐         ┌──────────┐         ┌──────────┐         ┌──────────┐
│ iOS App │         │ Apple    │         │ Supabase │         │ Database │
│         │         │ Sign In  │         │ Auth     │         │          │
└────┬────┘         └────┬─────┘         └────┬─────┘         └────┬─────┘
     │                   │                     │                    │
     │ 1. User taps      │                     │                    │
     │    "Sign In"      │                     │                    │
     │                   │                     │                    │
     │ 2. Request        │                     │                    │
     │    Apple Sign In  │                     │                    │
     ├──────────────────►│                     │                    │
     │                   │                     │                    │
     │                   │ 3. User authenticates│                    │
     │                   │                     │                    │
     │                   │◄────────────────────┤                    │
     │ 4. Receive ID     │                     │                    │
     │    token          │                     │                    │
     │◄──────────────────┤                     │                    │
     │                   │                     │                    │
     │ 5. Send token to  │                     │                    │
     │    Supabase Auth  │                     │                    │
     ├─────────────────────────────────────────►│                    │
     │                   │                     │                    │
     │                   │ 6. Verify token     │                    │
     │                   │    with Apple       │                    │
     │                   ├────────────────────►│                    │
     │                   │                     │                    │
     │                   │◄────────────────────┤                    │
     │                   │    {verified: true} │                    │
     │                   │                     │                    │
     │                   │ 7. Check if user    │                    │
     │                   │    exists           │                    │
     │                   ├────────────────────►│                    │
     │                   │                     │                    │
     │                   │◄────────────────────┤                    │
     │                   │    {exists: false}  │                    │
     │                   │                     │                    │
     │                   │ 8. Merge guest      │                    │
     │                   │    account (if any) │                    │
     │                   ├────────────────────►│                    │
     │                   │                     │                    │
     │                   │ 9. Create user OR   │                    │
     │                   │    return existing  │                    │
     │                   ├────────────────────►│                    │
     │                   │                     │                    │
     │ 10. Receive session token               │                    │
     │◄─────────────────────────────────────────┤                    │
     │                   │                     │                    │
     │ 11. Store session │                     │                    │
     │     (in Keychain) │                     │                    │
     │                   │                     │                    │
```

**What happens:**
1. User taps "Sign In with Apple"
2. iOS requests Apple Sign In
3. Apple authenticates user
4. iOS receives ID token
5. iOS sends token to Supabase Auth
6. Supabase verifies token with Apple
7. Supabase checks if user exists (by apple_sub)
8. If guest account exists: Merge credits and history
9. Create new user OR return existing user
10. iOS receives session token
11. iOS stores token securely (Keychain)

---

## 🏗️ Backend Building Plan

### Phase 0: Setup & Infrastructure (2-3 days)

**Goal:** Set up Supabase project and production-ready database schema

#### Tasks:

1. **Create Supabase Project**
   - Go to supabase.com
   - Create new project
   - Note down: Project URL, Anon Key, Service Role Key

2. **Set Up Database Schema** (UPDATED with production fields)
   
   Create migration file: `supabase/migrations/001_create_tables.sql`
   
   ```sql
   -- ==========================================
   -- TABLE: users
   -- ==========================================
   CREATE TABLE IF NOT EXISTS public.users (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       email TEXT,
       device_id TEXT UNIQUE,
       apple_sub TEXT UNIQUE,
       is_guest BOOLEAN DEFAULT true,
       tier TEXT DEFAULT 'free' CHECK (tier IN ('free', 'premium')),
       credits_remaining INTEGER DEFAULT 0,
       credits_total INTEGER DEFAULT 0,
       initial_grant_claimed BOOLEAN DEFAULT false,
       language TEXT DEFAULT 'en',
       theme_preference TEXT DEFAULT 'system',
       created_at TIMESTAMPTZ DEFAULT now(),
       updated_at TIMESTAMPTZ DEFAULT now(),
       
       CONSTRAINT users_identity_check CHECK (
           (email IS NOT NULL) OR (device_id IS NOT NULL)
       )
   );

   CREATE INDEX idx_users_device_id ON users(device_id);
   CREATE INDEX idx_users_apple_sub ON users(apple_sub);

   -- ==========================================
   -- TABLE: models
   -- ==========================================
   CREATE TABLE IF NOT EXISTS public.models (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       name TEXT NOT NULL,
       category TEXT NOT NULL,
       description TEXT,
       cost_per_generation INTEGER NOT NULL DEFAULT 4,
       provider TEXT NOT NULL,
       provider_model_id TEXT, -- NEW: e.g., "fal-ai/veo3.1"
       is_featured BOOLEAN DEFAULT false,
       is_available BOOLEAN DEFAULT true,
       thumbnail_url TEXT,
       created_at TIMESTAMPTZ DEFAULT now()
   );

   CREATE INDEX idx_models_provider ON models(provider);
   CREATE INDEX idx_models_featured ON models(is_featured) WHERE is_featured = true;

   -- ==========================================
   -- TABLE: video_jobs
   -- ==========================================
   CREATE TABLE IF NOT EXISTS public.video_jobs (
       job_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
       model_id UUID NOT NULL REFERENCES models(id),
       prompt TEXT NOT NULL,
       settings JSONB DEFAULT '{}',
       status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
       video_url TEXT,
       thumbnail_url TEXT,
       credits_used INTEGER NOT NULL,
       error_message TEXT,
       provider_job_id TEXT, -- NEW: Track provider's job ID
       created_at TIMESTAMPTZ DEFAULT now(),
       completed_at TIMESTAMPTZ
   );

   CREATE INDEX idx_video_jobs_user ON video_jobs(user_id, created_at DESC);
   CREATE INDEX idx_video_jobs_status ON video_jobs(status);
   CREATE INDEX idx_video_jobs_provider ON video_jobs(provider_job_id);

   -- ==========================================
   -- TABLE: quota_log (Credit transactions)
   -- ==========================================
   CREATE TABLE IF NOT EXISTS public.quota_log (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
       job_id UUID REFERENCES video_jobs(job_id) ON DELETE SET NULL,
       change INTEGER NOT NULL,
       reason TEXT NOT NULL,
       transaction_id TEXT UNIQUE, -- For IAP purchases
       balance_after INTEGER, -- NEW: Credit balance after transaction
       created_at TIMESTAMPTZ DEFAULT now()
   );

   CREATE INDEX idx_quota_log_user ON quota_log(user_id, created_at DESC);
   CREATE INDEX idx_quota_log_transaction ON quota_log(transaction_id);

   -- ==========================================
   -- TABLE: idempotency_log (Prevent duplicates)
   -- ==========================================
   CREATE TABLE IF NOT EXISTS public.idempotency_log (
       idempotency_key UUID PRIMARY KEY,
       user_id UUID REFERENCES users(id) ON DELETE CASCADE,
       job_id UUID REFERENCES video_jobs(job_id) ON DELETE SET NULL,
       operation_type TEXT NOT NULL,
       response_data JSONB,
       status_code INTEGER,
       created_at TIMESTAMPTZ DEFAULT now(),
       expires_at TIMESTAMPTZ DEFAULT now() + INTERVAL '24 hours'
   );

   CREATE INDEX idx_idempotency_user ON idempotency_log(user_id, created_at);
   CREATE INDEX idx_idempotency_expires ON idempotency_log(expires_at);
   ```

3. **Create Atomic Stored Procedures** (Prevent race conditions)
   
   Add to same migration file:
   
   ```sql
   -- ==========================================
   -- STORED PROCEDURE: Deduct Credits Atomically
   -- ==========================================
   CREATE OR REPLACE FUNCTION deduct_credits(
       p_user_id UUID,
       p_amount INTEGER,
       p_reason TEXT DEFAULT 'video_generation'
   ) RETURNS JSONB AS $$
   DECLARE
       current_credits INTEGER;
       new_balance INTEGER;
   BEGIN
       -- Lock row to prevent race conditions
       SELECT credits_remaining INTO current_credits
       FROM users
       WHERE id = p_user_id
       FOR UPDATE;
       
       IF current_credits IS NULL THEN
           RETURN jsonb_build_object(
               'success', false,
               'error', 'User not found'
           );
       END IF;
       
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
           updated_at = now()
       WHERE id = p_user_id
       RETURNING credits_remaining INTO new_balance;
       
       -- Log transaction
       INSERT INTO quota_log (user_id, change, reason, balance_after)
       VALUES (p_user_id, -p_amount, p_reason, new_balance);
       
       RETURN jsonb_build_object(
           'success', true,
           'credits_remaining', new_balance
       );
   END;
   $$ LANGUAGE plpgsql SECURITY DEFINER;

   -- ==========================================
   -- STORED PROCEDURE: Add Credits Atomically
   -- ==========================================
   CREATE OR REPLACE FUNCTION add_credits(
       p_user_id UUID,
       p_amount INTEGER,
       p_reason TEXT,
       p_transaction_id TEXT DEFAULT NULL
   ) RETURNS JSONB AS $$
   DECLARE
       new_balance INTEGER;
       existing_transaction BOOLEAN;
   BEGIN
       -- Check for duplicate transaction
       IF p_transaction_id IS NOT NULL THEN
           SELECT EXISTS(
               SELECT 1 FROM quota_log 
               WHERE transaction_id = p_transaction_id
           ) INTO existing_transaction;
           
           IF existing_transaction THEN
               RETURN jsonb_build_object(
                   'success', false,
                   'error', 'Transaction already processed'
               );
           END IF;
       END IF;
       
       -- Add credits
       UPDATE users
       SET credits_remaining = credits_remaining + p_amount,
           credits_total = credits_total + p_amount,
           updated_at = now()
       WHERE id = p_user_id
       RETURNING credits_remaining INTO new_balance;
       
       -- Log transaction
       INSERT INTO quota_log (
           user_id, 
           change, 
           reason, 
           balance_after,
           transaction_id
       ) VALUES (
           p_user_id, 
           p_amount, 
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

4. **Enable Row-Level Security (RLS)**
   
   Add to migration file:
   
   ```sql
   -- ==========================================
   -- RLS POLICIES
   -- ==========================================
   
   -- Users table
   ALTER TABLE users ENABLE ROW LEVEL SECURITY;
   
   CREATE POLICY "Users can view own profile"
   ON users FOR SELECT
   USING (auth.uid() = id);
   
   CREATE POLICY "Users can update own profile"
   ON users FOR UPDATE
   USING (auth.uid() = id);
   
   -- Video jobs table
   ALTER TABLE video_jobs ENABLE ROW LEVEL SECURITY;
   
   CREATE POLICY "Users can view own jobs"
   ON video_jobs FOR SELECT
   USING (auth.uid() = user_id);
   
   CREATE POLICY "Users can insert own jobs"
   ON video_jobs FOR INSERT
   WITH CHECK (auth.uid() = user_id);
   
   -- Quota log table
   ALTER TABLE quota_log ENABLE ROW LEVEL SECURITY;
   
   CREATE POLICY "Users can view own transactions"
   ON quota_log FOR SELECT
   USING (auth.uid() = user_id);
   
   -- Models table (public read-only)
   ALTER TABLE models ENABLE ROW LEVEL SECURITY;
   
   CREATE POLICY "Anyone can view available models"
   ON models FOR SELECT
   USING (is_available = true);
   ```

5. **Set Up Storage Buckets**
   - Create bucket: `videos` (public, but with RLS)
   - Create bucket: `thumbnails` (public, but with RLS)
   - Set up storage policies

6. **Configure Authentication**
   - Enable Apple Sign-In provider
   - Configure redirect URLs
   - Set up DeviceCheck verification

7. **Environment Variables Documentation**
   
   Create `.env.example`:
   
   ```bash
   # Supabase
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
   
   # External AI Providers
   FALAI_API_KEY=your-falai-key
   RUNWAY_API_KEY=your-runway-key (future)
   PIKA_API_KEY=your-pika-key (future)
   
   # Apple IAP & DeviceCheck
   APPLE_BUNDLE_ID=com.yourdomain.rendio
   APPLE_TEAM_ID=YOUR_TEAM_ID
   APPLE_KEY_ID=YOUR_KEY_ID
   APPLE_ISSUER_ID=YOUR_ISSUER_ID
   APPLE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
   APPLE_DEVICECHECK_KEY_ID=YOUR_DEVICECHECK_KEY_ID
   APPLE_DEVICECHECK_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
   
   # Environment
   ENVIRONMENT=production # or development, staging
   ```

#### Deliverables:
- ✅ Supabase project created
- ✅ Database tables created with RLS
- ✅ Stored procedures created (atomic operations)
- ✅ Idempotency table created
- ✅ Storage buckets configured
- ✅ Authentication providers configured
- ✅ Environment variables documented

---

### Phase 0.5: Security Essentials (2 days) 🔐

**Goal:** Implement production-grade security before building features

**Why This Phase?** The original plan had placeholder code for Apple IAP and DeviceCheck verification. This phase replaces "TODO" comments with real security implementations to prevent:
- Fake credit purchases (revenue loss)
- Unlimited guest account creation (credit farming)
- Users locked out after token expiration

#### Tasks:

1. **Implement Real Apple IAP Verification**
   
   Replace the mock verification with App Store Server API v2:
   
   File: `supabase/functions/_shared/apple-iap.ts`
   
   ```typescript
   import * as jose from 'https://deno.land/x/jose@v4.14.4/index.ts'
   
   interface AppleVerificationResult {
     valid: boolean
     product_id: string
     original_transaction_id: string
     purchase_date: number
   }
   
   export async function verifyAppleTransaction(
     transactionId: string
   ): Promise<AppleVerificationResult> {
     
     // 1. Create JWT for Apple API authentication
     const privateKey = Deno.env.get('APPLE_PRIVATE_KEY')!
       .replace(/\\n/g, '\n')
     
     const algorithm = 'ES256'
     const key = await jose.importPKCS8(privateKey, algorithm)
     
     const jwt = await new jose.SignJWT({})
       .setProtectedHeader({ 
         alg: algorithm,
         kid: Deno.env.get('APPLE_KEY_ID')!
       })
       .setIssuer(Deno.env.get('APPLE_ISSUER_ID')!)
       .setAudience('appstoreconnect-v1')
       .setIssuedAt()
       .setExpirationTime('1h')
       .sign(key)
     
     // 2. Call Apple's App Store Server API
     const response = await fetch(
       `https://api.storekit.itunes.apple.com/inApps/v1/transactions/${transactionId}`,
       {
         headers: {
           'Authorization': `Bearer ${jwt}`,
           'Content-Type': 'application/json'
         }
       }
     )
     
     if (!response.ok) {
       const error = await response.text()
       throw new Error(`Apple verification failed: ${error}`)
     }
     
     // 3. Parse and validate response
     const data = await response.json()
     
     // Decode the signed transaction (JWS format)
     const { payload } = await jose.jwtVerify(
       data.signedTransaction,
       // Apple's public key verification (simplified - in production use Apple's certs)
       key
     )
     
     return {
       valid: true,
       product_id: payload.productId as string,
       original_transaction_id: payload.originalTransactionId as string,
       purchase_date: payload.purchaseDate as number
     }
   }
   ```

2. **Implement Real DeviceCheck Verification**
   
   File: `supabase/functions/_shared/device-check.ts`
   
   ```typescript
   import * as jose from 'https://deno.land/x/jose@v4.14.4/index.ts'
   
   interface DeviceCheckResult {
     valid: boolean
     is_first_time: boolean
   }
   
   export async function verifyDeviceToken(
     deviceToken: string,
     deviceId: string
   ): Promise<DeviceCheckResult> {
     
     // 1. Create JWT for DeviceCheck API
     const privateKey = Deno.env.get('APPLE_DEVICECHECK_PRIVATE_KEY')!
       .replace(/\\n/g, '\n')
     
     const algorithm = 'ES256'
     const key = await jose.importPKCS8(privateKey, algorithm)
     
     const jwt = await new jose.SignJWT({})
       .setProtectedHeader({ 
         alg: algorithm,
         kid: Deno.env.get('APPLE_DEVICECHECK_KEY_ID')!
       })
       .setIssuer(Deno.env.get('APPLE_TEAM_ID')!)
       .setIssuedAt()
       .setExpirationTime('1h')
       .sign(key)
     
     // 2. Query DeviceCheck API
     const queryResponse = await fetch(
       'https://api.devicecheck.apple.com/v1/query_two_bits',
       {
         method: 'POST',
         headers: {
           'Authorization': `Bearer ${jwt}`,
           'Content-Type': 'application/json'
         },
         body: JSON.stringify({
           device_token: deviceToken,
           transaction_id: deviceId,
           timestamp: Date.now()
         })
       }
     )
     
     if (!queryResponse.ok) {
       throw new Error('DeviceCheck verification failed')
     }
     
     const data = await queryResponse.json()
     
     // bit0 = false means device hasn't claimed initial grant yet
     const isFirstTime = data.bit0 === false
     
     // 3. If first time, mark bit0 as true
     if (isFirstTime) {
       await fetch(
         'https://api.devicecheck.apple.com/v1/update_two_bits',
         {
           method: 'POST',
           headers: {
             'Authorization': `Bearer ${jwt}`,
             'Content-Type': 'application/json'
           },
           body: JSON.stringify({
             device_token: deviceToken,
             transaction_id: deviceId,
             timestamp: Date.now(),
             bit0: true // Mark as used
           })
         }
       )
     }
     
     return {
       valid: true,
       is_first_time: isFirstTime
     }
   }
   ```

3. **Add Anonymous Auth for Guest Users**
   
   Update `supabase/functions/device-check/index.ts`:
   
   ```typescript
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
         // Return existing user (no new auth session needed)
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
       
       // 4. Create user record with auth.uid
       const { data: newUser, error: userError } = await supabaseClient
         .from('users')
         .insert({
           id: authData.user.id, // Use auth user ID
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
       
       // 6. Return user data + auth session
       return new Response(
         JSON.stringify({
           user_id: newUser.id,
           credits_remaining: newUser.credits_remaining,
           is_new: true,
           session: authData.session // iOS client stores this
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

4. **Add Basic Token Refresh Logic**
   
   Create `supabase/functions/_shared/auth-helper.ts`:
   
   ```typescript
   import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
   
   export async function getAuthenticatedUser(
     req: Request,
     supabaseClient: SupabaseClient
   ) {
     const authHeader = req.headers.get('Authorization')
     
     if (!authHeader) {
       throw new Error('Missing Authorization header')
     }
     
     const token = authHeader.replace('Bearer ', '')
     
     // Get user from token
     const { data: { user }, error } = await supabaseClient.auth.getUser(token)
     
     if (error || !user) {
       throw new Error('Invalid or expired token')
     }
     
     return user
   }
   ```
   
   Update iOS `AuthService.swift`:
   
   ```swift
   import Supabase
   
   actor AuthService {
       static let shared = AuthService()
       private let supabaseClient: SupabaseClient
       
       private var refreshTask: Task<Session, Error>?
       
       private init() {
           supabaseClient = SupabaseClient(
               supabaseURL: URL(string: AppConfig.supabaseURL)!,
               supabaseKey: AppConfig.supabaseAnonKey
           )
       }
       
       func refreshTokenIfNeeded() async throws -> Bool {
           // Prevent concurrent refresh attempts
           if let existingTask = refreshTask {
               _ = try? await existingTask.value
               return true
           }
           
           guard let session = try? await supabaseClient.auth.session else {
               return false
           }
           
           // Check if token expires in < 5 minutes
           let expiresAt = session.expiresAt
           let now = Date().timeIntervalSince1970
           
           if expiresAt - now < 300 {
               let task = Task {
                   try await supabaseClient.auth.refreshSession()
               }
               refreshTask = task
               defer { refreshTask = nil }
               
               do {
                   _ = try await task.value
                   return true
               } catch {
                   return false
               }
           }
           
           return true
       }
   }
   ```
   
   Update `APIClient.swift` to auto-refresh on 401:
   
   ```swift
   private func executeWithRetry<T: Decodable>(
       request: URLRequest,
       attempt: Int = 1
   ) async throws -> T {
       do {
           let (data, response) = try await session.data(for: request)
           
           guard let httpResponse = response as? HTTPURLResponse else {
               throw AppError.invalidResponse
           }
           
           // Handle 401 Unauthorized
           if httpResponse.statusCode == 401 && attempt == 1 {
               // Try to refresh token
               if await AuthService.shared.refreshTokenIfNeeded() {
                   // Retry request with new token
                   return try await executeWithRetry(request: request, attempt: attempt + 1)
               }
           }
           
           try handleHTTPStatus(httpResponse.statusCode, data: data)
           return try decoder.decode(T.self, from: data)
           
       } catch {
           // ... existing retry logic ...
       }
   }
   ```

5. **Update Environment Variables**
   
   Add to `.env.example`:
   
   ```bash
   # Apple IAP Verification (App Store Server API)
   APPLE_BUNDLE_ID=com.yourdomain.rendio
   APPLE_TEAM_ID=YOUR_TEAM_ID
   APPLE_KEY_ID=YOUR_KEY_ID
   APPLE_ISSUER_ID=YOUR_ISSUER_ID
   APPLE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
   
   # Apple DeviceCheck
   APPLE_DEVICECHECK_KEY_ID=YOUR_DEVICECHECK_KEY_ID
   APPLE_DEVICECHECK_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
   ```

#### Deliverables:
- ✅ Apple IAP verification uses real App Store Server API
- ✅ DeviceCheck verification prevents credit farming
- ✅ Guest users get anonymous JWT (can use RLS + Realtime)
- ✅ Token refresh prevents unexpected logouts
- ✅ All TODOs replaced with production code

#### Testing Checklist:
- [ ] Real Apple IAP receipt validates correctly
- [ ] Fake receipt gets rejected (test with expired transaction)
- [ ] DeviceCheck prevents duplicate initial grants
- [ ] Guest user can query database directly (RLS works)
- [ ] Token auto-refreshes before expiration
- [ ] 401 error triggers refresh + retry

---

### Phase 1: Core Database & API Setup (3-4 days)

**Goal:** Build foundation APIs for user management and credits

#### Tasks:

1. **Create Device Check Endpoint**
   
   File: `supabase/functions/device-check/index.ts`
   
   ```typescript
   import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
   import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
   
   serve(async (req) => {
     try {
       const { device_id, device_token } = await req.json()
       
       // Initialize Supabase client
       const supabaseClient = createClient(
         Deno.env.get('SUPABASE_URL') ?? '',
         Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
       )
       
       // 1. Verify device token with Apple (simplified for MVP)
       // In production, implement full Apple DeviceCheck verification
       // See: https://developer.apple.com/documentation/devicecheck
       
       // 2. Check if user exists
       const { data: existingUser } = await supabaseClient
         .from('users')
         .select('*')
         .eq('device_id', device_id)
         .single()
       
       if (existingUser) {
         return new Response(
           JSON.stringify({
             user_id: existingUser.id,
             credits_remaining: existingUser.credits_remaining,
             is_new: false
           }),
           { headers: { 'Content-Type': 'application/json' } }
         )
       }
       
       // 3. Create new guest user with initial credits
       const { data: newUser, error } = await supabaseClient
         .from('users')
         .insert({
           device_id: device_id,
           is_guest: true,
           tier: 'free',
           credits_remaining: 10,
           credits_total: 10,
           initial_grant_claimed: true,
           language: 'en',
           theme_preference: 'system'
         })
         .select()
         .single()
       
       if (error) throw error
       
       // 4. Log initial credit grant
       await supabaseClient.rpc('add_credits', {
         p_user_id: newUser.id,
         p_amount: 10,
         p_reason: 'initial_grant'
       })
       
       return new Response(
         JSON.stringify({
           user_id: newUser.id,
           credits_remaining: newUser.credits_remaining,
           is_new: true
         }),
         { headers: { 'Content-Type': 'application/json' } }
       )
       
     } catch (error) {
       return new Response(
         JSON.stringify({ error: error.message }),
         { status: 500, headers: { 'Content-Type': 'application/json' } }
       )
     }
   })
   ```

2. **Create Credit Management Endpoint**
   
   File: `supabase/functions/update-credits/index.ts`
   
   ```typescript
   import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
   import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
   
   serve(async (req) => {
     try {
       const { user_id, transaction_id } = await req.json()
       
       const supabaseClient = createClient(
         Deno.env.get('SUPABASE_URL') ?? '',
         Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
       )
       
       // 1. Verify transaction with Apple's NEW App Store Server API
       // TODO: Implement Apple's App Store Server API verification
       // For now, using simplified verification
       
       // Example verification (replace with actual Apple API call):
       const verification = await verifyWithApple(transaction_id)
       
       if (!verification.valid) {
         return new Response(
           JSON.stringify({ error: 'Invalid transaction' }),
           { status: 400, headers: { 'Content-Type': 'application/json' } }
         )
       }
       
       // 2. Get product configuration (NEVER trust client)
       const productConfig: Record<string, number> = {
         'com.rendio.credits.10': 10,
         'com.rendio.credits.50': 50,
         'com.rendio.credits.100': 100
       }
       
       const creditsToAdd = productConfig[verification.product_id]
       
       if (!creditsToAdd) {
         return new Response(
           JSON.stringify({ error: 'Unknown product' }),
           { status: 400, headers: { 'Content-Type': 'application/json' } }
         )
       }
       
       // 3. Add credits atomically (handles duplicate check)
       const { data: result } = await supabaseClient.rpc('add_credits', {
         p_user_id: user_id,
         p_amount: creditsToAdd,
         p_reason: 'iap_purchase',
         p_transaction_id: transaction_id
       })
       
       if (!result.success) {
         return new Response(
           JSON.stringify({ error: result.error }),
           { status: 400, headers: { 'Content-Type': 'application/json' } }
         )
       }
       
       return new Response(
         JSON.stringify({
           success: true,
           credits_added: creditsToAdd,
           credits_remaining: result.credits_remaining
         }),
         { headers: { 'Content-Type': 'application/json' } }
       )
       
     } catch (error) {
       return new Response(
         JSON.stringify({ error: error.message }),
         { status: 500, headers: { 'Content-Type': 'application/json' } }
       )
     }
   })
   
   // Simplified Apple verification (implement full version in production)
   async function verifyWithApple(transactionId: string) {
     // TODO: Implement actual Apple App Store Server API call
     // For MVP, return mock validation
     return {
       valid: true,
       product_id: 'com.rendio.credits.10'
     }
   }
   ```

3. **Create Get Credits Endpoint**
   
   File: `supabase/functions/get-user-credits/index.ts`
   
   ```typescript
   import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
   import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
   
   serve(async (req) => {
     try {
       const url = new URL(req.url)
       const user_id = url.searchParams.get('user_id')
       
       if (!user_id) {
         return new Response(
           JSON.stringify({ error: 'user_id required' }),
           { status: 400, headers: { 'Content-Type': 'application/json' } }
         )
       }
       
       const supabaseClient = createClient(
         Deno.env.get('SUPABASE_URL') ?? '',
         Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
       )
       
       const { data: user, error } = await supabaseClient
         .from('users')
         .select('credits_remaining')
         .eq('id', user_id)
         .single()
       
       if (error) throw error
       
       return new Response(
         JSON.stringify({ credits_remaining: user.credits_remaining }),
         { headers: { 'Content-Type': 'application/json' } }
       )
       
     } catch (error) {
       return new Response(
         JSON.stringify({ error: error.message }),
         { status: 500, headers: { 'Content-Type': 'application/json' } }
       )
     }
   })
   ```

4. **Create Shared Utilities**
   
   File: `supabase/functions/_shared/logger.ts`
   
   ```typescript
   export function logEvent(
     eventType: string,
     data: Record<string, any>,
     level: 'info' | 'error' | 'warn' = 'info'
   ) {
     const logEntry = {
       timestamp: new Date().toISOString(),
       level,
       event: eventType,
       ...data,
       environment: Deno.env.get('ENVIRONMENT')
     }
     
     console.log(JSON.stringify(logEntry))
   }
   ```

5. **Test Endpoints**
   - Use Postman or curl to test
   - Verify RLS policies work
   - Test credit deduction race conditions
   - Test duplicate transaction prevention

#### Deliverables:
- ✅ Device check endpoint working
- ✅ Credit management working with Apple IAP
- ✅ RLS policies tested
- ✅ Endpoints return correct JSON
- ✅ Duplicate prevention working

---

### Phase 2: Video Generation API (4-5 days)

**Goal:** Build video generation workflow with idempotency and rollback

#### Tasks:

1. **Create Generate Video Endpoint (WITH IDEMPOTENCY)**
   
   File: `supabase/functions/generate-video/index.ts`
   
   ```typescript
   import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
   import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
   import { logEvent } from '../_shared/logger.ts'
   
   serve(async (req) => {
     try {
       // 1. Get idempotency key from header
       const idempotencyKey = req.headers.get('Idempotency-Key')
       
       if (!idempotencyKey) {
         return new Response(
           JSON.stringify({ error: 'Idempotency-Key header required' }),
           { status: 400, headers: { 'Content-Type': 'application/json' } }
         )
       }
       
       const { user_id, model_id, prompt, settings } = await req.json()
       
       const supabaseClient = createClient(
         Deno.env.get('SUPABASE_URL') ?? '',
         Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
       )
       
       // 2. Check idempotency (prevent duplicate processing)
       const { data: existing } = await supabaseClient
         .from('idempotency_log')
         .select('job_id, response_data, status_code')
         .eq('idempotency_key', idempotencyKey)
         .eq('user_id', user_id)
         .gt('expires_at', new Date().toISOString())
         .single()
       
       if (existing) {
         // Return cached response
         logEvent('idempotent_replay', { 
           user_id, 
           idempotency_key: idempotencyKey 
         })
         
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
       
       // 3. Fetch model details
       const { data: model, error: modelError } = await supabaseClient
         .from('models')
         .select('cost_per_generation, provider, provider_model_id')
         .eq('id', model_id)
         .single()
       
       if (modelError) throw modelError
       
       // 4. Deduct credits atomically
       const { data: deductResult } = await supabaseClient.rpc('deduct_credits', {
         p_user_id: user_id,
         p_amount: model.cost_per_generation,
         p_reason: 'video_generation'
       })
       
       if (!deductResult.success) {
         return new Response(
           JSON.stringify({ 
             error: deductResult.error,
             credits_remaining: deductResult.current_credits || 0
           }),
           { status: 402, headers: { 'Content-Type': 'application/json' } }
         )
       }
       
       // 5. Create video job
       const { data: job, error: jobError } = await supabaseClient
         .from('video_jobs')
         .insert({
           user_id: user_id,
           model_id: model_id,
           prompt: prompt,
           settings: settings || {},
           status: 'pending',
           credits_used: model.cost_per_generation
         })
         .select()
         .single()
       
       if (jobError) {
         // ROLLBACK: Refund credits if job creation failed
         await supabaseClient.rpc('add_credits', {
           p_user_id: user_id,
           p_amount: model.cost_per_generation,
           p_reason: 'generation_failed_refund'
         })
         
         throw jobError
       }
       
       // 6. Call provider API
       let providerJobId: string | null = null
       
       try {
         const providerResult = await callProviderAPI(
           model.provider,
           model.provider_model_id,
           prompt,
           settings
         )
         
         providerJobId = providerResult.job_id
         
         // Update job with provider_job_id
         await supabaseClient
           .from('video_jobs')
           .update({ provider_job_id: providerJobId })
           .eq('job_id', job.job_id)
         
       } catch (providerError) {
         // ROLLBACK: Mark job as failed and refund credits
         await supabaseClient
           .from('video_jobs')
           .update({
             status: 'failed',
             error_message: providerError.message
           })
           .eq('job_id', job.job_id)
         
         await supabaseClient.rpc('add_credits', {
           p_user_id: user_id,
           p_amount: model.cost_per_generation,
           p_reason: 'generation_failed_refund'
         })
         
         throw providerError
       }
       
       // 7. Store idempotency record
       const responseBody = {
         job_id: job.job_id,
         status: 'pending',
         credits_used: model.cost_per_generation
       }
       
       await supabaseClient.from('idempotency_log').insert({
         idempotency_key: idempotencyKey,
         user_id: user_id,
         job_id: job.job_id,
         operation_type: 'video_generation',
         response_data: responseBody,
         status_code: 200
       })
       
       logEvent('video_generation_started', {
         user_id,
         job_id: job.job_id,
         model_id,
         provider: model.provider,
         credits_used: model.cost_per_generation
       })
       
       return new Response(
         JSON.stringify(responseBody),
         { headers: { 'Content-Type': 'application/json' } }
       )
       
     } catch (error) {
       logEvent('video_generation_error', { error: error.message }, 'error')
       
       return new Response(
         JSON.stringify({ error: error.message }),
         { status: 500, headers: { 'Content-Type': 'application/json' } }
       )
     }
   })
   
   // Provider API caller
   async function callProviderAPI(
     provider: string,
     modelId: string,
     prompt: string,
     settings: any
   ) {
     switch (provider) {
       case 'fal':
         return await callFalAI(modelId, prompt, settings)
       case 'runway':
         // Future implementation
         throw new Error('Runway not yet implemented')
       case 'pika':
         // Future implementation
         throw new Error('Pika not yet implemented')
       default:
         throw new Error(`Unknown provider: ${provider}`)
     }
   }
   
   // FalAI adapter
   async function callFalAI(modelId: string, prompt: string, settings: any) {
     const apiKey = Deno.env.get('FALAI_API_KEY')
     
     const response = await fetch(`https://fal.run/${modelId}`, {
       method: 'POST',
       headers: {
         'Authorization': `Key ${apiKey}`,
         'Content-Type': 'application/json'
       },
       body: JSON.stringify({
         prompt: prompt,
         ...settings
       })
     })
     
     if (!response.ok) {
       throw new Error(`FalAI error: ${response.statusText}`)
     }
     
     const data = await response.json()
     
     return {
       job_id: data.request_id || data.id
     }
   }
   ```

2. **Create Get Video Status Endpoint**
   
   File: `supabase/functions/get-video-status/index.ts`
   
   ```typescript
   import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
   import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
   
   serve(async (req) => {
     try {
       const url = new URL(req.url)
       const job_id = url.searchParams.get('job_id')
       
       if (!job_id) {
         return new Response(
           JSON.stringify({ error: 'job_id required' }),
           { status: 400, headers: { 'Content-Type': 'application/json' } }
         )
       }
       
       const supabaseClient = createClient(
         Deno.env.get('SUPABASE_URL') ?? '',
         Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
       )
       
       // 1. Get job from database
       const { data: job, error } = await supabaseClient
         .from('video_jobs')
         .select('*')
         .eq('job_id', job_id)
         .single()
       
       if (error) throw error
       
       // 2. If still pending/processing, check provider status
       if (job.status === 'pending' || job.status === 'processing') {
         try {
           const providerStatus = await checkProviderStatus(
             job.provider_job_id,
             job.model_id
           )
           
           if (providerStatus.status === 'completed') {
             // Update job in database
             await supabaseClient
               .from('video_jobs')
               .update({
                 status: 'completed',
                 video_url: providerStatus.video_url,
                 thumbnail_url: providerStatus.thumbnail_url,
                 completed_at: new Date().toISOString()
               })
               .eq('job_id', job_id)
             
             return new Response(
               JSON.stringify({
                 job_id: job.job_id,
                 status: 'completed',
                 video_url: providerStatus.video_url,
                 thumbnail_url: providerStatus.thumbnail_url
               }),
               { headers: { 'Content-Type': 'application/json' } }
             )
           }
         } catch (providerError) {
           // If provider check fails, return current DB status
           console.error('Provider check failed:', providerError)
         }
       }
       
       // 3. Return current status
       return new Response(
         JSON.stringify({
           job_id: job.job_id,
           status: job.status,
           video_url: job.video_url,
           thumbnail_url: job.thumbnail_url
         }),
         { headers: { 'Content-Type': 'application/json' } }
       )
       
     } catch (error) {
       return new Response(
         JSON.stringify({ error: error.message }),
         { status: 500, headers: { 'Content-Type': 'application/json' } }
       )
     }
   })
   
   async function checkProviderStatus(providerJobId: string, modelId: string) {
     // Simplified - implement actual provider status check
     const apiKey = Deno.env.get('FALAI_API_KEY')
     
     const response = await fetch(`https://fal.run/status/${providerJobId}`, {
       headers: {
         'Authorization': `Key ${apiKey}`
       }
     })
     
     if (!response.ok) {
       throw new Error(`Provider status check failed: ${response.statusText}`)
     }
     
     const data = await response.json()
     
     return {
       status: data.status,
       video_url: data.video?.url,
       thumbnail_url: data.thumbnail?.url
     }
   }
   ```

3. **iOS Client Integration (Idempotency)**
   
   Update your Swift `VideoGenerationService`:
   
   ```swift
   // In VideoGenerationService.swift
   func generateVideo(
       userId: String, 
       modelId: String, 
       prompt: String,
       settings: VideoSettings
   ) async throws -> VideoGenerationResponse {
       
       // Generate idempotency key
       let idempotencyKey = UUID().uuidString
       
       let request = VideoGenerationRequest(
           user_id: userId,
           model_id: modelId,
           prompt: prompt,
           settings: settings
       )
       
       // Call API with idempotency key in header
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

#### Deliverables:
- ✅ Video generation endpoint with idempotency
- ✅ Provider adapters working (FalAI)
- ✅ Status polling working
- ✅ Rollback logic tested
- ✅ Videos stored in Supabase Storage

---

### Phase 3: History & User Management (2 days)

**Goal:** Build history and user profile APIs

#### Tasks:

1. **Create Get Video Jobs Endpoint**
   
   File: `supabase/functions/get-video-jobs/index.ts`
   
   ```typescript
   import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
   import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
   
   serve(async (req) => {
     try {
       const url = new URL(req.url)
       const user_id = url.searchParams.get('user_id')
       const limit = parseInt(url.searchParams.get('limit') || '20')
       const offset = parseInt(url.searchParams.get('offset') || '0')
       
       if (!user_id) {
         return new Response(
           JSON.stringify({ error: 'user_id required' }),
           { status: 400, headers: { 'Content-Type': 'application/json' } }
         )
       }
       
       const supabaseClient = createClient(
         Deno.env.get('SUPABASE_URL') ?? '',
         Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
       )
       
       const { data: jobs, error } = await supabaseClient
         .from('video_jobs')
         .select(`
           job_id,
           prompt,
           status,
           video_url,
           thumbnail_url,
           credits_used,
           created_at,
           models (name)
         `)
         .eq('user_id', user_id)
         .order('created_at', { ascending: false })
         .range(offset, offset + limit - 1)
       
       if (error) throw error
       
       // Transform to match iOS model
       const transformedJobs = jobs.map(job => ({
         job_id: job.job_id,
         prompt: job.prompt,
         model_name: job.models?.name || 'Unknown Model',
         credits_used: job.credits_used,
         status: job.status,
         video_url: job.video_url,
         thumbnail_url: job.thumbnail_url,
         created_at: job.created_at
       }))
       
       return new Response(
         JSON.stringify({ jobs: transformedJobs }),
         { headers: { 'Content-Type': 'application/json' } }
       )
       
     } catch (error) {
       return new Response(
         JSON.stringify({ error: error.message }),
         { status: 500, headers: { 'Content-Type': 'application/json' } }
       )
     }
   })
   ```

2. **Create Delete Video Job Endpoint**
   
   File: `supabase/functions/delete-video-job/index.ts`
   
   ```typescript
   import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
   import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
   
   serve(async (req) => {
     try {
       const { job_id, user_id } = await req.json()
       
       const supabaseClient = createClient(
         Deno.env.get('SUPABASE_URL') ?? '',
         Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
       )
       
       // 1. Verify ownership
       const { data: job } = await supabaseClient
         .from('video_jobs')
         .select('user_id, video_url')
         .eq('job_id', job_id)
         .single()
       
       if (!job || job.user_id !== user_id) {
         return new Response(
           JSON.stringify({ error: 'Job not found or unauthorized' }),
           { status: 404, headers: { 'Content-Type': 'application/json' } }
         )
       }
       
       // 2. Delete video from storage (if exists)
       if (job.video_url) {
         // Extract path from URL and delete from storage
         // TODO: Implement storage deletion
       }
       
       // 3. Delete job record
       const { error } = await supabaseClient
         .from('video_jobs')
         .delete()
         .eq('job_id', job_id)
       
       if (error) throw error
       
       return new Response(
         JSON.stringify({ success: true }),
         { headers: { 'Content-Type': 'application/json' } }
       )
       
     } catch (error) {
       return new Response(
         JSON.stringify({ error: error.message }),
         { status: 500, headers: { 'Content-Type': 'application/json' } }
       )
     }
   })
   ```

3. **Create Get Models Endpoint**
   
   File: `supabase/functions/get-models/index.ts`
   
   ```typescript
   import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
   import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
   
   serve(async (req) => {
     try {
       const supabaseClient = createClient(
         Deno.env.get('SUPABASE_URL') ?? '',
         Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
       )
       
       const { data: models, error } = await supabaseClient
         .from('models')
         .select('*')
         .eq('is_available', true)
         .order('is_featured', { ascending: false })
         .order('name', { ascending: true })
       
       if (error) throw error
       
       return new Response(
         JSON.stringify({ models }),
         { headers: { 'Content-Type': 'application/json' } }
       )
       
     } catch (error) {
       return new Response(
         JSON.stringify({ error: error.message }),
         { status: 500, headers: { 'Content-Type': 'application/json' } }
       )
     }
   })
   ```

4. **Create User Profile Endpoint**
   
   File: `supabase/functions/get-user-profile/index.ts`
   
   ```typescript
   import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
   import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
   
   serve(async (req) => {
     try {
       const url = new URL(req.url)
       const user_id = url.searchParams.get('user_id')
       
       if (!user_id) {
         return new Response(
           JSON.stringify({ error: 'user_id required' }),
           { status: 400, headers: { 'Content-Type': 'application/json' } }
         )
       }
       
       const supabaseClient = createClient(
         Deno.env.get('SUPABASE_URL') ?? '',
         Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
       )
       
       const { data: user, error } = await supabaseClient
         .from('users')
         .select('*')
         .eq('id', user_id)
         .single()
       
       if (error) throw error
       
       return new Response(
         JSON.stringify(user),
         { headers: { 'Content-Type': 'application/json' } }
       )
       
     } catch (error) {
       return new Response(
         JSON.stringify({ error: error.message }),
         { status: 500, headers: { 'Content-Type': 'application/json' } }
       )
     }
   })
   ```

#### Deliverables:
- ✅ History endpoint working with pagination
- ✅ Delete endpoint working
- ✅ Models endpoint working
- ✅ User profile endpoint working

---

### Phase 4: Integration & Testing (3-4 days)

**Goal:** Connect iOS app to backend and test everything

#### Tasks:

1. **Update iOS Services**
   - Replace mock services with real API calls
   - Use `APIClient.shared.request(...)` pattern
   - Handle errors properly
   - Add retry logic

2. **Test End-to-End Flows**
   - Test onboarding (new user)
   - Test onboarding (existing user)
   - Test video generation
   - Test idempotency (retry with same key)
   - Test credit purchase
   - Test sign in with Apple
   - Test history loading
   - Test rollback on failure

3. **Test Edge Cases**
   - Insufficient credits
   - Network timeout during generation
   - Provider API failure
   - Duplicate transaction_id
   - Duplicate idempotency key
   - Concurrent video generations

4. **Performance Testing**
   - Test with 100+ video jobs
   - Test pagination
   - Test concurrent requests
   - Monitor database queries
   - Check stored procedure performance

5. **Security Audit**
   - Test RLS policies
   - Test unauthorized access attempts
   - Verify no API keys exposed in client
   - Test token refresh
   - Verify atomic credit operations
   - Test idempotency expiration

#### Deliverables:
- ✅ iOS app connected to backend
- ✅ All features working
- ✅ Idempotency tested
- ✅ Rollback tested
- ✅ Performance acceptable
- ✅ Security verified

---

### Phase 5: Webhook System (Replace Polling) (3-4 days) 🔔

**Goal:** Replace polling with event-driven architecture using webhooks for real-time video status updates

**Why:** Reduce API costs, improve battery life, and provide instant user notifications when videos complete

#### Tasks:

1. **Create Webhook Delivery System**

   File: `supabase/functions/webhook-delivery/index.ts`

   ```typescript
   import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
   import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

   // HMAC signature validation for security
   async function validateSignature(
     payload: string,
     signature: string,
     secret: string
   ): Promise<boolean> {
     const encoder = new TextEncoder()
     const key = await crypto.subtle.importKey(
       'raw',
       encoder.encode(secret),
       { name: 'HMAC', hash: 'SHA-256' },
       false,
       ['sign']
     )

     const signatureBytes = await crypto.subtle.sign(
       'HMAC',
       key,
       encoder.encode(payload)
     )

     const expectedSignature = Array.from(new Uint8Array(signatureBytes))
       .map(b => b.toString(16).padStart(2, '0'))
       .join('')

     return expectedSignature === signature
   }

   serve(async (req) => {
     try {
       const signature = req.headers.get('X-Webhook-Signature')
       const payload = await req.text()

       // Validate webhook signature
       const secret = Deno.env.get('WEBHOOK_SECRET')!
       const isValid = await validateSignature(payload, signature!, secret)

       if (!isValid) {
         return new Response(
           JSON.stringify({ error: 'Invalid signature' }),
           { status: 401 }
         )
       }

       const event = JSON.parse(payload)

       const supabaseClient = createClient(
         Deno.env.get('SUPABASE_URL')!,
         Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
       )

       // Process webhook event
       switch (event.type) {
         case 'video.completed':
           await handleVideoCompleted(event.data, supabaseClient)
           break
         case 'video.failed':
           await handleVideoFailed(event.data, supabaseClient)
           break
       }

       // Log webhook delivery
       await supabaseClient.from('webhook_deliveries').insert({
         event_type: event.type,
         payload: event,
         status: 'processed'
       })

       return new Response(JSON.stringify({ success: true }), {
         headers: { 'Content-Type': 'application/json' }
       })
     } catch (error) {
       return new Response(
         JSON.stringify({ error: error.message }),
         { status: 500 }
       )
     }
   })

   async function handleVideoCompleted(data: any, client: any) {
     // Update video job
     await client
       .from('video_jobs')
       .update({
         status: 'completed',
         video_url: data.video_url,
         thumbnail_url: data.thumbnail_url,
         completed_at: new Date().toISOString()
       })
       .eq('provider_job_id', data.provider_job_id)

     // Send APNs push notification
     const job = await client
       .from('video_jobs')
       .select('user_id')
       .eq('provider_job_id', data.provider_job_id)
       .single()

     await sendPushNotification(job.data.user_id, {
       title: 'Video Ready!',
       body: 'Your video generation is complete',
       data: { job_id: data.job_id }
     })
   }

   async function handleVideoFailed(data: any, client: any) {
     // Mark job as failed and refund credits
     const job = await client
       .from('video_jobs')
       .select('user_id, credits_used')
       .eq('provider_job_id', data.provider_job_id)
       .single()

     await client
       .from('video_jobs')
       .update({
         status: 'failed',
         error_message: data.error
       })
       .eq('provider_job_id', data.provider_job_id)

     // Refund credits
     await client.rpc('add_credits', {
       p_user_id: job.data.user_id,
       p_amount: job.data.credits_used,
       p_reason: 'generation_failed_refund'
     })
   }

   async function sendPushNotification(userId: string, notification: any) {
     // TODO: Implement APNs push notification
     // Requires user's device token and APNs certificate
   }
   ```

2. **Add Webhook Deliveries Table**

   Create migration: `supabase/migrations/005_create_webhook_tables.sql`

   ```sql
   CREATE TABLE IF NOT EXISTS webhook_deliveries (
     id BIGSERIAL PRIMARY KEY,
     event_type TEXT NOT NULL,
     payload JSONB NOT NULL,
     status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processed', 'failed')),
     retry_count INTEGER DEFAULT 0,
     last_error TEXT,
     created_at TIMESTAMPTZ DEFAULT now()
   );

   CREATE INDEX idx_webhook_status ON webhook_deliveries(status);
   CREATE INDEX idx_webhook_created ON webhook_deliveries(created_at);
   ```

3. **Implement Idempotency for Webhooks**

   Add to webhook handler:

   ```typescript
   // Check if webhook already processed
   const eventId = event.id // Provider's unique event ID

   const { data: existing } = await supabaseClient
     .from('webhook_deliveries')
     .select('id')
     .eq('payload->id', eventId)
     .single()

   if (existing) {
     return new Response(JSON.stringify({ success: true, cached: true }), {
       headers: { 'Content-Type': 'application/json' }
     })
   }
   ```

4. **Update iOS App to Register Device Token**

   iOS Service to register for push notifications:

   ```swift
   func registerForPushNotifications() async throws {
       let settings = await UNUserNotificationCenter.current()
           .notificationSettings()

       guard settings.authorizationStatus == .authorized else { return }

       DispatchQueue.main.async {
           UIApplication.shared.registerForRemoteNotifications()
       }
   }

   func application(
       _ application: UIApplication,
       didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
   ) {
       let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()

       Task {
           try await updateDeviceToken(token)
       }
   }
   ```

#### Deliverables:
- ✅ Webhook endpoint with HMAC signature validation
- ✅ APNs push notification integration
- ✅ Idempotency for webhook processing
- ✅ iOS app registers for push notifications
- ✅ Polling removed from iOS app

---

### Phase 6: Retry Logic for External APIs (2-3 days) 🔄

**Goal:** Implement exponential backoff retry logic for external API calls to handle transient failures

**Why:** Improve reliability when calling FalAI, Runway, and other providers

#### Tasks:

1. **Create Retry Utility with Exponential Backoff**

   File: `supabase/functions/_shared/fetch-with-retry.ts`

   ```typescript
   interface RetryConfig {
     maxRetries: number
     initialDelay: number
     maxDelay: number
     retryableStatusCodes: number[]
   }

   const defaultConfig: RetryConfig = {
     maxRetries: 3,
     initialDelay: 2000, // 2 seconds
     maxDelay: 30000, // 30 seconds
     retryableStatusCodes: [408, 429, 500, 502, 503, 504]
   }

   export async function fetchWithRetry(
     url: string,
     options: RequestInit = {},
     config: Partial<RetryConfig> = {}
   ): Promise<Response> {
     const finalConfig = { ...defaultConfig, ...config }
     let lastError: Error | null = null

     for (let attempt = 0; attempt <= finalConfig.maxRetries; attempt++) {
       try {
         const controller = new AbortController()
         const timeout = setTimeout(() => controller.abort(), 30000)

         const response = await fetch(url, {
           ...options,
           signal: controller.signal
         })

         clearTimeout(timeout)

         // Success
         if (response.ok) {
           return response
         }

         // Non-retryable error
         if (!finalConfig.retryableStatusCodes.includes(response.status)) {
           return response
         }

         // Retryable error
         lastError = new Error(
           `HTTP ${response.status}: ${response.statusText}`
         )

       } catch (error) {
         lastError = error as Error
       }

       // Don't retry on last attempt
       if (attempt === finalConfig.maxRetries) {
         break
       }

       // Calculate exponential backoff
       const delay = Math.min(
         finalConfig.initialDelay * Math.pow(2, attempt),
         finalConfig.maxDelay
       )

       console.log(`Retry attempt ${attempt + 1} after ${delay}ms`)
       await new Promise(resolve => setTimeout(resolve, delay))
     }

     throw lastError || new Error('Request failed after retries')
   }
   ```

2. **Update Provider API Calls to Use Retry Logic**

   Update `generate-video/index.ts`:

   ```typescript
   import { fetchWithRetry } from '../_shared/fetch-with-retry.ts'

   async function callFalAI(modelId: string, prompt: string, settings: any) {
     const apiKey = Deno.env.get('FALAI_API_KEY')

     const response = await fetchWithRetry(
       `https://fal.run/${modelId}`,
       {
         method: 'POST',
         headers: {
           'Authorization': `Key ${apiKey}`,
           'Content-Type': 'application/json'
         },
         body: JSON.stringify({
           prompt: prompt,
           ...settings
         })
       },
       {
         maxRetries: 3,
         initialDelay: 2000,
         maxDelay: 30000
       }
     )

     if (!response.ok) {
       throw new Error(`FalAI error: ${response.statusText}`)
     }

     const data = await response.json()

     return {
       job_id: data.request_id || data.id
     }
   }
   ```

3. **Add Timeout Handling**

   ```typescript
   export async function fetchWithTimeout(
     url: string,
     options: RequestInit = {},
     timeoutMs: number = 30000
   ): Promise<Response> {
     const controller = new AbortController()
     const timeout = setTimeout(() => controller.abort(), timeoutMs)

     try {
       const response = await fetch(url, {
         ...options,
         signal: controller.signal
       })
       clearTimeout(timeout)
       return response
     } catch (error) {
       clearTimeout(timeout)
       if (error.name === 'AbortError') {
         throw new Error('Request timeout')
       }
       throw error
     }
   }
   ```

#### Deliverables:
- ✅ Exponential backoff utility (2s → 4s → 8s → 30s max)
- ✅ Timeout handling for all external APIs
- ✅ Configurable retry logic per provider
- ✅ Logging for retry attempts

---

### Phase 7: Error Handling with i18n (2-3 days) 🌍

**Goal:** Implement standardized error codes with internationalized messages (English, Turkish, Spanish)

**Why:** Provide clear, localized error messages to users across different regions

#### Tasks:

1. **Define Error Code System**

   File: `supabase/functions/_shared/error-codes.ts`

   ```typescript
   export enum ErrorCode {
     // Client errors (4xxx)
     ERR_4001 = 'ERR_4001', // Insufficient credits
     ERR_4002 = 'ERR_4002', // Invalid model
     ERR_4003 = 'ERR_4003', // Invalid prompt
     ERR_4004 = 'ERR_4004', // Rate limit exceeded
     ERR_4005 = 'ERR_4005', // Unauthorized

     // Provider errors (5xxx)
     ERR_5001 = 'ERR_5001', // Provider timeout
     ERR_5002 = 'ERR_5002', // Provider unavailable
     ERR_5003 = 'ERR_5003', // Provider rejected request

     // System errors (6xxx)
     ERR_6001 = 'ERR_6001', // Database error
     ERR_6002 = 'ERR_6002', // Storage error
     ERR_6003 = 'ERR_6003', // Internal server error
   }

   export const ErrorMessages: Record<ErrorCode, Record<string, string>> = {
     [ErrorCode.ERR_4001]: {
       en: 'You need {required} credits, but only have {available}. Please purchase more credits.',
       tr: '{required} krediye ihtiyacınız var, ancak sadece {available} krediniz var. Lütfen daha fazla kredi satın alın.',
       es: 'Necesitas {required} créditos, pero solo tienes {available}. Por favor compra más créditos.'
     },
     [ErrorCode.ERR_4002]: {
       en: 'The selected model is not available.',
       tr: 'Seçilen model mevcut değil.',
       es: 'El modelo seleccionado no está disponible.'
     },
     [ErrorCode.ERR_4003]: {
       en: 'Please provide a valid prompt (minimum 3 characters).',
       tr: 'Lütfen geçerli bir prompt girin (minimum 3 karakter).',
       es: 'Por favor proporciona un prompt válido (mínimo 3 caracteres).'
     },
     [ErrorCode.ERR_4004]: {
       en: 'Too many requests. Please wait {seconds} seconds before trying again.',
       tr: 'Çok fazla istek. Lütfen tekrar denemeden önce {seconds} saniye bekleyin.',
       es: 'Demasiadas solicitudes. Por favor espera {seconds} segundos antes de intentar de nuevo.'
     },
     [ErrorCode.ERR_4005]: {
       en: 'Unauthorized. Please sign in again.',
       tr: 'Yetkisiz. Lütfen tekrar giriş yapın.',
       es: 'No autorizado. Por favor inicia sesión de nuevo.'
     },
     [ErrorCode.ERR_5001]: {
       en: 'Video generation timed out. Please try again.',
       tr: 'Video oluşturma zaman aşımına uğradı. Lütfen tekrar deneyin.',
       es: 'La generación de video agotó el tiempo. Por favor inténtalo de nuevo.'
     },
     [ErrorCode.ERR_5002]: {
       en: 'Video generation service is temporarily unavailable. Please try again later.',
       tr: 'Video oluşturma servisi geçici olarak kullanılamıyor. Lütfen daha sonra tekrar deneyin.',
       es: 'El servicio de generación de video no está disponible temporalmente. Por favor inténtalo más tarde.'
     },
     [ErrorCode.ERR_5003]: {
       en: 'Your prompt was rejected. Please try a different prompt.',
       tr: 'Promptunuz reddedildi. Lütfen farklı bir prompt deneyin.',
       es: 'Tu prompt fue rechazado. Por favor intenta con un prompt diferente.'
     },
     [ErrorCode.ERR_6001]: {
       en: 'Database error. Please try again later.',
       tr: 'Veritabanı hatası. Lütfen daha sonra tekrar deneyin.',
       es: 'Error de base de datos. Por favor inténtalo más tarde.'
     },
     [ErrorCode.ERR_6002]: {
       en: 'Storage error. Please try again later.',
       tr: 'Depolama hatası. Lütfen daha sonra tekrar deneyin.',
       es: 'Error de almacenamiento. Por favor inténtalo más tarde.'
     },
     [ErrorCode.ERR_6003]: {
       en: 'An unexpected error occurred. Please try again.',
       tr: 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.',
       es: 'Ocurrió un error inesperado. Por favor inténtalo de nuevo.'
     }
   }
   ```

2. **Create Error Response Builder**

   File: `supabase/functions/_shared/error-response.ts`

   ```typescript
   import { ErrorCode, ErrorMessages } from './error-codes.ts'

   interface ErrorResponseOptions {
     code: ErrorCode
     language?: 'en' | 'tr' | 'es'
     variables?: Record<string, string | number>
     details?: any
   }

   export function createErrorResponse(options: ErrorResponseOptions): Response {
     const {
       code,
       language = 'en',
       variables = {},
       details
     } = options

     let message = ErrorMessages[code][language] || ErrorMessages[code]['en']

     // Replace variables in message
     Object.entries(variables).forEach(([key, value]) => {
       message = message.replace(`{${key}}`, String(value))
     })

     const statusCode = getStatusCode(code)

     return new Response(
       JSON.stringify({
         error: {
           code,
           message,
           details
         }
       }),
       {
         status: statusCode,
         headers: { 'Content-Type': 'application/json' }
       }
     )
   }

   function getStatusCode(code: ErrorCode): number {
     if (code.startsWith('ERR_4')) return 400
     if (code.startsWith('ERR_5')) return 502
     if (code.startsWith('ERR_6')) return 500
     return 500
   }
   ```

3. **Update Endpoints to Use Error System**

   Update `generate-video/index.ts`:

   ```typescript
   import { createErrorResponse } from '../_shared/error-response.ts'
   import { ErrorCode } from '../_shared/error-codes.ts'

   // Get user's preferred language
   const userLanguage = req.headers.get('Accept-Language')?.split(',')[0]?.substring(0, 2) || 'en'
   const language = ['en', 'tr', 'es'].includes(userLanguage) ? userLanguage : 'en'

   // Check credits
   if (!deductResult.success) {
     return createErrorResponse({
       code: ErrorCode.ERR_4001,
       language,
       variables: {
         required: model.cost_per_generation,
         available: deductResult.current_credits || 0
       }
     })
   }
   ```

4. **Add Error Log Table**

   Create migration: `supabase/migrations/006_create_error_log.sql`

   ```sql
   CREATE TABLE IF NOT EXISTS error_log (
     id BIGSERIAL PRIMARY KEY,
     user_id UUID REFERENCES users(id),
     error_code TEXT NOT NULL,
     endpoint TEXT NOT NULL,
     request_data JSONB,
     error_details JSONB,
     created_at TIMESTAMPTZ DEFAULT now()
   );

   CREATE INDEX idx_error_code ON error_log(error_code);
   CREATE INDEX idx_error_user ON error_log(user_id, created_at DESC);
   ```

#### Deliverables:
- ✅ Standardized error codes (ERR_4xxx, ERR_5xxx, ERR_6xxx)
- ✅ Localized messages (en, tr, es)
- ✅ Error response builder utility
- ✅ Error logging to database

---

### Phase 8: IP-Based Rate Limiting (2 days) 🛡️

**Goal:** Implement rate limiting to prevent abuse and credit farming

**Why:** Prevent malicious users from spamming API endpoints

#### Tasks:

1. **Add Rate Limit Table**

   Create migration: `supabase/migrations/007_create_rate_limit.sql`

   ```sql
   CREATE TABLE IF NOT EXISTS rate_limit_log (
     id BIGSERIAL PRIMARY KEY,
     ip_address INET NOT NULL,
     action TEXT NOT NULL, -- 'video_generation', 'credit_purchase', etc.
     user_id UUID REFERENCES users(id),
     created_at TIMESTAMPTZ DEFAULT now()
   );

   CREATE INDEX idx_rate_limit_ip_action ON rate_limit_log(ip_address, action, created_at);

   -- Auto-cleanup old rate limit logs (keep 7 days)
   CREATE OR REPLACE FUNCTION cleanup_rate_limit_logs()
   RETURNS void AS $$
   BEGIN
     DELETE FROM rate_limit_log
     WHERE created_at < now() - INTERVAL '7 days';
   END;
   $$ LANGUAGE plpgsql;
   ```

2. **Create Rate Limit Middleware**

   File: `supabase/functions/_shared/rate-limiter.ts`

   ```typescript
   interface RateLimitConfig {
     action: string
     maxRequests: number
     windowMinutes: number
   }

   export async function checkRateLimit(
     req: Request,
     config: RateLimitConfig,
     supabaseClient: any
   ): Promise<{ allowed: boolean; retryAfter?: number }> {

     // Get client IP (handle proxies)
     const forwardedFor = req.headers.get('X-Forwarded-For')
     const ip = forwardedFor ? forwardedFor.split(',')[0].trim() :
                req.headers.get('CF-Connecting-IP') || '0.0.0.0'

     // Count recent requests
     const windowStart = new Date(Date.now() - config.windowMinutes * 60 * 1000)

     const { count, error } = await supabaseClient
       .from('rate_limit_log')
       .select('*', { count: 'exact', head: true })
       .eq('ip_address', ip)
       .eq('action', config.action)
       .gte('created_at', windowStart.toISOString())

     if (error) throw error

     if (count >= config.maxRequests) {
       // Calculate retry-after seconds
       const oldestRequest = await supabaseClient
         .from('rate_limit_log')
         .select('created_at')
         .eq('ip_address', ip)
         .eq('action', config.action)
         .gte('created_at', windowStart.toISOString())
         .order('created_at', { ascending: true })
         .limit(1)
         .single()

       const retryAfter = Math.ceil(
         (new Date(oldestRequest.data.created_at).getTime() +
         config.windowMinutes * 60 * 1000 -
         Date.now()) / 1000
       )

       return { allowed: false, retryAfter }
     }

     // Log this request
     await supabaseClient.from('rate_limit_log').insert({
       ip_address: ip,
       action: config.action
     })

     return { allowed: true }
   }
   ```

3. **Update Endpoints with Rate Limiting**

   Update `generate-video/index.ts`:

   ```typescript
   import { checkRateLimit } from '../_shared/rate-limiter.ts'
   import { createErrorResponse } from '../_shared/error-response.ts'
   import { ErrorCode } from '../_shared/error-codes.ts'

   serve(async (req) => {
     try {
       const supabaseClient = createClient(
         Deno.env.get('SUPABASE_URL')!,
         Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
       )

       // Check rate limit: max 10 video generations per hour
       const rateLimitCheck = await checkRateLimit(
         req,
         {
           action: 'video_generation',
           maxRequests: 10,
           windowMinutes: 60
         },
         supabaseClient
       )

       if (!rateLimitCheck.allowed) {
         return createErrorResponse({
           code: ErrorCode.ERR_4004,
           variables: { seconds: rateLimitCheck.retryAfter },
           details: { retry_after: rateLimitCheck.retryAfter }
         })
       }

       // Continue with video generation...
     } catch (error) {
       // ... error handling
     }
   })
   ```

4. **Add Rate Limit Headers**

   ```typescript
   // Add rate limit info to response headers
   return new Response(JSON.stringify(responseBody), {
     headers: {
       'Content-Type': 'application/json',
       'X-RateLimit-Limit': String(config.maxRequests),
       'X-RateLimit-Remaining': String(config.maxRequests - currentCount),
       'X-RateLimit-Reset': new Date(resetTime).toISOString()
     }
   })
   ```

#### Deliverables:
- ✅ IP-based rate limiting (10 videos/hour)
- ✅ Rate limit headers in responses
- ✅ Auto-cleanup of old logs (7 day retention)
- ✅ Configurable limits per endpoint

---

### Phase 9: Admin Tools (3-4 days) 🔧

**Goal:** Build admin-only endpoints for managing users, credits, and models

**Why:** Allow support team to issue refunds, manage models, and view user stats

#### Tasks:

1. **Create Admin Actions Table**

   Create migration: `supabase/migrations/008_create_admin_tables.sql`

   ```sql
   CREATE TABLE IF NOT EXISTS admin_actions (
     id BIGSERIAL PRIMARY KEY,
     admin_user_id UUID NOT NULL REFERENCES users(id),
     action_type TEXT NOT NULL CHECK (action_type IN (
       'credit_refund',
       'credit_adjustment',
       'model_disable',
       'model_enable',
       'user_ban',
       'user_unban'
     )),
     target_user_id UUID REFERENCES users(id),
     target_model_id UUID REFERENCES models(id),
     amount INTEGER, -- For credit adjustments
     reason TEXT NOT NULL,
     details JSONB DEFAULT '{}',
     created_at TIMESTAMPTZ DEFAULT now()
   );

   CREATE INDEX idx_admin_actions_admin ON admin_actions(admin_user_id, created_at DESC);
   CREATE INDEX idx_admin_actions_target_user ON admin_actions(target_user_id, created_at DESC);

   -- Add admin flag to users table
   ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT false;
   ```

2. **Create Admin Authentication Middleware**

   File: `supabase/functions/_shared/admin-auth.ts`

   ```typescript
   export async function requireAdmin(
     req: Request,
     supabaseClient: any
   ): Promise<{ admin: any }> {

     const authHeader = req.headers.get('Authorization')

     if (!authHeader) {
       throw new Error('Missing Authorization header')
     }

     const token = authHeader.replace('Bearer ', '')

     // Get user from token
     const { data: { user }, error } = await supabaseClient.auth.getUser(token)

     if (error || !user) {
       throw new Error('Invalid token')
     }

     // Check if user is admin
     const { data: userData } = await supabaseClient
       .from('users')
       .select('is_admin')
       .eq('id', user.id)
       .single()

     if (!userData?.is_admin) {
       throw new Error('Admin access required')
     }

     return { admin: user }
   }
   ```

3. **Create Manual Credit Refund Endpoint**

   File: `supabase/functions/admin-refund-credits/index.ts`

   ```typescript
   import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
   import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
   import { requireAdmin } from '../_shared/admin-auth.ts'

   serve(async (req) => {
     try {
       const supabaseClient = createClient(
         Deno.env.get('SUPABASE_URL')!,
         Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
       )

       // Verify admin
       const { admin } = await requireAdmin(req, supabaseClient)

       const { user_id, amount, reason } = await req.json()

       // Add credits
       const { data: result } = await supabaseClient.rpc('add_credits', {
         p_user_id: user_id,
         p_amount: amount,
         p_reason: `admin_refund: ${reason}`
       })

       if (!result.success) {
         return new Response(
           JSON.stringify({ error: result.error }),
           { status: 400 }
         )
       }

       // Log admin action
       await supabaseClient.from('admin_actions').insert({
         admin_user_id: admin.id,
         action_type: 'credit_refund',
         target_user_id: user_id,
         amount: amount,
         reason: reason
       })

       return new Response(
         JSON.stringify({
           success: true,
           new_balance: result.credits_remaining
         }),
         { headers: { 'Content-Type': 'application/json' } }
       )

     } catch (error) {
       return new Response(
         JSON.stringify({ error: error.message }),
         { status: error.message.includes('Admin') ? 403 : 500 }
       )
     }
   })
   ```

4. **Create Model Management Endpoints**

   File: `supabase/functions/admin-toggle-model/index.ts`

   ```typescript
   import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
   import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
   import { requireAdmin } from '../_shared/admin-auth.ts'

   serve(async (req) => {
     try {
       const supabaseClient = createClient(
         Deno.env.get('SUPABASE_URL')!,
         Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
       )

       const { admin } = await requireAdmin(req, supabaseClient)

       const { model_id, is_available, reason } = await req.json()

       // Update model
       const { error } = await supabaseClient
         .from('models')
         .update({ is_available })
         .eq('id', model_id)

       if (error) throw error

       // Log admin action
       await supabaseClient.from('admin_actions').insert({
         admin_user_id: admin.id,
         action_type: is_available ? 'model_enable' : 'model_disable',
         target_model_id: model_id,
         reason: reason
       })

       return new Response(
         JSON.stringify({ success: true }),
         { headers: { 'Content-Type': 'application/json' } }
       )

     } catch (error) {
       return new Response(
         JSON.stringify({ error: error.message }),
         { status: 500 }
       )
     }
   })
   ```

5. **Create User Stats Endpoint**

   File: `supabase/functions/admin-user-stats/index.ts`

   ```typescript
   import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
   import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
   import { requireAdmin } from '../_shared/admin-auth.ts'

   serve(async (req) => {
     try {
       const supabaseClient = createClient(
         Deno.env.get('SUPABASE_URL')!,
         Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
       )

       await requireAdmin(req, supabaseClient)

       const url = new URL(req.url)
       const user_id = url.searchParams.get('user_id')

       if (!user_id) {
         return new Response(
           JSON.stringify({ error: 'user_id required' }),
           { status: 400 }
         )
       }

       // Get user info
       const { data: user } = await supabaseClient
         .from('users')
         .select('*')
         .eq('id', user_id)
         .single()

       // Get video job stats
       const { data: jobs, count: totalJobs } = await supabaseClient
         .from('video_jobs')
         .select('*', { count: 'exact' })
         .eq('user_id', user_id)

       const completedJobs = jobs?.filter(j => j.status === 'completed').length || 0
       const failedJobs = jobs?.filter(j => j.status === 'failed').length || 0

       // Get credit transaction history
       const { data: transactions } = await supabaseClient
         .from('quota_log')
         .select('*')
         .eq('user_id', user_id)
         .order('created_at', { ascending: false })
         .limit(20)

       return new Response(
         JSON.stringify({
           user,
           stats: {
             total_jobs: totalJobs,
             completed_jobs: completedJobs,
             failed_jobs: failedJobs,
             success_rate: totalJobs > 0 ? (completedJobs / totalJobs * 100).toFixed(2) : 0
           },
           recent_transactions: transactions
         }),
         { headers: { 'Content-Type': 'application/json' } }
       )

     } catch (error) {
       return new Response(
         JSON.stringify({ error: error.message }),
         { status: error.message.includes('Admin') ? 403 : 500 }
       )
     }
   })
   ```

#### Deliverables:
- ✅ Admin authentication middleware
- ✅ Manual credit refund endpoint
- ✅ Model enable/disable endpoint
- ✅ User stats viewer endpoint
- ✅ Admin action logging

---

## 📊 Implementation Timeline (Smart MVP + Production Features)

### MVP Timeline (Phases 0-4)

| Phase | Duration | Priority | Key Features | Dependencies |
|-------|----------|----------|--------------|--------------|
| Phase 0: Setup | 2-3 days | P0 (Critical) | Database schema, stored procedures, idempotency table | None |
| **Phase 0.5: Security** | **2 days** | **P0 (Critical)** | **Real IAP/DeviceCheck, anonymous auth, token refresh** | **Phase 0** |
| Phase 1: Core APIs | 3-4 days | P0 (Critical) | DeviceCheck, credits, Apple IAP validation | Phase 0.5 |
| Phase 2: Video Generation | 4-5 days | P0 (Critical) | Idempotency, rollback, FalAI integration | Phase 1 |
| Phase 3: History & User | 2 days | P1 (High) | History, models, profile | Phase 1 |
| Phase 4: Integration | 3-4 days | P0 (Critical) | Testing, edge cases, security audit | Phase 2, 3 |

**MVP Total:** 16-20 days (~3-4 weeks)

---

### Production Features Timeline (Phases 5-9)

| Phase | Duration | Priority | Key Features | Dependencies |
|-------|----------|----------|--------------|--------------|
| Phase 5: Webhooks | 3-4 days | P1 (High) | HMAC validation, APNs push, replace polling | Phase 4 |
| Phase 6: Retry Logic | 2-3 days | P1 (High) | Exponential backoff, timeout handling | Phase 2 |
| Phase 7: Error Handling i18n | 2-3 days | P1 (High) | Error codes, localized messages (en/tr/es) | Phase 2 |
| Phase 8: Rate Limiting | 2 days | P1 (High) | IP-based limits, auto-cleanup | Phase 1 |
| Phase 9: Admin Tools | 3-4 days | P2 (Medium) | Credit refunds, model management, user stats | Phase 1 |

**Production Features Total:** 12-16 days (~2-3 weeks)

---

**Grand Total Estimated Time:** 28-36 days (~5-7 weeks)

**Timeline Comparison:**
- Original Plan (MVP only): 14-18 days
- Smart MVP with Security (Phases 0-4): 16-20 days
- **Smart MVP + Production Features (Phases 0-9): 28-36 days**
- Full Production with all optimizations (Option A): 22-24 days (see `backend-building-plan-production.md`)

---

## 🎯 Success Criteria

After completing all phases, you should have:

### ✅ **Working Backend:**
- All 10+ endpoints functional
- Database with proper RLS
- **Stored procedures for atomic operations**
- **Idempotency protection**
- **Rollback on failure**
- Storage configured
- Authentication working

### ✅ **iOS App Connected:**
- All mock services replaced
- Real API calls working
- **Idempotency keys sent with requests**
- Error handling working
- **Rollback handling**
- Offline handling graceful

### ✅ **Production Ready:**
- **No double-charging (idempotency works)**
- **No race conditions (atomic operations)**
- **Modern Apple IAP validation**
- Security tested
- Performance acceptable
- Error logging working
- Monitoring set up

---

## ⚠️ Known Limitations (MVP Trade-offs)

This Smart MVP (Option B) prioritizes **shipping fast with security**. These optimizations are intentionally deferred:

### 🟡 Performance Limitations (Works for 1K-10K users)

#### 1. **Polling Instead of Realtime**
**Current:** iOS polls `/get-video-status` every 2-4 seconds  
**Impact:** Higher API costs, battery drain  
**When to Fix:** When monthly costs exceed $100 or users complain about battery  
**Solution:** Migrate to Supabase Realtime subscriptions (see `backend-building-plan-production.md`)

#### 2. **No ETag Caching for Models**
**Current:** Fetches all models from database every time  
**Impact:** Unnecessary bandwidth, slower app  
**When to Fix:** When you have 50+ models or users in low-bandwidth areas  
**Solution:** Add ETag headers + conditional requests (saves 90% bandwidth)

#### 3. **No Idempotency Log Cleanup**
**Current:** `idempotency_log` table grows forever  
**Impact:** After 1 month with 10K daily requests = 300K rows (slower queries)  
**When to Fix:** When query time > 200ms or table size > 1GB  
**Solution:** Add daily cron job to delete expired records

#### 4. **Simple Polling Interval**
**Current:** Fixed 2-4 second intervals  
**Impact:** Wastes API calls for long-running videos (5+ min)  
**When to Fix:** When API costs scale with user count  
**Solution:** Exponential backoff (2s → 4s → 8s → 30s max)

---

### 🟢 Data Limitations (Non-Critical)

#### 5. **No Request Rate Limiting**
**Current:** Users can spam video generation requests  
**Impact:** Potential abuse, but credits provide natural rate limit  
**When to Fix:** When you detect abuse patterns in logs  
**Solution:** Add rate limiting at Edge Function level (10 requests/minute)

#### 6. **No Database Connection Pooling**
**Current:** Supabase handles this automatically  
**Impact:** None for MVP, but limits scale to ~100 concurrent users  
**When to Fix:** When concurrent users > 500  
**Solution:** Use Supavisor or PgBouncer

---

### 🔵 Nice-to-Have Features (Post-Launch)

#### 7. **No Video Storage Cleanup**
**Current:** Old videos stay in storage forever  
**Impact:** Storage costs grow indefinitely ($0.021/GB/month)  
**When to Fix:** When storage costs > $50/month  
**Solution:** Delete videos older than 90 days (with user option to keep favorites)

#### 8. **Basic Structured Logging**
**Current:** Simple `console.log()` statements  
**Impact:** Hard to debug production issues  
**When to Fix:** When you have your first production incident  
**Solution:** Integrate Sentry/Datadog for real-time error tracking

---

### 📊 Scale Projections

**Smart MVP can handle:**
- ✅ 1,000 monthly active users
- ✅ 10,000 video generations/month
- ✅ ~$50-100/month infrastructure costs

**Needs optimization at:**
- ⚠️ 10,000+ monthly active users
- ⚠️ 100,000+ video generations/month
- ⚠️ $500+/month infrastructure costs

**When you hit these limits:** Migrate to Option A (`backend-building-plan-production.md`)

---

## ✅ Production Readiness Checklist

Before deploying to production, verify all items:

### 🔒 Security

- [ ] All endpoints validate JWT tokens
- [ ] RLS policies tested with unauthorized access attempts
- [ ] Apple IAP receipts validated server-side (not client-side)
- [ ] DeviceCheck tokens verified with Apple's API
- [ ] No API keys exposed in client code
- [ ] Service role key only used in backend, never exposed
- [ ] Stored procedures use `SECURITY DEFINER` safely

### 💪 Reliability

- [ ] **Idempotency keys implemented for video generation**
- [ ] **Idempotency keys implemented for credit purchases**
- [ ] **Credit deduction uses atomic stored procedures**
- [ ] **Rollback logic tested for failed video generations**
- [ ] Database transactions use `FOR UPDATE` locks
- [ ] Duplicate transaction prevention working (IAP)
- [ ] Duplicate operation prevention working (idempotency)

### 🎬 Video Processing

- [ ] Video generation creates job in database
- [ ] Provider API calls handle timeouts
- [ ] Failed generation refunds credits automatically
- [ ] Video files stored with proper permissions
- [ ] Status polling works correctly
- [ ] Provider job IDs tracked in database

### 📊 Monitoring

- [ ] Structured logging implemented
- [ ] Key metrics tracked: credits deducted, videos generated, failures
- [ ] Errors logged with context
- [ ] Critical alerts configured

### ⚡ Performance

- [ ] Database indexes created on frequently queried columns
- [ ] Stored procedures tested with concurrent requests
- [ ] Pagination implemented for history endpoints
- [ ] Query performance acceptable (< 100ms for most queries)

### 📚 Documentation

- [ ] Environment variables documented
- [ ] API endpoints documented with examples
- [ ] Deployment procedure documented
- [ ] Rollback procedure documented
- [ ] Database migration procedure documented

---

## 🚀 Production Features (Phases 5-9)

**Note:** These features were previously listed as "Optional Phase 2 Features (Future)". They are now fully documented as **Phases 5-9** with complete implementation details above.

### ✅ Now Documented (See Phases 5-9):

- **✅ Webhook System** → Phase 5: Replace polling with event-driven webhooks + APNs push
- **✅ Retry Logic** → Phase 6: Exponential backoff for external API calls
- **✅ Error Handling i18n** → Phase 7: Standardized error codes with localized messages
- **✅ Rate Limiting** → Phase 8: IP-based rate limiting with auto-cleanup
- **✅ Admin Tools** → Phase 9: Credit refunds, model management, user stats

### 🔮 Future Enhancements (Post Phase 9)

These features can be added after completing Phases 0-9:

#### Advanced Monitoring & Observability
- Integrate Sentry for real-time error tracking
- Set up Datadog or similar for metrics dashboard
- Create admin dashboard with Grafana for system monitoring
- Add distributed tracing with OpenTelemetry

#### Video Storage Optimization
- Implement CDN caching (CloudFlare/Fastly)
- Add video compression pipeline
- Implement storage cleanup for old videos (90-day retention)
- Add video quality transcoding options

#### Performance Optimizations
- Database connection pooling (PgBouncer/Supavisor)
- Read replicas for analytics queries
- Redis caching layer for frequently accessed data
- ETag/conditional requests for model listings

---

## 📚 Key Documents Reference

- **API Blueprint:** `docs/active/design/backend/api-layer-blueprint.md`
- **Database Schema:** `docs/active/design/database/data-schema-final.md`
- **Integration Rules:** `docs/active/design/backend/backend-integration-rulebook.md`
- **Provider Adapters:** `docs/active/design/backend/api-adapter-interface.md`
- **Frontend Integration Plan:** `backend/implementation/phase1-backend-integration-plan.md`

---

## 🚀 Next Steps

### Path 1: MVP Launch (Phases 0-4: 16-20 days)

**Goal:** Launch with core features and security

1. **Review this plan** - Understand Phase 0.5 security requirements
2. **Get Apple credentials** - IAP keys + DeviceCheck keys
3. **Set up Supabase project** - Create account and project
4. **Start Phase 0** - Database setup with stored procedures
5. **Complete Phase 0.5** - Implement real security (IAP + DeviceCheck)
6. **Build Phases 1-4** - Follow the plan sequentially
7. **Test end-to-end** - Verify security + basic features work
8. **Launch MVP** - Deploy to production and monitor

### Path 2: Production Features (Phases 5-9: +12-16 days)

**Goal:** Add production-grade features for scale and reliability

9. **Monitor MVP metrics** - Track API costs, user complaints, query times
10. **Implement Phase 5** - Webhook system to replace polling
11. **Implement Phase 6** - Retry logic for external APIs
12. **Implement Phase 7** - Error handling with i18n (en/tr/es)
13. **Implement Phase 8** - IP-based rate limiting
14. **Implement Phase 9** - Admin tools for support team
15. **Test production features** - Verify all new functionality
16. **Deploy production features** - Roll out to users

### Path 3: Advanced Optimizations (When Needed)

**Goal:** Scale to 10K+ users with advanced performance features

17. **Monitor metrics** - Track API costs, query times, user complaints
18. **Identify bottlenecks** - Use "Known Limitations" section as guide
19. **Implement advanced monitoring** - Sentry, Datadog, Grafana
20. **Add performance optimizations** - Connection pooling, caching, CDN
21. **Consider Option A migration** - If needed, see `backend-building-plan-production.md`

---

## 💡 Backend Plan Features Summary

This comprehensive plan includes:

### ✅ **Core MVP Features (Phases 0-4)**

**Security (Production-Grade):**
1. **🔐 Real Apple IAP Verification** - App Store Server API v2 (NOT mocked)
2. **🛡️ Real DeviceCheck** - Prevents credit farming
3. **🔑 Anonymous JWT for Guests** - Enables RLS + Realtime
4. **🔄 Token Auto-Refresh** - Prevents unexpected logouts

**Reliability (MVP-Level):**
5. **⚛️ Atomic Operations** - Database stored procedures prevent race conditions
6. **🔄 Idempotency** - Prevents double-charging if user retries
7. **🔙 Rollback Logic** - Credits refunded if generation fails
8. **📊 Audit Trail** - `balance_after` field tracks all changes

### ✅ **Production Features (Phases 5-9)**

**Event-Driven Architecture:**
9. **🔔 Webhook System** - Replace polling with real-time webhooks + APNs push
10. **🔐 HMAC Signature Validation** - Secure webhook processing
11. **🔄 Webhook Idempotency** - Prevent duplicate event processing

**Reliability & Error Handling:**
12. **🔄 Exponential Backoff** - Smart retry logic (2s → 4s → 8s → 30s max)
13. **⏱️ Timeout Handling** - Graceful failure for slow providers
14. **🌍 Internationalized Errors** - Localized messages (en/tr/es)
15. **📝 Standardized Error Codes** - ERR_4xxx, ERR_5xxx, ERR_6xxx system

**Security & Admin:**
16. **🛡️ IP-Based Rate Limiting** - Prevent abuse (10 videos/hour)
17. **🔧 Admin Tools** - Credit refunds, model management, user stats
18. **📊 Admin Action Logging** - Full audit trail for support actions

### ⚠️ **Known Limitations (For MVP Phase Only)**

These are deferred in Phases 0-4, but addressed in Phases 5-9:
- ~~Realtime subscriptions (use polling for now)~~ → **✅ Fixed in Phase 5 (Webhooks)**
- ~~No retry logic~~ → **✅ Fixed in Phase 6 (Exponential Backoff)**
- ~~No error handling~~ → **✅ Fixed in Phase 7 (Error i18n)**
- ~~No rate limiting~~ → **✅ Fixed in Phase 8 (IP Rate Limiting)**
- ETag caching (fetch models every time for now) → **Future enhancement**
- Idempotency cleanup (table grows, but fine for MVP) → **Future enhancement**

**Result:**
- **Phases 0-4:** Secure MVP that can accept payments + scale to 1K users
- **Phases 5-9:** Production-ready system that scales to 10K+ users with admin support

---

## 🎯 Decision Guide: When to Migrate to Option A?

| Metric | MVP Threshold | Production Upgrade Needed |
|--------|---------------|--------------------------|
| Monthly Active Users | < 10,000 | ✅ Stay on Option B |
| Video Generations/Month | < 100,000 | ✅ Stay on Option B |
| Monthly Infrastructure Costs | < $500 | ✅ Stay on Option B |
| API Response Time (95th percentile) | < 2 seconds | ✅ Stay on Option B |
| Database Query Time | < 200ms | ✅ Stay on Option B |
| User Complaints About Battery | Rare | ✅ Stay on Option B |

**When ANY metric exceeds threshold:** Implement optimizations from `backend-building-plan-production.md`

---

**Questions?** Review the detailed documentation in `docs/active/design/backend/` folder.

**Ready to start?** Begin with Phase 0: Setup & Infrastructure.

**Need more performance?** See `backend-building-plan-production.md` for Option A.

---

**Document Status:** ✅ Ready for Implementation (Complete Edition - Phases 0-9)
**Last Updated:** 2025-11-05
**Version:** 3.0 (MVP + Production Features)
**Includes:**
- ✅ Smart MVP with Security (Phases 0-4): 16-20 days
- ✅ Production Features (Phases 5-9): 12-16 days
- ✅ Webhooks, Retry Logic, Error i18n, Rate Limiting, Admin Tools
**Alternative:** See `backend-building-plan-production.md` for advanced optimizations
