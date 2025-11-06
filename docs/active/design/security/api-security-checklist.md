# API Security Checklist

**Version:** 1.0
**Date:** 2025-01-05
**Status:** Active
**Purpose:** Pre-deployment security verification for Rendio AI backend integration

---

## Overview

This checklist ensures all security measures are properly implemented before deploying backend-connected services to production. Each item must be verified and checked off before release.

**Review Frequency:**
- ✅ Before initial production deployment
- ✅ Before each major backend change
- ✅ After security incident
- ✅ Quarterly security audit

---

## 1. API Key Management

### 1.1 Key Storage
- [ ] No API keys hardcoded in source files
- [ ] No API keys in `Info.plist` (use `.xcconfig` instead)
- [ ] All `.xcconfig` files added to `.gitignore`
- [ ] Template `.xcconfig.template` files provided for team
- [ ] Supabase anon key stored in environment configuration
- [ ] FalAI API key NEVER exposed to client (server-side only)

**Verification:**
```bash
# Search for potential hardcoded keys
grep -r "sk_" RendioAI/
grep -r "apikey" RendioAI/ --exclude-dir=docs
grep -r "supabase" RendioAI/ --exclude="*.xcconfig"

# Should return no matches in source files
```

### 1.2 Key Rotation
- [ ] Process documented for rotating Supabase anon key
- [ ] Process documented for rotating FalAI key (backend)
- [ ] Old keys revoked after rotation
- [ ] App version pinning strategy if key rotation needed

**Test:** Rotate key and verify app handles gracefully

---

## 2. Authentication & Authorization

### 2.1 Token Management
- [ ] Supabase SDK handles token storage (Keychain)
- [ ] No manual token storage in UserDefaults
- [ ] No tokens logged in console (even in debug builds)
- [ ] Token refresh implemented and tested
- [ ] Session timeout handled gracefully

**Verification:**
```swift
// Check UserDefaults for leaked tokens
let defaults = UserDefaults.standard.dictionaryRepresentation()
// Verify no keys like "auth_token", "access_token", etc.
```

### 2.2 Request Authentication
- [ ] All API requests include `apikey` header
- [ ] Authenticated requests include `Authorization: Bearer {token}`
- [ ] APIClient automatically adds auth headers
- [ ] No auth headers in query parameters
- [ ] 401 responses trigger token refresh

**Test Cases:**
```swift
// Test 1: Unauthenticated request (guest user)
let response = try await VideoService.shared.generateVideo(...)
// Should include apikey header but no Bearer token

// Test 2: Authenticated request (signed-in user)
try await AuthService.shared.signInWithApple(...)
let response = try await VideoService.shared.generateVideo(...)
// Should include both apikey and Bearer token

// Test 3: Expired token
// Mock expired token → verify auto-refresh → verify retry
```

### 2.3 Session Security
- [ ] Session tokens never logged
- [ ] Session tokens cleared on sign-out
- [ ] Session tokens cleared on account deletion
- [ ] Biometric authentication for sensitive operations (future)

---

## 3. Row-Level Security (RLS) Policies

### 3.1 Users Table
- [ ] RLS enabled on `users` table
- [ ] Policy: User can only read own row (`auth.uid() = id`)
- [ ] Policy: User can only update own row
- [ ] No public read access

**Test:**
```sql
-- Test as User A
SET request.jwt.claim.sub = 'user-a-id';
SELECT * FROM users WHERE id = 'user-b-id'; -- Should return 0 rows

-- Test update other user
UPDATE users SET credits_remaining = 999 WHERE id = 'user-b-id'; -- Should fail
```

### 3.2 Video Jobs Table
- [ ] RLS enabled on `video_jobs` table
- [ ] Policy: User can only read own jobs (`user_id = auth.uid()`)
- [ ] Policy: User can only delete own jobs
- [ ] No cross-user access possible

**Test:**
```sql
-- Test as User A
SET request.jwt.claim.sub = 'user-a-id';
SELECT * FROM video_jobs WHERE user_id = 'user-b-id'; -- Should return 0 rows

-- Test delete other user's job
DELETE FROM video_jobs WHERE id = 'user-b-job-id'; -- Should fail
```

### 3.3 Models Table
- [ ] RLS enabled (or public read-only)
- [ ] No write access from client
- [ ] Only admin can update models

**Test:**
```sql
-- Test as any user
UPDATE models SET cost_per_generation = 1 WHERE id = 'model-1'; -- Should fail
```

### 3.4 Credit Log Table
- [ ] RLS enabled on `credit_log` table
- [ ] Policy: User can only read own transactions
- [ ] No write access from client (write via Edge Function only)

---

## 4. Edge Function Security

### 4.1 Function Authorization
- [ ] All Edge Functions validate `Authorization` header
- [ ] Guest users validated via `device_id`
- [ ] Registered users validated via JWT
- [ ] Invalid tokens rejected with 401

