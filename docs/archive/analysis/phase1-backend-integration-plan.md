# Phase 1: Backend Integration - Implementation Plan & Analysis

**Document Version:** 1.0
**Date:** 2025-11-05
**Status:** Ready for Implementation
**Priority:** P0 (CRITICAL - Blocking)

---

## Executive Summary

This document provides a comprehensive, production-ready implementation plan for Phase 1 Backend Integration of the Rendio AI iOS application. The frontend is 100% complete with all 7 blueprint screens implemented, but all services currently use mock data. This phase focuses on replacing mock services with real Supabase API calls, establishing a robust network layer, and ensuring production-grade error handling.

**Current State:**
- ✅ Frontend: 100% complete (7/7 screens)
- ✅ UI Components: 25+ reusable components
- ✅ Architecture: MVVM with protocol-based services
- ✅ Design System: Consistent token usage
- ✅ Localization: 3 languages (en, tr, es)
- ❌ Backend Integration: 0% (all mock data)
- ❌ Real API Calls: 0 implemented
- ❌ Production Network Layer: Not implemented

**Phase 1 Objective:**
Transform all 10 mock services into production-ready backend-connected services with proper error handling, authentication, and retry logic.

---

## Section 1: Phase 1 Implementation Plan (3-5 Subphases)

### Phase 1.1: Foundation & Configuration (2 days)
**Priority:** P0 (Blocking all other phases)
**Complexity:** Low-Medium
**Dependencies:** None

#### Deliverables:
1. **Environment Configuration System**
   - Create `Core/Configuration/AppConfig.swift`
   - Create `Core/Configuration/SupabaseConfig.swift`
   - Add configuration to `Info.plist` (or use `.xcconfig` files)
   - Support multiple environments (dev, staging, prod)

2. **Build Configuration Setup**
   - Create `.xcconfig` files for each environment
   - Configure Xcode schemes (Debug, Staging, Production)
   - Add preprocessor flags for conditional compilation

3. **Centralized Network Layer**
   - Create `Core/Networking/APIClient.swift` - Central HTTP client
   - Create `Core/Networking/APIRequest.swift` - Request builder
   - Create `Core/Networking/APIResponse.swift` - Response parser
   - Create `Core/Networking/NetworkInterceptor.swift` - Request/response interceptor

#### Implementation Details:

**AppConfig.swift:**
```swift
import Foundation

enum Environment {
    case development
    case staging
    case production

    #if DEBUG
    static let current: Environment = .development
    #else
    static let current: Environment = .production
    #endif
}

struct AppConfig {
    // MARK: - Supabase Configuration
    static var supabaseURL: String {
        switch Environment.current {
        case .development:
            return Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL_DEV") as? String ?? ""
        case .staging:
            return Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL_STAGING") as? String ?? ""
        case .production:
            return Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL_PROD") as? String ?? ""
        }
    }

    static var supabaseAnonKey: String {
        switch Environment.current {
        case .development:
            return Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY_DEV") as? String ?? ""
        case .staging:
            return Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY_STAGING") as? String ?? ""
        case .production:
            return Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY_PROD") as? String ?? ""
        }
    }

    // MARK: - API Configuration
    static var apiTimeout: TimeInterval {
        switch Environment.current {
        case .development: return 30.0
        case .staging: return 20.0
        case .production: return 15.0
        }
    }

    static var maxRetryAttempts: Int {
        return 3
    }

    static var enableLogging: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
```

**APIClient.swift:**
```swift
import Foundation

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConfig.apiTimeout
        config.timeoutIntervalForResource = AppConfig.apiTimeout * 2
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    // MARK: - Request Methods

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        let url = try buildURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        // Add default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")

        // Add custom headers
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        // Add body if present
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }

        // Log request (debug only)
        if AppConfig.enableLogging {
            logRequest(request)
        }

        // Execute request with retry logic
        return try await executeWithRetry(request: request)
    }

    private func executeWithRetry<T: Decodable>(
        request: URLRequest,
        attempt: Int = 1
    ) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.invalidResponse
            }

            // Log response (debug only)
            if AppConfig.enableLogging {
                logResponse(httpResponse, data: data)
            }

            // Handle status codes
            try handleHTTPStatus(httpResponse.statusCode, data: data)

            // Decode response
            return try decoder.decode(T.self, from: data)

        } catch {
            // Retry on network errors if attempts remaining
            if shouldRetry(error: error) && attempt < AppConfig.maxRetryAttempts {
                let delay = exponentialBackoff(attempt: attempt)
                try await Task.sleep(for: .seconds(delay))
                return try await executeWithRetry(request: request, attempt: attempt + 1)
            }

            throw mapError(error)
        }
    }

    // MARK: - Helper Methods

    private func buildURL(endpoint: String) throws -> URL {
        let baseURL = AppConfig.supabaseURL
        guard let url = URL(string: "\(baseURL)/functions/v1/\(endpoint)") else {
            throw AppError.invalidURL
        }
        return url
    }

    private func handleHTTPStatus(_ statusCode: Int, data: Data) throws {
        switch statusCode {
        case 200...299:
            return
        case 400:
            throw AppError.badRequest
        case 401:
            throw AppError.unauthorized
        case 403:
            throw AppError.forbidden
        case 404:
            throw AppError.notFound
        case 429:
            throw AppError.rateLimitExceeded
        case 500...599:
            throw AppError.serverError
        default:
            throw AppError.unknownError(statusCode: statusCode)
        }
    }

    private func shouldRetry(error: Error) -> Bool {
        if let urlError = error as? URLError {
            return [.timedOut, .networkConnectionLost, .notConnectedToInternet].contains(urlError.code)
        }
        return false
    }

    private func exponentialBackoff(attempt: Int) -> Double {
        return pow(2.0, Double(attempt)) // 2s, 4s, 8s
    }

    private func mapError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut: return .networkTimeout
            case .notConnectedToInternet: return .noInternetConnection
            case .cannotFindHost, .cannotConnectToHost: return .serverUnreachable
            default: return .networkFailure
            }
        }
        return .unknownError(statusCode: 0)
    }

    private func logRequest(_ request: URLRequest) {
        print("🌐 [API Request]")
        print("URL: \(request.url?.absoluteString ?? "nil")")
        print("Method: \(request.httpMethod ?? "nil")")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("Body: \(bodyString)")
        }
    }

    private func logResponse(_ response: HTTPURLResponse, data: Data) {
        print("📡 [API Response]")
        print("Status: \(response.statusCode)")
        print("URL: \(response.url?.absoluteString ?? "nil")")
        if let bodyString = String(data: data, encoding: .utf8) {
            print("Body: \(bodyString)")
        }
    }
}

enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
}
```

