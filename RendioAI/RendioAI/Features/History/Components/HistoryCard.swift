//
//  HistoryCard.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct HistoryCard: View {
    let job: VideoJob
    let onTap: () -> Void
    let onPlay: (() -> Void)?
    let onDownload: (() -> Void)?
    let onShare: (() -> Void)?
    let onRetry: (() -> Void)?
    let onDelete: (() -> Void)?
    
    init(
        job: VideoJob,
        onTap: @escaping () -> Void,
        onPlay: (() -> Void)? = nil,
        onDownload: (() -> Void)? = nil,
        onShare: (() -> Void)? = nil,
        onRetry: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.job = job
        self.onTap = onTap
        self.onPlay = onPlay
        self.onDownload = onDownload
        self.onShare = onShare
        self.onRetry = onRetry
        self.onDelete = onDelete
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Thumbnail and Status
                thumbnailSection
                
                // Prompt Text
                Text(job.prompt)
                    .font(.body)
                    .foregroundColor(Color("TextPrimary"))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Model and Credits Info
                HStack(spacing: 8) {
                    Text(job.model_name)
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                    
                    Text("•")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                    
                    Text("\(job.credits_used) \(NSLocalizedString("credits_short", comment: "credits"))")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                }
                
                // Status Badge
                statusBadge
                
                // Action Buttons
                actionButtons
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("SurfaceCard"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if let onDelete = onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label(
                        NSLocalizedString("common.delete", comment: "Delete"),
                        systemImage: "trash.fill"
                    )
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var thumbnailSection: some View {
        ZStack(alignment: .topTrailing) {
            // Thumbnail
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("SurfaceBase").opacity(0.5))
                .frame(height: 120)
                .overlay(
                    Group {
                        if let thumbnailURL = job.thumbnail_url, let url = URL(string: thumbnailURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .tint(Color("BrandPrimary"))
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    placeholderIcon
                                @unknown default:
                                    placeholderIcon
                                }
                            }
                        } else {
                            placeholderIcon
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                )
                .accessibilityHidden(true)
        }
    }
    
    private var placeholderIcon: some View {
        Image(systemName: "video.fill")
            .font(.largeTitle)
            .foregroundColor(Color("TextSecondary"))
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            if job.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                Text(NSLocalizedString("history.status.completed", comment: "Completed"))
            } else if job.isProcessing {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                Text(NSLocalizedString("history.status.processing", comment: "Processing"))
            } else if job.isFailed {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                Text(NSLocalizedString("history.status.failed", comment: "Failed"))
            } else {
                Image(systemName: "clock.fill")
                    .font(.caption)
                Text(NSLocalizedString("history.status.pending", comment: "Pending"))
            }
        }
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .cornerRadius(6)
        .accessibilityLabel(NSLocalizedString("history.status.\(job.status.rawValue)", comment: ""))
        .accessibilityAddTraits(.isStaticText)
    }
    
    private var statusColor: Color {
        switch job.status {
        case .completed:
            return Color("AccentSuccess")
        case .processing, .pending:
            return Color("AccentWarning")
        case .failed:
            return Color("AccentError")
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 8) {
            if job.isCompleted {
                if let onPlay = onPlay {
                    actionButton(
                        title: NSLocalizedString("history.actions.play", comment: "Play"),
                        icon: "play.fill",
                        action: onPlay
                    )
                }
                if let onDownload = onDownload {
                    actionButton(
                        title: NSLocalizedString("history.actions.download", comment: "Download"),
                        icon: "arrow.down.circle.fill",
                        action: onDownload
                    )
                }
                if let onShare = onShare {
                    actionButton(
                        title: NSLocalizedString("history.actions.share", comment: "Share"),
                        icon: "square.and.arrow.up.fill",
                        action: onShare
                    )
                }
            } else if job.isProcessing || job.isPending {
                actionButton(
                    title: NSLocalizedString("history.actions.wait", comment: "Wait"),
                    icon: "clock.fill",
                    action: {},
                    isEnabled: false
                )
            } else if job.isFailed {
                if let onRetry = onRetry {
                    actionButton(
                        title: NSLocalizedString("history.actions.retry", comment: "Retry"),
                        icon: "arrow.clockwise",
                        action: onRetry
                    )
                }
            }
        }
    }
    
    private func actionButton(
        title: String,
        icon: String,
        action: @escaping () -> Void,
        isEnabled: Bool = true,
        isDestructive: Bool = false
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isDestructive ? Color("AccentError") : Color("BrandPrimary"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                (isDestructive ? Color("AccentError") : Color("BrandPrimary"))
                    .opacity(isEnabled ? 0.1 : 0.05)
            )
            .cornerRadius(6)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
        .accessibilityLabel(title)
        .accessibilityHint(isEnabled ? "" : NSLocalizedString("common.accessibility.disabled", comment: "Button is disabled"))
    }
    
    // MARK: - Accessibility
    
    private var accessibilityLabel: String {
        var label = "\(job.prompt). "
        label += "\(NSLocalizedString("history.status.\(job.status.rawValue)", comment: "")). "
        label += "\(job.model_name). "
        label += "\(job.credits_used) \(NSLocalizedString("credits_short", comment: ""))"
        return label
    }
    
    private var accessibilityHint: String {
        if job.isCompleted {
            return NSLocalizedString("history.accessibility.tap_to_view", comment: "Double tap to view video")
        } else if job.isProcessing || job.isPending {
            return NSLocalizedString("history.accessibility.processing", comment: "Video is being processed")
        } else {
            return NSLocalizedString("history.accessibility.tap_for_options", comment: "Double tap for options")
        }
    }
}

// MARK: - Preview

#Preview("Completed") {
    ScrollView {
        VStack(spacing: 12) {
            HistoryCard(
                job: VideoJob.previewCompleted,
                onTap: {},
                onPlay: {},
                onDownload: {},
                onShare: {}
            )
        }
        .padding()
    }
    .background(Color("SurfaceBase"))
}

#Preview("Processing") {
    ScrollView {
        VStack(spacing: 12) {
            HistoryCard(
                job: VideoJob.previewProcessing,
                onTap: {}
            )
        }
        .padding()
    }
    .background(Color("SurfaceBase"))
}

#Preview("Failed") {
    ScrollView {
        VStack(spacing: 12) {
            HistoryCard(
                job: VideoJob.previewFailed,
                onTap: {},
                onRetry: {},
                onDelete: {}
            )
        }
        .padding()
    }
    .background(Color("SurfaceBase"))
}
