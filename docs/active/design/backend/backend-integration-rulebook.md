# Backend Integration Rulebook

**Version:** 1.0
**Date:** 2025-11-05
**Status:** Active
**Scope:** iOS Swift backend integration standards

---

## Purpose

This document defines the coding standards, patterns, and conventions for integrating iOS frontend services with Supabase backend APIs. All developers must follow these guidelines to ensure consistency, maintainability, and quality across the codebase.

**Companion to:** `general-rulebook.md` (architectural patterns)

---

## 1. Network Layer Standards

### 1.1 APIClient Usage

**Rule:** ALL backend communication MUST go through `APIClient.shared`

```swift
// ✅ CORRECT
class VideoGenerationService {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func generateVideo(request: VideoGenerationRequest) async throws -> VideoGenerationResponse {
        return try await apiClient.request(
            endpoint: "generate-video",
            method: .POST,
            body: request
        )
    }
}

// ❌ WRONG: Direct URLSession usage
class VideoGenerationService {
    func generateVideo() async throws {
        let url = URL(string: "https://api.example.com/generate")!
        let (data, _) = try await URLSession.shared.data(from: url)
        // WRONG - bypasses retry logic, logging, error handling
    }
}
```

### 1.2 Request Builder Conventions

**Endpoint Naming:**
- Use kebab-case: `"generate-video"`, `"get-video-status"`, `"update-credits"`
- No leading slash
- No query parameters in endpoint string (use parameters argument if needed)

```swift
// ✅ CORRECT
try await apiClient.request(
    endpoint: "generate-video",
    method: .POST,
    body: request
)

// ❌ WRONG
try await apiClient.request(
    endpoint: "/generate-video?user_id=123", // No leading slash or query params
    method: .POST
)
```

**HTTP Method Usage:**
- `GET` - Fetch data (idempotent)
- `POST` - Create new resource or trigger action
- `PUT` - Replace entire resource
- `PATCH` - Update partial resource
- `DELETE` - Remove resource

### 1.3 Response Parsing Standards

**Rule:** Use generic type parameter for type-safe responses

```swift
// ✅ CORRECT: Type-safe response
let response: VideoGenerationResponse = try await apiClient.request(
    endpoint: "generate-video",
    method: .POST,
    body: request
)

// ❌ WRONG: Manual JSON parsing
let data = try await apiClient.requestData(...)
let json = try JSONSerialization.jsonObject(with: data)
// WRONG - lose type safety
```

**Validation After Parsing:**
```swift
struct VideoGenerationResponse: Codable {
    let job_id: String
    let status: String
    let credits_used: Int

    func validate() throws {
        guard !job_id.isEmpty else {
            throw AppError.invalidResponse
        }
        guard ["pending", "processing", "completed", "failed"].contains(status) else {
            throw AppError.invalidResponse
        }
        guard credits_used > 0 else {
            throw AppError.invalidResponse
        }
    }
}

// In service:
let response: VideoGenerationResponse = try await apiClient.request(...)
try response.validate() // Always validate
return response
```

---

## 2. Service Layer Conventions

### 2.1 Protocol Naming

**Rule:** Service protocols MUST end with `Protocol` suffix

```swift
// ✅ CORRECT
protocol VideoGenerationServiceProtocol {
    func generateVideo(request: VideoGenerationRequest) async throws -> VideoGenerationResponse
}

// ❌ WRONG
protocol VideoGenerationService { ... } // Missing 'Protocol'
protocol IVideoGenerationService { ... } // Don't use 'I' prefix
protocol VideoGenerating { ... } // Ambiguous
```

### 2.2 Singleton Pattern

**Rule:** Services MUST use singleton pattern with dependency injection support

```swift
// ✅ CORRECT: Singleton with DI support
class VideoGenerationService: VideoGenerationServiceProtocol {
    static let shared = VideoGenerationService()

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    private init() {} // ❌ WRONG - prevents DI for testing
}

// ✅ CORRECT: Proper DI support
class VideoGenerationService: VideoGenerationServiceProtocol {
    static let shared = VideoGenerationService()

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }
    // No private init() - allows testing with mock APIClient
}
```

### 2.3 Mock Service Implementation

**Rule:** Each service protocol MUST have a separate `Mock{Service}` class for testing