**AppError Extension:**
```swift
enum AppError: Error {
    // Existing errors
    case networkFailure
    case networkTimeout
    case invalidResponse
    case insufficientCredits
    case deviceCheckFailed
    case unauthorized

    // New errors for Phase 1
    case invalidURL
    case badRequest
    case forbidden
    case notFound
    case rateLimitExceeded
    case serverError
    case noInternetConnection
    case serverUnreachable
    case unknownError(statusCode: Int)

    var localizedKey: String {
        switch self {
        case .networkFailure: return "error.network.failure"
        case .networkTimeout: return "error.network.timeout"
        case .invalidResponse: return "error.network.invalid_response"
        case .insufficientCredits: return "error.credit.insufficient"
        case .unauthorized: return "error.auth.unauthorized"
        case .deviceCheckFailed: return "error.auth.device_invalid"
        case .noInternetConnection: return "error.network.no_internet"
        case .serverUnreachable: return "error.network.server_unreachable"
        case .rateLimitExceeded: return "error.network.rate_limit"
        case .serverError: return "error.server.internal"
        default: return "error.general.unexpected"
        }
    }
}
```

#### Acceptance Criteria:
- [ ] AppConfig loads correct values for each environment
- [ ] APIClient successfully makes test requests to Supabase
- [ ] Request timeout works as configured
- [ ] Retry logic works (test with network interruption)
- [ ] All configuration values are externalized (no hardcoded URLs/keys in code)
- [ ] Logging works in debug builds only

#### Risks:
- ❌ **BLOCKER:** Supabase credentials not available → Action: Coordinate with backend team
- ⚠️ **Medium:** Info.plist keys exposed in Git → Action: Use `.xcconfig` + `.gitignore`
- ⚠️ **Medium:** Build configuration complexity → Action: Document setup in README

---

### Phase 1.2: Authentication & Device Management (1.5 days)
**Priority:** P0 (Blocking service integration)
**Complexity:** Medium-High
**Dependencies:** Phase 1.1 (APIClient)

#### Deliverables:
1. **DeviceCheck Integration**
   - Update `DeviceCheckService.swift` to use real Apple DeviceCheck API
   - Implement token generation
   - Handle device verification failures

2. **Onboarding Service Backend Integration**
   - Update `OnboardingService.swift` to call POST `/device/check`
   - Handle existing vs. new user flow
   - Parse `OnboardingResponse` from backend

3. **Authentication Service Backend Integration**
   - Update `AuthService.swift` to integrate Supabase Auth
   - Implement Apple Sign-In flow with Supabase
   - Handle token refresh
   - Implement session management

4. **User Service Backend Integration**
   - Update `UserService.swift` to fetch from Supabase `users` table
   - Implement guest-to-registered user merge flow
   - Handle account deletion

#### Implementation Details:

**Updated OnboardingService.swift:**
```swift
class OnboardingService: OnboardingServiceProtocol {
    static let shared = OnboardingService()
    private let apiClient = APIClient.shared

    private init() {}

    func checkDevice(deviceId: String) async throws -> OnboardingResponse {
        struct DeviceCheckRequest: Encodable {
            let device_id: String
        }

        let request = DeviceCheckRequest(device_id: deviceId)

        let response: OnboardingResponse = try await apiClient.request(
            endpoint: "device/check",
            method: .POST,
            body: request
        )

        return response
    }
}
```

**Updated AuthService.swift (Supabase Auth):**
```swift
import Supabase

class AuthService {
    static let shared = AuthService()
    private let supabaseClient: SupabaseClient

    private init() {
        supabaseClient = SupabaseClient(
            supabaseURL: URL(string: AppConfig.supabaseURL)!,
            supabaseKey: AppConfig.supabaseAnonKey
        )
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> User {
        let session = try await supabaseClient.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )

        // Fetch user profile from database
        let userProfile: UserProfile = try await supabaseClient
            .from("users")
            .select()
            .eq("id", value: session.user.id.uuidString)
            .single()
            .execute()
            .value

        return User(from: userProfile, session: session)
    }

    func signOut() async throws {
        try await supabaseClient.auth.signOut()
    }

    func getCurrentSession() async throws -> Session? {
        return try await supabaseClient.auth.session
    }
}
```

#### Acceptance Criteria:
- [ ] DeviceCheck successfully generates and validates tokens
- [ ] Onboarding flow works for both new and existing users
- [ ] Apple Sign-In successfully authenticates via Supabase
- [ ] Session tokens are properly stored and refreshed
- [ ] Guest-to-registered user merge preserves credits
- [ ] Account deletion removes all user data

#### Risks:
- ❌ **BLOCKER:** Apple DeviceCheck not configured → Action: Enable DeviceCheck in Apple Developer
- ❌ **BLOCKER:** Supabase Auth not configured → Action: Enable Apple Sign-In provider in Supabase
- ⚠️ **High:** Token refresh failure → Action: Implement automatic retry with exponential backoff
- ⚠️ **Medium:** Race condition in user merge → Action: Use database transactions

---

### Phase 1.3: Core Services Backend Integration (2.5 days)
**Priority:** P0 (Core functionality)
**Complexity:** Medium
**Dependencies:** Phase 1.1 (APIClient), Phase 1.2 (Auth)

#### Deliverables:
1. **CreditService Backend Integration**
   - Update `fetchCredits()` to GET from Supabase `users` table
   - Update `updateCredits()` to POST `/update-credits`
   - Implement real-time credit sync

2. **ModelService Backend Integration**
   - Update `fetchModels()` to GET from Supabase `models` table
   - Add caching strategy (cache for 1 hour)
   - Handle model availability status

3. **VideoGenerationService Backend Integration**
   - Update `generateVideo()` to POST `/generate-video`
   - Add proper request/response handling
   - Handle authentication headers
   - Add retry logic for network failures

4. **ResultService Backend Integration**
   - Update `fetchVideoJob()` to GET `/get-video-status`
   - Update `pollJobStatus()` to use real endpoint
   - Handle job status transitions (pending → processing → completed)

5. **HistoryService Backend Integration**
   - Update `fetchVideoJobs()` to GET `/get-video-jobs`
   - Update `deleteVideoJob()` to DELETE `/delete-video-job`
   - Add pagination support

#### Implementation Details:

**Updated VideoGenerationService.swift:**
```swift
class VideoGenerationService: VideoGenerationServiceProtocol {
    static let shared = VideoGenerationService()
    private let apiClient = APIClient.shared

    private init() {}

    func generateVideo(request: VideoGenerationRequest) async throws -> VideoGenerationResponse {
        // Validate request
        guard !request.prompt.isEmpty else {
            throw AppError.badRequest
        }

        // Build request body
        struct GenerateVideoRequest: Encodable {
            let user_id: String
            let model_id: String
            let prompt: String
            let aspect_ratio: String?
            let resolution: String?
            let duration: Int?
        }

        let body = GenerateVideoRequest(
            user_id: request.userId,
            model_id: request.modelId,
            prompt: request.prompt,
            aspect_ratio: request.settings.aspectRatio,
            resolution: request.settings.resolution,
            duration: request.settings.duration
        )

        // Make API call
        let response: VideoGenerationResponse = try await apiClient.request(
            endpoint: "generate-video",
            method: .POST,
            body: body
        )

        return response
    }
}
```

