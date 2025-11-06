//
//  ModelService.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

protocol ModelServiceProtocol {
    func fetchModels() async throws -> [ModelPreview]
    func fetchModelDetail(id: String) async throws -> ModelDetail
    func fetchActiveModel() async throws -> ModelDetail
}

class ModelService: ModelServiceProtocol {
    static let shared = ModelService()

    private let baseURL = "https://ojcnjxzctnwbmupggoxq.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qY25qeHpjdG53Ym11cGdnb3hxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMjkzNjIsImV4cCI6MjA3NzkwNTM2Mn0._bKw_0kYf65SxYC8ik3_SMdMgUYoxgVbisvCdRfYo08"
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchModels() async throws -> [ModelPreview] {
        // Query Supabase REST API directly (no endpoint exists yet - Phase 3 feature)
        // Fetch only available models
        guard let url = URL(string: "\(baseURL)/rest/v1/models?is_available=eq.true&select=id,name,category,thumbnail_url,is_featured&order=is_featured.desc,name.asc") else {
            print("❌ ModelService: Invalid URL")
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
            print("❌ ModelService: Invalid response type")
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
            let models = try decoder.decode([ModelPreview].self, from: data)
            return models
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
