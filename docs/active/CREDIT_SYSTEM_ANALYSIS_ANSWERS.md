# Credit System Analysis - Answers

**Based on:** RendioAI codebase analysis  
**Date:** 2025-11-08

---

## 🎯 Priority Questions (Quick Answers)

1. **Where are credits stored?** → `users` table (`credits_remaining`, `credits_total`) + `quota_log` table (audit trail)
2. **How are credits deducted?** → Backend atomically via `generate_video_atomic()` stored procedure (FOR UPDATE lock)
3. **How are credits initialized?** → On device check (first app launch) via `device-check` Edge Function → grants 10 credits
4. **How does frontend sync with backend?** → Fetches on app launch, before operations, and after credit changes
5. **What happens on errors?** → Network failures: show error, keep cached. Insufficient credits: show error (402 status), block operation

---

## 1. Credit Initialization & Setup

### When are credits first granted?

- [x] **On device check** (first app launch)
- [ ] On app install?
- [ ] On first app launch? (same as device check)
- [ ] On user signup/registration?
- [ ] Other: _______________

**Details:**
- Credits are granted when `device-check` Edge Function is called
- This happens during onboarding flow when app first launches
- See: `RendioAI/supabase/functions/device-check/index.ts` lines 108-140

### How many credits are granted initially?

- [x] **Fixed amount: 10 credits**
- [ ] Variable based on user type
- [ ] Promotional amount
- [ ] Other: _______________

**Details:**
- All new users get exactly 10 credits
- See: `device-check/index.ts` line 137: `p_amount: 10`

### Where is the initial grant handled?

- [ ] Frontend (iOS app)
- [x] **Backend (Edge Function)**
- [x] **Database trigger/function** (stored procedure)
- [ ] Other: _______________

**Details:**
- `device-check` Edge Function creates user, then calls `add_credits()` stored procedure
- This ensures proper audit trail and atomic operation
- See: `device-check/index.ts` lines 135-140

---

## 2. Credit Storage & Database

### What database tables store credits?

- [x] **Integrated in users table** (`credits_remaining`, `credits_total`)
- [ ] Single table (e.g., `user_credits`)
- [ ] Separate tables for authenticated vs anonymous
- [ ] Other: _______________

**Details:**
- `users` table has: `credits_remaining` (current balance), `credits_total` (lifetime total)
- Both authenticated and anonymous users use same table structure
- See: `20251105000001_create_tables.sql` lines 17-18

### What columns exist in credit table(s)?

- [x] **`user_id`** (via `id` UUID primary key)
- [x] **`credits_remaining`** (current balance)
- [x] **`credits_total`** (lifetime total)
- [x] **`created_at`** / **`updated_at`**
- [x] **`initial_grant_claimed`** (boolean flag)
- [ ] `device_id` (separate column, not for credits)
- [ ] Other: _______________

**Details:**
- See: `20251105000001_create_tables.sql` lines 10-25

### Is there a transaction/audit log table?

- [x] **Yes - table name: `quota_log`**
- [ ] No
- [ ] Logs in same table
- [ ] Other: _______________

**Details:**
- `quota_log` table tracks all credit changes
- Columns: `user_id`, `job_id`, `change` (amount), `reason`, `transaction_id`, `balance_after`, `created_at`
- See: `20251105000001_create_tables.sql` lines 100-120

---

## 3. Credit Deduction Flow

### When are credits deducted?

- [ ] Before API call (optimistic)
- [ ] After API call succeeds
- [x] **Atomically in database function** (as part of job creation)
- [ ] Other: _______________

**Details:**
- Credits are deducted atomically when creating video job via `generate_video_atomic()` stored procedure
- This happens in a single transaction: check credits → deduct → create job
- See: `20251108000004_fix_atomic_generate_video.sql` lines 27-100

### How is deduction handled?

- [ ] Frontend subtracts, then backend validates
- [x] **Backend deducts atomically (single source of truth)**
- [ ] Both frontend and backend deduct
- [ ] Other: _______________