**Updated CreditService.swift with Supabase Direct Query:**
```swift
import Supabase

class CreditService: CreditServiceProtocol {
    static let shared = CreditService()
    private let supabaseClient: SupabaseClient

    private init() {
        supabaseClient = SupabaseClient(
            supabaseURL: URL(string: AppConfig.supabaseURL)!,
            supabaseKey: AppConfig.supabaseAnonKey
        )
    }

    func fetchCredits() async throws -> Int {
        guard let userId = await AuthService.shared.getCurrentUserId() else {
            throw AppError.unauthorized
        }

        struct UserCredits: Decodable {
            let credits_remaining: Int
        }

        let result: UserCredits = try await supabaseClient
            .from("users")
            .select("credits_remaining")
            .eq("id", value: userId)
            .single()
            .execute()
            .value

        return result.credits_remaining
    }

    func updateCredits(change: Int, reason: String) async throws -> Int {
        struct UpdateCreditsRequest: Encodable {
            let user_id: String
            let change: Int
            let reason: String
        }

        guard let userId = await AuthService.shared.getCurrentUserId() else {
            throw AppError.unauthorized
        }

        let request = UpdateCreditsRequest(
            user_id: userId,
            change: change,
            reason: reason
        )

        struct UpdateCreditsResponse: Decodable {
            let credits_remaining: Int
        }

        let response: UpdateCreditsResponse = try await APIClient.shared.request(
            endpoint: "update-credits",
            method: .POST,
            body: request
        )

        return response.credits_remaining
    }

    func hasSufficientCredits(cost: Int) async throws -> Bool {
        let creditsRemaining = try await fetchCredits()
        return creditsRemaining >= cost
    }
}
```

**Updated ModelService.swift with Caching:**
```swift
import Supabase

class ModelService: ModelServiceProtocol {
    static let shared = ModelService()
    private let supabaseClient: SupabaseClient

    // Cache
    private var cachedModels: [ModelPreview]?
    private var cacheTimestamp: Date?
    private let cacheValidityDuration: TimeInterval = 3600 // 1 hour

    private init() {
        supabaseClient = SupabaseClient(
            supabaseURL: URL(string: AppConfig.supabaseURL)!,
            supabaseKey: AppConfig.supabaseAnonKey
        )
    }

    func fetchModels() async throws -> [ModelPreview] {
        // Check cache validity
        if let cached = cachedModels,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheValidityDuration {
            return cached
        }

        // Fetch from Supabase
        let models: [ModelPreview] = try await supabaseClient
            .from("models")
            .select()
            .eq("is_available", value: true)
            .order("is_featured", ascending: false)
            .execute()
            .value

        // Update cache
        cachedModels = models
        cacheTimestamp = Date()

        return models
    }

    func fetchModelDetail(id: String) async throws -> ModelDetail {
        let model: ModelDetail = try await supabaseClient
            .from("models")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value

        return model
    }

    func invalidateCache() {
        cachedModels = nil
        cacheTimestamp = nil
    }
}
```

#### Acceptance Criteria:
- [ ] Credits fetch correctly from Supabase
- [ ] Credit updates are reflected immediately
- [ ] Models load from database with correct filtering
- [ ] Model cache works (subsequent calls use cached data)
- [ ] Video generation creates job in database
- [ ] Result polling returns correct job status
- [ ] History loads with pagination
- [ ] Delete operation removes job from database

#### Risks:
- ⚠️ **High:** Credit deduction race condition → Action: Use database transactions in Edge Function
- ⚠️ **Medium:** Model cache stale data → Action: Add manual refresh capability
- ⚠️ **Medium:** Polling too frequent → Action: Implement exponential backoff (1s, 2s, 4s, 8s)
- ⚠️ **Low:** Pagination performance → Action: Add limit/offset parameters

---

### Phase 1.4: Testing & Validation (1.5 days)
**Priority:** P1 (High)
**Complexity:** Medium
**Dependencies:** Phase 1.1, 1.2, 1.3

#### Deliverables:
1. **Unit Tests for Services**
   - Test each service with mock APIClient
   - Test error handling paths
   - Test retry logic
   - Target 70%+ code coverage

2. **Integration Tests**
   - Test full video generation flow
   - Test onboarding flow (new vs. existing user)
   - Test credit purchase flow
   - Test account merge flow

3. **Network Error Simulation**
   - Test offline mode
   - Test timeout handling
   - Test retry exhaustion
   - Test rate limiting

4. **Manual QA Checklist**
   - Test on real device with real network
   - Test all happy paths
   - Test all error paths
   - Verify error messages are user-friendly

#### Implementation Details:

**Example Unit Test (VideoGenerationServiceTests.swift):**
```swift
import XCTest
@testable import RendioAI

@MainActor
class VideoGenerationServiceTests: XCTestCase {
    var service: VideoGenerationService!
    var mockAPIClient: MockAPIClient!

    override func setUp() async throws {
        mockAPIClient = MockAPIClient()
        service = VideoGenerationService(apiClient: mockAPIClient)
    }

    func testGenerateVideo_Success() async throws {
        // Given
        let expectedResponse = VideoGenerationResponse(
            job_id: "test-job-123",
            status: "pending",
            credits_used: 4
        )
        mockAPIClient.responseToReturn = expectedResponse

        let request = VideoGenerationRequest(
            userId: "test-user",
            modelId: "test-model",
            prompt: "Test prompt",
            settings: .default
        )

        // When
        let response = try await service.generateVideo(request: request)

        // Then
        XCTAssertEqual(response.job_id, "test-job-123")
        XCTAssertEqual(response.status, "pending")
        XCTAssertEqual(response.credits_used, 4)
        XCTAssertEqual(mockAPIClient.requestCount, 1)
    }

    func testGenerateVideo_EmptyPrompt_ThrowsError() async {
        // Given
        let request = VideoGenerationRequest(
            userId: "test-user",
            modelId: "test-model",
            prompt: "",
            settings: .default
        )

        // When/Then
        do {
            _ = try await service.generateVideo(request: request)
            XCTFail("Should throw badRequest error")
        } catch let error as AppError {
            XCTAssertEqual(error, .badRequest)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testGenerateVideo_NetworkFailure_RetriesThreeTimes() async {
        // Given
        mockAPIClient.shouldThrowError = true
        mockAPIClient.errorToThrow = AppError.networkTimeout

        let request = VideoGenerationRequest(
            userId: "test-user",
            modelId: "test-model",
            prompt: "Test prompt",
            settings: .default
        )

        // When/Then
        do {
            _ = try await service.generateVideo(request: request)
            XCTFail("Should throw after retries exhausted")
        } catch {
            // Verify retry attempts (1 initial + 3 retries = 4 total)
            XCTAssertEqual(mockAPIClient.requestCount, 4)
        }
    }
}
```

