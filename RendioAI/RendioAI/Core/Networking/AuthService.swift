//
//  AuthService.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation
import AuthenticationServices
import SwiftUI

// MARK: - AuthService Protocol

protocol AuthServiceProtocol {
    /// Initiates Apple Sign-In flow and returns authentication result
    func signInWithApple() async throws -> AppleAuthResult

    /// Merges guest account with authenticated Apple user
    func mergeGuestToUser(deviceId: String, appleSub: String, identityToken: Data?, authorizationCode: Data?) async throws -> User

    /// Signs out the current user (clears session but keeps device_id)
    func signOut(userId: String) async throws

    /// Retrieves current authentication state
    func getAuthState() async -> AuthState
}

// MARK: - Auth State

enum AuthState {
    case guest(deviceId: String)
    case authenticated(user: User)
    case unauthenticated
}

// MARK: - AuthService Implementation

@MainActor
class AuthService: NSObject, AuthServiceProtocol {
    static let shared = AuthService()

    // Private properties
    private var currentContinuation: CheckedContinuation<AppleAuthResult, Error>?

    // Token refresh concurrency control
    private nonisolated(unsafe) var refreshTask: Task<String, Error>?
    private let refreshLock = NSLock()

    // MARK: - Sign In with Apple

    func signInWithApple() async throws -> AppleAuthResult {
        return try await withCheckedThrowingContinuation { continuation in
            self.currentContinuation = continuation

            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }

    // MARK: - Merge Guest to User

    func mergeGuestToUser(
        deviceId: String,
        appleSub: String,
        identityToken: Data?,
        authorizationCode: Data?
    ) async throws -> User {
        // Delegate to UserService which has the real implementation
        // identityToken and authorizationCode are available for future Apple verification
        // but not needed for basic merge operation

        print("✅ AuthService: Delegating merge to UserService")
        print("   Device ID: \(deviceId)")
        print("   Apple Sub: \(appleSub)")

        let mergedUser = try await UserService.shared.mergeGuestToUser(
            deviceId: deviceId,
            appleSub: appleSub
        )

        // Phase 2: Store user credentials in Keychain
        // Phase 2: Update local auth state

        print("✅ AuthService: Merge completed successfully")
        print("   User ID: \(mergedUser.id)")
        print("   Credits: \(mergedUser.creditsRemaining)")

        return mergedUser
    }

    // MARK: - Sign Out

    func signOut(userId: String) async throws {
        // Phase 2: Replace with actual logout endpoint call
        // Endpoint: POST /api/logout
        // Body: { user_id }
        // Currently using mock data for development

        // Simulate network delay
        try await Task.sleep(for: .seconds(0.5))

        // Phase 2: Clear auth tokens from Keychain (keep device_id)
        // Phase 2: Clear any cached user data

        print("User signed out successfully: \(userId)")
    }

    // MARK: - Get Auth State

    func getAuthState() async -> AuthState {
        // Phase 2: Check Keychain for stored credentials
        // - If apple_sub exists and valid → .authenticated
        // - If only device_id exists → .guest
        // - Otherwise → .unauthenticated
        // Currently using mock implementation

        // Mock implementation
        if let deviceId = getDeviceId() {
            return .guest(deviceId: deviceId)
        }

        return .unauthenticated
    }

    // MARK: - Token Management

    /// Refreshes the access token using the refresh token
    /// Thread-safe: Multiple concurrent calls will share the same refresh operation
    /// - Returns: New access token
    /// - Throws: AppError.unauthorized if refresh fails or no refresh token available
    nonisolated func refreshAccessToken() async throws -> String {
        // Concurrency protection: Check if refresh is already in progress
        refreshLock.lock()
        if let existingTask = refreshTask {
            refreshLock.unlock()
            print("🔄 AuthService: Refresh already in progress, waiting for it...")
            return try await existingTask.value
        }

        // Start new refresh task
        let task = Task<String, Error> {
            return try await self.performTokenRefresh()
        }
        refreshTask = task
        refreshLock.unlock()

        // Ensure we clean up the task when done
        defer {
            refreshLock.lock()
            refreshTask = nil
            refreshLock.unlock()
        }

        return try await task.value
    }

    /// Performs the actual token refresh (called by refreshAccessToken)
    private nonisolated func performTokenRefresh() async throws -> String {
        print("🔄 AuthService: Starting token refresh...")

        // 1. Get refresh token from Keychain
        guard let refreshToken = KeychainManager.shared.getRefreshToken() else {
            print("❌ AuthService: No refresh token found in Keychain")
            throw AppError.unauthorized
        }

        // 2. Build request to Supabase auth endpoint
        guard let url = URL(string: "\(AppConfig.supabaseURL)/auth/v1/token?grant_type=refresh_token") else {
            print("❌ AuthService: Invalid Supabase URL")
            throw AppError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")

        // 3. Send refresh token in request body
        let body = ["refresh_token": refreshToken]
        request.httpBody = try JSONEncoder().encode(body)

        // 4. Make network request
        let (data, response) = try await URLSession.shared.data(for: request)

        // 5. Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ AuthService: Invalid response type")
            throw AppError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("❌ AuthService: Token refresh failed (HTTP \(httpResponse.statusCode)): \(errorData)")
            }
            throw AppError.unauthorized
        }

        // 6. Parse response
        struct RefreshResponse: Codable {
            let access_token: String
            let refresh_token: String?
            let expires_in: Int?
            let token_type: String?
        }

        let refreshResponse = try JSONDecoder().decode(RefreshResponse.self, from: data)

        // 7. Save new access token to Keychain
        KeychainManager.shared.saveAccessToken(refreshResponse.access_token)

        // 8. Save new refresh token if provided (token rotation)
        if let newRefreshToken = refreshResponse.refresh_token {
            KeychainManager.shared.saveRefreshToken(newRefreshToken)
            print("✅ AuthService: Refresh token rotated and saved")
        }

        // 9. Log success
        if let expiresIn = refreshResponse.expires_in {
            print("✅ AuthService: Token refreshed successfully (expires in \(expiresIn)s)")
        } else {
            print("✅ AuthService: Token refreshed successfully")
        }

        return refreshResponse.access_token
    }

