//
//  FeaturedModelCard.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct FeaturedModelCard: View {
    let model: ModelPreview
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Thumbnail
                thumbnailView

                // Model info
                modelInfoView
            }
            .padding(16)
            .background(Color("SurfaceCard"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(model.name), \(model.category)")
        .accessibilityHint("home.accessibility.tap_to_view".localized)
    }

    // MARK: - Subviews

    private var thumbnailView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color("SurfaceCard").opacity(0.5))
            .frame(height: 120)
            .overlay(
                Group {
                    if let thumbnailURL = model.thumbnailURL {
                        AsyncImage(url: thumbnailURL) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
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
                .clipShape(RoundedRectangle(cornerRadius: 12))
            )
            .accessibilityHidden(true)
    }

    private var placeholderIcon: some View {
        Image(systemName: "video.fill")
            .font(.largeTitle)
            .foregroundColor(Color("TextSecondary"))
    }

    private var modelInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(model.name)
                .font(.headline)
                .foregroundColor(Color("TextPrimary"))
                .lineLimit(1)

            Text(model.category)
                .font(.caption)
                .foregroundColor(Color("TextSecondary"))
                .lineLimit(1)
        }
    }
}

struct FeaturedThemeCard: View {
    let theme: Theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Thumbnail
                thumbnailView

                // Theme info
                themeInfoView
            }
            .padding(16)
            .background(Color("SurfaceCard"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.name)")
        .accessibilityHint("home.accessibility.tap_to_view".localized)
    }

    // MARK: - Subviews

    private var thumbnailView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color("SurfaceCard").opacity(0.5))
            .frame(height: 120)
            .overlay(
                Group {
                    if let thumbnailURL = theme.thumbnailURL {
                        AsyncImage(url: thumbnailURL) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
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
                .clipShape(RoundedRectangle(cornerRadius: 12))
            )
            .accessibilityHidden(true)
    }

    private var placeholderIcon: some View {
        Image(systemName: "video.fill")
            .font(.largeTitle)
            .foregroundColor(Color("TextSecondary"))
    }

    private var themeInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(theme.name)
                .font(.headline)
                .foregroundColor(Color("TextPrimary"))
                .lineLimit(1)

            if let description = theme.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))
                    .lineLimit(1)
            }
        }
    }
}

#Preview("With Thumbnail") {
    FeaturedModelCard(
        model: ModelPreview(
            id: "1",
            name: "FalAI Veo 3.1",
            category: "Text-to-Video",
            thumbnailURL: nil,
            isFeatured: true
        ),
        action: {}
    )
    .padding()
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    FeaturedModelCard(
        model: ModelPreview(
            id: "1",
            name: "Sora 2",
            category: "Image-to-Video",
            thumbnailURL: nil,
            isFeatured: true
        ),
        action: {}
    )
    .padding()
    .preferredColorScheme(.dark)
}
