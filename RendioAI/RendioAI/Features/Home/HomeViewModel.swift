//
//  HomeViewModel.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var creditsRemaining: Int = 0
    @Published var searchQuery: String = ""
    @Published var featuredThemes: [Theme] = []
    @Published var allThemes: [Theme] = []
    @Published var isLoading: Bool = false
    @Published var selectedCarouselIndex: Int = 0
    @Published var errorMessage: String?
    @Published var showingErrorAlert: Bool = false

    // MARK: - Private Properties

    private let themeService: ThemeServiceProtocol
    private let creditService: CreditServiceProtocol
    private var carouselTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var showQuotaWarning: Bool {
        creditsRemaining < 10
    }

    var filteredThemes: [Theme] {
        if searchQuery.isEmpty {
            return allThemes
        }
        return allThemes.filter { theme in
            theme.name.localizedCaseInsensitiveContains(searchQuery) ||
            (theme.description?.localizedCaseInsensitiveContains(searchQuery) ?? false)
        }
    }

    // MARK: - Initialization

    init(
        themeService: ThemeServiceProtocol = ThemeService.shared,
        creditService: CreditServiceProtocol = CreditService.shared
    ) {
        self.themeService = themeService
        self.creditService = creditService
    }

    // MARK: - Public Methods

    func loadData() {
        Task {
            isLoading = true
            do {
                // Fetch themes (critical - must succeed)
                let fetchedThemes = try await themeService.fetchThemes()
                
                // Update themes state immediately
                allThemes = fetchedThemes
                featuredThemes = fetchedThemes.filter { $0.isFeatured }
                
                // Reset carousel index to prevent out-of-bounds
                if !featuredThemes.isEmpty {
                    selectedCarouselIndex = 0
                }
                
                // Fetch credits separately (non-critical - can fail gracefully)
                do {
                    let fetchedCredits = try await creditService.fetchCredits()
                    creditsRemaining = fetchedCredits
                } catch {
                    // If credits fail (e.g., no user_id), just log and continue
                    // User can still browse themes, credits will show as 0
                    print("⚠️ HomeViewModel: Failed to fetch credits: \(error)")
                    creditsRemaining = 0
                }

            } catch {
                // Only handle error if themes failed (critical failure)
                handleError(error)
            }
            isLoading = false
        }
    }

    func startCarouselTimer() {
        stopCarouselTimer()

        carouselTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))

                guard !Task.isCancelled, !featuredThemes.isEmpty else {
                    break
                }

                selectedCarouselIndex = (selectedCarouselIndex + 1) % featuredThemes.count
            }
        }
    }

    func stopCarouselTimer() {
        carouselTask?.cancel()
        carouselTask = nil
    }

    // MARK: - Private Methods

    private func handleError(_ error: Error) {
        // Map error to user-friendly message
        if let appError = error as? AppError {
            errorMessage = appError.errorDescription
        } else {
            errorMessage = "error.general.unexpected"
        }
        showingErrorAlert = true
    }

    // MARK: - Deinitialization

    deinit {
        carouselTask?.cancel()
    }
}

