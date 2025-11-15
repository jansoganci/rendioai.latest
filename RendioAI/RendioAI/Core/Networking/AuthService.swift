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
