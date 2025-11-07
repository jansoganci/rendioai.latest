//
//  HistoryService.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

protocol HistoryServiceProtocol {
    func fetchVideoJobs(userId: String?) async throws -> [VideoJob]
    func deleteVideoJob(jobId: String) async throws
}

class HistoryService: HistoryServiceProtocol {
    static let shared = HistoryService()
    
    private var baseURL: String { AppConfig.supabaseURL }
    private var anonKey: String { AppConfig.supabaseAnonKey }
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Fetch Video Jobs
    
    func fetchVideoJobs(userId: String?) async throws -> [VideoJob] {
        // Get user_id from parameter or local storage
        let targetUserId: String
        if let userId = userId {
            targetUserId = userId
        } else if let storedUserId = UserDefaultsManager.shared.currentUserId {
            targetUserId = storedUserId
        } else {
            print("❌ HistoryService: No user_id provided and none found in local storage")
            throw AppError.invalidResponse
        }
        
        // Build URL with query parameters
        var components = URLComponents(string: "\(baseURL)/functions/v1/get-video-jobs")
        components?.queryItems = [
            URLQueryItem(name: "user_id", value: targetUserId),
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "offset", value: "0")
        ]
        
        guard let url = components?.url else {
            print("❌ HistoryService: Invalid URL")
            throw AppError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ HistoryService: Invalid response type")
            throw AppError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                throw AppError.userNotFound
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ HistoryService: Backend error: \(errorString)")
            }
            throw AppError.networkFailure
        }
        
        // Decode response
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            struct JobsResponse: Codable {
                let jobs: [VideoJob]
            }
            
            let jobsResponse = try decoder.decode(JobsResponse.self, from: data)
            return jobsResponse.jobs
        } catch {
            print("❌ HistoryService: Failed to decode response: \(error)")
            throw AppError.invalidResponse
        }
    }
    
    // MARK: - Delete Video Job
    
    func deleteVideoJob(jobId: String) async throws {
        // Get user_id from local storage
        guard let userId = UserDefaultsManager.shared.currentUserId else {
            print("❌ HistoryService: No user_id found in local storage")
            throw AppError.invalidResponse
        }
        
        guard let url = URL(string: "\(baseURL)/functions/v1/delete-video-job") else {
            print("❌ HistoryService: Invalid URL")
            throw AppError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        struct DeleteRequest: Codable {
            let job_id: String
            let user_id: String
        }
        
        let body = DeleteRequest(job_id: jobId, user_id: userId)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ HistoryService: Invalid response type")
            throw AppError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                throw AppError.userNotFound
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ HistoryService: Backend error: \(errorString)")
            }
            throw AppError.networkFailure
        }
        
        // Decode response
        struct DeleteResponse: Codable {
            let success: Bool
        }
        
        do {
            let deleteResponse = try JSONDecoder().decode(DeleteResponse.self, from: data)
            guard deleteResponse.success else {
                print("❌ HistoryService: Delete operation returned success: false")
                throw AppError.invalidResponse
            }
        } catch {
            print("❌ HistoryService: Failed to decode delete response: \(error)")
            throw AppError.invalidResponse
        }
    }
}

// MARK: - Mock Service for Testing

class MockHistoryService: HistoryServiceProtocol {
    var jobsToReturn: [VideoJob] = VideoJob.previewList
    var shouldThrowError = false
    var errorToThrow: Error = AppError.networkFailure
    
    func fetchVideoJobs(userId: String?) async throws -> [VideoJob] {
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Simulate network delay
        try await Task.sleep(for: .seconds(0.3))
        
        return jobsToReturn
    }
    
    func deleteVideoJob(jobId: String) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Simulate network delay
        try await Task.sleep(for: .seconds(0.2))
        
        // Remove from mock data
        jobsToReturn.removeAll { $0.job_id == jobId }
    }
}
