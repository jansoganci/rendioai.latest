//
//  ResultService.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

// MARK: - ResultService Protocol

protocol ResultServiceProtocol {
    /// Fetches a single video job by job ID
    func fetchVideoJob(jobId: String) async throws -> VideoJob
    
    /// Polls job status until completed, failed, or max attempts reached
    /// - Parameters:
    ///   - jobId: The job ID to poll
    ///   - maxAttempts: Maximum number of polling attempts (default: 60)
    ///   - pollInterval: Time between polls in seconds (default: 5.0)
    /// - Returns: The VideoJob when completed or failed
    func pollJobStatus(jobId: String, maxAttempts: Int, pollInterval: TimeInterval) async throws -> VideoJob
}

// MARK: - ResultService Implementation

class ResultService: ResultServiceProtocol {
    static let shared = ResultService()
    
    private let baseURL = "https://ojcnjxzctnwbmupggoxq.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qY25qeHpjdG53Ym11cGdnb3hxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMjkzNjIsImV4cCI6MjA3NzkwNTM2Mn0._bKw_0kYf65SxYC8ik3_SMdMgUYoxgVbisvCdRfYo08"
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Fetch Video Job
    
    func fetchVideoJob(jobId: String) async throws -> VideoJob {
        // Validate input
        guard !jobId.isEmpty else {
            print("❌ ResultService: Empty job_id")
            throw AppError.invalidResponse
        }
        
        // Call backend endpoint: GET /functions/v1/get-video-status?job_id={uuid}
        guard let url = URL(string: "\(baseURL)/functions/v1/get-video-status?job_id=\(jobId)") else {
            print("❌ ResultService: Invalid URL")
            throw AppError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ ResultService: Invalid response type")
            throw AppError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ ResultService: Backend error: \(errorString)")
            }
            throw AppError.networkFailure
        }
        
        // Backend returns: {job_id, status, video_url?, thumbnail_url?, error_message?}
        let decoder = JSONDecoder()
        
        do {
            struct BackendResponse: Codable {
                let job_id: String
                let status: String
                let prompt: String?
                let model_name: String?
                let credits_used: Int?
                let video_url: String?
                let thumbnail_url: String?
                let error_message: String?
                let created_at: String?
            }
            
            let backendResponse = try decoder.decode(BackendResponse.self, from: data)
            
            // Map backend status to VideoJob.JobStatus
            let jobStatus = VideoJob.JobStatus(rawValue: backendResponse.status) ?? .pending
            
            // Parse created_at date if provided
            var createdAt = Date()
            if let createdAtString = backendResponse.created_at {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: createdAtString) {
                    createdAt = date
                } else {
                    formatter.formatOptions = [.withInternetDateTime]
                    if let date = formatter.date(from: createdAtString) {
                        createdAt = date
                    }
                }
            }
            
            // Map to VideoJob with all fields from backend
            return VideoJob(
                job_id: backendResponse.job_id,
                prompt: backendResponse.prompt ?? "",
                model_name: backendResponse.model_name ?? "",
                credits_used: backendResponse.credits_used ?? 0,
                status: jobStatus,
                video_url: backendResponse.video_url,
                thumbnail_url: backendResponse.thumbnail_url,
                created_at: createdAt
            )
        } catch {
            print("❌ ResultService: Failed to decode response: \(error)")
            throw AppError.invalidResponse
        }
    }
    
    // MARK: - Poll Job Status
    
    func pollJobStatus(
        jobId: String,
        maxAttempts: Int = 60,
        pollInterval: TimeInterval = 5.0
    ) async throws -> VideoJob {
        // Validate input
        guard !jobId.isEmpty else {
            throw AppError.invalidResponse
        }
        
        guard maxAttempts > 0 else {
            throw AppError.invalidResponse
        }
        
        var attempt = 0
        
        while attempt < maxAttempts {
            // Fetch current job status
            let job = try await fetchVideoJob(jobId: jobId)
            
            // Check if job is completed or failed
            if job.isCompleted || job.isFailed {
                return job
            }
            
            // Increment attempt counter
            attempt += 1
            
            // If not done, wait before next poll (unless this was the last attempt)
            if attempt < maxAttempts {
                try await Task.sleep(for: .seconds(pollInterval))
            }
        }
        
        // If we've exhausted all attempts, return the last known status
        // This allows the UI to show the current state even if polling timed out
        return try await fetchVideoJob(jobId: jobId)
    }
}

// MARK: - Mock Service for Testing

class MockResultService: ResultServiceProtocol {
    var jobToReturn: VideoJob?
    var shouldThrowError = false
    var errorToThrow: Error = AppError.networkFailure
    var pollingBehavior: PollingBehavior = .immediateCompletion
    
    enum PollingBehavior {
        case immediateCompletion
        case progressiveStatus  // pending -> processing -> completed
        case slowProgress       // Multiple processing states before completion
    }
    
    func fetchVideoJob(jobId: String) async throws -> VideoJob {
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Simulate network delay
        try await Task.sleep(for: .seconds(0.3))
        
        if let job = jobToReturn {
            return job
        }
        
        // Default: Return completed job
        return VideoJob.previewCompleted
    }
    
    func pollJobStatus(jobId: String, maxAttempts: Int, pollInterval: TimeInterval) async throws -> VideoJob {
        if shouldThrowError {
            throw errorToThrow
        }
        
        switch pollingBehavior {
        case .immediateCompletion:
            // Return completed job immediately
            try await Task.sleep(for: .seconds(0.5))
            return VideoJob.previewCompleted
            
        case .progressiveStatus:
            // Simulate progression: pending -> processing -> completed
            var currentStatus = VideoJob.JobStatus.pending
            var attempt = 0
            
            while attempt < maxAttempts && currentStatus != .completed {
                try await Task.sleep(for: .seconds(pollInterval))
                
                // Progress status
                switch currentStatus {
                case .pending:
                    currentStatus = .processing
                case .processing:
                    currentStatus = .completed
                case .completed, .failed:
                    break
                }
                
                attempt += 1
            }
            
            return VideoJob(
                job_id: jobId,
                prompt: "Test prompt",
                model_name: "Test Model",
                credits_used: 4,
                status: currentStatus,
                video_url: currentStatus == .completed ? "https://cdn.supabase.com/video.mp4" : nil,
                created_at: Date()
            )
            
        case .slowProgress:
            // Simulate slow progression (multiple processing states)
            var attempt = 0
            let completionAttempt = maxAttempts / 2  // Complete halfway through
            
            while attempt < maxAttempts {
                try await Task.sleep(for: .seconds(pollInterval))
                
                let status: VideoJob.JobStatus = attempt < completionAttempt ? .processing : .completed
                
                if status == .completed {
                    return VideoJob(
                        job_id: jobId,
                        prompt: "Test prompt",
                        model_name: "Test Model",
                        credits_used: 4,
                        status: .completed,
                        video_url: "https://cdn.supabase.com/video.mp4",
                        created_at: Date()
                    )
                }
                
                attempt += 1
            }
            
            // Timeout - return processing status
            return VideoJob(
                job_id: jobId,
                prompt: "Test prompt",
                model_name: "Test Model",
                credits_used: 4,
                status: .processing,
                created_at: Date()
            )
        }
    }
}

