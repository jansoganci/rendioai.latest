//
//  OnboardingStateManager.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

// MARK: - Onboarding State Manager

/// Centralized manager for all onboarding-related state
class OnboardingStateManager {
    static let shared = OnboardingStateManager()

    private let defaults = UserDefaultsManager.shared

    private init() {}

    // MARK: - Device & Onboarding State

    /// Unique device identifier from backend
    var deviceId: String? {
        get {
            printStateSummary()
            return defaults.deviceId
        }
        set { defaults.deviceId = newValue }
    }

    /// Whether onboarding has been completed
    var isOnboardingCompleted: Bool {
        get {
            printStateSummary()
            return defaults.onboardingCompleted
        }
        set { defaults.onboardingCompleted = newValue }
    }

    /// Whether this is the first app launch
    var isFirstLaunch: Bool {
        return !defaults.hasLaunchedBefore
    }

    // MARK: - Banner State

    /// Whether the welcome banner has been seen
    var hasSeenWelcomeBanner: Bool {
        get { defaults.hasSeenWelcomeBanner }
        set { defaults.hasSeenWelcomeBanner = newValue }
    }

    /// Check if welcome banner should be shown
    /// - Returns: true if this is first launch and banner not yet seen
    func shouldShowWelcomeBanner() -> Bool {
        return isFirstLaunch && !hasSeenWelcomeBanner
    }

    /// Mark welcome banner as seen (dismisses it permanently)
    func markWelcomeBannerAsSeen() {
        hasSeenWelcomeBanner = true
        print("✅ Welcome banner marked as seen")
    }

    // MARK: - Onboarding Flow

    /// Save complete onboarding state from API response
    /// - Parameter state: Onboarding state from backend
    func saveOnboardingResult(_ state: OnboardingState) {
        defaults.saveOnboardingState(state)
        isOnboardingCompleted = true

        print("✅ OnboardingStateManager: Saved onboarding result")
        print("   - Device ID: \(state.deviceId)")
        print("   - First Launch: \(state.isFirstLaunch)")
        print("   - Should Show Welcome: \(state.shouldShowWelcomeBanner)")
        printStateSummary()
    }

    /// Complete onboarding with fallback data (when network fails)
    /// - Parameter deviceId: Fallback device ID (usually UUID)
    func completeOnboardingWithFallback(deviceId: String) {
        self.deviceId = deviceId
        isOnboardingCompleted = true
        defaults.hasLaunchedBefore = true
        
        // CRITICAL FIX: Also save currentUserId (fallback deviceId becomes user_id)
        UserDefaultsManager.shared.currentUserId = deviceId
        
        print("✅ OnboardingStateManager: Completed with fallback")
        print("   - Fallback Device ID: \(deviceId)")
        print("   - User ID: \(deviceId)")
        printStateSummary()
    }

    // MARK: - Reset & Debug

    /// Clear all onboarding state (for testing or account deletion)
    func resetOnboardingState() {
        defaults.clearOnboardingState()
        print("🗑️ OnboardingStateManager: All state cleared")
        printStateSummary()
    }

    /// Get current onboarding state summary (for debugging)
    func getStateSummary() -> String {
        """
        Onboarding State Summary:
        - Device ID: \(deviceId ?? "none")
        - Onboarding Completed: \(isOnboardingCompleted)
        - First Launch: \(isFirstLaunch)
        - Has Launched Before: \(defaults.hasLaunchedBefore)
        - Welcome Banner Seen: \(hasSeenWelcomeBanner)
        - Should Show Welcome: \(shouldShowWelcomeBanner())
        """
    }

    /// Print current state to console (for debugging)
    func debugPrintState() {
        print("🔍 \(getStateSummary())")
    }

    func printStateSummary() {
        print("🧭 OnboardingStateManager → device_id:", defaults.deviceId ?? "nil")
        print("🧭 OnboardingStateManager → user_id:", defaults.currentUserId ?? "nil")
        print("🧭 OnboardingStateManager → credits_remaining:", (UserDefaults.standard.object(forKey: "app.cachedCredits") as? Int) ?? 0)
        print("🧭 OnboardingStateManager → onboarding_completed:", defaults.onboardingCompleted)
    }
}

// MARK: - Onboarding State Extensions

extension OnboardingStateManager {
    /// Check if user is in "new user" state
    /// - Returns: true if first launch and onboarding completed
    var isNewUser: Bool {
        return isFirstLaunch && isOnboardingCompleted
    }

    /// Check if user is in "returning user" state
    /// - Returns: true if not first launch
    var isReturningUser: Bool {
        return !isFirstLaunch
    }

    /// Check if onboarding needs to be performed
    /// - Returns: true if onboarding not yet completed
    var needsOnboarding: Bool {
        return !isOnboardingCompleted
    }
}
