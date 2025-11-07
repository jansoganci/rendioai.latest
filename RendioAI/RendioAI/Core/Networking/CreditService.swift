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
        // Phase 2: Implement actual credit update via Supabase
        // This would call POST /update-credits endpoint
        // Currently using mock data for development
        try await Task.sleep(for: .seconds(0.2))

        // Simulate returning new balance
        return max(0, 10 + change)
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
