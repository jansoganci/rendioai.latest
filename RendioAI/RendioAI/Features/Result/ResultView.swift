//
//  ResultView.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI
import Foundation

// Extension to make URL Identifiable for sheet presentation
extension URL: Identifiable {
    public var id: String {
        self.absoluteString
    }
}

struct ResultView: View {
    let jobId: String
    let themeId: String?
    
    @StateObject private var viewModel: ResultViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var shareURL: URL?
    @State private var regenerateThemeId: String?
    @State private var regeneratePrompt: String?
    
    init(jobId: String, themeId: String? = nil) {
        self.jobId = jobId
        self.themeId = themeId
        self._viewModel = StateObject(wrappedValue: ResultViewModel(jobId: jobId))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color("SurfaceBase")
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                // Initial loading state
                loadingView
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerView
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        
                        // Video Player
                        VideoPlayerView(
                            videoURL: viewModel.videoURL,
                            isProcessing: viewModel.isProcessing,
                            hasFailed: viewModel.hasFailed
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        
                        // Info Card (only show if job exists)
                        if let job = viewModel.videoJob {
                            ResultInfoCard(
                                prompt: job.prompt,
                                modelName: job.model_name,
                                creditsUsed: job.credits_used
                            )
                            .padding(.horizontal, 16)
                        }
                        
                        // Action Buttons
                        ActionButtonsRow(
                            canSave: viewModel.canSave,
                            canShare: viewModel.canShare,
                            isSaving: viewModel.isSaving,
                            onSave: {
                                viewModel.saveToLibrary()
                            },
                            onShare: {
                                handleShare()
                            },
                            onRegenerate: {
                                handleRegenerate()
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        // Polling indicator (if processing)
                        if viewModel.isPolling {
                            pollingIndicator
                                .padding(.top, 8)
                        }
                        
                        // Bottom padding
                        Spacer()
                            .frame(height: 32)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                backButton
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                homeButton
            }
        }
        .onAppear {
            viewModel.loadJobStatus()
        }
        .onDisappear {
            viewModel.stopPolling()
        }
        .sheet(item: $shareURL) { url in
            ShareLink(item: url) {
                VStack(spacing: 16) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 48))
                        .foregroundColor(Color("BrandPrimary"))
                    
                    Text(NSLocalizedString("result.share", comment: "Share"))
                        .font(.headline)
                        .foregroundColor(Color("TextPrimary"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .alert(NSLocalizedString("common.error", comment: "Error"), isPresented: $viewModel.showingErrorAlert) {
            Button(NSLocalizedString("common.ok", comment: "OK"), role: .cancel) { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(NSLocalizedString(errorMessage, comment: "Error message"))
            }
        }
        .alert(NSLocalizedString("common.success", comment: "Success"), isPresented: $viewModel.showingSuccessAlert) {
            Button(NSLocalizedString("common.ok", comment: "OK"), role: .cancel) { }
        } message: {
            if let successMessage = viewModel.successMessage {
                Text(NSLocalizedString(successMessage, comment: "Success message"))
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { regenerateThemeId != nil },
            set: { 
                print("🔵 navigationDestination setter called: \($0)")
                if !$0 { 
                    regenerateThemeId = nil
                    regeneratePrompt = nil
                } else if regenerateThemeId != nil {
                    print("🔵 navigationDestination triggered with themeId: \(regenerateThemeId!)")
                }
            }
        )) {
            if let themeId = regenerateThemeId {
                ModelDetailView(themeId: themeId, initialPrompt: regeneratePrompt)
                    .onAppear {
                        print("🔵 ModelDetailView appeared in navigationDestination with themeId: \(themeId)")
                    }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color("BrandPrimary"))
                .scaleEffect(1.5)
            
            Text(NSLocalizedString("result.loading", comment: "Loading video"))
                .font(.body)
                .foregroundColor(Color("TextSecondary"))
        }
        .accessibilityLabel(NSLocalizedString("result.accessibility.loading", comment: "Loading video"))
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text(NSLocalizedString("result.title", comment: "Your Video is Ready!"))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color("TextPrimary"))
            
            if viewModel.isProcessing {
                Text(NSLocalizedString("result.processing", comment: "Processing video..."))
                    .font(.subheadline)
                    .foregroundColor(Color("TextSecondary"))
            } else if viewModel.hasFailed {
                Text(NSLocalizedString("result.failed", comment: "Video generation failed"))
                    .font(.subheadline)
                    .foregroundColor(Color("AccentError"))
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(headerAccessibilityLabel)
    }
    
    private var backButton: some View {
        Button(action: {
            dismiss()
        }) {
            Image(systemName: "chevron.left")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color("TextPrimary"))
        }
        .accessibilityLabel(NSLocalizedString("common.back", comment: "Back button"))
    }
    
    private var homeButton: some View {
        Button(action: {
            // Navigate to Home tab
            // This will be handled by dismissing to root
            dismiss()
        }) {
            Image(systemName: "house.fill")
                .font(.title3)
                .foregroundColor(Color("TextPrimary"))
        }
        .accessibilityLabel(NSLocalizedString("tab.home", comment: "Home tab"))
        .accessibilityHint(NSLocalizedString("result.home_hint", comment: "Double tap to go to home"))
    }
    
    private var pollingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.8)
                .tint(Color("BrandPrimary"))
            
            Text(NSLocalizedString("result.checking_status", comment: "Checking status..."))
                .font(.caption)
                .foregroundColor(Color("TextSecondary"))
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(NSLocalizedString("result.checking_status", comment: "Checking status..."))
    }
    
