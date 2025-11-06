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
    
    private let baseURL = "https://ojcnjxzctnwbmupggoxq.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qY25qeHpjdG53Ym11cGdnb3hxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMjkzNjIsImV4cCI6MjA3NzkwNTM2Mn0._bKw_0kYf65SxYC8ik3_SMdMgUYoxgVbisvCdRfYo08"
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
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
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

