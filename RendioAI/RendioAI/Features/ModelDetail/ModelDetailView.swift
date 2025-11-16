//
//  ModelDetailView.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct ModelDetailView: View {
    let theme: Theme
    let initialPrompt: String?

    @StateObject private var viewModel: ModelDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var generatedJobId: String?

    // Primary initializer - uses Theme object
    init(theme: Theme, initialPrompt: String? = nil) {
        self.theme = theme
        self.initialPrompt = initialPrompt
        self._viewModel = StateObject(wrappedValue: ModelDetailViewModel(theme: theme, initialPrompt: initialPrompt))
    }

    // Legacy initializer - for backward compatibility (deep links, regeneration)
    init(themeId: String, initialPrompt: String? = nil) {
        let placeholderTheme = Theme(
            id: themeId,
            name: "Loading...",
            description: nil,
            thumbnailURL: nil,
            prompt: "",
            isFeatured: false,
            isAvailable: true,
            defaultSettings: nil,
            createdAt: Date()
        )

        self.theme = placeholderTheme
        self.initialPrompt = initialPrompt
        self._viewModel = StateObject(wrappedValue: ModelDetailViewModel(theme: nil, themeId: themeId, initialPrompt: initialPrompt))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color("SurfaceBase")
                .ignoresSafeArea()

            // Only show full-page loading on FIRST load (when no theme exists - legacy path only)
            if viewModel.isLoading && viewModel.theme == nil {
                ProgressView()
                    .tint(Color("BrandPrimary"))
            } else if let theme = viewModel.theme {
                // Show UI immediately if we have theme (always true with new approach)
                ScrollView {
                    VStack(spacing: 0) {
                        // Header - Always visible
                        headerView(theme: theme, activeModel: viewModel.activeModel)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        // Theme Description - Always visible
                        descriptionSection(theme: theme)
                            .padding(.horizontal, 16)
                            .padding(.top, 24)

                        // Prompt Input - Always visible
                        PromptInputField(
                            text: $viewModel.prompt,
                            placeholder: NSLocalizedString("model_detail.prompt_placeholder", comment: "Prompt placeholder"),
                            isEnabled: !viewModel.isLoadingModel
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 24)

                        // Model-dependent sections - Progressive loading
                        if viewModel.isLoadingModel {
                            // Inline loading state (not full-page)
                            VStack(spacing: 16) {
                                ProgressView()
                                    .tint(Color("BrandPrimary"))
                                Text(NSLocalizedString("model_detail.loading_settings", comment: "Loading settings"))
                                    .font(.caption)
                                    .foregroundColor(Color("TextSecondary"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else if let activeModel = viewModel.activeModel {
                            // Image Picker (only if model requires image)
                            if activeModel.requiredFields?.needsImage == true {
                                ImagePickerView(
                                    selectedImage: $viewModel.selectedImage,
                                    isRequired: true,
                                    isEnabled: !viewModel.isGenerating && !viewModel.isUploadingImage
                                )
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                            }

                            // Dynamic Settings Panel
                            DynamicSettingsPanel(
                                settings: $viewModel.settings,
                                modelRequirements: activeModel.requiredFields
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 16)

                            // Credit Info Bar
                            CreditInfoBar(
                                cost: viewModel.generationCost,
                                creditsRemaining: viewModel.creditsRemaining
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        }

                        // Tip Text - Always visible
                        tipSection
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 100) // Space for fixed button
                    }
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            // Fixed Generate Button at bottom
            generateButtonSection
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    Color("SurfaceBase")
                        .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
                )
        }
        .onAppear {
            viewModel.loadModelDetail()
        }
        .onChange(of: viewModel.generatedJobId) { newValue in
            if let jobId = newValue {
                generatedJobId = jobId
            }
        }
        .alert(NSLocalizedString("common.error", comment: "Error"), isPresented: $viewModel.showingErrorAlert) {
            Button(NSLocalizedString("common.ok", comment: "OK"), role: .cancel) { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(NSLocalizedString(errorMessage, comment: "Error message"))
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { generatedJobId != nil },
            set: { if !$0 { generatedJobId = nil } }
        )) {
            if let jobId = generatedJobId {
                ResultView(jobId: jobId, themeId: theme.id)
            }
        }
    }
    
    // MARK: - Header View
    
    private func headerView(theme: Theme, activeModel: ModelDetail?) -> some View {
        HStack {
            // Back Button
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("TextPrimary"))
            }
            .accessibilityLabel(NSLocalizedString("common.back", comment: "Back button"))
            
            // Theme Name (or active model name as fallback)
            Text(theme.name)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color("TextPrimary"))
            
            Spacer()
            
            // Credit Badge
            creditBadgeView
        }
        .frame(height: 44)
    }
    
    private var creditBadgeView: some View {
        HStack(spacing: 4) {
            Text("\(viewModel.creditsRemaining)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color("BrandPrimary"))
            
            Text(NSLocalizedString("credits_short", comment: "Credits abbreviation"))
                .font(.caption)
                .foregroundColor(Color("TextSecondary"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color("BrandPrimary").opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Description Section
    
    private func descriptionSection(theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let description = theme.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(Color("TextSecondary"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color("SurfaceCard"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
    

    
    // MARK: - Tip Section
    
    private var tipSection: some View {
        Text(NSLocalizedString("model_detail.tip", comment: "Tip text"))
            .font(.caption)
            .foregroundColor(Color("TextSecondary"))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Generate Button Section
    
    private var generateButtonSection: some View {
        PrimaryButton(
            title: viewModel.isGenerating
                ? NSLocalizedString("model_detail.generating", comment: "Generating...")
                : NSLocalizedString("model_detail.generate_button", comment: "Generate button"),
            action: {
                viewModel.generateVideo()
            },
            isEnabled: viewModel.canGenerate,
            isLoading: viewModel.isGenerating,
            icon: viewModel.isGenerating ? nil : "🎥"
        )
        .accessibilityLabel(viewModel.isGenerating 
            ? NSLocalizedString("model_detail.generating", comment: "Generating")
            : NSLocalizedString("model_detail.generate_button", comment: "Generate button"))
        .accessibilityHint(NSLocalizedString("model_detail.generate_button", comment: "Generate video hint"))
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    NavigationStack {
        ModelDetailView(themeId: "preview-theme-id")
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    NavigationStack {
        ModelDetailView(themeId: "preview-theme-id")
    }
    .preferredColorScheme(.dark)
}