    /// Gets a valid access token, refreshing if expired or expiring soon
    /// - Parameter bufferMinutes: Refresh if token expires within this many minutes (default: 5)
    /// - Returns: Valid access token
    /// - Throws: AppError if no token available or refresh fails
    nonisolated func getValidAccessToken(bufferMinutes: Int = 5) async throws -> String {
        // 1. Get current access token from Keychain
        guard let accessToken = KeychainManager.shared.getAccessToken() else {
            print("❌ AuthService: No access token found in Keychain")
            throw AppError.unauthorized
        }

        // 2. Check if token is expired or expiring soon
        if let expiryDate = KeychainManager.shared.getAccessTokenExpiry() {
            let now = Date()
            let bufferDate = now.addingTimeInterval(TimeInterval(bufferMinutes * 60))

            if bufferDate >= expiryDate {
                // Token expired or expiring soon - refresh it
                let timeUntilExpiry = expiryDate.timeIntervalSince(now)
                let minutesUntilExpiry = Int(timeUntilExpiry / 60)

                if minutesUntilExpiry <= 0 {
                    print("⚠️ AuthService: Token EXPIRED - refreshing now...")
                } else {
                    print("⚠️ AuthService: Token expires in \(minutesUntilExpiry) min - refreshing proactively...")
                }

                return try await refreshAccessToken()
            } else {
                // Token is still valid
                let timeUntilExpiry = expiryDate.timeIntervalSince(now)
                let minutesUntilExpiry = Int(timeUntilExpiry / 60)
                print("✅ AuthService: Token still valid (expires in \(minutesUntilExpiry) min)")
            }
        } else {
            // Couldn't parse expiry - refresh to be safe
            print("⚠️ AuthService: Couldn't parse token expiry - refreshing to be safe...")
            return try await refreshAccessToken()
        }

        // 3. Return existing valid token
        return accessToken
    }

