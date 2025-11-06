//
//  HistoryView.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var selectedJobId: String?
    
    var body: some View {
        ZStack {
            // Background
            Color("SurfaceBase")
                .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.historySections.isEmpty {
                // Initial loading state
                ProgressView()
                    .tint(Color("BrandPrimary"))
                    .accessibilityLabel(NSLocalizedString("history.accessibility.loading", comment: "Loading history"))
            } else if viewModel.isEmpty {
                // Empty state
                HistoryEmptyState(onGenerateVideo: {
                    // Navigation to Home/ModelDetail not in blueprint - handled by tab navigation
                })
            } else {
                // Content with sections
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Search Bar
                        SearchBar(searchQuery: $viewModel.searchQuery)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        
                        // History Sections
                        ForEach(viewModel.filteredSections) { section in
                            HistorySection(
                                section: section,
                                onCardTap: { job in
                                    selectedJobId = job.job_id
                                },
                                onPlay: { job in
                                    selectedJobId = job.job_id
                                },
                                onDownload: { job in
                                    // Video download handled by ResultView
                                    selectedJobId = job.job_id
                                },
                                onShare: { job in
                                    // Video sharing handled by ResultView
                                    selectedJobId = job.job_id
                                },
                                onRetry: { job in
                                    // Retry generation handled by ResultView
                                    selectedJobId = job.job_id
                                },
                                onDelete: { job in
                                    viewModel.deleteJob(jobId: job.job_id)
                                }
                            )
                        }
                        
                        // Bottom padding
                        Spacer()
                            .frame(height: 32)
                    }
                }
                .refreshable {
                    await viewModel.refreshHistory()
                }
                .accessibilityLabel(NSLocalizedString("history.title", comment: "History title"))
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(NSLocalizedString("history.title", comment: "History title"))
        .onAppear {
            viewModel.loadHistory()
        }
        .alert(
            NSLocalizedString("common.error", comment: "Error"),
            isPresented: $viewModel.showingErrorAlert
        ) {
            Button(NSLocalizedString("common.ok", comment: "OK"), role: .cancel) { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(NSLocalizedString(errorMessage, comment: ""))
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedJobId != nil },
            set: { if !$0 { selectedJobId = nil } }
        )) {
            if let jobId = selectedJobId {
                ResultView(jobId: jobId)
            }
        }
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    NavigationStack {
        HistoryView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    NavigationStack {
        HistoryView()
    }
    .preferredColorScheme(.dark)
}