**Test Cases:**
```bash
# Test 1: No auth header
curl -X POST https://your-project.supabase.co/functions/v1/generate-video \
  -H "Content-Type: application/json" \
  -d '{"prompt": "test"}'
# Expected: 401 Unauthorized

# Test 2: Invalid token
curl -X POST https://your-project.supabase.co/functions/v1/generate-video \
  -H "Authorization: Bearer invalid-token" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "test"}'
# Expected: 401 Unauthorized

# Test 3: Valid token but wrong user_id
curl -X POST https://your-project.supabase.co/functions/v1/generate-video \
  -H "Authorization: Bearer valid-token-user-a" \
  -H "Content-Type: application/json" \
  -d '{"user_id": "user-b-id", "prompt": "test"}'
# Expected: 403 Forbidden
```

### 4.2 Input Validation
- [ ] All user inputs validated in Edge Functions
- [ ] Prompt length limited (e.g., max 1000 characters)
- [ ] User ID validated against authenticated user
- [ ] Model ID validated against available models
- [ ] SQL injection prevention (use parameterized queries)
- [ ] XSS prevention (sanitize user inputs)

**Validation Template:**
```typescript
// In Edge Function
const { user_id, model_id, prompt } = await req.json();

// Validate authenticated user matches request user_id
const authUserId = req.headers.get('x-user-id'); // From JWT
if (authUserId !== user_id) {
  return new Response('Forbidden', { status: 403 });
}

// Validate prompt length
if (!prompt || prompt.length > 1000) {
  return new Response('Invalid prompt', { status: 400 });
}

// Validate model exists
const { data: model } = await supabase
  .from('models')
  .select('id')
  .eq('id', model_id)
  .single();

if (!model) {
  return new Response('Invalid model', { status: 400 });
}
```

### 4.3 Rate Limiting
- [ ] Rate limiting implemented per user
- [ ] Separate limits for guest vs. registered users
- [ ] 429 status code returned when limit exceeded
- [ ] Client handles 429 gracefully

**Rate Limits:**
- Guest users: 5 requests/hour
- Free tier: 20 requests/hour
- Premium tier: 100 requests/hour

**Test:**
```swift
// Test rate limit exceeded
for _ in 1...10 {
    do {
        try await VideoService.shared.generateVideo(...)
    } catch AppError.rateLimitExceeded {
        // Expected after limit reached
        print("Rate limit working correctly")
    }
}
```

---

## 5. Data Validation

### 5.1 Client-Side Validation
- [ ] Prompt not empty before sending request
- [ ] Prompt length validated (max 1000 chars)
- [ ] Model ID validated (exists in local model list)
- [ ] Credit balance checked before generation

**Example:**
```swift
func generateVideo(prompt: String, modelId: String) async throws {
    // Validate prompt
    guard !prompt.isEmpty else {
        throw AppError.validationError("Prompt cannot be empty")
    }
    guard prompt.count <= 1000 else {
        throw AppError.validationError("Prompt too long")
    }

    // Validate model exists
    let models = try await ModelService.shared.fetchModels()
    guard models.contains(where: { $0.id == modelId }) else {
        throw AppError.validationError("Invalid model")
    }

    // Check credits
    let hasCredits = try await CreditService.shared.hasSufficientCredits(cost: 4)
    guard hasCredits else {
        throw AppError.insufficientCredits
    }

    // Proceed with generation
    ...
}
```

### 5.2 Server-Side Validation
- [ ] All inputs re-validated in Edge Functions
- [ ] Credit balance verified atomically in database
- [ ] Model availability checked
- [ ] User existence verified

---

## 6. Sensitive Data Protection

### 6.1 PII (Personally Identifiable Information)
- [ ] Email never logged
- [ ] Device ID never logged
- [ ] Apple sub ID never logged
- [ ] User ID only logged in error reporting (with consent)

**Logging Policy:**
```swift
// ❌ WRONG
print("User email: \(user.email)")

// ✅ CORRECT
print("User ID: \(user.id)") // Only if necessary for debugging
```

### 6.2 Error Messages
- [ ] Error messages don't leak sensitive info
- [ ] Stack traces not exposed to client
- [ ] Generic error messages for security failures

**Example:**
```swift
// ❌ WRONG: Leaks info
throw AppError.custom("User with email john@example.com not found")

// ✅ CORRECT: Generic
throw AppError.unauthorized
```

### 6.3 Logging
- [ ] No sensitive data in logs
- [ ] Logs disabled in production (or sanitized)
- [ ] API keys redacted in logs
- [ ] Tokens redacted in logs

**Safe Logging:**
```swift
if AppConfig.enableLogging {
    print("🌐 API Request: POST /generate-video")
    print("Headers: apikey=REDACTED, Authorization=REDACTED")
    print("Body: {prompt: \"\(prompt.prefix(50))...\", model_id: \(modelId)}")
}
```

---

## 7. Network Security

### 7.1 HTTPS Enforcement
- [ ] All API calls use HTTPS
- [ ] No HTTP fallback
- [ ] ATS (App Transport Security) enabled
- [ ] Certificate validation enabled

**Info.plist Check:**
```xml
<!-- Should NOT have this exception -->
<key>NSAllowsArbitraryLoads</key>
<false/>
```

### 7.2 Certificate Pinning (Optional but Recommended)
- [ ] Consider certificate pinning for high-security needs
- [ ] Document pinning strategy if implemented
- [ ] Plan for certificate rotation