    /// Refreshes token in background if needed (safe for app launch)
    /// Does not throw - logs errors instead
    nonisolated func refreshTokenIfNeeded(bufferMinutes: Int = 10) async {
        // 1. Check if user is onboarded (has user_id)
        guard UserDefaultsManager.shared.currentUserId != nil else {
            print("ℹ️ AuthService: No user ID found - skipping token refresh")
            return
        }

        // 2. Check if access token exists
        guard KeychainManager.shared.getAccessToken() != nil else {
            print("ℹ️ AuthService: No access token found - skipping refresh")
            return
        }

        // 3. Check if token expires soon
        guard let expiryDate = KeychainManager.shared.getAccessTokenExpiry() else {
            print("⚠️ AuthService: Couldn't parse token expiry - attempting refresh anyway...")

            do {
                _ = try await refreshAccessToken()
            } catch {
                print("❌ AuthService: Background refresh failed: \(error.localizedDescription)")
            }
            return
        }

        // 4. Calculate if refresh is needed
        let now = Date()
        let bufferDate = now.addingTimeInterval(TimeInterval(bufferMinutes * 60))

        if bufferDate >= expiryDate {
            let timeUntilExpiry = expiryDate.timeIntervalSince(now)
            let minutesUntilExpiry = Int(timeUntilExpiry / 60)

            if minutesUntilExpiry <= 0 {
                print("🔄 AuthService: Token EXPIRED - refreshing in background...")
            } else {
                print("🔄 AuthService: Token expires in \(minutesUntilExpiry) min - refreshing proactively in background...")
            }

            do {
                _ = try await refreshAccessToken()
                print("✅ AuthService: Background token refresh successful")
            } catch {
                print("❌ AuthService: Background refresh failed: \(error.localizedDescription)")
                // Don't throw - this is a background operation
            }
        } else {
            let timeUntilExpiry = expiryDate.timeIntervalSince(now)
            let minutesUntilExpiry = Int(timeUntilExpiry / 60)
            print("✅ AuthService: Token still valid (expires in \(minutesUntilExpiry) min) - no refresh needed")
        }
    }

    // MARK: - Private Helpers

    private func getDeviceId() -> String? {
        // Phase 2: Retrieve from Keychain
        // Currently using mock device ID
        return "mock-device-id-12345"
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                currentContinuation?.resume(throwing: AppError.unauthorized)
                currentContinuation = nil
                return
            }

            let result = AppleAuthResult(
                appleSub: appleIDCredential.user,
                fullName: appleIDCredential.fullName,
                email: appleIDCredential.email,
                identityToken: appleIDCredential.identityToken,
                authorizationCode: appleIDCredential.authorizationCode
            )

            currentContinuation?.resume(returning: result)
            currentContinuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            // Check if user cancelled
            if let authError = error as? ASAuthorizationError,
               authError.code == .canceled {
                currentContinuation?.resume(throwing: AppError.unauthorized)
            } else {
                currentContinuation?.resume(throwing: AppError.networkError(error.localizedDescription))
            }
            currentContinuation = nil
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Get the key window from main actor
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return ASPresentationAnchor()
        }
        return window
    }
}

// MARK: - Mock AuthService

class MockAuthService: AuthServiceProtocol {
    var shouldSucceed = true
    var mockUser: User?

    func signInWithApple() async throws -> AppleAuthResult {
        try await Task.sleep(for: .seconds(1.0))

        if shouldSucceed {
            return AppleAuthResult(
                appleSub: "001234.abc123def456.7890",
                fullName: PersonNameComponents(
                    givenName: "John",
                    familyName: "Doe"
                ),
                email: "john.doe@privaterelay.appleid.com",
                identityToken: Data(),
                authorizationCode: Data()
            )
        } else {
            throw AppError.unauthorized
        }
    }

    func mergeGuestToUser(
        deviceId: String,
        appleSub: String,
        identityToken: Data?,
        authorizationCode: Data?
    ) async throws -> User {
        try await Task.sleep(for: .seconds(1.0))

        if shouldSucceed {
            return mockUser ?? User(
                id: UUID().uuidString,
                email: "john.doe@privaterelay.appleid.com",
                deviceId: deviceId,
                appleSub: appleSub,
                isGuest: false,
                tier: .free,
                creditsRemaining: 10,
                creditsTotal: 10,
                initialGrantClaimed: true,
                language: "en",
                themePreference: "system",
                createdAt: Date(),
                updatedAt: Date()
            )
        } else {
            throw AppError.networkError("Merge failed")
        }
    }

    func signOut(userId: String) async throws {
        try await Task.sleep(for: .seconds(0.5))

        if !shouldSucceed {
            throw AppError.networkError("Sign out failed")
        }
    }

    func getAuthState() async -> AuthState {
        if let user = mockUser {
            return .authenticated(user: user)
        }
        return .guest(deviceId: "mock-device-id")
    }
}
