//
//  RendioAIApp.swift
//  RendioAI
//
//  Created by Can Soğancı on 4.11.2025.
//

import SwiftUI

@main
struct RendioAIApp: App {
    @StateObject private var themeObserver = ThemeObserver()
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var onboardingViewModel = OnboardingViewModel()

    init() {
        // Configure StableID first (for persistent device identification)
        // This must happen before any device identification is needed
        if #available(iOS 16.0, *) {
            // Use App Store Transaction ID for best stability (iOS 16.0+)
            Task {
                await StableIDService.shared.configureWithAppTransactionID()
            }
        } else {
            // Fallback to auto-generated ID for older iOS versions
            StableIDService.shared.configure()
        }

        // Set language preference at app launch (before any views render)
        // This must happen before any NSLocalizedString is called
        let defaults = UserDefaultsManager.shared

        // If language is not set, default to "en" and save it
        if UserDefaults.standard.string(forKey: "app.settings.language") == nil {
            defaults.language = "en"
        }

        let savedLanguage = defaults.language
        UserDefaults.standard.set([savedLanguage, "en"], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()

        // Force Bundle to use our language preference
        // This must be done before any view renders

        // Background token refresh on app launch
        // Refreshes JWT token if it expires within 10 minutes
        Task {
            await AuthService.shared.refreshTokenIfNeeded()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(themeObserver.colorScheme)
                .environmentObject(themeObserver)
                .environmentObject(localizationManager)
                .task {
                    // Perform onboarding in background on first launch
                    await performOnboardingIfNeeded()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Refresh token when app returns from background
                    // This ensures token is fresh after long background periods
                    Task {
                        await AuthService.shared.refreshTokenIfNeeded()
                    }
                }
        }
    }

    // MARK: - Background Onboarding

    private func performOnboardingIfNeeded() async {
        let result = await onboardingViewModel.performOnboarding()

        // Log result
        switch result {
        case .success(let response):
            print("✅ Onboarding success:")
            print("   - Device ID: \(response.deviceId)")
            print("   - Is Existing User: \(response.isExistingUser)")
            print("   - Credits: \(response.creditsRemaining)")

        case .fallback(let reason, let deviceId):
            print("⚠️ Onboarding fallback:")
            print("   - Reason: \(reason)")
            print("   - Device ID: \(deviceId)")

        case .alreadyCompleted:
            print("ℹ️ Onboarding already completed")
        }
    }
}