```swift
// ✅ CORRECT: Separate mock class
class MockVideoGenerationService: VideoGenerationServiceProtocol {
    var responseToReturn: VideoGenerationResponse?
    var shouldThrowError = false
    var errorToThrow: Error = AppError.networkFailure

    func generateVideo(request: VideoGenerationRequest) async throws -> VideoGenerationResponse {
        if shouldThrowError {
            throw errorToThrow
        }

        return responseToReturn ?? VideoGenerationResponse.default
    }
}

// ❌ WRONG: Mixed mock and real logic
class VideoGenerationService {
    func generateVideo() async throws {
        #if DEBUG
        return mockResponse // WRONG - separate classes instead
        #else
        return realResponse
        #endif
    }
}
```

### 2.4 Async Function Signatures

**Rule:** ALL service methods MUST use `async throws` pattern

```swift
// ✅ CORRECT
func fetchModels() async throws -> [ModelPreview]

// ❌ WRONG: Completion handlers
func fetchModels(completion: @escaping (Result<[ModelPreview], Error>) -> Void)

// ❌ WRONG: Force-try
func fetchModels() async -> [ModelPreview] // Can't propagate errors
```

---

## 3. Model Mapping

### 3.1 Naming Conventions

**Request Models:** `{Action}{Resource}Request`
```swift
struct VideoGenerationRequest: Codable { ... }
struct UpdateCreditsRequest: Codable { ... }
struct DeleteVideoJobRequest: Codable { ... }
```

**Response Models:** `{Action}{Resource}Response` OR `{Resource}` (if simple)
```swift
struct VideoGenerationResponse: Codable { ... }
struct UpdateCreditsResponse: Codable { ... }
// OR for simple responses:
struct VideoJob: Codable { ... } // Response from get-video-status
```

**Database Models:** `{Resource}` (PascalCase, singular)
```swift
struct User: Codable { ... }
struct VideoJob: Codable { ... }
struct Model: Codable { ... } // But use ModelPreview/ModelDetail to avoid conflicts
```

### 3.2 Codable Conformance

**Rule:** Use `CodingKeys` for snake_case ↔ camelCase conversion

```swift
// ✅ CORRECT: Explicit CodingKeys
struct VideoGenerationRequest: Codable {
    let userId: String
    let modelId: String
    let prompt: String
    let aspectRatio: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case modelId = "model_id"
        case prompt
        case aspectRatio = "aspect_ratio"
    }
}

// ❌ ACCEPTABLE but not preferred: JSONDecoder.keyDecodingStrategy
// Reason: Less explicit, harder to debug, can't mix conventions
```

**Optional Fields:**
```swift
// ✅ CORRECT: Optional for nullable fields
struct User: Codable {
    let id: String
    let email: String? // Nullable for guest users
    let deviceId: String? // Nullable for registered users
    let creditsRemaining: Int // Always required
}

// ❌ WRONG: Force-unwrapping optionals
struct User: Codable {
    let email: String // Crashes for guest users

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.email = try container.decode(String.self, forKey: .email) // CRASH
    }
}
```

### 3.3 Date/Timestamp Handling

**Rule:** Use ISO8601 format for all date/time fields

```swift
// ✅ CORRECT: Configure JSONDecoder
extension JSONDecoder {
    static var backend: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

// Usage:
let response = try JSONDecoder.backend.decode(VideoJob.self, from: data)

// ❌ WRONG: Custom date parsing per model
struct VideoJob: Codable {
    let createdAt: Date

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateString = try container.decode(String.self, forKey: .createdAt)
        // WRONG - use global strategy
    }
}
```

### 3.4 Enum Raw Values

**Rule:** Backend enum values MUST match database values exactly

```swift
// ✅ CORRECT: Raw values match backend
enum JobStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
}

// ❌ WRONG: Different values
enum JobStatus: String, Codable {
    case pending = "PENDING" // Backend uses lowercase
    case processing = "inProgress" // Backend uses "processing"
}
```

---

## 4. Error Handling

### 4.1 AppError Usage

**Rule:** ALL service errors MUST be mapped to `AppError`

