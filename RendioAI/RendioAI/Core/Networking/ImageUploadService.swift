//
//  ImageUploadService.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation
import UIKit

protocol ImageUploadServiceProtocol {
    func uploadImage(_ image: UIImage, userId: String) async throws -> String
}

class ImageUploadService: ImageUploadServiceProtocol {
    static let shared = ImageUploadService()
    
    private var baseURL: String { AppConfig.supabaseURL }
    private var anonKey: String { AppConfig.supabaseAnonKey }
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func uploadImage(_ image: UIImage, userId: String) async throws -> String {
        // Convert UIImage to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ ImageUploadService: Failed to convert image to JPEG")
            throw AppError.invalidResponse
        }

        // Generate unique filename (use same filename for retry)
        let filename = "input_\(UUID().uuidString).jpg"
        let filePath = "\(userId)/\(filename)"

        // Get valid JWT token (auto-refreshes if needed)
        var authToken = try await AuthService.shared.getValidAccessToken()
        print("✅ ImageUploadService: Got valid JWT token")

        // First attempt
        var uploadResult = try await performUpload(
            imageData: imageData,
            filePath: filePath,
            authToken: authToken
        )

        // If first attempt failed with 401/403, refresh token and retry ONCE
        if case .authError(let statusCode) = uploadResult {
            print("⚠️ ImageUploadService: Upload failed with HTTP \(statusCode) - refreshing token and retrying...")

            // Force token refresh
            authToken = try await AuthService.shared.refreshAccessToken()
            print("✅ ImageUploadService: Token refreshed, retrying upload...")

            // Retry with fresh token
            uploadResult = try await performUpload(
                imageData: imageData,
                filePath: filePath,
                authToken: authToken
            )
        }

        // Check final result
        switch uploadResult {
        case .success(let publicURL):
            print("✅ ImageUploadService: Upload successful")
            return publicURL
        case .authError(let statusCode):
            print("❌ ImageUploadService: Upload failed after retry with HTTP \(statusCode)")
            throw AppError.unauthorized
        case .error(let message):
            print("❌ ImageUploadService: Upload failed: \(message)")
            throw AppError.networkFailure
        }
    }

    /// Performs the actual upload request
    /// - Returns: Upload result (success with URL, auth error, or general error)
    private func performUpload(
        imageData: Data,
        filePath: String,
        authToken: String
    ) async throws -> UploadResult {
        // Construct upload URL (Supabase Storage REST API format)
        guard let url = URL(string: "\(baseURL)/storage/v1/object/thumbnails/\(filePath)") else {
            print("❌ ImageUploadService: Invalid upload URL")
            return .error("Invalid upload URL")
        }

        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = imageData

        // Perform upload
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ ImageUploadService: Invalid response type")
            return .error("Invalid response type")
        }

        // Check response status
        if (200...299).contains(httpResponse.statusCode) {
            // Success - construct and return public URL
            let publicURL = "\(baseURL)/storage/v1/object/public/thumbnails/\(filePath)"
            return .success(publicURL)
        } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            // Auth error - token might be expired
            if let errorString = String(data: data, encoding: .utf8) {
                print("⚠️ ImageUploadService: Auth error (HTTP \(httpResponse.statusCode)): \(errorString)")
            }
            return .authError(httpResponse.statusCode)
        } else {
            // Other error
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ ImageUploadService: Upload error (HTTP \(httpResponse.statusCode)): \(errorString)")
                return .error(errorString)
            }
            return .error("HTTP \(httpResponse.statusCode)")
        }
    }

    /// Result of an upload attempt
    private enum UploadResult {
        case success(String)        // Public URL
        case authError(Int)          // HTTP status code (401 or 403)
        case error(String)           // Error message
    }
}

// MARK: - Mock Service for Testing

class MockImageUploadService: ImageUploadServiceProtocol {
    var shouldThrowError = false
    var uploadedImageURL: String = "https://example.com/mock-image.jpg"
    
    func uploadImage(_ image: UIImage, userId: String) async throws -> String {
        if shouldThrowError {
            throw AppError.networkFailure
        }
        
        // Simulate upload delay
        try await Task.sleep(for: .seconds(0.5))
        
        return uploadedImageURL
    }
}

