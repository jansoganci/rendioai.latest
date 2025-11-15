//
//  OnboardingTestHelper.swift
//  RendioAI
//
//  Created by Rendio AI Team
//  FOR DEVELOPMENT & TESTING ONLY
//

import Foundation

#if DEBUG

/// Helper class for testing onboarding scenarios during development
class OnboardingTestHelper {
    static let shared = OnboardingTestHelper()

    private let stateManager = OnboardingStateManager.shared

    private init() {}

    // MARK: - Test Scenarios

    /// Simulate first-time user (new install)
    func simulateFirstTimeUser() {
        print("🧪 TEST: Simulating first-time user")
        stateManager.resetOnboardingState()
        UserDefaultsManager.shared.hasLaunchedBefore = false

        print("✅ State reset:")
        stateManager.debugPrintState()
    }

    /// Simulate returning user with credits
    func simulateReturningUser(withCredits credits: Int = 5) {
        print("🧪 TEST: Simulating returning user with \(credits) credits")

        // Set up as completed onboarding
        stateManager.deviceId = "test-device-\(UUID().uuidString)"
        stateManager.isOnboardingCompleted = true
        stateManager.hasSeenWelcomeBanner = true
        UserDefaultsManager.shared.hasLaunchedBefore = true

        print("✅ Returning user setup complete")
        stateManager.debugPrintState()
    }

    /// Simulate new user who just completed onboarding
    func simulateNewUserAfterOnboarding(withCredits credits: Int = 10) {
        print("🧪 TEST: Simulating new user after onboarding with \(credits) credits")

        // Set up as new user who just onboarded
        let response = OnboardingResponse(
            user_id: "test-device-\(UUID().uuidString)",
            credits_remaining: credits,
            is_new: true,
            access_token: "test-access-token-\(UUID().uuidString)",  // Test token
            refresh_token: "test-refresh-token-\(UUID().uuidString)"  // Test token
        )

        let onboardingState = OnboardingState(from: response)
        stateManager.saveOnboardingResult(onboardingState)
        stateManager.hasSeenWelcomeBanner = false // Not seen yet

        print("✅ New user setup complete")
        stateManager.debugPrintState()
    }

    /// Simulate user with low credits (< 10)
    func simulateLowCreditUser(withCredits credits: Int = 3) {
        print("🧪 TEST: Simulating low credit user with \(credits) credits")

        stateManager.deviceId = "test-device-\(UUID().uuidString)"
        stateManager.isOnboardingCompleted = true
        stateManager.hasSeenWelcomeBanner = true
        UserDefaultsManager.shared.hasLaunchedBefore = true

        print("✅ Low credit user setup complete")
        stateManager.debugPrintState()
    }

    /// Simulate user with no credits
    func simulateNoCreditUser() {
        print("🧪 TEST: Simulating user with no credits")
        simulateLowCreditUser(withCredits: 0)
    }

    // MARK: - State Inspection

    /// Print current onboarding state
    func printCurrentState() {
        print("🔍 CURRENT STATE:")
        stateManager.debugPrintState()
    }

    /// Check if welcome banner should show
    func shouldShowWelcomeBanner() -> Bool {
        let shouldShow = stateManager.shouldShowWelcomeBanner()
        print("🔍 Should show welcome banner: \(shouldShow)")
        return shouldShow
    }

    // MARK: - Reset

    /// Complete reset of all onboarding state
    func resetAll() {
        print("🧪 TEST: Complete reset of all state")
        stateManager.resetOnboardingState()
        UserDefaultsManager.shared.hasLaunchedBefore = false

        print("✅ Complete reset done")
        stateManager.debugPrintState()
    }

    // MARK: - Quick Actions

    /// Force show welcome banner (resets seen flag)
    func forceShowWelcomeBanner() {
        print("🧪 TEST: Forcing welcome banner to show")
        stateManager.hasSeenWelcomeBanner = false
        UserDefaultsManager.shared.hasLaunchedBefore = false
        print("✅ Welcome banner will show on next launch")
    }

    /// Mark welcome banner as seen
    func dismissWelcomeBanner() {
        print("🧪 TEST: Marking welcome banner as seen")
        stateManager.markWelcomeBannerAsSeen()
        print("✅ Welcome banner dismissed")
    }
}

// MARK: - Preview Helpers

extension OnboardingTestHelper {
    /// Get configured mock services for testing
    func getTestMockServices(
        shouldSucceed: Bool = true,
        shouldReturnNewUser: Bool = true
    ) -> (deviceCheck: MockDeviceCheckService, onboarding: MockOnboardingService) {
        let mockDeviceCheck = MockDeviceCheckService()
        mockDeviceCheck.shouldSucceed = shouldSucceed

        let mockOnboarding = MockOnboardingService()
        mockOnboarding.shouldSucceed = shouldSucceed
        mockOnboarding.shouldReturnNewUser = shouldReturnNewUser

        return (mockDeviceCheck, mockOnboarding)
    }
}

#endif