**Integration Test Example:**
```swift
@MainActor
class VideoGenerationFlowTests: XCTestCase {
    func testFullVideoGenerationFlow() async throws {
        // Given - Real services connected to test environment
        let videoService = VideoGenerationService.shared
        let creditService = CreditService.shared
        let resultService = ResultService.shared

        // 1. Check initial credits
        let initialCredits = try await creditService.fetchCredits()
        XCTAssertGreaterThan(initialCredits, 0)

        // 2. Generate video
        let request = VideoGenerationRequest(
            userId: "test-user",
            modelId: "1",
            prompt: "A beautiful sunset",
            settings: .default
        )
        let response = try await videoService.generateVideo(request: request)
        XCTAssertEqual(response.status, "pending")

        // 3. Verify credits deducted
        let creditsAfter = try await creditService.fetchCredits()
        XCTAssertEqual(creditsAfter, initialCredits - response.credits_used)

        // 4. Poll for result (max 30 seconds)
        var attempts = 0
        var finalStatus: VideoJob?
        while attempts < 15 {
            let job = try await resultService.fetchVideoJob(jobId: response.job_id)
            if job.status == .completed || job.status == .failed {
                finalStatus = job
                break
            }
            try await Task.sleep(for: .seconds(2))
            attempts += 1
        }

        // 5. Verify completion
        XCTAssertNotNil(finalStatus)
        XCTAssertEqual(finalStatus?.status, .completed)
    }
}
```

#### Acceptance Criteria:
- [ ] All unit tests pass with 70%+ coverage
- [ ] Integration tests pass in test environment
- [ ] Error handling works correctly (offline, timeout, server error)
- [ ] Retry logic works as expected
- [ ] User-facing error messages are localized and clear
- [ ] No crashes or force-unwrap failures

#### Risks:
- ⚠️ **Medium:** Test environment not stable → Action: Use mock backend or local Supabase
- ⚠️ **Medium:** Tests take too long → Action: Use shorter timeouts in test environment
- ⚠️ **Low:** Flaky tests due to network → Action: Mock network layer for unit tests

---

### Phase 1.5: Production Hardening (1 day)
**Priority:** P1 (High)
**Complexity:** Low-Medium
**Dependencies:** Phase 1.4 (all tests passing)

#### Deliverables:
1. **Security Review**
   - Review API key storage (use Keychain if needed)
   - Verify no secrets in code
   - Review RLS policies
   - Test unauthorized access attempts

2. **Error Logging & Monitoring**
   - Integrate crash reporting (Firebase Crashlytics or Sentry)
   - Add structured logging (OSLog)
   - Log all API errors with context
   - Add performance monitoring

3. **Performance Optimization**
   - Profile network requests with Instruments
   - Optimize JSON parsing
   - Reduce memory allocations
   - Add request deduplication

4. **Documentation**
   - Document all API endpoints
   - Document error codes
   - Document retry behavior
   - Update README with backend setup

#### Implementation Details:

**Logging Service (Core/Services/LoggingService.swift):**
```swift
import OSLog

class LoggingService {
    static let shared = LoggingService()

    private let logger = Logger(subsystem: "com.rendioai.app", category: "networking")

    func logAPIRequest(endpoint: String, method: String) {
        logger.info("🌐 API Request: \(method) \(endpoint)")
    }

    func logAPIResponse(endpoint: String, statusCode: Int, duration: TimeInterval) {
        logger.info("📡 API Response: \(endpoint) - Status: \(statusCode) - Duration: \(duration)s")
    }

    func logAPIError(endpoint: String, error: Error) {
        logger.error("❌ API Error: \(endpoint) - Error: \(error.localizedDescription)")
    }

    func logCreditUpdate(oldValue: Int, newValue: Int, reason: String) {
        logger.notice("💰 Credits Updated: \(oldValue) → \(newValue) - Reason: \(reason)")
    }
}
```

**Crash Reporting Integration:**
```swift
import FirebaseCrashlytics

class ErrorReportingService {
    static let shared = ErrorReportingService()

    func reportError(_ error: Error, context: [String: Any] = [:]) {
        #if !DEBUG
        Crashlytics.crashlytics().record(error: error)
        context.forEach { key, value in
            Crashlytics.crashlytics().setCustomValue(value, forKey: key)
        }
        #endif

        // Also log locally
        print("🔴 Error: \(error) | Context: \(context)")
    }

    func setUserIdentifier(_ userId: String) {
        #if !DEBUG
        Crashlytics.crashlytics().setUserID(userId)
        #endif
    }
}
```

#### Acceptance Criteria:
- [ ] No API keys hardcoded in source files
- [ ] All sensitive data stored in Keychain
- [ ] Crash reporting configured and tested
- [ ] Logging works without affecting performance
- [ ] All API endpoints documented
- [ ] README updated with setup instructions

#### Risks:
- ⚠️ **Low:** Logging overhead → Action: Use appropriate log levels (debug only in dev)
- ⚠️ **Low:** Crash reporting quota → Action: Configure sampling rate

---

## Section 2: Documentation Audit

### Overview
The Rendio AI project has comprehensive documentation across multiple domains. This section audits the existing documentation to determine its sufficiency for Phase 1 Backend Integration.

### Documentation Inventory

#### ✅ **Excellent Documentation (Production-Ready)**

1. **`../NEXT_STEPS_ROADMAP.md`** (468 lines)
   - **Status:** ✅ Complete and actionable
   - **Quality:** High - includes specific tasks, timelines, and code examples
   - **Coverage:** All 4 phases including backend integration
   - **Gap:** None - this document is excellent

2. **`docs/active/design/backend/api-layer-blueprint.md`** (244 lines)
   - **Status:** ✅ Complete
   - **Quality:** High - clear endpoint definitions, request/response structures
   - **Coverage:** All Edge Functions documented
   - **Gap:** None - includes folder structure and adapter pattern

3. **`docs/active/design/database/data-schema-final.md`** (193 lines)
   - **Status:** ✅ Complete
   - **Quality:** High - detailed table schemas with RLS policies
   - **Coverage:** All tables (users, video_jobs, models, credit_log)
   - **Gap:** None - includes indexes and constraints

