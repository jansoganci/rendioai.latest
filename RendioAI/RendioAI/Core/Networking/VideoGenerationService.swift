//
//  VideoGenerationService.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

protocol VideoGenerationServiceProtocol {
    func generateVideo(request: VideoGenerationRequest) async throws -> VideoGenerationResponse
}

class VideoGenerationService: VideoGenerationServiceProtocol {
    static let shared = VideoGenerationService()
    
    private var baseURL: String { AppConfig.supabaseURL }
    private var anonKey: String { AppConfig.supabaseAnonKey }
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func generateVideo(request: VideoGenerationRequest) async throws -> VideoGenerationResponse {
        // Endpoint: POST /functions/v1/generate-video
        guard let url = URL(string: "\(baseURL)/functions/v1/generate-video") else {
            print("❌ VideoGenerationService: Invalid URL")
            throw AppError.invalidResponse
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue(anonKey, forHTTPHeaderField: "apikey")
        urlRequest.setValue(UUID().uuidString, forHTTPHeaderField: "Idempotency-Key")
        
        // Convert VideoSettings to backend format
        let duration = request.settings.duration ?? 8
        let backendDuration = min(max(4, duration), 12) // Clamp to 4-12 range
        
        // Build backend settings
        let backendSettings: [String: Any] = [
            "resolution": request.settings.resolution ?? "720p",
            "aspect_ratio": request.settings.aspect_ratio ?? "auto",
            "duration": backendDuration
        ]
        
        // Build request body
        var requestBody: [String: Any] = [
            "user_id": request.user_id,
            "theme_id": request.theme_id,
            "prompt": request.prompt,
            "settings": backendSettings
        ]
        
        // Add image_url if provided
        if let imageUrl = request.image_url {
            requestBody["image_url"] = imageUrl
        }
        
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Perform request
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkFailure
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorData["error"] as? String {
                print("❌ VideoGenerationService: Backend error: \(errorMessage)")
                throw AppError.networkFailure
            }
            throw AppError.networkFailure
        }
        
        // Decode response
        let decoder = JSONDecoder()
        
        do {
            let response = try decoder.decode(VideoGenerationResponse.self, from: data)
            print("✅ Video generation started: job_id=\(response.job_id)")
            return response
        } catch {
            print("❌ VideoGenerationService: Failed to decode response: \(error)")
            throw AppError.invalidResponse
        }
    }
}

// MARK: - Mock Service for Testing
class MockVideoGenerationService: VideoGenerationServiceProtocol {
    var responseToReturn: VideoGenerationResponse?
    var shouldThrowError = false
    var errorToThrow: Error = AppError.networkFailure
    
    func generateVideo(request: VideoGenerationRequest) async throws -> VideoGenerationResponse {
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let response = responseToReturn {
            return response
        }
        
        // Default mock response
        return VideoGenerationResponse(
            job_id: UUID().uuidString,
            status: "pending",
            credits_used: 4
        )
    }
}
