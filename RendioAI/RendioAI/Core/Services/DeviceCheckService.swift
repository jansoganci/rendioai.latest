//
//  DeviceCheckService.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation
import DeviceCheck

// MARK: - DeviceCheck Service Protocol

protocol DeviceCheckServiceProtocol {
    /// Generates a device token for fraud prevention
    func generateToken() async throws -> Data

    /// Checks if DeviceCheck is available on current device
    var isSupported: Bool { get }
}

// MARK: - DeviceCheck Service Implementation

class DeviceCheckService: DeviceCheckServiceProtocol {
    static let shared = DeviceCheckService()

    private init() {}

    /// Check if DeviceCheck is supported on this device
    var isSupported: Bool {
        return DCDevice.current.isSupported
    }

    /// Generate a device token
    /// - Returns: Device token data
    /// - Throws: OnboardingError if token generation fails
    func generateToken() async throws -> Data {
        // Check if DeviceCheck is supported
        guard isSupported else {
            throw OnboardingError.deviceCheckUnavailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            DCDevice.current.generateToken { data, error in
                if let error = error {
                    print("❌ DeviceCheck token generation failed: \(error.localizedDescription)")
                    continuation.resume(throwing: OnboardingError.deviceCheckFailed)
                    return
                }

                guard let data = data else {
                    print("❌ DeviceCheck token data is nil")
                    continuation.resume(throwing: OnboardingError.deviceCheckFailed)
                    return
                }

                print("✅ DeviceCheck token generated successfully")
                continuation.resume(returning: data)
            }
        }
    }

    /// Convert token data to base64 string for API transmission
    func tokenToBase64(_ data: Data) -> String {
        return data.base64EncodedString()
    }
}

// MARK: - Mock DeviceCheck Service

class MockDeviceCheckService: DeviceCheckServiceProtocol {
    var isSupported: Bool = true
    var shouldSucceed: Bool = true
    var mockToken: Data = "mock-device-token-12345".data(using: .utf8)!

    func generateToken() async throws -> Data {
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(500))

        if shouldSucceed {
            print("✅ Mock DeviceCheck token generated")
            return mockToken
        } else {
            print("❌ Mock DeviceCheck token generation failed")
            throw OnboardingError.deviceCheckFailed
        }
    }
}