**Details:**
- Frontend checks credits before calling API (optimistic check)
- But actual deduction happens in backend stored procedure with row locking
- Frontend never directly modifies credits
- See: `ModelDetailViewModel.swift` line 186 (frontend check) vs `generate-video/index.ts` line 265 (backend atomic deduction)

### What happens if deduction fails?

- [x] **Show error, don't deduct** (transaction rolls back)
- [ ] Retry automatically
- [ ] Refund if already deducted
- [ ] Other: _______________

**Details:**
- If insufficient credits, stored procedure raises exception
- Transaction rolls back automatically (no deduction, no job created)
- Frontend receives 402 status with error message
- See: `generate-video/index.ts` lines 286-299

### Is there idempotency protection?

- [x] **Yes - how: `idempotency_log` table with UUID keys**
- [ ] No
- [ ] Only for purchases
- [ ] Other: _______________

**Details:**
- Each video generation request includes `idempotency_key` (UUID)
- Backend checks `idempotency_log` table before processing
- If key exists, returns cached response (prevents double-charging)
- See: `20251108000004_fix_atomic_generate_video.sql` lines 64-93

---

## 4. Credit Addition (Purchases/Grants)

### How are credits added?

- [x] **In-app purchases (IAP)** - Apple StoreKit
- [x] **Admin grants** - via `add_credits()` stored procedure
- [ ] Promotional codes (not implemented)
- [x] **Initial grant** - via `device-check` endpoint
- [ ] Refunds (not implemented, but could use `add_credits()`)
- [ ] Other: _______________

**Details:**
- IAP: `update-credits` Edge Function verifies Apple transaction, then calls `add_credits()`
- Initial grant: `device-check` calls `add_credits()` with reason 'initial_grant'
- See: `update-credits/index.ts` and `device-check/index.ts`

### Where is purchase validation handled?

- [ ] Frontend (StoreKit)
- [x] **Backend (Edge Function)** - verifies with Apple App Store Server API
- [ ] Both (frontend + backend verification)
- [ ] Other: _______________

**Details:**
- Frontend initiates purchase via StoreKit
- Backend verifies transaction with Apple's API
- Backend determines credit amount (never trusts client)
- See: `update-credits/index.ts` lines 67-86

### What happens on purchase success?

- [ ] Credits added immediately
- [x] **Credits added after verification** (backend verifies first)
- [ ] Credits queued for processing
- [ ] Other: _______________

**Details:**
- Backend verifies transaction with Apple
- Only then calls `add_credits()` stored procedure
- Duplicate transaction prevention via `transaction_id` unique constraint
- See: `update-credits/index.ts` lines 103-134

---

## 5. Credit Validation & Checks

### When are credits checked?

- [x] **Before showing generate button** (frontend check)
- [x] **Before API call** (frontend check via `hasSufficientCredits()`)
- [x] **In backend before processing** (stored procedure checks)
- [x] **All of the above**
- [ ] Other: _______________

**Details:**
- Frontend: `ModelDetailViewModel.swift` line 186 checks before allowing generation
- Backend: `generate_video_atomic()` checks credits before deducting (line 41-43)
- Multiple layers prevent insufficient credit operations

### How is "insufficient credits" handled?

- [x] **Show error message** (402 status code)
- [ ] Show paywall
- [ ] Disable button (frontend does this, but backend also validates)
- [ ] Other: _______________

**Details:**
- Frontend: Button disabled if insufficient credits (UI check)
- Backend: Returns 402 status with error message if insufficient
- See: `generate-video/index.ts` lines 286-299

### Is there a minimum credit threshold?

- [ ] Yes - amount: _______________
- [x] **No** (any positive balance allows operations)
- [ ] Only for certain features
- [ ] Other: _______________

**Details:**
- No minimum threshold - if credits >= cost, operation proceeds
- Cost varies by model and settings

---

## 6. Frontend/Backend Sync

### How does frontend know credit balance?

- [x] **Fetches from backend on app launch**
- [x] **Fetches before each operation**
- [ ] Backend returns balance in API responses (sometimes, but not consistently)
- [ ] Cached locally, synced periodically
- [ ] Other: _______________

