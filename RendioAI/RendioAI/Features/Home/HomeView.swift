//
//  HomeView.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedThemeId: String?
    @State private var showWelcomeBanner: Bool = false
    @State private var showingPurchaseSheet: Bool = false

    private let stateManager = OnboardingStateManager.shared

    var body: some View {
        ZStack {
            // Background
            Color("SurfaceBase")
                .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.allThemes.isEmpty {
                // Initial loading state
                ProgressView()
                    .tint(Color("BrandPrimary"))
                    .accessibilityLabel("home.accessibility.loading".localized)
            } else {
                ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerView
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    
                    // Search Bar
                    searchBarView
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                    // Welcome Banner (for new users)
                    if showWelcomeBanner {
                        WelcomeBanner {
                            withAnimation {
                                showWelcomeBanner = false
                            }
                            stateManager.markWelcomeBannerAsSeen()
                        }
                        .padding(.top, 16)
                    }

                    // Low Credit Banner
                    if shouldShowLowCreditBanner {
                        LowCreditBanner(
                            creditsRemaining: viewModel.creditsRemaining,
                            onBuyCredits: {
                                showingPurchaseSheet = true
                            }
                        )
                        .padding(.top, 16)
                    }
                    
                    // Featured Themes Carousel
                    if !viewModel.featuredThemes.isEmpty {
                        featuredThemesSection
                            .padding(.top, 24)
                    }
                    
                    // All Themes Grid
                    allThemesSection
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                }
            }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Check if welcome banner should be shown
            showWelcomeBanner = stateManager.shouldShowWelcomeBanner()

            viewModel.loadData()
            viewModel.startCarouselTimer()
        }
        .onDisappear {
            viewModel.stopCarouselTimer()
        }
        .alert("common.error".localized, isPresented: $viewModel.showingErrorAlert) {
            Button("common.ok".localized, role: .cancel) { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage.localized)
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedThemeId != nil },
            set: { if !$0 { selectedThemeId = nil } }
        )) {
            if let themeId = selectedThemeId {
                ModelDetailView(themeId: themeId)
            }
        }
        .sheet(isPresented: $showingPurchaseSheet) {
            PurchaseSheet { creditsAdded in
                Task {
                    // Refresh credits after purchase
                    viewModel.loadData()
                }
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            // App Title
            Text("home_title".localized)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color("TextPrimary"))

            Spacer()

            // Credit Badge - only shows when credits are loaded
            if viewModel.creditsRemaining > 0 {
                CreditBadge(
                    creditsRemaining: viewModel.creditsRemaining,
                    onTap: {
                        showingPurchaseSheet = true
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(height: 44)
        .animation(.easeInOut(duration: 0.3), value: viewModel.creditsRemaining)
    }
    
    // MARK: - Search Bar View
    
    private var searchBarView: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color("TextSecondary"))
                .font(.body)
                .accessibilityHidden(true)
            
            TextField(
                "home_search_placeholder".localized,
                text: $viewModel.searchQuery
            )
            .font(.body)
            .foregroundColor(Color("TextPrimary"))
            .accessibilityLabel("home.accessibility.search_label".localized)
            .accessibilityHint("home.accessibility.search_hint".localized)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color("SurfaceCard"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Featured Themes Section
    
    private var featuredThemesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("home_featured_models".localized)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color("TextPrimary"))
                .padding(.horizontal, 16)
            
            // Carousel
            TabView(selection: $viewModel.selectedCarouselIndex) {
                ForEach(Array(viewModel.featuredThemes.enumerated()), id: \.element.id) { index, theme in
                    featuredThemeCard(theme: theme)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 200)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(String(format: "home.accessibility.carousel_label".localized, viewModel.selectedCarouselIndex + 1, viewModel.featuredThemes.count))
            .accessibilityHint("home.accessibility.carousel_hint".localized)
        }
    }
    
    private func featuredThemeCard(theme: Theme) -> some View {
        FeaturedThemeCard(
            theme: theme,
            action: {
                selectedThemeId = theme.id
            }
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - All Themes Section
    
    private var allThemesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("home_all_models".localized)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color("TextPrimary"))
                .padding(.horizontal, 16)
            
            if viewModel.filteredThemes.isEmpty {
                emptyStateView
                    .padding(.horizontal, 16)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(viewModel.filteredThemes) { theme in
                        themeGridCard(theme: theme)
                    }
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func themeGridCard(theme: Theme) -> some View {
        ThemeGridCard(
            theme: theme,
            action: {
                selectedThemeId = theme.id
            }
        )
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "home_no_models_found".localized
        )
    }

    // MARK: - Computed Properties

    /// Check if low credit banner should be shown
    private var shouldShowLowCreditBanner: Bool {
        return viewModel.creditsRemaining > 0 && viewModel.creditsRemaining < 10
    }
}

#Preview("Light Mode") {
    HomeView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    HomeView()
        .preferredColorScheme(.dark)
}
