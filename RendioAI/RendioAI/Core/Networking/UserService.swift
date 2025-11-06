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

    private init() {}

    // MARK: - Public Methods

    func fetchUserProfile(userId: String) async throws -> User {
        // Phase 2: Replace with actual Supabase API call
        // Endpoint: GET /api/profile?user_id={userId}
        // Currently using mock data for development

        // Simulate network delay
        try await Task.sleep(for: .seconds(0.5))

        // Return mock user for now
        return User.guestPreview
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
