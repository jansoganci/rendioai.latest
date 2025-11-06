//
//  OnboardingViewModel.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation
import SwiftUI
import UIKit

// MARK: - Onboarding View Model

@MainActor
class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var isComplete = false
    @Published var currentStep: OnboardingStep = .idle
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Services

    private let deviceCheckService: DeviceCheckServiceProtocol
    private let onboardingService: OnboardingServiceProtocol
    private let stateManager: OnboardingStateManager

    // MARK: - Configuration

    private let maxRetryAttempts: Int
    private let retryDelay: TimeInterval

    // MARK: - Initialization

    init(
        deviceCheckService: DeviceCheckServiceProtocol = DeviceCheckService.shared,
        onboardingService: OnboardingServiceProtocol = OnboardingService.shared,
        stateManager: OnboardingStateManager = OnboardingStateManager.shared,
        maxRetryAttempts: Int = 3,
        retryDelay: TimeInterval = 2.0
    ) {
        self.deviceCheckService = deviceCheckService
        self.onboardingService = onboardingService
        self.stateManager = stateManager
        self.maxRetryAttempts = maxRetryAttempts
        self.retryDelay = retryDelay
    }

    // MARK: - Onboarding Flow

    /// Performs the complete onboarding flow
    /// - Returns: OnboardingResult indicating success or failure with details
    @discardableResult
    func performOnboarding() async -> OnboardingResult {
        // Check if onboarding is already completed
        if stateManager.isOnboardingCompleted {
            print("ℹ️ Onboarding already completed, checking user_id and device consistency...")
            
            // CRITICAL FIX: Check if identifierForVendor has changed
            let currentIdentifierForVendor = UIDevice.current.identifierForVendor?.uuidString
            let storedDeviceId = stateManager.deviceId
            
            // Check if identifierForVendor changed (simulator reset, app reinstall, etc.)
            if let currentId = currentIdentifierForVendor,
               let storedId = storedDeviceId,
               currentId != storedId {
                print("⚠️ identifierForVendor changed!")
                print("   - Stored deviceId: \(storedId)")
                print("   - Current identifierForVendor: \(currentId)")
                print("   - This means the device changed or simulator was reset")
                print("   🔄 Clearing onboarding state to trigger re-onboarding...")
                
                // Clear onboarding state to force re-onboarding
                stateManager.resetOnboardingState()
                // Continue to full onboarding flow below
            } else {
                // identifierForVendor matches, but check if user_id is missing
                if UserDefaultsManager.shared.currentUserId == nil {
                    if let deviceId = stateManager.deviceId {
                        UserDefaultsManager.shared.currentUserId = deviceId
                        print("✅ Restored user_id from deviceId: \(deviceId)")
                        currentStep = .completed
                        isComplete = true
                        return .alreadyCompleted
                    } else {
                        print("⚠️ Both user_id and deviceId missing, but onboarding marked complete")
                        print("   This shouldn't happen - clearing state to trigger re-onboarding...")
                        stateManager.resetOnboardingState()
                        // Continue to full onboarding flow below
                    }
                } else {
                    print("✅ user_id found: \(UserDefaultsManager.shared.currentUserId ?? "nil")")
                    print("✅ identifierForVendor matches stored deviceId")
                    currentStep = .completed
                    isComplete = true
                    return .alreadyCompleted
                }
            }
        }

        isLoading = true
        currentStep = .started

        do {
            // Step 1: Check DeviceCheck availability
            currentStep = .checkingDeviceSupport
            guard deviceCheckService.isSupported else {
                print("⚠️ DeviceCheck not supported")
                return await handleFallback(reason: .deviceCheckUnavailable)
            }

            // Step 2: Generate device token
            currentStep = .generatingToken
            let token = try await deviceCheckService.generateToken()
            print("✅ Device token generated")

            // Step 3: Check device with backend (with retry)
            currentStep = .checkingWithBackend
            let response = try await onboardingService.checkDeviceWithRetry(
                token: token,
                maxAttempts: maxRetryAttempts
            )
            print("✅ Device check successful")

            // Step 4: Save state
            currentStep = .savingState
            let onboardingState = OnboardingState(from: response)
            stateManager.saveOnboardingResult(onboardingState)
            
            // Save user_id for video generation
            UserDefaultsManager.shared.currentUserId = response.user_id
            print("✅ Saved user_id: \(response.user_id)")

            // Step 5: Complete
            currentStep = .completed
            isLoading = false
            isComplete = true

            print("✅ Onboarding completed successfully")
            stateManager.debugPrintState()

            return .success(response: response)

        } catch let error as OnboardingError {
            print("❌ Onboarding error: \(error.localizedDescription)")
            return await handleOnboardingError(error)

        } catch {
            print("❌ Unexpected error: \(error.localizedDescription)")
            return await handleFallback(reason: .unknownError(error))
        }
    }

    // MARK: - Error Handling

    /// Handle onboarding errors with appropriate fallback
    private func handleOnboardingError(_ error: OnboardingError) async -> OnboardingResult {
        switch error {
        case .deviceCheckFailed, .deviceCheckUnavailable:
            return await handleFallback(reason: .deviceCheckUnavailable)

        case .networkError, .maxRetriesExceeded, .invalidResponse:
            return await handleFallback(reason: .networkFailure)
        }
    }

    /// Handle fallback when onboarding fails
    private func handleFallback(reason: OnboardingFailureReason) async -> OnboardingResult {
        print("🔄 Using fallback strategy: \(reason)")

        currentStep = .usingFallback

        // Generate fallback device ID
        let fallbackDeviceId = UUID().uuidString
        stateManager.completeOnboardingWithFallback(deviceId: fallbackDeviceId)

        currentStep = .completed
        isLoading = false
        isComplete = true

        print("✅ Fallback completed")
        stateManager.debugPrintState()

        return .fallback(reason: reason, deviceId: fallbackDeviceId)
    }

    // MARK: - Manual Actions

    /// Retry onboarding (for manual retry from UI)
    func retryOnboarding() async {
        errorMessage = nil
        showError = false
        await performOnboarding()
    }

    /// Reset onboarding state (for testing or debugging)
    func resetOnboarding() {
        stateManager.resetOnboardingState()
        isComplete = false
        currentStep = .idle
        print("🔄 Onboarding reset")
    }

    // MARK: - State Queries

    /// Check if welcome banner should be shown
    var shouldShowWelcomeBanner: Bool {
        return stateManager.shouldShowWelcomeBanner()
    }

    /// Mark welcome banner as seen
    func dismissWelcomeBanner() {
        stateManager.markWelcomeBannerAsSeen()
    }
}

