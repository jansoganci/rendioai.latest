//
//  User.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

struct User: Identifiable, Codable {
    let id: String
    let email: String?
    let deviceId: String?
    let appleSub: String?
    let isGuest: Bool
    let tier: UserTier
    let creditsRemaining: Int
    let creditsTotal: Int
    let initialGrantClaimed: Bool
    let language: String
    let themePreference: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case deviceId = "device_id"
        case appleSub = "apple_sub"
        case isGuest = "is_guest"
        case tier
        case creditsRemaining = "credits_remaining"
        case creditsTotal = "credits_total"
        case initialGrantClaimed = "initial_grant_claimed"
        case language
        case themePreference = "theme_preference"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    var displayName: String {
        if isGuest {
            return NSLocalizedString("profile.guest_user", comment: "Guest user")
        }
        // Phase 2: Get actual name from Apple Sign-In (ASAuthorizationAppleIDCredential.fullName)
        // Currently using email as fallback
        return email ?? NSLocalizedString("profile.guest_user", comment: "Guest user")
    }

    var displayEmail: String {
        email ?? NSLocalizedString("profile.email_hidden", comment: "Hidden email")
    }

    var tierDisplayName: String {
        switch tier {
        case .free:
            return NSLocalizedString("profile.tier_free", comment: "Free tier")
        case .premium:
            return NSLocalizedString("profile.tier_premium", comment: "Premium tier")
        }
    }

    var creditsDisplay: String {
        String(format: NSLocalizedString("profile.credits_remaining", comment: ""),
               creditsRemaining)
    }

    // MARK: - User Tier

    enum UserTier: String, Codable {
        case free = "free"
        case premium = "premium"
    }

    // MARK: - Preview Data

    static var guestPreview: User {
        User(
            id: "guest-preview-id",
            email: nil,
            deviceId: "device-123",
            appleSub: nil,
            isGuest: true,
            tier: .free,
            creditsRemaining: 8,
            creditsTotal: 10,
            initialGrantClaimed: true,
            language: "en",
            themePreference: "system",
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    static var registeredPreview: User {
        User(
            id: "user-preview-id",
            email: "user@example.com",
            deviceId: "device-123",
            appleSub: "apple-sub-123",
            isGuest: false,
            tier: .free,
            creditsRemaining: 25,
            creditsTotal: 50,
            initialGrantClaimed: true,
            language: "en",
            themePreference: "system",
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    static var premiumPreview: User {
        User(
            id: "premium-preview-id",
            email: "premium@example.com",
            deviceId: "device-456",
            appleSub: "apple-sub-456",
            isGuest: false,
            tier: .premium,
            creditsRemaining: 100,
            creditsTotal: 100,
            initialGrantClaimed: true,
            language: "en",
            themePreference: "dark",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
