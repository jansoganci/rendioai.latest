//
//  OnboardingResponse.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

// MARK: - Onboarding Response Model

struct OnboardingResponse: Codable {
    // Backend actually returns these fields
    let user_id: String
    let credits_remaining: Int
    let is_new: Bool
    let access_token: String?      // JWT token for Supabase Storage operations
    let refresh_token: String?     // Refresh token to get new access_token
    
    // Computed properties for compatibility with existing code
    var deviceId: String { user_id }  // Use user_id as deviceId for compatibility
    var isExistingUser: Bool { !is_new }
    var creditsRemaining: Int { credits_remaining }
    var initialGrantClaimed: Bool { true }  // Assume granted if backend returns credits
    var showWelcomeBanner: Bool { is_new }
    var user: User {
        // Create minimal User object from backend response
        User(
            id: user_id,
            email: nil,
            deviceId: user_id,
            appleSub: nil,
            isGuest: true,
            tier: .free,
            creditsRemaining: credits_remaining,
            creditsTotal: credits_remaining,
            initialGrantClaimed: true,
            language: "en",
            themePreference: "system",
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    enum CodingKeys: String, CodingKey {
        case user_id
        case credits_remaining
        case is_new
        case access_token
        case refresh_token
    }
}

// MARK: - Onboarding State

struct OnboardingState {
    let deviceId: String
    let user: User
    let shouldShowWelcomeBanner: Bool
    let isFirstLaunch: Bool

    init(from response: OnboardingResponse) {
        self.deviceId = response.deviceId
        self.user = response.user
        self.shouldShowWelcomeBanner = response.showWelcomeBanner
        self.isFirstLaunch = !response.isExistingUser
    }
}

// MARK: - Onboarding Error

enum OnboardingError: LocalizedError {
    case deviceCheckFailed
    case deviceCheckUnavailable
    case networkError(String)
    case maxRetriesExceeded
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .deviceCheckFailed:
            return "Failed to generate device token"
        case .deviceCheckUnavailable:
            return "DeviceCheck is not available on this device"
        case .networkError(let message):
            return "Network error: \(message)"
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}

// MARK: - Preview Data

extension OnboardingResponse {
    static var newUserPreview: OnboardingResponse {
        OnboardingResponse(
            user_id: "device-uuid-123",
            credits_remaining: 10,
            is_new: true,
            access_token: "mock-access-token",
            refresh_token: "mock-refresh-token"
        )
    }

    static var existingUserPreview: OnboardingResponse {
        OnboardingResponse(
            user_id: "device-uuid-456",
            credits_remaining: 5,
            is_new: false,
            access_token: "mock-access-token",
            refresh_token: "mock-refresh-token"
        )
    }
}