**Details:**
- `CreditService.fetchCredits()` calls `get-user-credits` endpoint
- Called on app launch, before operations, after credit changes
- See: `CreditService.swift` lines 28-78

### How often is balance synced?

- [ ] On app launch only
- [x] **Before each credit operation** (via `hasSufficientCredits()`)
- [ ] Periodically in background
- [x] **On app foreground** (if implemented in app lifecycle)
- [ ] Other: _______________

**Details:**
- Frontend fetches credits before each generation attempt
- Also fetches after credit purchases
- See: `ModelDetailViewModel.swift` line 186

### What happens if frontend and backend are out of sync?

- [x] **Frontend always trusts backend** (backend is source of truth)
- [ ] Frontend shows cached value, syncs in background
- [ ] Error shown, force refresh
- [ ] Other: _______________

**Details:**
- Frontend checks credits optimistically (for UX)
- But backend validates and is final authority
- If frontend shows wrong balance, backend will reject operation
- Frontend then updates balance from backend response

---

## 7. Error Handling & Edge Cases

### What happens on network failure?

- [x] **Keep cached credits, show warning** (frontend shows last known balance)
- [ ] Block operations until network available
- [ ] Retry automatically
- [ ] Other: _______________

**Details:**
- Frontend may show cached balance if network fails
- But operation will fail when trying to generate (requires network)
- Error handling in `CreditService.swift` throws `AppError.networkFailure`

### What happens if user has 0 credits?

- [ ] Show paywall immediately
- [ ] Allow viewing but block generation
- [x] **Show "out of credits" message** (error alert)
- [ ] Other: _______________

**Details:**
- Generate button disabled if credits < cost
- If user somehow tries to generate, backend returns 402 error
- Frontend shows error alert
- See: `ModelDetailViewModel.swift` line 188

### What happens on duplicate requests?

- [x] **Idempotency prevents double charge** (via `idempotency_log`)
- [ ] Second request fails
- [ ] Both succeed (bug)
- [ ] Other: _______________

**Details:**
- Each request includes unique `idempotency_key`
- Backend checks `idempotency_log` before processing
- If key exists, returns cached response (no new charge)
- See: `generate-video/idempotency-service.ts`

### What happens if backend deducts but operation fails?

- [x] **Credits automatically refunded** (transaction rollback)
- [ ] Credits lost (bug)
- [ ] Manual refund required
- [ ] Other: _______________

**Details:**
- `generate_video_atomic()` runs in a transaction
- If video generation fails after deduction, entire transaction rolls back
- Credits are never lost due to atomic operations
- See: `20251108000004_fix_atomic_generate_video.sql` EXCEPTION block

---

## 8. User Experience

### How are credits displayed to user?

- [ ] Number badge in header
- [ ] On generate button
- [x] **In profile/settings** (`CreditInfoSection`)
- [x] **In model detail view** (`CreditInfoBar`)
- [ ] All of the above
- [ ] Other: _______________

**Details:**
- Profile screen: `CreditInfoSection` shows credits with buy button
- Model detail: `CreditInfoBar` shows current balance
- See: `ProfileView.swift` line 35 and `ModelDetailView.swift`

### Is there credit purchase UI?

- [x] **Yes - where: Profile screen (`PurchaseSheet`)**
- [ ] No
- [ ] Only paywall
- [ ] Other: _______________

**Details:**
- Profile screen has "Buy Credits" button
- Opens `PurchaseSheet` with IAP products
- See: `ProfileView.swift` and `PurchaseSheet.swift`

### Are there credit warnings?

- [ ] Yes - when credits < X
- [x] **No** (but UI shows balance, so user can see low credits)
- [ ] Only when 0
- [ ] Other: _______________

**Details:**
- No automatic warnings, but balance is always visible
- User can see when credits are low
- Generate button disabled if insufficient credits

---

## 9. Security & Validation

### How is credit manipulation prevented?

- [x] **Backend validates all operations** (stored procedures)
- [x] **Database constraints** (CHECK constraints, unique indexes)
- [x] **Row-level locking** (FOR UPDATE in stored procedures)
- [x] **All of the above**
- [ ] Other: _______________