4. **`docs/active/design/backend/api-adapter-interface.md`** (160 lines)
   - **Status:** ✅ Complete
   - **Quality:** High - clear provider abstraction with code examples
   - **Coverage:** Multi-provider support (FalAI, Sora, Runway, Pika)
   - **Gap:** None - includes error handling and response mapping

5. **`docs/active/design/general-rulebook.md`** (775 lines)
   - **Status:** ✅ Complete
   - **Quality:** Excellent - comprehensive architectural guidelines
   - **Coverage:** Architecture, naming, folder structure, patterns
   - **Gap:** None - this is a gold-standard rulebook

6. **`docs/active/design/operations/error-handling-guide.md`** (194 lines)
   - **Status:** ✅ Complete
   - **Quality:** High - unified error system with localization
   - **Coverage:** All error categories and mapping patterns
   - **Gap:** None - includes user-facing error messages

#### ⚠️ **Good Documentation (Needs Minor Enhancement)**

7. **`docs/active/design/security/security-policies.md`** (123 lines)
   - **Status:** ⚠️ Good but could be expanded
   - **Quality:** Medium-High
   - **Coverage:** RLS policies, access control, DeviceCheck basics
   - **Gaps:**
     - Missing: Certificate pinning guidance
     - Missing: API key rotation strategy
     - Missing: Rate limiting implementation details
     - Missing: Security testing checklist

8. **`.cursor/_context-backend-apis.md`** (160 lines)
   - **Status:** ⚠️ Good quick reference
   - **Quality:** Medium
   - **Coverage:** API endpoints with request/response examples
   - **Gaps:**
     - Missing: Authentication header examples
     - Missing: Error response formats
     - Missing: Pagination details for history endpoint

#### ❌ **Missing Documentation (Should Be Created)**

9. **Backend Integration Rulebook** - NOT FOUND
   - **Status:** ❌ Missing
   - **Recommended:** Create `docs/active/design/backend/backend-integration-rulebook.md`
   - **Should Include:**
     - Network layer conventions (APIClient usage patterns)
     - Request/response model naming conventions
     - Error handling patterns for backend services
     - Retry logic standards
     - Caching strategies
     - Environment configuration guidelines
     - Testing patterns for backend-connected services

10. **API Security Checklist** - NOT FOUND
    - **Status:** ❌ Missing
    - **Recommended:** Create `docs/active/design/security/api-security-checklist.md`
    - **Should Include:**
      - Pre-deployment security checklist
      - API key management verification
      - RLS policy testing procedures
      - Token refresh testing
      - Unauthorized access testing scenarios
      - Rate limiting verification
      - Input validation checklist

11. **Integration Test Plan** - NOT FOUND
    - **Status:** ❌ Missing
    - **Recommended:** Create `docs/active/testing/integration-test-plan.md`
    - **Should Include:**
      - Critical user flows to test
      - Test environment setup guide
      - Mock backend setup (if applicable)
      - Acceptance criteria for each flow
      - Performance benchmarks (e.g., API response times)
      - Error scenario test cases

12. **Backend Migration Guide** - NOT FOUND
    - **Status:** ❌ Missing
    - **Recommended:** Create `docs/active/guides/mock-to-real-migration-guide.md`
    - **Should Include:**
      - Step-by-step service replacement process
      - Checklist for each service
      - Rollback strategy
      - Feature flag usage (if applicable)
      - Verification steps after each service migration

### Documentation Sufficiency Analysis

**✅ Sufficient Areas:**
- Database schema design
- API endpoint definitions
- Provider adapter pattern
- Error handling system
- General architectural guidelines

**⚠️ Needs Enhancement:**
- Security implementation details
- API authentication examples
- Rate limiting specifics

**❌ Critical Gaps:**
- Backend integration coding standards
- Security testing procedures
- Integration test strategy
- Migration process documentation

### Recommendation: Create Backend Rulebook

**YES - A Backend Integration Rulebook is HIGHLY RECOMMENDED**

**Justification:**
1. **Consistency:** 10 services need backend integration - need consistent patterns
2. **Maintainability:** New developers should follow same conventions
3. **Quality:** Prevents drift between frontend models and backend schemas
4. **Efficiency:** Reduces decision paralysis during implementation
5. **Precedent:** The general-rulebook.md is excellent; backend-specific version needed

**Suggested Structure for Backend Integration Rulebook:**
```
# Backend Integration Rulebook

## 1. Network Layer Standards
   - APIClient usage patterns
   - Request builder conventions
   - Response parsing standards

## 2. Service Layer Conventions
   - Protocol naming (XServiceProtocol)
   - Singleton pattern usage
   - Dependency injection for testing
   - Mock service implementation

## 3. Model Mapping
   - Frontend model ↔ Backend response mapping
   - Codable conformance patterns
   - Date/timestamp handling
   - Enum raw value standards

## 4. Error Handling
   - HTTP status code mapping
   - AppError usage patterns
   - Localized error key conventions
   - Error context preservation

## 5. Authentication
   - Token management
   - Header injection
   - Session refresh
   - Unauthorized handling

## 6. Retry Logic
   - Retryable error detection
   - Exponential backoff formula
   - Max retry attempts
   - Request idempotency

## 7. Caching Strategies
   - Cache invalidation rules
   - Cache validity duration
   - Memory vs. disk caching
   - Cache key conventions

## 8. Testing Patterns
   - Service unit test structure
   - Mock APIClient usage
   - Integration test setup
   - Async test conventions

## 9. Configuration Management
   - Environment variables
   - Build configuration
   - Info.plist keys
   - Secret management

## 10. Migration Checklist
    - Replace mock service
    - Add unit tests
    - Add integration test
    - Update documentation
    - Code review checklist
```

---

## Section 3: Recommendations & Technical Standards

### 3.1 Backend Service Layer Conventions

**Protocol-Oriented Design (KEEP CURRENT PATTERN):**
```swift
// ✅ CORRECT: Protocol defines public interface
protocol VideoGenerationServiceProtocol {
    func generateVideo(request: VideoGenerationRequest) async throws -> VideoGenerationResponse
}

// ✅ CORRECT: Production implementation uses APIClient
class VideoGenerationService: VideoGenerationServiceProtocol {
    static let shared = VideoGenerationService()
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

// ✅ CORRECT: Separate mock for testing
class MockVideoGenerationService: VideoGenerationServiceProtocol {
    var responseToReturn: VideoGenerationResponse?
    var shouldThrowError = false

    func generateVideo(request: VideoGenerationRequest) async throws -> VideoGenerationResponse {
        if shouldThrowError { throw AppError.networkFailure }
        return responseToReturn ?? .default
    }
}
```

