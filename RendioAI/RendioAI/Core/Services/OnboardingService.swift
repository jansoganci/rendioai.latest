//
//  OnboardingService.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation
import UIKit

// MARK: - Onboarding Service Protocol

protocol OnboardingServiceProtocol {
    /// Performs device check with backend
    func checkDevice(token: Data) async throws -> OnboardingResponse

    /// Performs device check with retry logic
    func checkDeviceWithRetry(token: Data, maxAttempts: Int) async throws -> OnboardingResponse
}

// MARK: - Onboarding Service Implementation

class OnboardingService: OnboardingServiceProtocol {
    static let shared = OnboardingService()

    private let baseURL = "https://ojcnjxzctnwbmupggoxq.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qY25qeHpjdG53Ym11cGdnb3hxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMjkzNjIsImV4cCI6MjA3NzkwNTM2Mn0._bKw_0kYf65SxYC8ik3_SMdMgUYoxgVbisvCdRfYo08"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Device Check

    func checkDevice(token: Data) async throws -> OnboardingResponse {
        // Endpoint: POST /functions/v1/device-check
        guard let url = URL(string: "\(baseURL)/functions/v1/device-check") else {
            throw OnboardingError.invalidResponse
        }

        // Prepare request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        // Prepare body - device-check endpoint expects device_id and device_token
        let tokenString = token.base64EncodedString()
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let body: [String: Any] = [
            "device_id": deviceId,
            "device_token": tokenString
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Debug: Print request details
        print("📤 Request URL: \(url.absoluteString)")
        print("📤 Request body: device_id=\(deviceId), device_token=\(tokenString.prefix(20))...")

        // Perform request
        let (data, response) = try await session.data(for: request)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OnboardingError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error message from response
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorData["error"] as? String {
                print("❌ Backend error (HTTP \(httpResponse.statusCode)): \(errorMessage)")
                throw OnboardingError.networkError(errorMessage)
            }
            throw OnboardingError.networkError("HTTP \(httpResponse.statusCode)")
        }

        // Debug: Print raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Backend response: \(responseString)")
        }

        // Decode response
        let decoder = JSONDecoder()
        // Note: Not using convertFromSnakeCase because OnboardingResponse has explicit CodingKeys

        do {
            let onboardingResponse = try decoder.decode(OnboardingResponse.self, from: data)
            
            // Save user_id to local storage immediately after successful decode
            // This ensures user_id is always available for subsequent API calls
            UserDefaultsManager.shared.currentUserId = onboardingResponse.user_id
            print("✅ OnboardingService: Received user_id from backend: \(onboardingResponse.user_id)")
            print("✅ OnboardingService: Saved user_id to local storage")
            print("✅ Device check successful: \(onboardingResponse.isExistingUser ? "Existing" : "New") user")
            
            return onboardingResponse
        } catch {
            print("❌ Failed to decode onboarding response: \(error)")
            // Print the actual response data for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Raw response data: \(responseString)")
            }
            throw OnboardingError.invalidResponse
        }
    }

    // MARK: - Device Check with Retry

    func checkDeviceWithRetry(token: Data, maxAttempts: Int = 3) async throws -> OnboardingResponse {
        var attempts = 0
        var lastError: Error?

        while attempts < maxAttempts {
            do {
                print("🔄 Device check attempt \(attempts + 1)/\(maxAttempts)")
                let response = try await checkDevice(token: token)
                return response // Success!

            } catch {
                lastError = error
                attempts += 1

                print("⚠️ Device check attempt \(attempts) failed: \(error.localizedDescription)")

                // If not the last attempt, wait before retrying
                if attempts < maxAttempts {
                    let delaySeconds = 2.0
                    print("⏳ Waiting \(delaySeconds)s before retry...")
                    try await Task.sleep(for: .seconds(delaySeconds))
                }
            }
        }

        // All retries failed
        print("❌ All \(maxAttempts) device check attempts failed")
        throw lastError ?? OnboardingError.maxRetriesExceeded
    }
}

// MARK: - Mock Onboarding Service

class MockOnboardingService: OnboardingServiceProtocol {
    var shouldSucceed: Bool = true
    var shouldReturnNewUser: Bool = true
    var failAttempts: Int = 0 // Number of attempts that should fail before succeeding

    private var currentAttempt: Int = 0

    func checkDevice(token: Data) async throws -> OnboardingResponse {
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(800))

        // Simulate failures for testing retry logic
        if currentAttempt < failAttempts {
            currentAttempt += 1
            print("⚠️ Mock: Simulating failure (attempt \(currentAttempt)/\(failAttempts))")
            throw OnboardingError.networkError("Simulated network error")
        }

        // Reset for next test
        currentAttempt = 0

        if shouldSucceed {
            let response = shouldReturnNewUser
                ? OnboardingResponse.newUserPreview
                : OnboardingResponse.existingUserPreview

            print("✅ Mock: Device check successful (\(shouldReturnNewUser ? "New" : "Existing") user)")
            return response
        } else {
            print("❌ Mock: Device check failed")
            throw OnboardingError.networkError("Mock failure")
        }
    }

    func checkDeviceWithRetry(token: Data, maxAttempts: Int = 3) async throws -> OnboardingResponse {
        var attempts = 0
        var lastError: Error?

        while attempts < maxAttempts {
            do {
                print("🔄 Mock: Device check attempt \(attempts + 1)/\(maxAttempts)")
                let response = try await checkDevice(token: token)
                return response

            } catch {
                lastError = error
                attempts += 1

                if attempts < maxAttempts {
                    print("⏳ Mock: Waiting before retry...")
                    try await Task.sleep(for: .seconds(1.0)) // Shorter delay for testing
                }
            }
        }

        print("❌ Mock: All \(maxAttempts) attempts failed")
        throw lastError ?? OnboardingError.maxRetriesExceeded
    }

    // Helper to reset state between tests
    func reset() {
        currentAttempt = 0
        shouldSucceed = true
        shouldReturnNewUser = true
        failAttempts = 0
    }
}