    // MARK: - Private Methods
    
    private func handleShare() {
        print("🟢 Share button tapped")
        
        guard let videoURL = viewModel.videoURL else {
            print("❌ No videoURL available")
            return
        }
        
        print("📹 Video URL: \(videoURL)")
        print("✅ Sharing URL directly (no download) - iOS will handle it")
        
        // Share URL directly - no download needed
        // iOS ShareLink can handle remote URLs and will download if needed
        shareURL = videoURL
        print("✅ ShareLink presentation triggered with URL: \(videoURL)")
    }
    
    private func handleRegenerate() {
        print("🟢 Regenerate button tapped")
        
        // Get prompt for regeneration
        let prompt = viewModel.getPromptForRegeneration()
        print("🧠 Using prompt: \(prompt)")
        
        // Get themeId
        print("🔍 Checking themeId...")
        guard let themeId = themeId else {
            // If themeId not available, just dismiss
            print("⚠️ No themeId, dismissing view")
            dismiss()
            return
        }
        
        print("✅ ThemeId found: \(themeId)")
        
        // Set up navigation to ModelDetailView with prompt
        // navigationDestination will trigger automatically when regenerateThemeId is set
        // This will push ModelDetailView on top of ResultView
        print("🚀 Setting up navigation...")
        regeneratePrompt = prompt
        regenerateThemeId = themeId
        print("🚀 Navigating to ModelDetailView with themeId: \(themeId)")
        print("🚀 Prompt will be: \(prompt)")
        print("✅ Navigation state set - ModelDetailView will be pushed on top")
        print("✅ User can navigate back to ResultView if needed")
        
        // Don't dismiss ResultView - let navigationDestination handle it
        // ModelDetailView will be pushed on top, user can go back if needed
    }
    
    // MARK: - Accessibility
    
    private var headerAccessibilityLabel: String {
        var label = NSLocalizedString("result.title", comment: "Your Video is Ready!")
        
        if viewModel.isProcessing {
            label += ". \(NSLocalizedString("result.processing", comment: "Processing video..."))"
        } else if viewModel.hasFailed {
            label += ". \(NSLocalizedString("result.failed", comment: "Video generation failed"))"
        }
        
        return label
    }
}

// MARK: - Preview

#Preview("Light Mode - Processing") {
    NavigationStack {
        ResultView(jobId: "preview-job-id")
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode - Completed") {
    NavigationStack {
        ResultView(jobId: "preview-job-id")
    }
    .preferredColorScheme(.dark)
}
