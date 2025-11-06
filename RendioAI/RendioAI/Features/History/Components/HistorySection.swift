//
//  HistorySection.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct HistorySection: View {
    let section: HistorySectionModel
    let onCardTap: (VideoJob) -> Void
    let onPlay: ((VideoJob) -> Void)?
    let onDownload: ((VideoJob) -> Void)?
    let onShare: ((VideoJob) -> Void)?
    let onRetry: ((VideoJob) -> Void)?
    let onDelete: ((VideoJob) -> Void)?
    
    init(
        section: HistorySectionModel,
        onCardTap: @escaping (VideoJob) -> Void,
        onPlay: ((VideoJob) -> Void)? = nil,
        onDownload: ((VideoJob) -> Void)? = nil,
        onShare: ((VideoJob) -> Void)? = nil,
        onRetry: ((VideoJob) -> Void)? = nil,
        onDelete: ((VideoJob) -> Void)? = nil
    ) {
        self.section = section
        self.onCardTap = onCardTap
        self.onPlay = onPlay
        self.onDownload = onDownload
        self.onShare = onShare
        self.onRetry = onRetry
        self.onDelete = onDelete
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            Text(section.date)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color("TextPrimary"))
                .padding(.horizontal, 16)
            
            // History Cards
            VStack(spacing: 12) {
                ForEach(section.items) { job in
                    HistoryCard(
                        job: job,
                        onTap: {
                            onCardTap(job)
                        },
                        onPlay: onPlay.map { callback in { callback(job) } },
                        onDownload: onDownload.map { callback in { callback(job) } },
                        onShare: onShare.map { callback in { callback(job) } },
                        onRetry: onRetry.map { callback in { callback(job) } },
                        onDelete: onDelete.map { callback in { callback(job) } }
                    )
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            HistorySection(
                section: HistorySectionModel.previewSections[0],
                onCardTap: { _ in }
            )
        }
        .padding(.vertical, 16)
    }
    .background(Color("SurfaceBase"))
}
