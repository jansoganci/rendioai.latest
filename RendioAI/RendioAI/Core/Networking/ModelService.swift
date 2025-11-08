//
//  ModelService.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

// MARK: - Phase 5 Debug Helpers

// Toggle via build configuration: Set DEBUG_PHASE5=1 in build settings to enable
private func p5log(_ msg: String) {
    #if DEBUG
    print(msg)
    #endif
}

protocol ModelServiceProtocol {
    func fetchModels() async throws -> [ModelPreview]
    func fetchModelDetail(id: String) async throws -> ModelDetail
    func fetchActiveModel() async throws -> ModelDetail
}

class ModelService: ModelServiceProtocol {
    static let shared = ModelService()

    private var baseURL: String { AppConfig.supabaseURL }
    private var anonKey: String { AppConfig.supabaseAnonKey }
    private let session: URLSession

    // ETag cache storage
    private var cachedModels: [ModelPreview]?
    private var cachedETag: String?

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchModels() async throws -> [ModelPreview] {
        p5log("[P5][ModelService][Fetch][REQ] If-None-Match=\(cachedETag ?? "nil")")

        // Use Edge Function endpoint: GET /functions/v1/get-models
        guard let url = URL(string: "\(baseURL)/functions/v1/get-models") else {
            print("❌ ModelService: Invalid URL")
            throw AppError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add If-None-Match header if we have a cached ETag
        if let cachedETag = cachedETag {
            request.setValue(cachedETag, forHTTPHeaderField: "If-None-Match")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ ModelService: Invalid response type")
            throw AppError.invalidResponse
        }

        // Handle 304 Not Modified - return cached models
        if httpResponse.statusCode == 304 {
            if let cachedModels = cachedModels {
                p5log("[P5][ModelService][Fetch][HIT] ETag=\(cachedETag ?? "-") count=\(cachedModels.count)")
                print("✅ ModelService: Cache hit - returning cached models")
                return cachedModels
            } else {
                print("⚠️ ModelService: Got 304 but no cached models, refetching")
                throw AppError.invalidResponse
            }
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ ModelService: Backend error: \(errorString)")
            }
            throw AppError.networkFailure
        }

        // Decode response with models wrapper
        let decoder = JSONDecoder()

        do {
            struct ModelsResponse: Codable {
                let models: [ModelPreview]
            }

            let modelsResponse = try decoder.decode(ModelsResponse.self, from: data)

            // Update cache with new models
            cachedModels = modelsResponse.models

            // Extract and store ETag from response headers
            if let newETag = httpResponse.allHeaderFields["ETag"] as? String {
                cachedETag = newETag
                p5log("[P5][ModelService][Fetch][MISS] ETag=\(newETag) count=\(modelsResponse.models.count)")
                print("✅ ModelService: Updated cache with ETag: \(newETag)")
            }

            return modelsResponse.models
        } catch {
            print("❌ ModelService: Failed to decode models: \(error)")
            throw AppError.invalidResponse
        }
    }
    
    func fetchModelDetail(id: String) async throws -> ModelDetail {
        // Query Supabase REST API for single model with all fields
        guard let url = URL(string: "\(baseURL)/rest/v1/models?id=eq.\(id)&select=id,name,category,description,thumbnail_url,is_featured,cost_per_generation") else {
            print("❌ ModelService: Invalid URL for model detail: \(id)")
            throw AppError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ ModelService: Invalid response type for model detail")
            throw AppError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ ModelService: Backend error: \(errorString)")
            }
            throw AppError.networkFailure
        }
        
        let decoder = JSONDecoder()
        
        do {
            // Backend returns array, get first item
            let models = try decoder.decode([ModelDetail].self, from: data)
            guard let model = models.first else {
                print("❌ ModelService: Model not found: \(id)")
                throw AppError.invalidResponse
            }
            
            return model
        } catch {
            print("❌ ModelService: Failed to decode model detail: \(error)")
            throw AppError.invalidResponse
        }
    }
    
    func fetchActiveModel() async throws -> ModelDetail {
        // Query Supabase REST API for active model with all fields including required_fields
        guard let url = URL(string: "\(baseURL)/rest/v1/models?is_active=eq.true&is_available=eq.true&select=id,name,category,description,thumbnail_url,is_featured,cost_per_generation,required_fields") else {
            print("❌ ModelService: Invalid URL for active model")
            throw AppError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ ModelService: Invalid response type for active model")
            throw AppError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ ModelService: Backend error: \(errorString)")
            }
            throw AppError.networkFailure
        }
        
        let decoder = JSONDecoder()
        
        do {
            // Backend returns array, get first item
            let models = try decoder.decode([ModelDetail].self, from: data)
            guard let model = models.first else {
                print("❌ ModelService: No active model found")
                throw AppError.invalidResponse
            }
            
            return model
        } catch {
            print("❌ ModelService: Failed to decode active model: \(error)")
            throw AppError.invalidResponse
        }
    }
}

// MARK: - Mock Service for Testing
class MockModelService: ModelServiceProtocol {
    var modelsToReturn: [ModelPreview] = []
    var shouldThrowError = false

    func fetchModels() async throws -> [ModelPreview] {
        if shouldThrowError {
            throw AppError.networkFailure
        }
        return modelsToReturn
    }
    
    func fetchModelDetail(id: String) async throws -> ModelDetail {
        if shouldThrowError {
            throw AppError.networkFailure
        }
        
        guard let previewModel = modelsToReturn.first(where: { $0.id == id }) else {
            throw AppError.invalidResponse
        }
        
        return ModelDetail(
            from: previewModel,
            description: "Mock model description",
            costPerGeneration: 4
        )
    }
    
    func fetchActiveModel() async throws -> ModelDetail {
        if shouldThrowError {
            throw AppError.networkFailure
        }
        
        // Return first model as active, or create a default one
        if let previewModel = modelsToReturn.first {
            return ModelDetail(
                from: previewModel,
                description: "Mock active model description",
                costPerGeneration: 4,
                requiredFields: ModelRequirements.preview
            )
        } else {
            // Return a default active model
            return ModelDetail(
                id: "mock-active-1",
                name: "Mock Active Model",
                category: "Test",
                description: "Mock active model for testing",
                thumbnailURL: nil,
                isFeatured: true,
                costPerGeneration: 4,
                requiredFields: ModelRequirements.preview
            )
        }
    }
}
