//
//  ModelDetailViewModel.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI
import Foundation
import UIKit

@MainActor
class ModelDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var theme: Theme?
    @Published var activeModel: ModelDetail?
    @Published var prompt: String = ""
    @Published var settings: VideoSettings = .default
    @Published var selectedImage: UIImage?
    @Published var isUploadingImage: Bool = false
    @Published var isLoading: Bool = false
    @Published var isGenerating: Bool = false
    @Published var creditsRemaining: Int = 0
    @Published var errorMessage: String?
    @Published var showingErrorAlert: Bool = false
    @Published var generatedJobId: String?
    
    // MARK: - Private Properties
    
    private let themeId: String
    private let initialPrompt: String?
    private let themeService: ThemeServiceProtocol
    private let modelService: ModelServiceProtocol
    private let creditService: CreditServiceProtocol
    private let videoGenerationService: VideoGenerationServiceProtocol
    private let imageUploadService: ImageUploadServiceProtocol
    private var uploadedImageURL: String?
    
    // Get user_id from onboarding (stored after device-check)
    private var userId: String {
        UserDefaultsManager.shared.currentUserId ?? "user-placeholder-id"
    }
    
    // MARK: - Computed Properties
    
    var canGenerate: Bool {
        let hasPrompt = !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasCredits = creditsRemaining >= generationCost
        let hasImageIfRequired = !needsImage || selectedImage != nil
        let notGenerating = !isGenerating && !isUploadingImage
        
        return hasPrompt && hasCredits && hasImageIfRequired && notGenerating
    }
    
    var needsImage: Bool {
        activeModel?.requiredFields?.needsImage ?? false
    }
    
    var generationCost: Int {
        // Calculate cost dynamically based on duration: 1 second = 1 credit
        // Use current settings duration, or fallback to model default, or 4 seconds
        let duration = settings.duration ?? 
                      activeModel?.requiredFields?.settings?.duration?.default ?? 
                      4
        return duration
    }
    
    // Convenience property for backward compatibility
    var model: ModelDetail? {
        activeModel
    }
    
    // MARK: - Initialization
    
    init(
        themeId: String,
        initialPrompt: String? = nil,
        themeService: ThemeServiceProtocol = ThemeService.shared,
        modelService: ModelServiceProtocol = ModelService.shared,
        creditService: CreditServiceProtocol = CreditService.shared,
        videoGenerationService: VideoGenerationServiceProtocol = VideoGenerationService.shared,
        imageUploadService: ImageUploadServiceProtocol = ImageUploadService.shared
    ) {
        self.themeId = themeId
        self.initialPrompt = initialPrompt
        self.themeService = themeService
        self.modelService = modelService
        self.creditService = creditService
        self.videoGenerationService = videoGenerationService
        self.imageUploadService = imageUploadService
    }
    
    // MARK: - Public Methods
    
    func loadModelDetail() {
        Task {
            isLoading = true
            do {
                // Fetch theme and active model in parallel (critical - must succeed)
                async let fetchedTheme = themeService.fetchThemeDetail(id: themeId)
                async let fetchedActiveModel = modelService.fetchActiveModel()
                
                let (themeDetail, modelDetail) = try await (fetchedTheme, fetchedActiveModel)
                
                // Set theme and active model immediately
                theme = themeDetail
                activeModel = modelDetail
                
                // Pre-fill prompt: use initialPrompt if provided (for regeneration), otherwise use theme prompt
                prompt = initialPrompt ?? themeDetail.prompt
                
                // Apply theme's default settings if available
                if let defaultSettings = themeDetail.defaultSettings {
                    applyThemeDefaultSettings(defaultSettings)
                }
                
                // Fetch credits separately (non-critical - can fail gracefully)
                do {
                    let fetchedCredits = try await creditService.fetchCredits()
                    creditsRemaining = fetchedCredits
                } catch {
                    // If credits fail (e.g., no user_id), just log and continue
                    // User can still view the page, credits will show as 0
                    print("⚠️ ModelDetailViewModel: Failed to fetch credits: \(error)")
                    creditsRemaining = 0
                }
                
            } catch {
                // Only handle error if theme or active model failed (critical failure)
                handleError(error)
            }
            isLoading = false
        }
    }
    
    private func applyThemeDefaultSettings(_ defaultSettings: [String: Any]) {
        // Extract values from default settings, keeping existing values as fallback
        let duration = defaultSettings["duration"] as? Int ?? settings.duration
        let resolution = defaultSettings["resolution"] as? String ?? settings.resolution
        let aspectRatio = defaultSettings["aspect_ratio"] as? String ?? settings.aspect_ratio
        
        // Apply all settings at once
        settings = VideoSettings(
            duration: duration,
            resolution: resolution,
            aspect_ratio: aspectRatio,
            fps: settings.fps
        )
    }
    
    func generateVideo() {
        guard canGenerate else {
            // Validate before generating
            if prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = "error.validation.prompt_required"
                showingErrorAlert = true
            } else if creditsRemaining < generationCost {
                errorMessage = "error.credit.insufficient"
                showingErrorAlert = true
            } else if needsImage && selectedImage == nil {
                errorMessage = "error.validation.image_required"
                showingErrorAlert = true
            }
            return
        }
        
        guard let theme = theme else {
            errorMessage = "error.theme.not_found"
            showingErrorAlert = true
            return
        }
        
        guard let model = activeModel else {
            errorMessage = "error.model.not_found"
            showingErrorAlert = true
            return
        }
        
        Task {
            isGenerating = true
            errorMessage = nil
            
            do {
                // Check credits again before generating
                let hasCredits = try await creditService.hasSufficientCredits(cost: generationCost)
                guard hasCredits else {
                    throw AppError.insufficientCredits
                }
                
                // Upload image if required and selected
                var imageURL: String? = nil
                if needsImage, let image = selectedImage {
                    isUploadingImage = true
                    do {
                        imageURL = try await imageUploadService.uploadImage(image, userId: userId)
                        uploadedImageURL = imageURL
                        print("✅ ModelDetailViewModel: Image uploaded successfully: \(imageURL ?? "nil")")
                    } catch {
                        isUploadingImage = false
                        isGenerating = false
                        throw error
                    }
                    isUploadingImage = false
                }
                
                // Create request with theme_id, prompt, and image_url
                let request = VideoGenerationRequest(
                    user_id: userId,
                    theme_id: theme.id,
                    prompt: prompt.trimmingCharacters(in: .whitespacesAndNewlines),
                    image_url: imageURL,
                    settings: settings
                )
                
                // Generate video
                let response = try await videoGenerationService.generateVideo(request: request)
                
                // Update credits (deduct)
                let newCredits = try await creditService.updateCredits(
                    change: -response.credits_used,
                    reason: "generation"
                )
                
                creditsRemaining = newCredits
                generatedJobId = response.job_id
                isGenerating = false
                
                // Navigation to ResultView handled in View layer via navigationDestination
                
            } catch {
                handleError(error)
                isGenerating = false
            }
        }
    }
    
    func validatePrompt() -> Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Private Methods
    
    private func handleError(_ error: Error) {
        if let appError = error as? AppError {
            errorMessage = appError.errorDescription
        } else {
            errorMessage = "error.general.unexpected"
        }
        showingErrorAlert = true
    }
}