**❌ ANTI-PATTERNS TO AVOID:**
```swift
// ❌ WRONG: Hardcoded URLs in service
class VideoService {
    func generate() async throws {
        let url = URL(string: "https://api.example.com/generate")! // WRONG
    }
}

// ❌ WRONG: Mixed mock and real logic in same class
class VideoService {
    func generate() async throws {
        #if DEBUG
        return mockData // WRONG - separate classes instead
        #else
        return realData
        #endif
    }
}

// ❌ WRONG: No protocol (untestable)
class VideoService {
    static let shared = VideoService() // No protocol = hard to mock
}

// ❌ WRONG: Force-unwrapped optionals
let response = try! await service.generate() // WRONG - handle errors properly
```

### 3.2 Request/Response Model Standards

**Naming Convention:**
- Request models: `{Action}{Resource}Request` (e.g., `VideoGenerationRequest`)
- Response models: `{Action}{Resource}Response` (e.g., `VideoGenerationResponse`)
- Database models: `{Resource}` (e.g., `VideoJob`, `User`)

**Codable Best Practices:**
```swift
// ✅ CORRECT: Explicit CodingKeys for snake_case ↔ camelCase
struct VideoGenerationRequest: Codable {
    let userId: String
    let modelId: String
    let prompt: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case modelId = "model_id"
        case prompt
    }
}

// ✅ CORRECT: Date strategy configuration
extension JSONDecoder {
    static var backend: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

// ✅ CORRECT: Handle optional fields gracefully
struct User: Codable {
    let id: String
    let email: String?
    let deviceId: String?
    let creditsRemaining: Int

    // Provide defaults for optional fields
    var displayEmail: String {
        email ?? "Guest User"
    }
}

// ❌ WRONG: Force-unwrapping in init
struct User: Codable {
    let email: String // Should be optional for guest users

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.email = try container.decode(String.self, forKey: .email) // CRASHES for guests
    }
}
```

### 3.3 Environment Handling Standards

**Configuration Priority (Recommended):**
1. **Development:** Use `.xcconfig` files + Info.plist
2. **Staging:** Use separate `.xcconfig` + build scheme
3. **Production:** Use separate `.xcconfig` + build scheme

**Setup:**
```
RendioAI/
├── Configuration/
│   ├── Development.xcconfig
│   ├── Staging.xcconfig
│   └── Production.xcconfig
└── Info.plist (references $(SUPABASE_URL) from xcconfig)
```

**Development.xcconfig:**
```
// Development configuration
SUPABASE_URL = https://dev.supabase.co
SUPABASE_ANON_KEY = eyJhbGc... (dev key)
API_TIMEOUT = 30
ENABLE_LOGGING = YES
```

**Production.xcconfig:**
```
// Production configuration
SUPABASE_URL = https://prod.supabase.co
SUPABASE_ANON_KEY = eyJhbGc... (prod key)
API_TIMEOUT = 15
ENABLE_LOGGING = NO
```

**❌ NEVER DO THIS:**
```swift
// ❌ WRONG: Hardcoded URLs
let baseURL = "https://api.example.com"

// ❌ WRONG: Committed API keys
let apiKey = "sk_live_abc123..."

// ❌ WRONG: Environment check in every file
#if DEBUG
let url = "https://dev.example.com"
#else
let url = "https://prod.example.com"
#endif
```

### 3.4 Shared Backend Coding Guidelines

**Error Handling:**
```swift
// ✅ CORRECT: Specific error mapping
func mapHTTPError(_ statusCode: Int) -> AppError {
    switch statusCode {
    case 400: return .badRequest
    case 401: return .unauthorized
    case 403: return .forbidden
    case 404: return .notFound
    case 429: return .rateLimitExceeded
    case 500...599: return .serverError
    default: return .unknownError(statusCode: statusCode)
    }
}

// ✅ CORRECT: Preserve error context
catch {
    ErrorReportingService.shared.reportError(error, context: [
        "endpoint": endpoint,
        "userId": userId
    ])
    throw mapError(error)
}

// ❌ WRONG: Generic error without context
catch {
    throw AppError.networkFailure // Lost all context
}
```

**Async/Await Best Practices:**
```swift
// ✅ CORRECT: Use async/await consistently
func fetchData() async throws -> Data {
    return try await apiClient.request(...)
}

// ✅ CORRECT: Handle cancellation
func longRunningTask() async throws {
    try Task.checkCancellation()
    // ... work ...
}

// ❌ WRONG: Mixing completion handlers with async/await
func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
    Task {
        // WRONG - use async/await throughout
    }
}

// ❌ WRONG: Unstructured concurrency
func fetchMultiple() {
    Task { try await fetch1() } // Unstructured - use async let or TaskGroup
    Task { try await fetch2() }
}
```

**Dependency Injection:**
```swift
// ✅ CORRECT: Inject dependencies for testability
class HomeViewModel: ObservableObject {
    private let modelService: ModelServiceProtocol
    private let creditService: CreditServiceProtocol

    init(
        modelService: ModelServiceProtocol = ModelService.shared,
        creditService: CreditServiceProtocol = CreditService.shared
    ) {
        self.modelService = modelService
        self.creditService = creditService
    }
}

// ❌ WRONG: Hardcoded singleton usage
class HomeViewModel: ObservableObject {
    func loadData() {
        let models = ModelService.shared.fetchModels() // Untestable
    }
}
```

### 3.5 Integration Drift Prevention

**Risk: Frontend models don't match backend schema**

**Mitigation Strategies:**

1. **Use Shared Models Where Possible:**
```swift
// ✅ CORRECT: Single source of truth
struct VideoJob: Codable {
    let id: String
    let userId: String
    let status: JobStatus
    let createdAt: Date

    // Works for both API response and local storage
}

// ❌ WRONG: Duplicate models
struct VideoJobResponse: Codable { ... } // API response
struct VideoJobLocal { ... } // Local model
// Now you have two models to keep in sync!
```

2. **Backend Response Validation:**
```swift
// ✅ CORRECT: Validate response structure
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
    }
}
```

3. **Schema Change Detection:**
```swift
// ✅ CORRECT: Log decoding failures
do {
    let response = try decoder.decode(VideoJob.self, from: data)
} catch {
    // This alerts you to schema mismatches
    ErrorReportingService.shared.reportError(error, context: [
        "endpoint": endpoint,
        "responseBody": String(data: data, encoding: .utf8) ?? ""
    ])
    throw AppError.invalidResponse
}
```

4. **Integration Tests as Safety Net:**
```swift
// ✅ CORRECT: Integration test catches schema changes
func testVideoGenerationResponseStructure() async throws {
    let response = try await VideoGenerationService.shared.generateVideo(...)

    // If backend changes response structure, this test fails
    XCTAssertNotNil(response.job_id)
    XCTAssertNotNil(response.status)
    XCTAssertNotNil(response.credits_used)
}
```

---

## Section 4: Technical Risks & Mitigations

