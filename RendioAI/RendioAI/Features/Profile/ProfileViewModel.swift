//
//  ProfileViewModel.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

enum AlertType {
    case signOut
    case deleteAccount
    case guestPurchase
    case error
    case success
    case none
}

@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var user: User?
    @Published var isLoading: Bool = false

    // Unified Alert State
    @Published var showingAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var alertType: AlertType = .none

    // Navigation
    @Published var navigateToHistoryView: Bool = false

    // Sheet States
    @Published var showingSignInSheet: Bool = false
    @Published var showingPurchaseSheet: Bool = false

    // Settings
    @Published var selectedLanguage: String = "en"
    @Published var selectedTheme: String = "system"

    // MARK: - Private Properties

    private let userService: UserServiceProtocol
    private let creditService: CreditServiceProtocol
    private let authService: AuthServiceProtocol
    private let storeKitManager: StoreKitManagerProtocol
    private let defaults = UserDefaultsManager.shared
    private var onboardingManager: OnboardingStateManager { OnboardingStateManager.shared }
    
    // handled by UserService and AuthService (user ID from authenticated user or guest)
    private var resolvedUserId: String {
        if let userId = user?.id, !userId.isEmpty { return userId }
        if let onboardingUserId = onboardingManager.deviceId, !onboardingUserId.isEmpty { return onboardingUserId }
        if let storedUserId = UserDefaultsManager.shared.currentUserId, !storedUserId.isEmpty { return storedUserId }
        return ""
    }

    private var resolvedDeviceId: String {
        if let deviceId = user?.deviceId, !deviceId.isEmpty { return deviceId }
        if let onboardingDeviceId = onboardingManager.deviceId, !onboardingDeviceId.isEmpty { return onboardingDeviceId }
        return ""
    }

    // MARK: - Computed Properties

    var isGuest: Bool {
        user?.isGuest ?? true
    }

    var userName: String {
        user?.displayName ?? "profile.guest_user".localized
    }

    var userEmail: String {
        user?.displayEmail ?? "profile.email_hidden".localized
    }

    var tierDisplay: String {
        user?.tierDisplayName ?? "profile.tier_free".localized
    }

    var creditsRemaining: Int {
        user?.creditsRemaining ?? 0
    }

    var creditsTotal: Int {
        user?.creditsTotal ?? 10
    }

    var creditsDisplay: String {
        String(format: "profile.credits_remaining".localized,
               creditsRemaining)
    }

    var canBuyCredits: Bool {
        !isGuest // Only logged-in users can purchase
    }

    var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        }
        return "1.0.0"
    }

    // MARK: - Initialization

    init(
        userService: UserServiceProtocol = UserService.shared,
        creditService: CreditServiceProtocol = CreditService.shared,
        authService: AuthServiceProtocol = AuthService.shared,
        storeKitManager: StoreKitManagerProtocol = StoreKitManager.shared
    ) {
        self.userService = userService
        self.creditService = creditService
        self.authService = authService
        self.storeKitManager = storeKitManager

        // Load settings from UserDefaults
        self.selectedLanguage = defaults.language
        self.selectedTheme = defaults.themePreference
    }

    // MARK: - Public Methods

    func loadUserProfile() {
        Task {
            isLoading = true
            do {
                // Fetch user profile first (critical - must succeed)
                let userId = resolvedUserId
                let deviceId = resolvedDeviceId
                print("🧭 ProfileViewModel → Final user_id:", userId)
                print("🧭 ProfileViewModel → Final device_id:", deviceId)
                print("📤 ProfileViewModel → Request body:", ["user_id": userId, "device_id": deviceId])
                print("📤 ProfileViewModel → URL:", "\(AppConfig.supabaseURL)/functions/v1/get-user-profile")
                let userProfile = try await userService.fetchUserProfile(userId: userId)
                print("📥 ProfileViewModel → Response:", userProfile)
                print("📥 ProfileViewModel → Status Code:", "handled inside service")
                
                // Set user profile immediately
                user = userProfile

                // Sync settings from user profile (for logged-in users)
                if !userProfile.isGuest {
                    selectedLanguage = userProfile.language
                    selectedTheme = userProfile.themePreference
                    defaults.syncFromUser(userProfile)
                }

                // Fetch credits separately (non-critical - can fail gracefully)
                var credits: Int = userProfile.creditsRemaining // Use profile credits as fallback
                do {
                    print("🧭 ProfileViewModel → Final user_id:", userId)
                    print("🧭 ProfileViewModel → Final device_id:", deviceId)
                    print("📤 ProfileViewModel → Request body:", ["user_id": userId, "device_id": deviceId])
                    print("📤 ProfileViewModel → URL:", "\(AppConfig.supabaseURL)/functions/v1/get-user-credits")
                    credits = try await creditService.fetchCredits()
                    print("📥 ProfileViewModel → Response:", credits)
                    print("📥 ProfileViewModel → Status Code:", "handled inside service")
                } catch {
                    // If credits fail (e.g., no user_id), use profile credits or 0
                    print("⚠️ ProfileViewModel: Failed to fetch credits: \(error)")
                    credits = userProfile.creditsRemaining
                }

                // Update user with fetched credits
                if var updatedUser = user {
                    updatedUser = User(
                        id: updatedUser.id,
                        email: updatedUser.email,
                        deviceId: updatedUser.deviceId,
                        appleSub: updatedUser.appleSub,
                        isGuest: updatedUser.isGuest,
                        tier: updatedUser.tier,
                        creditsRemaining: credits,
                        creditsTotal: updatedUser.creditsTotal,
                        initialGrantClaimed: updatedUser.initialGrantClaimed,
                        language: updatedUser.language,
                        themePreference: updatedUser.themePreference,
                        createdAt: updatedUser.createdAt,
                        updatedAt: updatedUser.updatedAt
                    )
                    user = updatedUser
                }

            } catch {
                // Only handle error if user profile failed (critical failure)
                handleError(error)
            }
            isLoading = false
        }
    }

    // MARK: - Authentication Actions

    func signInWithApple() {
        Task {
            isLoading = true
            do {
                // Step 1: Perform Apple Sign-In
                let userId = resolvedUserId
                let deviceId = resolvedDeviceId
                print("🧭 ProfileViewModel → Final user_id:", userId)
                print("🧭 ProfileViewModel → Final device_id:", deviceId)
                print("🧩 Profile → Initiating Apple Sign-In for device_id:", deviceId)
                print("📤 ProfileViewModel → URL:", "AppleSignIn")
                let appleAuthResult = try await authService.signInWithApple()
                print("📥 ProfileViewModel → Response:", appleAuthResult)
                print("📥 ProfileViewModel → Status Code:", "handled inside service")

                // Step 2: Merge guest account with Apple user
                print("🧭 ProfileViewModel → Final user_id:", userId)
                print("🧭 ProfileViewModel → Final device_id:", deviceId)
                print("📤 ProfileViewModel → Request body:", [
                    "device_id": deviceId,
                    "apple_sub": appleAuthResult.appleSub,
                    "user_id": userId
                ])
                print("📤 ProfileViewModel → URL:", "\(AppConfig.supabaseURL)/functions/v1/merge-guest-user")
                let mergedUser = try await authService.mergeGuestToUser(
                    deviceId: deviceId,
                    appleSub: appleAuthResult.appleSub,
                    identityToken: appleAuthResult.identityToken,
                    authorizationCode: appleAuthResult.authorizationCode
                )
                print("📥 ProfileViewModel → Response:", mergedUser)
                print("📥 ProfileViewModel → Status Code:", "handled inside service")

                // Step 3: Update UI with merged user
                user = mergedUser
                selectedLanguage = mergedUser.language
                selectedTheme = mergedUser.themePreference

                // Step 4: Show success alert
                alertType = .success
                alertTitle = "common.success".localized
                alertMessage = "profile.sign_in".localized + " ✓"
                showingAlert = true

            } catch {
                // Handle sign-in errors
                if let appError = error as? AppError, appError == .unauthorized {
                    // User cancelled - don't show error
                    print("User cancelled Apple Sign-In")
                } else {
                    alertType = .error
                    alertTitle = "common.error".localized
                    alertMessage = "profile.sign_in_failed".localized
                    showingAlert = true
                }
            }
            isLoading = false
        }
    }

    func signOut() {
        alertType = .signOut
        alertTitle = "profile.sign_out_title".localized
        alertMessage = "profile.sign_out_message".localized
        showingAlert = true
    }

    func confirmSignOut() async {
        isLoading = true
        do {
            // Call logout endpoint
            let userId = resolvedUserId
            let deviceId = resolvedDeviceId
            print("🧭 ProfileViewModel → Final user_id:", userId)
            print("🧭 ProfileViewModel → Final device_id:", deviceId)
            print("📤 ProfileViewModel → Request body:", ["user_id": userId, "device_id": deviceId])
            print("📤 ProfileViewModel → URL:", "\(AppConfig.supabaseURL)/auth/v1/logout")
            try await authService.signOut(userId: userId)
            print("📥 ProfileViewModel → Response:", "Sign out completed for user_id: \(userId)")
            print("📥 ProfileViewModel → Status Code:", "handled inside service")

            // Clear user data and reset to guest state
            user = User.guestPreview

            // Reset settings to defaults
            selectedLanguage = "en"
            selectedTheme = "system"

        } catch {
            handleError(error)
        }
        isLoading = false
    }

    func restorePurchases() {
        Task {
            isLoading = true
            do {
                // Restore purchases using StoreKit
                let creditsRestored = try await storeKitManager.restorePurchases()

                // Refresh user profile to get updated credits
                await loadUserProfile()

                // Show success alert
                alertType = .success
                alertTitle = "common.success".localized
                alertMessage = String(format: "profile.restore_success".localized, creditsRestored)
                showingAlert = true

            } catch {
                handleError(error)
            }
            isLoading = false
        }
    }

    func deleteAccount() {
        alertType = .deleteAccount
        alertTitle = "profile.delete_account_title".localized
        alertMessage = "profile.delete_account_message".localized
        showingAlert = true
    }

    func confirmDeleteAccount() async {
        isLoading = true
        do {
            guard let userId = user?.id else {
                throw AppError.unauthorized
            }

            let deviceId = resolvedDeviceId
            print("🧭 ProfileViewModel → Final user_id:", userId)
            print("🧭 ProfileViewModel → Final device_id:", deviceId)
            print("📤 ProfileViewModel → Request body:", ["user_id": userId, "device_id": deviceId])
            print("📤 ProfileViewModel → URL:", "\(AppConfig.supabaseURL)/functions/v1/delete-account")
            try await userService.deleteAccount(userId: userId)
            print("📥 ProfileViewModel → Response:", "Delete account completed for user_id: \(userId)")
            print("📥 ProfileViewModel → Status Code:", "handled inside service")

            // Clear local data
            user = User.guestPreview

            // handled by AuthService.signOut() (Keychain cleanup in Phase 2)
            // Navigation handled by View layer (ProfileView → ContentView)

        } catch {
            alertType = .error
            alertTitle = "common.error".localized
            alertMessage = "profile.delete_failed".localized
            showingAlert = true
        }
        isLoading = false
    }

    // MARK: - Credit Actions

    func buyCredits() {
        if isGuest {
            showGuestPurchaseAlert()
        } else {
            // handled by StoreKitManager (IAP purchase flow via PurchaseSheet)
            showingPurchaseSheet = true
        }
    }

    func showGuestPurchaseAlert() {
        alertType = .guestPurchase
        alertTitle = "common.warning".localized
        alertMessage = "profile.guest_cannot_purchase".localized
        showingAlert = true
    }

    func navigateToHistory() {
        navigateToHistoryView = true
    }

    func handlePurchaseComplete(credits: Int) async {
        // Refresh user profile to get updated credits
        await loadUserProfile()

        // Show success alert
        await MainActor.run {
            alertType = .success
            alertTitle = "common.success".localized
            alertMessage = String(format: "profile.purchase_success".localized, credits)
            showingAlert = true
        }
    }

    // MARK: - Settings Actions

    func handleLanguageChange(_ language: String) {
        selectedLanguage = language

        // Persist to UserDefaults immediately (works for both guest and logged-in)
        defaults.language = language

        // Sync with backend for logged-in users
        if let user = user, !user.isGuest {
            Task {
                do {
                    let deviceId = resolvedDeviceId
                    print("🧭 ProfileViewModel → Final user_id:", user.id)
                    print("🧭 ProfileViewModel → Final device_id:", deviceId)
                    print("📤 ProfileViewModel → Request body:", ["user_id": user.id, "device_id": deviceId, "language": language, "theme": selectedTheme])
                    print("📤 ProfileViewModel → URL:", "\(AppConfig.supabaseURL)/functions/v1/update-user-settings")
                    let settings = UserSettings(language: language, themePreference: selectedTheme)
                    try await userService.updateUserSettings(userId: user.id, settings: settings)
                    print("📥 ProfileViewModel → Response:", "Language update succeeded")
                    print("📥 ProfileViewModel → Status Code:", "handled inside service")
                } catch {
                    // Silent fail - already persisted locally
                    print("Failed to sync language to backend: \(error)")
                }
            }
        }
    }

    func handleThemeChange(_ theme: String) {
        selectedTheme = theme

        // Persist to UserDefaults immediately (works for both guest and logged-in)
        // This will trigger NotificationCenter and update app-wide theme
        defaults.themePreference = theme

        // Sync with backend for logged-in users
        if let user = user, !user.isGuest {
            Task {
                do {
                    let deviceId = resolvedDeviceId
                    print("🧭 ProfileViewModel → Final user_id:", user.id)
                    print("🧭 ProfileViewModel → Final device_id:", deviceId)
                    print("📤 ProfileViewModel → Request body:", ["user_id": user.id, "device_id": deviceId, "language": selectedLanguage, "theme": theme])
                    print("📤 ProfileViewModel → URL:", "\(AppConfig.supabaseURL)/functions/v1/update-user-settings")
                    let settings = UserSettings(language: selectedLanguage, themePreference: theme)
                    try await userService.updateUserSettings(userId: user.id, settings: settings)
                    print("📥 ProfileViewModel → Response:", "Theme update succeeded")
                    print("📥 ProfileViewModel → Status Code:", "handled inside service")
                } catch {
                    // Silent fail - already persisted locally and applied
                    print("Failed to sync theme to backend: \(error)")
                }
            }
        }
    }

    // MARK: - Private Methods

    private func handleError(_ error: Error) {
        alertType = .error
        alertTitle = "common.error".localized

        if let appError = error as? AppError {
            alertMessage = appError.errorDescription ?? "error.general.unexpected".localized
        } else {
            alertMessage = "error.general.unexpected".localized
        }

        showingAlert = true
    }
}
