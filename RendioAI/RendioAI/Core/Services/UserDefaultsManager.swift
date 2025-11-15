//
//  UserDefaultsManager.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation
import SwiftUI

// MARK: - UserDefaultsManager

class UserDefaultsManager {
    static let shared = UserDefaultsManager()

    // MARK: - Keys

    private enum Keys {
        static let language = "app.settings.language"
        static let themePreference = "app.settings.theme"
        static let hasLaunchedBefore = "app.hasLaunchedBefore"
        static let lastSyncedUserId = "app.lastSyncedUserId"

        // Onboarding
        static let hasSeenWelcomeBanner = "app.onboarding.hasSeenWelcomeBanner"
        static let deviceId = "app.onboarding.deviceId"
        static let onboardingCompleted = "app.onboarding.completed"
    }

    // MARK: - Language

    var language: String {
        get {
            UserDefaults.standard.string(forKey: Keys.language) ?? "en"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.language)
            NotificationCenter.default.post(name: .languageDidChange, object: newValue)
        }
    }

    // MARK: - Theme

    var themePreference: String {
        get {
            UserDefaults.standard.string(forKey: Keys.themePreference) ?? "system"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.themePreference)
            NotificationCenter.default.post(name: .themeDidChange, object: newValue)
        }
    }

    var colorScheme: ColorScheme? {
        switch themePreference {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil // System
        }
    }

    // MARK: - App State

    var hasLaunchedBefore: Bool {
        get {
            UserDefaults.standard.bool(forKey: Keys.hasLaunchedBefore)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.hasLaunchedBefore)
        }
    }

    var lastSyncedUserId: String? {
        get {
            UserDefaults.standard.string(forKey: Keys.lastSyncedUserId)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.lastSyncedUserId)
        }
    }
    
    // Current user ID from onboarding (for video generation)
    var currentUserId: String? {
        get {
            UserDefaults.standard.string(forKey: "app.currentUserId")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "app.currentUserId")
        }
    }

    // MARK: - Onboarding State

    var hasSeenWelcomeBanner: Bool {
        get {
            UserDefaults.standard.bool(forKey: Keys.hasSeenWelcomeBanner)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.hasSeenWelcomeBanner)
        }
    }

    var deviceId: String? {
        get {
            UserDefaults.standard.string(forKey: Keys.deviceId)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.deviceId)
        }
    }

    var onboardingCompleted: Bool {
        get {
            UserDefaults.standard.bool(forKey: Keys.onboardingCompleted)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.onboardingCompleted)
        }
    }

    func saveOnboardingState(_ state: OnboardingState) {
        deviceId = state.deviceId
        onboardingCompleted = true
        hasLaunchedBefore = true
        
        // CRITICAL FIX: Also save currentUserId (deviceId == user_id in OnboardingResponse)
        currentUserId = state.deviceId
        
        // Cache credits from user object for debug display
        UserDefaults.standard.set(state.user.creditsRemaining, forKey: "app.cachedCredits")
        
        print("✅ Onboarding state saved:")
        print("   - Device ID: \(state.deviceId)")
        print("   - User ID: \(state.deviceId)")
        print("   - Credits: \(state.user.creditsRemaining)")
        print("   - First Launch: \(state.isFirstLaunch)")
        print("   - Show Welcome: \(state.shouldShowWelcomeBanner)")
    }

    func clearOnboardingState() {
        hasSeenWelcomeBanner = false
        deviceId = nil
        onboardingCompleted = false
        
        // CRITICAL FIX: Also clear currentUserId for consistency
        currentUserId = nil
        
        print("🗑️ Onboarding state cleared")
    }

    // MARK: - Sync with User Model

    func syncFromUser(_ user: User) {
        language = user.language
        themePreference = user.themePreference
        lastSyncedUserId = user.id
    }

    func createUserSettings() -> UserSettings {
        UserSettings(
            language: language,
            themePreference: themePreference
        )
    }

    // MARK: - Reset

    func resetToDefaults() {
        language = "en"
        themePreference = "system"
    }

    func clearUserData() {
        lastSyncedUserId = nil
        clearOnboardingState()
        // Keep language and theme preferences
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let languageDidChange = Notification.Name("app.languageDidChange")
    static let themeDidChange = Notification.Name("app.themeDidChange")
}

// MARK: - Theme Observer

@MainActor
class ThemeObserver: ObservableObject {
    @Published var colorScheme: ColorScheme?

    private let defaults = UserDefaultsManager.shared

    init() {
        self.colorScheme = defaults.colorScheme

        // Observe theme changes
        NotificationCenter.default.addObserver(
            forName: .themeDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            self.colorScheme = self.defaults.colorScheme
        }
    }
}
