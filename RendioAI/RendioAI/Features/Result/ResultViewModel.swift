//
//  ResultViewModel.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

// MARK: - Phase 5 Debug Helpers

// Toggle via build configuration: Set DEBUG_PHASE5=1 in build settings to enable
private func p5log(_ msg: String) {
    #if DEBUG
    print(msg)
    #endif
}

@MainActor
class ResultViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var videoJob: VideoJob?
    @Published var videoURL: URL?
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var showShareSheet: Bool = false
    @Published var prompt: String = ""
    @Published var modelName: String = ""
    @Published var creditsUsed: Int = 0
    @Published var errorMessage: String?
    @Published var showingErrorAlert: Bool = false
    @Published var showingSuccessAlert: Bool = false
    @Published var successMessage: String?

    // MARK: - Private Properties

    private let jobId: String
    private let resultService: ResultServiceProtocol
    private let storageService: StorageServiceProtocol
    private var subscriptionTask: Task<Void, Never>?
    
    // MARK: - Computed Properties
    
    /// Check if video is ready to play
    var isVideoReady: Bool {
        videoJob?.isCompleted == true && videoURL != nil
    }
    
    /// Check if job is still processing
    var isProcessing: Bool {
        videoJob?.isPending == true || videoJob?.isProcessing == true
    }
    
    /// Check if job failed
    var hasFailed: Bool {
        videoJob?.isFailed == true
    }
    
    /// Check if can save (video must be ready)
    var canSave: Bool {
        isVideoReady && !isSaving
    }
    
    /// Check if can share (video must be ready)
    var canShare: Bool {
        isVideoReady && !isSaving
    }
    
    // MARK: - Initialization
    
    init(
        jobId: String,
        resultService: ResultServiceProtocol = ResultService.shared,
        storageService: StorageServiceProtocol = StorageService.shared
    ) {
        self.jobId = jobId
        self.resultService = resultService
        self.storageService = storageService
    }
    
    // MARK: - Public Methods
    
    /// Load initial job status
    func loadJobStatus() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                let job = try await resultService.fetchVideoJob(jobId: jobId)
                updateJobState(job)

                // If job is still processing, start monitoring via Realtime
                if job.isPending || job.isProcessing {
                    startMonitoring()
                }

            } catch {
                handleError(error)
            }

            isLoading = false
        }
    }
    
    /// Start monitoring job status via Realtime subscriptions
    func startMonitoring() {
        p5log("[P5][ResultVM][Start] job_id=\(jobId)")

        // Stop any existing monitoring
        stopMonitoring()

        // Don't start if already completed or failed
        guard isProcessing else {
            return
        }

        subscriptionTask = Task {
            do {
                let result = try await withThrowingTaskGroup(of: Bool.self) { group in
                    // Realtime task
                    group.addTask {
                        for await job in self.resultService.subscribeToJobUpdates(jobId: self.jobId) {
                            p5log("[P5][ResultVM][Realtime][UPDATE] job_id=\(self.jobId) status=\(job.status.rawValue)")
                            await MainActor.run { self.updateJobState(job) }
                            if job.status == .completed || job.status == .failed {
                                // Stream path wins - job completed via realtime
                                p5log("[P5][ResultVM][Race][WIN]=Realtime job_id=\(self.jobId)")
                                return true
                            }
                        }
                        // Stream ended without completion
                        return false
                    }

                    // Timeout task (30s)
                    group.addTask {
                        try await Task.sleep(for: .seconds(30))
                        return false
                    }

                    // First finished wins
                    let winner = try await group.next() ?? false
                    group.cancelAll()
                    return winner
                }

                if result == true {
                    // Realtime completed normally
                    print("🧵 ResultViewModel: Realtime completed via stream")
                    return
                }

                // Timeout or no realtime updates -> fallback
                p5log("[P5][ResultVM][Race][WIN]=Timeout job_id=\(self.jobId) -> FallbackPolling")
                p5log("[P5][ResultVM][Fallback][START] job_id=\(self.jobId)")
                print("⏱️ ResultViewModel: Realtime timeout/no updates, falling back to polling")
                let job = try await self.resultService.pollJobStatus(
                    jobId: self.jobId,
                    maxAttempts: 60,
                    pollInterval: 5.0
                )
                await MainActor.run { self.updateJobState(job) }
                p5log("[P5][ResultVM][Fallback][END] job_id=\(self.jobId) status=\(job.status.rawValue)")
            } catch {
                // Realtime failed -> fallback to polling
                p5log("[P5][ResultVM][Race][ERR] job_id=\(self.jobId) error=\(error.localizedDescription)")
                p5log("[P5][ResultVM][Fallback][START] job_id=\(self.jobId)")
                print("⚠️ ResultViewModel: Realtime failed: \(error), using polling fallback")
                do {
                    let job = try await self.resultService.pollJobStatus(
                        jobId: self.jobId,
                        maxAttempts: 60,
                        pollInterval: 5.0
                    )
                    await MainActor.run { self.updateJobState(job) }
                    p5log("[P5][ResultVM][Fallback][END] job_id=\(self.jobId) status=\(job.status.rawValue)")
                } catch {
                    await MainActor.run { self.handleError(error) }
                }
            }
        }
    }

    /// Stop monitoring job status
    func stopMonitoring() {
        p5log("[P5][ResultVM][Stop] job_id=\(jobId)")
        subscriptionTask?.cancel()
        subscriptionTask = nil
    }

    /// Save video to Photos library
    func saveToLibrary() {
        guard canSave, let url = videoURL else {
            return
        }
        
        Task { @MainActor in
            isSaving = true
            errorMessage = nil
            
            do {
                // Check authorization first
                let authStatus = storageService.checkPhotosAuthorization()
                
                if authStatus != .authorized && authStatus != .limited {
                    // Request authorization
                    let newStatus = await storageService.requestPhotosAuthorization()

                    guard newStatus == .authorized || newStatus == .limited else {
                        throw AppError.unauthorized
                    }
                }
                
                // Download video if needed (if URL is remote)
                let localURL: URL
                if url.scheme == "http" || url.scheme == "https" {
                    localURL = try await storageService.downloadVideo(url: url)
                } else {
                    localURL = url
                }
                
                // Verify file exists before saving
                guard FileManager.default.fileExists(atPath: localURL.path) else {
                    throw AppError.invalidResponse
                }
                
                // Save to Photos library
                try await storageService.saveToPhotosLibrary(fileURL: localURL)
                
                // Success - reset saving state and show success message
                isSaving = false
                successMessage = "alert.video_saved"
                showingSuccessAlert = true
                
            } catch {
                handleError(error)
                isSaving = false
            }
        }
    }
    
    /// Share video
    /// Note: This method is kept for compatibility but the actual share preparation
    /// is now handled in ResultView.handleShare()
    func shareVideo() {
        // This method is no longer used - share is handled directly in ResultView
        // Keeping for backward compatibility
    }
    
    /// Get prompt for regeneration (returns current prompt)
    func getPromptForRegeneration() -> String {
        prompt
    }
    
    // MARK: - Private Methods
    
    /// Update state from VideoJob
    private func updateJobState(_ job: VideoJob) {
        videoJob = job
        prompt = job.prompt
        modelName = job.model_name
        creditsUsed = job.credits_used
        
        // Update video URL if job is completed and has video URL
        if job.isCompleted, let videoUrlString = job.video_url {
            videoURL = URL(string: videoUrlString)
        } else {
            videoURL = nil
        }
    }
    
    /// Handle errors and update UI state
    func handleError(_ error: Error) {
        if let appError = error as? AppError {
            errorMessage = appError.errorDescription
        } else {
            errorMessage = "error.general.unexpected"
        }
        showingErrorAlert = true
    }
    
    // MARK: - Deinitialization

    deinit {
        subscriptionTask?.cancel()
    }
}

