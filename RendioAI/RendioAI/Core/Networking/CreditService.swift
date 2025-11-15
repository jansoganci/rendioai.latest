//
//  CreditService.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation
import UIKit

protocol CreditServiceProtocol {
    func fetchCredits() async throws -> Int
    func updateCredits(change: Int, reason: String) async throws -> Int
    func hasSufficientCredits(cost: Int) async throws -> Bool
}

class CreditService: CreditServiceProtocol {
    static let shared = CreditService()

    private var baseURL: String { AppConfig.supabaseURL }
    private var anonKey: String { AppConfig.supabaseAnonKey }
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCredits() async throws -> Int {
        // Get user_id from local storage (saved during onboarding)
        guard let userId = UserDefaultsManager.shared.currentUserId else {
            print("❌ CreditService: No user_id found in local storage")
            throw AppError.invalidResponse
        }
        
        // Call backend endpoint: GET /functions/v1/get-user-credits?user_id={uuid}
        guard let url = URL(string: "\(baseURL)/functions/v1/get-user-credits?user_id=\(userId)") else {
            print("❌ CreditService: Invalid URL")
            throw AppError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ CreditService: Invalid response type")
            throw AppError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                throw AppError.userNotFound
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ CreditService: Backend error: \(errorString)")
            }
            throw AppError.networkFailure
        }
        
        // Backend returns: {credits_remaining: Int}
        let decoder = JSONDecoder()
        
        do {
            struct CreditsResponse: Codable {
                let credits_remaining: Int
            }
            
            let creditsResponse = try decoder.decode(CreditsResponse.self, from: data)
            return creditsResponse.credits_remaining
        } catch {
            print("❌ CreditService: Failed to decode response: \(error)")
            throw AppError.invalidResponse
        }
    }

    func updateCredits(change: Int, reason: String) async throws -> Int {
        // Get user_id from local storage (saved during onboarding)
        guard let userId = UserDefaultsManager.shared.currentUserId else {
            print("❌ CreditService: No user_id found in local storage")
            throw AppError.invalidResponse
        }

        // Call backend endpoint: POST /functions/v1/update-credits
        guard let url = URL(string: "\(baseURL)/functions/v1/update-credits") else {
            print("❌ CreditService: Invalid URL")
            throw AppError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Request body: { "user_id": "uuid", "transaction_id": "apple-transaction-id" }
        let body: [String: String] = [
            "user_id": userId,
            "transaction_id": reason  // Apple IAP transaction ID passed as 'reason'
        ]

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ CreditService: Invalid response type")
            throw AppError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ CreditService: Backend error: \(errorString)")
            }
            throw AppError.networkFailure
        }

        // Backend returns: { "success": true, "credits_added": 50, "credits_remaining": 60 }
        let decoder = JSONDecoder()

        do {
            struct UpdateCreditsResponse: Codable {
                let success: Bool
                let credits_added: Int
                let credits_remaining: Int
            }

            let updateResponse = try decoder.decode(UpdateCreditsResponse.self, from: data)

            if !updateResponse.success {
                print("❌ CreditService: Backend returned success = false")
                throw AppError.networkFailure
            }

            print("✅ CreditService: Credits updated successfully")
            print("   Added: \(updateResponse.credits_added)")
            print("   Remaining: \(updateResponse.credits_remaining)")

            return updateResponse.credits_remaining
        } catch {
            print("❌ CreditService: Failed to decode response: \(error)")
            throw AppError.invalidResponse
        }
    }
    
    func hasSufficientCredits(cost: Int) async throws -> Bool {
        let creditsRemaining = try await fetchCredits()
        return creditsRemaining >= cost
    }
}

// MARK: - Mock Service for Testing
class MockCreditService: CreditServiceProtocol {
    var creditsToReturn: Int = 10
    var shouldThrowError = false

    func fetchCredits() async throws -> Int {
        if shouldThrowError {
            throw AppError.networkFailure
        }
        return creditsToReturn
    }

    func updateCredits(change: Int, reason: String) async throws -> Int {
        if shouldThrowError {
            throw AppError.networkFailure
        }
        creditsToReturn = max(0, creditsToReturn + change)
        return creditsToReturn
    }
    
    func hasSufficientCredits(cost: Int) async throws -> Bool {
        if shouldThrowError {
            throw AppError.networkFailure
        }
        return creditsToReturn >= cost
    }
}
