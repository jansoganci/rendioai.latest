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
        // Call backend endpoint: POST /functions/v1/merge-guest-user
        guard let url = URL(string: "\(baseURL)/functions/v1/merge-guest-user") else {
            print("❌ UserService: Invalid URL")
            throw AppError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Validate inputs
        guard !deviceId.isEmpty, !appleSub.isEmpty else {
            print("❌ UserService: Invalid device_id or apple_sub")
            throw AppError.invalidResponse
        }

        let body: [String: String] = [
            "device_id": deviceId,
            "apple_sub": appleSub
        ]

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ UserService: Invalid response type")
            throw AppError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ UserService: Backend error: \(errorString)")
            }
            throw AppError.networkFailure
        }

        // Backend returns: { "success": true, "user": User }
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
            struct MergeResponse: Codable {
                let success: Bool
                let user: User
            }

            let mergeResponse = try decoder.decode(MergeResponse.self, from: data)

            if !mergeResponse.success {
                print("❌ UserService: Backend returned success = false")
                throw AppError.networkFailure
            }

            print("✅ UserService: Guest user merged successfully")
            print("   User ID: \(mergeResponse.user.id)")
            print("   Credits: \(mergeResponse.user.creditsRemaining)")

            return mergeResponse.user
        } catch {
            print("❌ UserService: Failed to decode merge response: \(error)")
            throw AppError.invalidResponse
        }
    }

    func deleteAccount(userId: String) async throws {
        // Call backend endpoint: POST /functions/v1/delete-account
        guard let url = URL(string: "\(baseURL)/functions/v1/delete-account") else {
            print("❌ UserService: Invalid URL")
            throw AppError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Validate input
        guard !userId.isEmpty else {
            print("❌ UserService: Invalid user_id")
            throw AppError.invalidResponse
        }

        let body: [String: String] = [
            "user_id": userId
        ]

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

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

        // Backend returns: { "success": true }
        do {
            struct DeleteResponse: Codable {
                let success: Bool
            }

            let deleteResponse = try JSONDecoder().decode(DeleteResponse.self, from: data)

            if !deleteResponse.success {
                print("❌ UserService: Backend returned success = false")
                throw AppError.networkFailure
            }

            print("✅ UserService: Account deleted successfully")
            print("   User ID: \(userId)")
        } catch {
            print("❌ UserService: Failed to decode delete response: \(error)")
            throw AppError.invalidResponse
        }

        // Note: CASCADE deletion handles:
        // - video_jobs (ON DELETE CASCADE)
        // - quota_log (ON DELETE CASCADE)
        // Storage cleanup can be added later if needed
    }

    func updateUserSettings(userId: String, settings: UserSettings) async throws {
        // Use Supabase REST API directly (simpler than Edge Function)
        // Endpoint: PATCH /rest/v1/users?id=eq.{userId}
        guard let url = URL(string: "\(baseURL)/rest/v1/users?id=eq.\(userId)") else {
            print("❌ UserService: Invalid URL")
            throw AppError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")

        // Validate inputs
        guard !userId.isEmpty else {
            print("❌ UserService: Invalid user_id")
            throw AppError.invalidResponse
        }

        let body: [String: String] = [
            "language": settings.language,
            "theme_preference": settings.themePreference
        ]

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ UserService: Invalid response type")
            throw AppError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ UserService: Backend error: \(errorString)")
            }
            throw AppError.networkFailure
        }

        // Verify update succeeded (REST API returns updated rows)
        do {
            struct UpdateResponse: Codable {
                let id: String
                let language: String
                let theme_preference: String
            }

            let results = try JSONDecoder().decode([UpdateResponse].self, from: data)

            guard results.count == 1 else {
                print("❌ UserService: Expected 1 updated row, got \(results.count)")
                throw AppError.invalidResponse
            }

            print("✅ UserService: Settings updated successfully")
            print("   User ID: \(userId)")
            print("   Language: \(results[0].language)")
            print("   Theme: \(results[0].theme_preference)")
        } catch {
            print("❌ UserService: Failed to decode update response: \(error)")
            throw AppError.invalidResponse
        }

        // Note: For guests, settings are stored locally in UserDefaults
        // For logged-in users, settings sync to Supabase users table (this function)
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
