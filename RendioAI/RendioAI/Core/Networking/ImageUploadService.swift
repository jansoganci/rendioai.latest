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
        
        // Get JWT token from Keychain (preferred) or fallback to anon key
        let authToken: String
        if let accessToken = KeychainManager.shared.getAccessToken() {
            authToken = accessToken
            print("✅ ImageUploadService: Using JWT token from Keychain")
        } else {
            // Fallback to anon key if no token available (backward compatibility)
            authToken = anonKey
            print("⚠️ ImageUploadService: No JWT token found, using anon key (may fail with RLS)")
        }
        
        // Generate unique filename
        let filename = "input_\(UUID().uuidString).jpg"
        let filePath = "\(userId)/\(filename)"
        
        // Construct upload URL (Supabase Storage REST API format)
        guard let url = URL(string: "\(baseURL)/storage/v1/object/thumbnails/\(filePath)") else {
            print("❌ ImageUploadService: Invalid upload URL")
            throw AppError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = imageData
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ ImageUploadService: Invalid response type")
            throw AppError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ ImageUploadService: Upload error: \(errorString)")
            }
            throw AppError.networkFailure
        }
        
        // Construct public URL
        let publicURL = "\(baseURL)/storage/v1/object/public/thumbnails/\(filePath)"
        
        return publicURL
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

