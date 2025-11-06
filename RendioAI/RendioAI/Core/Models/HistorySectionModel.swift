//
//  HistorySectionModel.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

struct HistorySectionModel: Identifiable {
    let id: String
    let date: String
    let items: [VideoJob]
    
    // MARK: - Initializer
    
    init(date: String, items: [VideoJob]) {
        self.id = date
        self.date = date
        self.items = items
    }
    
    // MARK: - Computed Properties
    
    /// Returns the date value for sorting purposes
    var dateValue: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.date(from: date)
    }
    
    /// Returns the date components for more accurate sorting
    var dateComponents: DateComponents? {
        guard let dateValue = dateValue else { return nil }
        return Calendar.current.dateComponents([.year, .month], from: dateValue)
    }
}

// MARK: - Preview Data

extension HistorySectionModel {
    static var previewSections: [HistorySectionModel] {
        let calendar = Calendar.current
        let now = Date()
        
        // Current month
        let currentMonthJobs = [
            VideoJob.previewProcessing,
            VideoJob.previewPending
        ]
        
        // Previous month (1 month ago)
        let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        let previousMonthJobs = [
            VideoJob.previewCompleted
        ]
        
        // Older month (2 months ago)
        let olderMonthDate = calendar.date(byAdding: .month, value: -2, to: now) ?? now
        let olderMonthJobs = [
            VideoJob.previewFailed
        ]
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        return [
            HistorySectionModel(
                date: formatter.string(from: now),
                items: currentMonthJobs
            ),
            HistorySectionModel(
                date: formatter.string(from: previousMonthDate),
                items: previousMonthJobs
            ),
            HistorySectionModel(
                date: formatter.string(from: olderMonthDate),
                items: olderMonthJobs
            )
        ]
    }
}