```swift
// ✅ CORRECT: Map to AppError
func fetchModels() async throws -> [ModelPreview] {
    do {
        return try await apiClient.request(
            endpoint: "get-models",
            method: .GET
        )
    } catch {
        throw mapError(error)
    }
}

private func mapError(_ error: Error) -> AppError {
    if let appError = error as? AppError {
        return appError
    }
    if let urlError = error as? URLError {
        switch urlError.code {
        case .timedOut: return .networkTimeout
        case .notConnectedToInternet: return .noInternetConnection
        default: return .networkFailure
        }
    }
    return .unknownError(statusCode: 0)
}

// ❌ WRONG: Propagate raw errors
func fetchModels() async throws -> [ModelPreview] {
    return try await apiClient.request(...) // Raw errors confuse ViewModel
}
```

### 4.2 HTTP Status Code Mapping

**Standard Mappings (enforced by APIClient):**
- `200-299` → Success
- `400` → `AppError.badRequest`
- `401` → `AppError.unauthorized`
- `403` → `AppError.forbidden`
- `404` → `AppError.notFound`
- `429` → `AppError.rateLimitExceeded`
- `500-599` → `AppError.serverError`

### 4.3 Error Context Preservation

**Rule:** Report errors with context before throwing

```swift
// ✅ CORRECT: Preserve context
func generateVideo(request: VideoGenerationRequest) async throws -> VideoGenerationResponse {
    do {
        return try await apiClient.request(...)
    } catch {
        ErrorReportingService.shared.reportError(error, context: [
            "endpoint": "generate-video",
            "userId": request.userId,
            "modelId": request.modelId
        ])
        throw mapError(error)
    }
}

// ❌ WRONG: No context
func generateVideo(...) async throws {
    return try await apiClient.request(...) // Lost all context if fails
}
```

### 4.4 Localized Error Keys

**Rule:** Use error localization keys from `error-handling-guide.md`

```swift
enum AppError: Error {
    case networkFailure
    case networkTimeout
    case insufficientCredits
    case unauthorized

    var localizedKey: String {
        switch self {
        case .networkFailure: return "error.network.failure"
        case .networkTimeout: return "error.network.timeout"
        case .insufficientCredits: return "error.credit.insufficient"
        case .unauthorized: return "error.auth.unauthorized"
        }
    }
}

// In ViewModel:
do {
    try await service.generateVideo(...)
} catch let error as AppError {
    errorMessage = NSLocalizedString(error.localizedKey, comment: "")
    showingErrorAlert = true
}
```

---

## 5. Authentication

### 5.1 Token Management

**Rule:** NEVER manually manage tokens - let Supabase SDK handle it

```swift
// ✅ CORRECT: Supabase SDK manages tokens
let session = try await supabaseClient.auth.session
// SDK automatically:
// - Stores token in Keychain
// - Refreshes when expired
// - Handles token invalidation

// ❌ WRONG: Manual token storage
class AuthService {
    var accessToken: String? // WRONG - use Supabase SDK
}
```

### 5.2 Header Injection

**Rule:** APIClient automatically adds auth headers

```swift
// APIClient.swift (already implemented)
func request<T: Decodable>(...) async throws -> T {
    var request = URLRequest(url: url)
    request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")

    // If user authenticated, add bearer token
    if let session = await AuthService.shared.getCurrentSession() {
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
    }

    // Services don't need to worry about auth headers
}
```

### 5.3 Session Refresh

**Rule:** APIClient handles token refresh automatically on 401

```swift
// APIClient handles this automatically:
if statusCode == 401 {
    // Attempt token refresh
    if try await AuthService.shared.refreshTokenIfNeeded() {
        // Retry request with new token
        return try await executeRequest(request)
    } else {
        throw AppError.unauthorized
    }
}

// Services just call normally:
let response = try await apiClient.request(...) // Auth handled transparently
```

### 5.4 Unauthorized Handling

**Rule:** Post notification on auth failure for global handling

```swift
// In APIClient:
if statusCode == 401 && !canRefreshToken {
    NotificationCenter.default.post(name: .userUnauthorized, object: nil)
    throw AppError.unauthorized
}

// In App root:
.onReceive(NotificationCenter.default.publisher(for: .userUnauthorized)) { _ in
    // Sign out user globally
    AuthService.shared.signOut()
    // Navigate to login
}
```