**Details:**
- All credit operations go through stored procedures (`add_credits`, `deduct_credits`, `generate_video_atomic`)
- Row-level locking prevents race conditions
- Unique constraints prevent duplicate transactions
- See: `20251105000002_create_stored_procedures.sql`

### Can users see their credit history?

- [ ] Yes - in app (not implemented yet)
- [x] **No** (but `quota_log` table exists for future implementation)
- [ ] Only in database
- [ ] Other: _______________

**Details:**
- `quota_log` table tracks all transactions
- UI for viewing history not yet implemented
- Can be added in Phase 3 (History feature)

### Are there rate limits?

- [ ] Yes - how: _______________
- [x] **No** (credits provide natural limit)
- [ ] Only for purchases
- [ ] Other: _______________

**Details:**
- No explicit rate limiting
- Credits act as natural rate limit
- See: `GENERAL_TECHNICAL_DECISIONS.md` line 306-317 (rate limiting planned for Phase 8)

---

## 10. Technical Implementation

### What database functions exist?

- [ ] `get_credits()` (not a function, just SELECT query)
- [x] **`deduct_credits()`** - atomically deduct credits
- [x] **`add_credits()`** - atomically add credits
- [x] **`generate_video_atomic()`** - deduct credits + create job atomically
- [ ] `consume_credits()` (not separate, part of `generate_video_atomic`)
- [ ] Other: _______________

**Details:**
- See: `20251105000002_create_stored_procedures.sql` (deduct_credits, add_credits)
- See: `20251108000004_fix_atomic_generate_video.sql` (generate_video_atomic)

### Are there Edge Functions for credits?

- [x] **Yes - list:**
  - `get-user-credits` - fetch current balance
  - `update-credits` - process IAP purchases
  - `device-check` - initial credit grant
  - `generate-video` - uses atomic procedure for deduction
- [ ] No
- [ ] Only for purchases
- [ ] Other: _______________

**Details:**
- See: `supabase/functions/` directory

### How is concurrency handled?

- [x] **Database row locking (SELECT FOR UPDATE)**
- [ ] Optimistic locking
- [x] **Transaction isolation** (PostgreSQL transactions)
- [ ] Other: _______________

**Details:**
- `FOR UPDATE` lock in stored procedures prevents race conditions
- All operations run in transactions
- See: `20251105000002_create_stored_procedures.sql` line 24

### Is there caching?

- [ ] Yes - where: _______________
- [x] **No** (frontend fetches from backend each time)
- [ ] Only for balance display
- [ ] Other: _______________

**Details:**
- No explicit caching layer
- Frontend may cache balance in state, but always fetches before operations
- Backend is always source of truth

---

## 11. Anonymous vs Authenticated Users

### Do anonymous users get credits?

- [x] **Yes - same as authenticated** (10 credits)
- [ ] Yes - different amount
- [ ] No
- [ ] Other: _______________

**Details:**
- Both guest and authenticated users get 10 initial credits
- Same credit system for both
- See: `device-check/index.ts` line 137

### What happens when anonymous user signs up?

- [ ] Credits transfer to authenticated account
- [x] **Credits stay with device** (user_id stays same, just `is_guest` flag changes)
- [ ] Credits reset
- [ ] Other: _______________

**Details:**
- User record is updated (not replaced) when signing up
- Same `user_id` is used, just `is_guest` changes to `false`
- Credits remain with same account
- See: User model structure

### Are credits shared across devices?

- [ ] Yes - for authenticated users (not implemented - would need Apple Sign-In account linking)
- [x] **No - per device** (each device gets own user_id)
- [ ] Only for purchases
- [ ] Other: _______________

**Details:**
- Each device has unique `device_id`, creates separate user record
- Credits are per-device, not per-account
- Future: Could link devices via Apple Sign-In account

---

## 12. Testing & Monitoring

### How are credit issues debugged?

- [x] **Database queries** (check `users` and `quota_log` tables)
- [x] **Transaction logs** (`quota_log` table)
- [x] **App logs** (Edge Function logs, iOS print statements)
- [x] **All of the above**
- [ ] Other: _______________

