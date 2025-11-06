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
    
    private init() {}
    
    // MARK: - Fetch Video Jobs
    
    func fetchVideoJobs(userId: String?) async throws -> [VideoJob] {
        // Phase 2: Replace with actual Supabase Edge Function call
        // Endpoint: GET /get-video-jobs?user_id={id} or GET /get-video-jobs?device_id={uuid}
        // Base URL: {SUPABASE_URL}/functions/v1
        // Currently using mock data for development
        
        // Simulate network delay
        try await Task.sleep(for: .seconds(0.5))
        return VideoJob.previewList
    }
    
    // MARK: - Delete Video Job
    
    func deleteVideoJob(jobId: String) async throws {
        // Phase 2: Replace with actual Supabase Edge Function call
        // Endpoint: DELETE /delete-video-job?job_id={id}
        // Base URL: {SUPABASE_URL}/functions/v1
        // Currently using mock data for development
        
        // Simulate network delay
        try await Task.sleep(for: .seconds(0.3))
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