---

## 6. Retry Logic

### 6.1 Retryable Errors

**Rule:** Retry ONLY on network errors, not client errors

```swift
func shouldRetry(error: Error) -> Bool {
    if let appError = error as? AppError {
        switch appError {
        case .networkTimeout, .noInternetConnection, .serverUnreachable:
            return true // Retryable
        case .badRequest, .unauthorized, .insufficientCredits:
            return false // Not retryable - client error
        default:
            return false
        }
    }
    return false
}
```

### 6.2 Exponential Backoff

**Rule:** Use exponential backoff: 2^attempt seconds

```swift
private func exponentialBackoff(attempt: Int) -> TimeInterval {
    return pow(2.0, Double(attempt)) // 2s, 4s, 8s
}

// Max 3 retries: 2s, 4s, 8s = 14s total delay
```

### 6.3 Max Retry Attempts

**Standard:** 3 retries maximum (4 total attempts: 1 initial + 3 retries)

```swift
let maxRetryAttempts = 3

func executeWithRetry<T>(..., attempt: Int = 1) async throws -> T {
    do {
        return try await execute(...)
    } catch {
        if shouldRetry(error: error) && attempt < maxRetryAttempts {
            let delay = exponentialBackoff(attempt: attempt)
            try await Task.sleep(for: .seconds(delay))
            return try await executeWithRetry(..., attempt: attempt + 1)
        }
        throw error
    }
}
```

### 6.4 Request Idempotency

**Rule:** Retryable requests MUST be idempotent

```swift
// ✅ SAFE TO RETRY: GET requests (idempotent)
func fetchModels() async throws -> [ModelPreview] {
    return try await apiClient.request(endpoint: "get-models", method: .GET)
    // Safe to retry - doesn't modify state
}

// ❌ NOT SAFE: POST credit deduction (not idempotent)
func deductCredits(amount: Int) async throws {
    try await apiClient.request(
        endpoint: "update-credits",
        method: .POST,
        body: UpdateCreditsRequest(change: -amount)
    )
    // DANGER: Retry could deduct credits multiple times!
}

// ✅ SOLUTION: Use idempotency key
struct UpdateCreditsRequest: Codable {
    let change: Int
    let idempotencyKey: String // Backend deduplicates on this key
}
```

---

## 7. Caching Strategies

### 7.1 Cache Invalidation Rules

**Rule:** Define explicit cache TTL per resource type

```swift
class ModelService {
    private var cachedModels: [ModelPreview]?
    private var cacheTimestamp: Date?
    private let cacheValidityDuration: TimeInterval = 3600 // 1 hour

    func fetchModels(forceRefresh: Bool = false) async throws -> [ModelPreview] {
        // Check cache
        if !forceRefresh,
           let cached = cachedModels,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheValidityDuration {
            return cached
        }

        // Fetch fresh
        let models = try await apiClient.request(...)
        cachedModels = models
        cacheTimestamp = Date()
        return models
    }

    func invalidateCache() {
        cachedModels = nil
        cacheTimestamp = nil
    }
}
```

**Cache TTL Guidelines:**
- Models: 1 hour (rarely change)
- User profile: 5 minutes (changes occasionally)
- Credits: NO CACHE (always fresh)
- Video history: 30 seconds (changes frequently)

### 7.2 Memory vs. Disk Caching

**Rule:** Use memory cache for small, frequently accessed data

```swift
// ✅ Memory cache for models (small, frequently accessed)
class ModelService {
    private var cachedModels: [ModelPreview]? // In-memory
}

// ✅ Disk cache for large data (images, videos)
class PhotoCache {
    func cache(image: UIImage, key: String) {
        let url = cacheDirectory.appendingPathComponent(key)
        try? image.pngData()?.write(to: url)
    }
}
```

### 7.3 Cache Key Conventions

**Rule:** Use consistent cache key format: `{resource}_{id}_{variant}`

```swift
// ✅ CORRECT
let cacheKey = "model_detail_\(modelId)_\(language)"
let thumbnailKey = "thumbnail_\(modelId)_small"

// ❌ WRONG
let cacheKey = modelId // Ambiguous
let cacheKey = "model-\(modelId)" // Inconsistent separator
```

