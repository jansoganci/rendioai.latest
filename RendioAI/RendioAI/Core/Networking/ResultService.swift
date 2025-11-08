//
//  ResultService.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation
import Supabase

// MARK: - Phase 5 Debug Helpers

// Toggle via build configuration: Set DEBUG_PHASE5=1 in build settings to enable
private func p5log(_ msg: String) {
    #if DEBUG
    print(msg)
    #endif
}

private struct P5Timer {
    let t = Date()
    func ms() -> Int {
        Int(Date().timeIntervalSince(t) * 1000)
    }
}

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

    /// Subscribes to real-time updates for a video job
    /// - Parameter jobId: The job ID to monitor
    /// - Returns: AsyncStream that yields VideoJob updates
    func subscribeToJobUpdates(jobId: String) -> AsyncStream<VideoJob>
}

// MARK: - ResultService Implementation

class ResultService: ResultServiceProtocol {
    static let shared = ResultService()

    private var baseURL: String { AppConfig.supabaseURL }
    private var anonKey: String { AppConfig.supabaseAnonKey }
    private let session: URLSession
    private let supabaseClient: SupabaseClient

    init(session: URLSession = .shared) {
        self.session = session
        self.supabaseClient = SupabaseClient(
            supabaseURL: URL(string: AppConfig.supabaseURL)!,
            supabaseKey: AppConfig.supabaseAnonKey
        )
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
        let timer = P5Timer()
        p5log("[P5][ResultService][Poll][START] job_id=\(jobId) maxAttempts=\(maxAttempts)")

        // Validate input
        guard !jobId.isEmpty else {
            throw AppError.invalidResponse
        }

        guard maxAttempts > 0 else {
            throw AppError.invalidResponse
        }

        var attempt = 0
        var interval: TimeInterval = 2.0  // Start with 2 seconds

        while attempt < maxAttempts {
            // Fetch current job status
            let job = try await fetchVideoJob(jobId: jobId)

            p5log("[P5][ResultService][Poll][ATTEMPT] #\(attempt + 1) status=\(job.status.rawValue) nextWait=\(Int(interval))s")

            // Check if job is completed or failed
            if job.isCompleted || job.isFailed {
                p5log("[P5][ResultService][Poll][OK] job_id=\(jobId) status=\(job.status.rawValue) totalMs=\(timer.ms())")
                return job
            }

            // Increment attempt counter
            attempt += 1

            // If not done, wait before next poll (unless this was the last attempt)
            if attempt < maxAttempts {
                // Exponential backoff: 2s → 4s → 8s → 16s → 30s (capped)
                try await Task.sleep(for: .seconds(interval))
                interval = min(interval * 2, 30.0)
            }
        }

        // If we've exhausted all attempts, return the last known status
        // This allows the UI to show the current state even if polling timed out
        p5log("[P5][ResultService][Poll][TIMEOUT] job_id=\(jobId) totalMs=\(timer.ms())")
        return try await fetchVideoJob(jobId: jobId)
    }

    // MARK: - Realtime Subscription

    func subscribeToJobUpdates(jobId: String) -> AsyncStream<VideoJob> {
        AsyncStream { continuation in
            p5log("[P5][ResultService][Realtime][SUB] job_id=\(jobId)")
            let channel = supabaseClient.channel("video-job-\(jobId)")

            _ = channel.onPostgresChange(
                UpdateAction.self,
                schema: "public",
                table: "video_jobs",
                filter: "job_id=eq.\(jobId)"
            ) { change in
                do {
                    let decoder = JSONDecoder()

                    // Configure date decoding
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    decoder.dateDecodingStrategy = .custom { decoder in
                        let container = try decoder.singleValueContainer()
                        let dateString = try container.decode(String.self)

                        if let date = formatter.date(from: dateString) {
                            return date
                        }

                        // Fallback without fractional seconds
                        formatter.formatOptions = [.withInternetDateTime]
                        if let date = formatter.date(from: dateString) {
                            return date
                        }

                        return Date()
                    }

                    // Decode VideoJob from realtime payload
                    let job = try change.decodeRecord(as: VideoJob.self, decoder: decoder)

                    p5log("[P5][ResultService][Realtime][UPDATE] job_id=\(jobId) status=\(job.status.rawValue)")
                    print("✅ ResultService: Received realtime update - status: \(job.status)")

                    // Yield the updated job to the stream
                    continuation.yield(job)

                    // End stream when job is completed or failed
                    if job.status == .completed || job.status == .failed {
                        p5log("[P5][ResultService][Realtime][END] job_id=\(jobId) status=\(job.status.rawValue)")
                        print("✅ ResultService: Job finished, ending realtime stream")
                        continuation.finish()
                    }
                } catch {
                    p5log("[P5][ResultService][Realtime][ERR] decode failed: \(error.localizedDescription)")
                    print("❌ ResultService: Failed to decode realtime payload: \(error)")
                }
            }

            // Subscribe to the channel
            Task {
                await channel.subscribe()
                p5log("[P5][ResultService][Realtime][SUBSCRIBED] job_id=\(jobId)")
                print("✅ ResultService: Subscribed to realtime updates for job \(jobId)")
            }

            // Clean up on stream termination
            continuation.onTermination = { @Sendable _ in
                Task {
                    await channel.unsubscribe()
                    p5log("[P5][ResultService][Realtime][UNSUBSCRIBE] job_id=\(jobId)")
                    print("✅ ResultService: Unsubscribed from realtime updates for job: \(jobId)")
                }
            }
        }
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

    func subscribeToJobUpdates(jobId: String) -> AsyncStream<VideoJob> {
        AsyncStream { continuation in
            // Mock implementation: immediately yield completed job
            Task {
                try? await Task.sleep(for: .seconds(1))
                continuation.yield(VideoJob.previewCompleted)
                continuation.finish()
            }
        }
    }
}

