//
//  ResultViewModel.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

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
    @Published var isPolling: Bool = false
    
    // MARK: - Private Properties
    
    private let jobId: String
    private let resultService: ResultServiceProtocol
    private let storageService: StorageServiceProtocol
    private var pollingTask: Task<Void, Never>?
    
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
                
                // If job is still processing, start polling
                if job.isPending || job.isProcessing {
                    startPolling()
                }
                
            } catch {
                handleError(error)
            }
            
            isLoading = false
        }
    }
    
    /// Start polling job status
    func startPolling() {
        // Stop any existing polling
        stopPolling()
        
        // Don't start if already completed or failed
        guard isProcessing else {
            return
        }
        
        isPolling = true
        
        pollingTask = Task {
            do {
                // Poll with max 60 attempts, 5 second intervals
                let job = try await resultService.pollJobStatus(
                    jobId: jobId,
                    maxAttempts: 60,
                    pollInterval: 5.0
                )
                
                // Update state with final job status
                updateJobState(job)
                
                // Stop polling (completed or failed)
                isPolling = false
                
            } catch {
                // If polling fails, stop polling and show error
                isPolling = false
                handleError(error)
            }
        }
    }
    
    /// Stop polling job status
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        isPolling = false
    }
    
    /// Save video to Photos library
    func saveToLibrary() {
        guard canSave, let url = videoURL else {
            return
        }
        
        Task {
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
        pollingTask?.cancel()
    }
}