**Details:**
- `quota_log` provides full audit trail
- Edge Functions log events via `logEvent()`
- See: `_shared/logger.ts`

### Are there admin tools?

- [ ] Yes - for what: _______________
- [x] **No** (but can use database directly or Edge Functions)
- [ ] Only database access
- [ ] Other: _______________

**Details:**
- No dedicated admin UI
- Can call `add_credits()` stored procedure directly for admin grants
- Database access for debugging

---

## 13. Migration & Compatibility

### Has the credit system changed over time?

- [x] **Yes - what changed:**
  - Initially: Separate `deduct_credits()` call before job creation
  - Now: Atomic `generate_video_atomic()` combines deduction + job creation
  - Added idempotency protection
  - Added transaction rollback on failure
- [ ] No
- [ ] Minor updates only
- [ ] Other: _______________

**Details:**
- Migration: `20251108000002_create_atomic_generate_video.sql` (initial)
- Fix: `20251108000004_fix_atomic_generate_video.sql` (corrected column names, added missing fields)
- See: Migration files

### Are there legacy systems to support?

- [ ] Yes - what: _______________
- [x] **No** (system is new, no legacy)
- [ ] Migration completed
- [ ] Other: _______________

**Details:**
- This is a new system, no legacy compatibility needed

---

## 📝 Additional Notes

### What works really well?

1. **Atomic operations** - `generate_video_atomic()` ensures credits are never lost
2. **Audit trail** - `quota_log` table provides complete transaction history
3. **Idempotency** - Prevents double-charging on duplicate requests
4. **Row-level locking** - Prevents race conditions in concurrent requests
5. **Transaction rollback** - Automatic refund if operation fails

### What are the pain points?

1. **No credit history UI** - Users can't see transaction history (but data exists)
2. **No rate limiting** - Credits provide natural limit, but no explicit rate limiting
3. **Per-device credits** - Credits don't sync across devices (by design, but could be improved)
4. **No credit warnings** - Users don't get alerts when credits are low
5. **Frontend caching** - Balance might be stale if network fails (but backend validates)

### What would you change if rebuilding?

1. **Credit history UI** - Add transaction history view in Profile screen
2. **Rate limiting** - Add explicit rate limits (e.g., 10 videos/hour) in addition to credits
3. **Cross-device sync** - Link devices via Apple Sign-In account for shared credits
4. **Credit warnings** - Add push notifications or in-app alerts when credits < 5
5. **Optimistic UI updates** - Better handling of network failures with cached balance
6. **Promotional codes** - Add support for promo codes to grant credits
7. **Credit packages** - More granular credit packages (not just IAP)

### Any special edge cases or gotchas?

1. **Idempotency key expiration** - Keys expire after 24 hours (might need longer for some use cases)
2. **Transaction ID uniqueness** - IAP transaction IDs must be unique (enforced by database constraint)
3. **Initial grant flag** - `initial_grant_claimed` flag prevents double-granting, but not used in current flow
4. **Credit cost calculation** - Cost varies by model and settings, calculated dynamically
5. **Network failure handling** - Frontend might show stale balance if network fails, but backend always validates
6. **Guest vs authenticated** - Same credit system, but only authenticated users can purchase (IAP requires sign-in)

---

## 📚 Key Files Reference

### Database
- `supabase/migrations/20251105000001_create_tables.sql` - Table definitions
- `supabase/migrations/20251105000002_create_stored_procedures.sql` - Credit functions
- `supabase/migrations/20251108000004_fix_atomic_generate_video.sql` - Atomic generation

### Backend
- `supabase/functions/device-check/index.ts` - Initial credit grant
- `supabase/functions/get-user-credits/index.ts` - Fetch balance
- `supabase/functions/update-credits/index.ts` - IAP purchases
- `supabase/functions/generate-video/index.ts` - Video generation (uses atomic procedure)

### Frontend
- `RendioAI/Core/Networking/CreditService.swift` - Credit API client
- `RendioAI/Features/ModelDetail/ModelDetailViewModel.swift` - Credit checks before generation
- `RendioAI/Features/Profile/ProfileViewModel.swift` - Credit display and purchase

---

**End of Analysis**