**Future Enhancement:**
```swift
// Certificate pinning implementation (Phase 2)
class CertificatePinner: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Validate certificate
        // ...
    }
}
```

### 7.3 Request/Response Encryption
- [ ] All data encrypted in transit (HTTPS)
- [ ] Sensitive data encrypted at rest (Keychain)
- [ ] No plaintext storage of credentials

---

## 8. DeviceCheck Integration

### 8.1 Fraud Prevention
- [ ] DeviceCheck token generated on device
- [ ] Token sent to backend for validation
- [ ] Backend validates token with Apple
- [ ] First-time credit claim validated via DeviceCheck
- [ ] No ability to claim free credits multiple times

**Test Cases:**
```swift
// Test 1: First-time user
let response = try await OnboardingService.shared.checkDevice(deviceId: newDeviceId)
XCTAssertEqual(response.isExistingUser, false)
XCTAssertEqual(response.initialGrantClaimed, false)
// User should receive initial credits

// Test 2: Returning user
let response2 = try await OnboardingService.shared.checkDevice(deviceId: newDeviceId)
XCTAssertEqual(response2.isExistingUser, true)
XCTAssertEqual(response2.initialGrantClaimed, true)
// User should NOT receive additional free credits
```

### 8.2 Device Rotation Attack Prevention
- [ ] Device ID tracked in database
- [ ] One free credit grant per device (via DeviceCheck)
- [ ] Multiple device attempts logged
- [ ] Suspicious activity flagged

---

## 9. Error Handling Security

### 9.1 Error Information Disclosure
- [ ] Error messages don't reveal system details
- [ ] Database error messages not exposed
- [ ] Generic errors for authentication failures

**Example:**
```swift
// ❌ WRONG: Reveals info
catch {
    throw AppError.custom("PostgreSQL error: connection to 10.0.0.5:5432 failed")
}

// ✅ CORRECT: Generic
catch {
    throw AppError.serverError
}
```

### 9.2 Error Logging
- [ ] Errors logged server-side with full context
- [ ] Client-side errors sanitized before logging
- [ ] Error reporting service configured (Crashlytics, Sentry)

---

## 10. Testing & Verification

### 10.1 Security Test Cases
- [ ] Unauthorized access test (cross-user access)
- [ ] Token expiration test
- [ ] Rate limiting test
- [ ] Input validation test (SQL injection, XSS)
- [ ] Credit deduction race condition test
- [ ] RLS policy test

### 10.2 Penetration Testing
- [ ] Consider third-party security audit (pre-launch)
- [ ] Automated security scanning (OWASP ZAP, etc.)
- [ ] Manual penetration testing

### 10.3 Vulnerability Scanning
- [ ] Dependency scanning (Swift Package Manager)
- [ ] Known vulnerability check
- [ ] Regular security updates

---

## 11. Deployment Security

### 11.1 Pre-Production Checklist
- [ ] All tests pass (unit, integration, security)
- [ ] Code review completed
- [ ] Security review completed
- [ ] Environment variables configured correctly
- [ ] Production keys rotated (not using dev keys)
- [ ] Logging disabled or sanitized

### 11.2 Production Monitoring
- [ ] Error rate monitoring
- [ ] Unauthorized access attempt monitoring
- [ ] Rate limiting alerts
- [ ] Credit balance anomaly detection

### 11.3 Incident Response Plan
- [ ] Security incident response documented
- [ ] Contact list for security issues
- [ ] Process for emergency key rotation
- [ ] User notification process (if breach occurs)

---

## 12. Compliance & Privacy

### 12.1 GDPR Compliance
- [ ] User can request data deletion
- [ ] User data export capability
- [ ] Privacy policy updated
- [ ] Cookie/tracking consent (if applicable)

### 12.2 Data Retention
- [ ] User data deletion on account removal
- [ ] Video job retention policy defined (e.g., 30 days)
- [ ] Audit log retention policy

### 12.3 Terms of Service
- [ ] Terms of service reviewed
- [ ] User acceptance flow implemented
- [ ] Terms version tracking

---

## Security Checklist Summary

**Critical (Must-Have Before Launch):**
- ✅ No hardcoded API keys
- ✅ RLS policies enabled and tested
- ✅ Token management secure
- ✅ Input validation on client and server
- ✅ HTTPS enforcement
- ✅ DeviceCheck fraud prevention

**High Priority (Should Have):**
- ✅ Rate limiting
- ✅ Error information disclosure prevention
- ✅ Security test cases pass
- ✅ Logging sanitized

**Medium Priority (Nice to Have):**
- ⚠️ Certificate pinning
- ⚠️ Third-party security audit
- ⚠️ Automated vulnerability scanning

---

## Sign-Off

**Before production deployment, the following roles must sign off:**

| Role | Name | Date | Signature |
|------|------|------|-----------|
| iOS Lead Developer | | | |
| Backend Developer | | | |
| Security Reviewer | | | |
| Product Manager | | | |

---

**Document Status:** ✅ Active
**Last Updated:** 2025-01-05
**Next Review:** Before production deployment
