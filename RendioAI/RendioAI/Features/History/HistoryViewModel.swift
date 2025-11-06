//
//  HistoryViewModel.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

@MainActor
class HistoryViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var historySections: [HistorySectionModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingErrorAlert: Bool = false
    @Published var searchQuery: String = ""
    
    // MARK: - Private Properties
    
    private let historyService: HistoryServiceProtocol
    
    // handled by DeviceCheckService and OnboardingStateManager (device ID management)
    // Phase 2: Will use authenticated user ID from AuthService
    private var userId: String? {
        // Placeholder - should be retrieved from DeviceCheck or Auth service
        "user-placeholder-id"
    }
    
    // MARK: - Computed Properties
    
    /// Filtered sections based on search query
    var filteredSections: [HistorySectionModel] {
        if searchQuery.isEmpty {
            return historySections
        }
        
        // Filter jobs within each section by prompt text
        return historySections.compactMap { section in
            let filteredJobs = section.items.filter { job in
                job.prompt.localizedCaseInsensitiveContains(searchQuery)
            }
            
            // Only include section if it has matching jobs
            guard !filteredJobs.isEmpty else {
                return nil
            }
            
            return HistorySectionModel(
                date: section.date,
                items: filteredJobs
            )
        }
    }
    
    /// Check if history is empty
    var isEmpty: Bool {
        filteredSections.isEmpty && !isLoading
    }
    
    // MARK: - Initialization
    
    init(historyService: HistoryServiceProtocol = HistoryService.shared) {
        self.historyService = historyService
    }
    
    // MARK: - Public Methods
    
    /// Load history from API
    func loadHistory() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                let jobs = try await historyService.fetchVideoJobs(userId: userId)
                historySections = groupJobsByDate(jobs)
            } catch {
                handleError(error)
            }
            
            isLoading = false
        }
    }
    
    /// Refresh history (pull-to-refresh)
    func refreshHistory() async {
        do {
            let jobs = try await historyService.fetchVideoJobs(userId: userId)
            historySections = groupJobsByDate(jobs)
        } catch {
            handleError(error)
        }
    }
    
    /// Delete a video job
    func deleteJob(jobId: String) {
        Task {
            do {
                try await historyService.deleteVideoJob(jobId: jobId)
                
                // Remove job from local sections
                historySections = historySections.compactMap { section in
                    let filteredItems = section.items.filter { $0.job_id != jobId }
                    
                    // Only include section if it still has jobs
                    guard !filteredItems.isEmpty else {
                        return nil
                    }
                    
                    return HistorySectionModel(
                        date: section.date,
                        items: filteredItems
                    )
                }
            } catch {
                handleError(error)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Group jobs by month/year and sort newest first
    private func groupJobsByDate(_ jobs: [VideoJob]) -> [HistorySectionModel] {
        guard !jobs.isEmpty else {
            return []
        }
        
        // Date formatter for section headers
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        // Group jobs by month/year
        let grouped = Dictionary(grouping: jobs) { job in
            formatter.string(from: job.created_at)
        }
        
        // Convert to sections and sort by date (newest first)
        let sections = grouped.map { dateString, jobs in
            // Sort jobs within section by date (newest first)
            let sortedJobs = jobs.sorted { $0.created_at > $1.created_at }
            
            return HistorySectionModel(
                date: dateString,
                items: sortedJobs
            )
        }
        
        // Sort sections by date (newest first)
        return sections.sorted { section1, section2 in
            guard let date1 = section1.dateValue,
                  let date2 = section2.dateValue else {
                return false
            }
            return date1 > date2
        }
    }
    
    /// Handle errors and update UI state
    private func handleError(_ error: Error) {
        if let appError = error as? AppError {
            errorMessage = appError.errorDescription
        } else {
            errorMessage = "error.general.unexpected"
        }
        showingErrorAlert = true
    }
}
