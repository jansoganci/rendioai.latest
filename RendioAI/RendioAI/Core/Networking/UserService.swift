//
//  UserService.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

protocol UserServiceProtocol {
    func fetchUserProfile(userId: String) async throws -> User
    func mergeGuestToUser(deviceId: String, appleSub: String) async throws -> User
    func deleteAccount(userId: String) async throws
    func updateUserSettings(userId: String, settings: UserSettings) async throws
}

class UserService: UserServiceProtocol {
    static let shared = UserService()

    private var baseURL: String { AppConfig.supabaseURL }
    private var anonKey: String { AppConfig.supabaseAnonKey }
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Public Methods

    func fetchUserProfile(userId: String) async throws -> User {
        // Use Edge Function endpoint: GET /functions/v1/get-user-profile?user_id={userId}
        var components = URLComponents(string: "\(baseURL)/functions/v1/get-user-profile")
        components?.queryItems = [
            URLQueryItem(name: "user_id", value: userId)
        ]
        
        guard let url = components?.url else {
            print("❌ UserService: Invalid URL")
            throw AppError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ UserService: Invalid response type")
            throw AppError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                throw AppError.userNotFound
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ UserService: Backend error: \(errorString)")
            }
            throw AppError.networkFailure
        }
        
        // Decode user profile
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Fallback without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO8601 date: \(dateString)"
            )
        }
        
        do {
            let user = try decoder.decode(User.self, from: data)
            return user
        } catch {
            print("❌ UserService: Failed to decode user profile: \(error)")
            throw AppError.invalidResponse
        }
    }

    func mergeGuestToUser(deviceId: String, appleSub: String) async throws -> User {
        // Phase 2: Replace with actual Supabase Edge Function call
        // Endpoint: POST /api/merge-guest-to-user
        // Body: { device_id: String, apple_sub: String }
        // Currently using mock data for development

        // Simulate network delay
        try await Task.sleep(for: .seconds(0.8))

        // Validate inputs
        guard !deviceId.isEmpty, !appleSub.isEmpty else {
            throw AppError.invalidResponse
        }

        // Return mock merged user
        return User.registeredPreview
    }

    func deleteAccount(userId: String) async throws {
        // Phase 2: Replace with actual Supabase Edge Function call
        // Endpoint: DELETE /api/user
        // Body: { user_id: String }
        // Currently using mock data for development

        // Simulate network delay
        try await Task.sleep(for: .seconds(1.0))

        // Validate input
        guard !userId.isEmpty else {
            throw AppError.invalidResponse
        }

        // Account deletion would cascade delete:
        // - video_jobs
        // - quota_log
        // - Mark videos for deletion
    }

    func updateUserSettings(userId: String, settings: UserSettings) async throws {
        // Phase 2: Replace with actual Supabase API call
        // Endpoint: PATCH /api/user-settings
        // Body: { user_id: String, language: String, theme_preference: String }
        // Currently using mock data for development

        // Simulate network delay
        try await Task.sleep(for: .seconds(0.3))

        // Validate inputs
        guard !userId.isEmpty else {
            throw AppError.invalidResponse
        }

        // For guests, settings are stored locally in UserDefaults
        // For logged-in users, settings sync to Supabase users table
    }
}

// MARK: - Mock Service for Testing

class MockUserService: UserServiceProtocol {
    var userToReturn: User = .guestPreview
    var shouldThrowError = false
    var errorToThrow: Error = AppError.networkFailure

    func fetchUserProfile(userId: String) async throws -> User {
        if shouldThrowError {
            throw errorToThrow
        }
        return userToReturn
    }

    func mergeGuestToUser(deviceId: String, appleSub: String) async throws -> User {
        if shouldThrowError {
            throw errorToThrow
        }
        return .registeredPreview
    }

    func deleteAccount(userId: String) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
    }

    func updateUserSettings(userId: String, settings: UserSettings) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
    }
}