---

## 8. Testing Patterns

### 8.1 Service Unit Test Structure

**Standard Structure:**
```swift
@MainActor
class VideoGenerationServiceTests: XCTestCase {
    var service: VideoGenerationService!
    var mockAPIClient: MockAPIClient!

    override func setUp() async throws {
        mockAPIClient = MockAPIClient()
        service = VideoGenerationService(apiClient: mockAPIClient)
    }

    override func tearDown() async throws {
        service = nil
        mockAPIClient = nil
    }

    func testGenerateVideo_Success() async throws {
        // GIVEN: Setup
        mockAPIClient.responseToReturn = VideoGenerationResponse.mock

        // WHEN: Execute
        let response = try await service.generateVideo(request: .mock)

        // THEN: Verify
        XCTAssertEqual(response.job_id, "mock-job-id")
        XCTAssertEqual(mockAPIClient.requestCount, 1)
    }

    func testGenerateVideo_NetworkFailure_ThrowsError() async {
        // GIVEN
        mockAPIClient.shouldThrowError = true
        mockAPIClient.errorToThrow = AppError.networkTimeout

        // WHEN/THEN
        do {
            _ = try await service.generateVideo(request: .mock)
            XCTFail("Should throw networkTimeout")
        } catch let error as AppError {
            XCTAssertEqual(error, .networkTimeout)
        }
    }
}
```

### 8.2 Mock APIClient Usage

**Rule:** Use MockAPIClient for service tests, not real network

```swift
class MockAPIClient: APIClient {
    var responseToReturn: Any?
    var shouldThrowError = false
    var errorToThrow: Error = AppError.networkFailure
    var requestCount = 0

    override func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable?
    ) async throws -> T {
        requestCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        guard let response = responseToReturn as? T else {
            throw AppError.invalidResponse
        }

        return response
    }
}
```

### 8.3 Integration Test Setup

**Rule:** Integration tests use real services with test environment

```swift
class VideoGenerationIntegrationTests: XCTestCase {
    func testFullVideoGenerationFlow() async throws {
        // Use real services connected to test environment
        let videoService = VideoGenerationService.shared
        let creditService = CreditService.shared

        // 1. Check initial credits
        let initialCredits = try await creditService.fetchCredits()

        // 2. Generate video
        let response = try await videoService.generateVideo(...)

        // 3. Verify credits deducted
        let newCredits = try await creditService.fetchCredits()
        XCTAssertEqual(newCredits, initialCredits - response.credits_used)
    }
}
```

### 8.4 Async Test Conventions

**Rule:** Use `async throws` for test methods

```swift
// ✅ CORRECT
func testFetchModels() async throws {
    let models = try await service.fetchModels()
    XCTAssertFalse(models.isEmpty)
}

// ❌ WRONG: Completion handler
func testFetchModels() {
    let expectation = XCTestExpectation()
    service.fetchModels { result in
        // WRONG - use async/await
        expectation.fulfill()
    }
    wait(for: [expectation], timeout: 5.0)
}
```

---

## 9. Configuration Management

### 9.1 Environment Variables

**Rule:** Use `.xcconfig` files for environment-specific configuration

```
// Development.xcconfig
SUPABASE_URL = https://dev.supabase.co
SUPABASE_ANON_KEY = eyJhbGc...
API_TIMEOUT = 30
ENABLE_LOGGING = YES

// Production.xcconfig
SUPABASE_URL = https://prod.supabase.co
SUPABASE_ANON_KEY = eyJhbGc...
API_TIMEOUT = 15
ENABLE_LOGGING = NO
```

### 9.2 Info.plist Keys

**Rule:** Reference `.xcconfig` variables in Info.plist

```xml
<key>SUPABASE_URL</key>
<string>$(SUPABASE_URL)</string>

<key>SUPABASE_ANON_KEY</key>
<string>$(SUPABASE_ANON_KEY)</string>
```

### 9.3 AppConfig Usage

**Rule:** ALL configuration MUST go through `AppConfig`

```swift
// ✅ CORRECT
let url = AppConfig.supabaseURL
let timeout = AppConfig.apiTimeout

// ❌ WRONG: Hardcoded
let url = "https://api.example.com"
```

### 9.4 Secret Management