### 4.1 Critical Risks (P0 - Must Address Before Launch)

#### Risk 1: Credit Deduction Race Condition
**Scenario:** User taps "Generate" multiple times quickly → multiple videos generated → credits over-deducted

**Impact:** 🔴 CRITICAL - Financial impact, user trust

**Mitigation:**
1. **Frontend:** Disable button immediately after tap
```swift
@Published var isGenerating = false

func generateVideo() async {
    guard !isGenerating else { return } // Prevent duplicate calls
    isGenerating = true
    defer { isGenerating = false }

    // ... generation logic
}
```

2. **Backend:** Use database transactions in Edge Function
```typescript
// Supabase Edge Function
const { data: user, error } = await supabase
  .rpc('deduct_credits_atomic', {
    p_user_id: userId,
    p_amount: creditCost
  });
```

3. **Database:** Create atomic RPC function
```sql
CREATE OR REPLACE FUNCTION deduct_credits_atomic(
  p_user_id uuid,
  p_amount integer
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
  v_current_credits integer;
BEGIN
  -- Lock row for update
  SELECT credits_remaining INTO v_current_credits
  FROM users
  WHERE id = p_user_id
  FOR UPDATE;

  -- Check sufficient credits
  IF v_current_credits < p_amount THEN
    RAISE EXCEPTION 'Insufficient credits';
  END IF;

  -- Deduct atomically
  UPDATE users
  SET credits_remaining = credits_remaining - p_amount
  WHERE id = p_user_id;

  RETURN credits_remaining;
END;
$$;
```

**Verification:**
- [ ] Button disabled during generation
- [ ] Database transaction tested
- [ ] Concurrent request test passes

---

#### Risk 2: Token Refresh Failure
**Scenario:** User session expires mid-operation → API calls fail with 401

**Impact:** 🔴 HIGH - Breaks user flow, requires re-authentication

**Mitigation:**
1. **Implement Automatic Token Refresh:**
```swift
class AuthService {
    func refreshTokenIfNeeded() async throws {
        guard let session = try await supabaseClient.auth.session else {
            throw AppError.unauthorized
        }

        let expiresAt = session.expiresAt
        let now = Date().timeIntervalSince1970

        // Refresh if token expires in < 5 minutes
        if expiresAt - now < 300 {
            _ = try await supabaseClient.auth.refreshSession()
        }
    }
}
```

2. **Intercept 401 Responses:**
```swift
class APIClient {
    func request<T: Decodable>(...) async throws -> T {
        do {
            return try await executeRequest(...)
        } catch AppError.unauthorized {
            // Attempt token refresh
            try await AuthService.shared.refreshTokenIfNeeded()
            // Retry request once
            return try await executeRequest(...)
        }
    }
}
```

**Verification:**
- [ ] Token refresh tested
- [ ] 401 retry logic tested
- [ ] User not logged out unnecessarily

---

#### Risk 3: Supabase RLS Policy Misconfiguration
**Scenario:** RLS policy allows user to access other users' data

**Impact:** 🔴 CRITICAL - Security breach, privacy violation

**Mitigation:**
1. **Test RLS Policies in Supabase Dashboard:**
```sql
-- Test as specific user
SET request.jwt.claim.sub = 'user-id-here';

-- Should return only user's own data
SELECT * FROM video_jobs WHERE user_id = auth.uid();
```

2. **Integration Test for Unauthorized Access:**
```swift
func testCannotAccessOtherUsersVideos() async throws {
    // Sign in as User A
    try await AuthService.shared.signInAsTestUser(id: "user-a")

    // Attempt to fetch User B's video
    do {
        _ = try await HistoryService.shared.fetchVideoJob(jobId: "user-b-video-id")
        XCTFail("Should not access other user's video")
    } catch AppError.forbidden {
        // Expected
    }
}
```

**Verification:**
- [ ] All RLS policies tested
- [ ] Cross-user access test passes
- [ ] Security review completed

---

### 4.2 High Risks (P1 - Address During Implementation)

#### Risk 4: API Response Time Variability
**Scenario:** Video generation takes 30s-5min → user doesn't know if app is working

**Impact:** 🟡 HIGH - Poor UX, user abandonment

**Mitigation:**
1. **Implement Progressive Status Updates:**
```swift
func pollJobStatus(jobId: String) async throws -> VideoJob {
    var attempts = 0
    var delay: TimeInterval = 1.0

    while attempts < 60 { // Max 5 minutes (if delay = 5s avg)
        let job = try await fetchVideoJob(jobId: jobId)

        // Show progress to user
        if let progress = job.progress {
            updateProgress(progress) // 0-100%
        }

        if job.status == .completed || job.status == .failed {
            return job
        }

        // Exponential backoff: 1s, 2s, 4s, 8s (max)
        try await Task.sleep(for: .seconds(min(delay, 8.0)))
        delay *= 2
        attempts += 1
    }

    throw AppError.timeout
}
```

2. **Add Progress Indicators:**
```swift
// In ViewModel
@Published var generationProgress: Double = 0.0
@Published var generationStatus: String = "Initializing..."

func updateProgress(_ progress: Double) {
    self.generationProgress = progress

    switch progress {
    case 0..<0.2:
        generationStatus = "Preparing request..."
    case 0.2..<0.5:
        generationStatus = "Generating video..."
    case 0.5..<0.8:
        generationStatus = "Processing video..."
    case 0.8..<1.0:
        generationStatus = "Finalizing..."
    default:
        generationStatus = "Complete!"
    }
}
```

**Verification:**
- [ ] Polling works with exponential backoff
- [ ] Progress indicator shows status
- [ ] Timeout after reasonable duration

---

#### Risk 5: Model Cache Stale Data
**Scenario:** New model added to database → not showing in app for 1 hour (cache TTL)

**Impact:** 🟡 MEDIUM - Outdated UI, user confusion

**Mitigation:**
1. **Add Manual Cache Invalidation:**
```swift
class ModelService {
    func invalidateCache() {
        cachedModels = nil
        cacheTimestamp = nil
    }
}

// In ViewModel
func refreshModels() async {
    ModelService.shared.invalidateCache()
    await loadModels()
}
```

2. **Add Pull-to-Refresh:**
```swift
// In HomeView
.refreshable {
    await viewModel.refreshModels()
}
```

3. **Invalidate Cache on App Foreground (Optional):**
```swift
.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
    Task {
        await viewModel.refreshModels()
    }
}
```

**Verification:**
- [ ] Pull-to-refresh invalidates cache
- [ ] Manual refresh works
- [ ] Cache expires after TTL

---

### 4.3 Medium Risks (P2 - Monitor & Address if Occurs)

#### Risk 6: Pagination Performance Degradation
**Scenario:** User has 1000+ videos in history → slow query

**Impact:** 🟢 MEDIUM - Slow loading, poor UX for power users