// MARK: - Onboarding Step

enum OnboardingStep: String, CustomStringConvertible {
    case idle = "Idle"
    case started = "Started"
    case checkingDeviceSupport = "Checking Device Support"
    case generatingToken = "Generating Token"
    case checkingWithBackend = "Checking with Backend"
    case savingState = "Saving State"
    case usingFallback = "Using Fallback"
    case completed = "Completed"

    var description: String { rawValue }
}

// MARK: - Onboarding Result

enum OnboardingResult {
    case success(response: OnboardingResponse)
    case fallback(reason: OnboardingFailureReason, deviceId: String)
    case alreadyCompleted

    var isSuccessful: Bool {
        switch self {
        case .success, .fallback, .alreadyCompleted:
            return true
        }
    }

    var deviceId: String? {
        switch self {
        case .success(let response):
            return response.deviceId
        case .fallback(_, let deviceId):
            return deviceId
        case .alreadyCompleted:
            return OnboardingStateManager.shared.deviceId
        }
    }
}

// MARK: - Onboarding Failure Reason

enum OnboardingFailureReason: CustomStringConvertible {
    case deviceCheckUnavailable
    case networkFailure
    case unknownError(Error)

    var description: String {
        switch self {
        case .deviceCheckUnavailable:
            return "DeviceCheck unavailable"
        case .networkFailure:
            return "Network failure"
        case .unknownError(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