**Rule:** NEVER commit secrets to Git

```gitignore
# .gitignore
*.xcconfig
Info.plist

# Keep template files only
!Configuration/*.xcconfig.template
```

---

## 10. Migration Checklist

### 10.1 Service Migration Steps

**For Each Service:**

1. **Read Current Mock Implementation**
   - Understand expected behavior
   - Identify all methods
   - Note edge cases

2. **Update Service Implementation**
   - Replace mock logic with APIClient calls
   - Add proper error handling
   - Add retry logic (if needed)
   - Remove Task.sleep() delays

3. **Update Response Models**
   - Ensure CodingKeys match backend
   - Add validation logic
   - Handle optional fields

4. **Write Unit Tests**
   - Test success case
   - Test error cases
   - Test retry logic
   - Target 70%+ coverage

5. **Write Integration Test**
   - Test full flow with real backend
   - Verify data persistence
   - Test error recovery

6. **Code Review**
   - Follow backend-integration-rulebook.md
   - Check error handling
   - Verify no hardcoded values
   - Confirm tests pass

7. **Update Documentation**
   - Update service documentation
   - Add API endpoint notes
   - Document known issues

### 10.2 Verification Checklist

**Per Service:**
- [ ] No mock logic remaining
- [ ] Uses APIClient.shared
- [ ] Proper error handling
- [ ] Unit tests pass (70%+ coverage)
- [ ] Integration test passes
- [ ] Code review completed
- [ ] Documentation updated

### 10.3 Rollback Strategy

**If Service Migration Fails:**

1. **Revert to Mock:**
   - Keep protocol unchanged
   - Swap implementation back to mock
   - Feature flag to control real vs. mock

2. **Feature Flag Pattern:**
```swift
class ServiceFactory {
    static var useRealBackend: Bool {
        UserDefaults.standard.bool(forKey: "useRealBackend")
    }

    static func createVideoService() -> VideoGenerationServiceProtocol {
        if useRealBackend {
            return VideoGenerationService.shared
        } else {
            return MockVideoGenerationService()
        }
    }
}
```

---

## Appendix A: Common Mistakes

### Mistake 1: Force-Unwrapping Optionals
```swift
// ❌ WRONG
let email = user.email! // Crashes for guest users

// ✅ CORRECT
let email = user.email ?? "Guest"
```

### Mistake 2: Ignoring Errors
```swift
// ❌ WRONG
try? await service.generateVideo(...) // Silently fails

// ✅ CORRECT
do {
    try await service.generateVideo(...)
} catch {
    handleError(error)
}
```

### Mistake 3: Blocking Main Thread
```swift
// ❌ WRONG
func loadData() {
    Task {
        let data = try await service.fetchData()
        // Update UI
    }
}

// ✅ CORRECT (in ViewModel)
@MainActor
func loadData() async {
    do {
        let data = try await service.fetchData()
        // Update @Published properties safely on main actor
    } catch {
        handleError(error)
    }
}
```

### Mistake 4: Hardcoded Test Data in Production
```swift
// ❌ WRONG
func fetchModels() async throws -> [ModelPreview] {
    #if DEBUG
    return mockModels // WRONG - use separate mock class
    #else
    return try await apiClient.request(...)
    #endif
}

// ✅ CORRECT
// Separate classes: ModelService and MockModelService
```

---

## Appendix B: Quick Reference

**APIClient Call Template:**
```swift
let response: ResponseType = try await apiClient.request(
    endpoint: "endpoint-name",
    method: .POST,
    body: requestBody
)
```

**Service Template:**
```swift
protocol MyServiceProtocol {
    func doSomething() async throws -> ResultType
}

class MyService: MyServiceProtocol {
    static let shared = MyService()
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func doSomething() async throws -> ResultType {
        let response: ResponseType = try await apiClient.request(...)
        return response
    }
}

class MockMyService: MyServiceProtocol {
    var responseToReturn: ResultType?
    var shouldThrowError = false

    func doSomething() async throws -> ResultType {
        if shouldThrowError { throw AppError.networkFailure }
        return responseToReturn ?? .default
    }
}
```

---

**Document Status:** ✅ Active
**Last Updated:** 2025-11-05
**Next Review:** After first service migration