**Mitigation:**
1. **Implement Cursor-Based Pagination:**
```swift
func fetchVideoJobs(limit: Int = 20, after: String? = nil) async throws -> PaginatedResponse<VideoJob> {
    struct HistoryQuery: Encodable {
        let user_id: String
        let limit: Int
        let after: String?
    }

    let query = HistoryQuery(
        user_id: userId,
        limit: limit,
        after: after
    )

    let response: PaginatedResponse<VideoJob> = try await apiClient.request(
        endpoint: "get-video-jobs",
        method: .POST,
        body: query
    )

    return response
}

struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let nextCursor: String?
    let hasMore: Bool
}
```

2. **Add Database Index:**
```sql
CREATE INDEX idx_video_jobs_user_created ON video_jobs (user_id, created_at DESC);
```

**Verification:**
- [ ] Query performance tested with 1000+ records
- [ ] Database index created
- [ ] Pagination UI works

---

### 4.4 Authentication Best Practices

**Token Storage:**
```swift
// ✅ CORRECT: Supabase SDK handles token storage securely
// No manual token storage needed - SDK uses Keychain automatically
```

**Session Management:**
```swift
class AuthService {
    func observeAuthState() {
        supabaseClient.auth.onAuthStateChange { event, session in
            switch event {
            case .signedIn:
                // Update app state
                UserState.shared.setCurrentUser(session?.user)
            case .signedOut:
                // Clear app state
                UserState.shared.clearCurrentUser()
            case .tokenRefreshed:
                // Session automatically updated by SDK
                break
            }
        }
    }
}
```

**Unauthorized Access Handling:**
```swift
// In APIClient
if statusCode == 401 {
    // Attempt token refresh
    if try await AuthService.shared.refreshTokenIfNeeded() {
        // Retry request with new token
        return try await executeRequest(request)
    } else {
        // Token refresh failed - sign out user
        NotificationCenter.default.post(name: .userUnauthorized, object: nil)
        throw AppError.unauthorized
    }
}
```

---

## Section 5: Summary Checklist

### Pre-Implementation Checklist

**Environment Setup:**
- [ ] Supabase project URL and anon key obtained
- [ ] DeviceCheck enabled in Apple Developer account
- [ ] Apple Sign-In configured in Supabase Auth
- [ ] Test environment available (dev/staging)
- [ ] `.xcconfig` files created for each environment
- [ ] `.gitignore` updated to exclude sensitive config files

**Dependencies:**
- [ ] Supabase Swift SDK installed (`supabase-swift`)
- [ ] Firebase Crashlytics installed (optional but recommended)
- [ ] Network reachability framework available (if needed)

**Documentation:**
- [ ] Read all Phase 1 documentation
- [ ] Understand current service architecture
- [ ] Review backend API documentation
- [ ] Review database schema

---

### Implementation Checklist (Per Subphase)

**Phase 1.1: Foundation & Configuration**
- [ ] `AppConfig.swift` created with environment support
- [ ] `SupabaseConfig.swift` created
- [ ] `APIClient.swift` implemented with retry logic
- [ ] `APIRequest.swift` and `APIResponse.swift` created
- [ ] `NetworkInterceptor.swift` implemented
- [ ] Configuration tested in all environments
- [ ] Logging works (debug only)

**Phase 1.2: Authentication & Device Management**
- [ ] `DeviceCheckService.swift` uses real Apple DeviceCheck
- [ ] `OnboardingService.swift` calls `/device/check`
- [ ] `AuthService.swift` integrates Supabase Auth
- [ ] Apple Sign-In flow tested
- [ ] Token refresh tested
- [ ] Guest-to-registered merge tested

**Phase 1.3: Core Services Backend Integration**
- [ ] `CreditService.swift` fetches from Supabase
- [ ] `ModelService.swift` fetches from Supabase with caching
- [ ] `VideoGenerationService.swift` calls `/generate-video`
- [ ] `ResultService.swift` polls `/get-video-status`
- [ ] `HistoryService.swift` fetches from `/get-video-jobs`
- [ ] All services handle errors correctly
- [ ] All services have retry logic

**Phase 1.4: Testing & Validation**
- [ ] Unit tests written for all services
- [ ] 70%+ code coverage achieved
- [ ] Integration tests pass
- [ ] Network error simulation tested
- [ ] Timeout handling tested
- [ ] Manual QA completed

**Phase 1.5: Production Hardening**
- [ ] Security review completed
- [ ] No hardcoded secrets in code
- [ ] Crash reporting integrated
- [ ] Logging service implemented
- [ ] Performance profiled with Instruments
- [ ] Documentation updated

---

### Post-Implementation Verification

**Functional Verification:**
- [ ] User can complete onboarding (new user)
- [ ] User can sign in with Apple
- [ ] User can browse models
- [ ] User can generate video
- [ ] Video generation polls correctly
- [ ] Credits deduct correctly
- [ ] History loads correctly
- [ ] User can delete videos
- [ ] User can sign out
- [ ] Guest user flow works

**Non-Functional Verification:**
- [ ] App doesn't crash on network errors
- [ ] Offline mode handled gracefully
- [ ] Error messages are user-friendly
- [ ] API response time acceptable (< 2s for non-generation)
- [ ] Memory usage acceptable
- [ ] No memory leaks detected
- [ ] Battery usage acceptable

**Security Verification:**
- [ ] RLS policies tested
- [ ] Unauthorized access blocked
- [ ] API keys not exposed
- [ ] Token refresh works
- [ ] Session timeout works

---

## Conclusion

This Phase 1 Backend Integration plan provides a comprehensive, production-ready roadmap for replacing all mock services with real Supabase backend integration. The plan is structured into 5 manageable subphases with clear deliverables, acceptance criteria, and risk mitigations.

**Key Success Factors:**
1. ✅ Complete Phase 1.1 (Configuration) first - it blocks everything else
2. ✅ Test thoroughly after each subphase
3. ✅ Create backend-integration-rulebook.md to maintain consistency
4. ✅ Use integration tests as safety net for schema changes
5. ✅ Monitor and address risks proactively

**Estimated Timeline:**
- Phase 1.1: 2 days
- Phase 1.2: 1.5 days
- Phase 1.3: 2.5 days
- Phase 1.4: 1.5 days
- Phase 1.5: 1 day
- **Total: 8-9 days** (approximately 2 weeks with buffer)

**Next Steps:**
1. Review and approve this plan
2. Set up Supabase credentials and DeviceCheck
3. Create backend-integration-rulebook.md
4. Begin Phase 1.1 implementation
5. Daily standups to track progress and blockers

---

**Document Status:** ✅ Ready for Review
**Last Updated:** 2025-01-05
**Next Review:** After Phase 1.1 completion
