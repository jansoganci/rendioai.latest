//
//  ThemeService.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

protocol ThemeServiceProtocol {
    func fetchThemes() async throws -> [Theme]
    func fetchThemeDetail(id: String) async throws -> Theme
}

class ThemeService: ThemeServiceProtocol {
    static let shared = ThemeService()

    private var baseURL: String { AppConfig.supabaseURL }
    private var anonKey: String { AppConfig.supabaseAnonKey }
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchThemes() async throws -> [Theme] {
        // Query Supabase REST API directly
        // Fetch only available themes, ordered by featured first
        guard let url = URL(string: "\(baseURL)/rest/v1/themes?is_available=eq.true&select=id,name,description,thumbnail_url,prompt,is_featured,is_available,default_settings,created_at&order=is_featured.desc,name.asc") else {
            print("❌ ThemeService: Invalid URL")
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
            print("❌ ThemeService: Invalid response type")
            throw AppError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ ThemeService: Backend error: \(errorString)")
            }
            throw AppError.networkFailure
        }
        
        let decoder = JSONDecoder()
        
        do {
            let themes = try decoder.decode([Theme].self, from: data)
            return themes
        } catch {
            print("❌ ThemeService: Failed to decode themes: \(error)")
            throw AppError.invalidResponse
        }
    }
    
    func fetchThemeDetail(id: String) async throws -> Theme {
        // Query Supabase REST API for single theme with all fields
        guard let url = URL(string: "\(baseURL)/rest/v1/themes?id=eq.\(id)&is_available=eq.true&select=id,name,description,thumbnail_url,prompt,is_featured,is_available,default_settings,created_at") else {
            print("❌ ThemeService: Invalid URL for theme detail: \(id)")
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
            print("❌ ThemeService: Invalid response type for theme detail")
            throw AppError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ ThemeService: Backend error: \(errorString)")
            }
            throw AppError.networkFailure
        }
        
        let decoder = JSONDecoder()
        
        do {
            // Backend returns array, get first item
            let themes = try decoder.decode([Theme].self, from: data)
            guard let theme = themes.first else {
                print("❌ ThemeService: Theme not found: \(id)")
                throw AppError.invalidResponse
            }
            
            return theme
        } catch {
            print("❌ ThemeService: Failed to decode theme detail: \(error)")
            throw AppError.invalidResponse
        }
    }
}

// MARK: - Mock Service for Testing
class MockThemeService: ThemeServiceProtocol {
    var themesToReturn: [Theme] = []
    var shouldThrowError = false

    func fetchThemes() async throws -> [Theme] {
        if shouldThrowError {
            throw AppError.networkFailure
        }
        return themesToReturn
    }
    
    func fetchThemeDetail(id: String) async throws -> Theme {
        if shouldThrowError {
            throw AppError.networkFailure
        }
        
        guard let theme = themesToReturn.first(where: { $0.id == id }) else {
            throw AppError.invalidResponse
        }
        
        return theme
    }
}

