//
//  ModelGridCard.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct ModelGridCard: View {
    let model: ModelPreview
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail (maintains 16:9 ratio)
                thumbnailView

                // Model name (fixed height for consistency)
                Text(model.name)
                    .font(.headline)
                    .foregroundColor(Color("TextPrimary"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .frame(maxWidth: .infinity, minHeight: 14, alignment: .topLeading)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color("SurfaceCard"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel("\(model.name), \(model.category)")
        .accessibilityHint("home.accessibility.tap_to_view".localized)
    }

    // MARK: - Subviews

    private var thumbnailView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color("SurfaceCard").opacity(0.5))
            .aspectRatio(16/9, contentMode: .fit)
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
                .clipShape(RoundedRectangle(cornerRadius: 8))
            )
            .accessibilityHidden(true)
    }

    private var placeholderIcon: some View {
        Image(systemName: "video.fill")
            .font(.title3)
            .foregroundColor(Color("TextSecondary"))
    }
}

struct ThemeGridCard: View {
    let theme: Theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail (maintains 16:9 ratio)
                thumbnailView

                // Theme name (fixed height for consistency)
                Text(theme.name)
                    .font(.headline)
                    .foregroundColor(Color("TextPrimary"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .frame(maxWidth: .infinity, minHeight: 14, alignment: .topLeading)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color("SurfaceCard"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel(theme.name)
        .accessibilityHint("home.accessibility.tap_to_view".localized)
    }

    // MARK: - Subviews

    private var thumbnailView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color("SurfaceCard").opacity(0.5))
            .aspectRatio(16/9, contentMode: .fit)
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
                .clipShape(RoundedRectangle(cornerRadius: 8))
            )
            .accessibilityHidden(true)
    }

    private var placeholderIcon: some View {
        Image(systemName: "video.fill")
            .font(.title3)
            .foregroundColor(Color("TextSecondary"))
    }
}

#Preview("Light Mode") {
    LazyVGrid(columns: [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ], spacing: 12) {
        ModelGridCard(
            model: ModelPreview(
                id: "1",
                name: "Runway Gen-3",
                category: "Video Generation",
                thumbnailURL: nil,
                isFeatured: false
            ),
            action: {}
        )

        ModelGridCard(
            model: ModelPreview(
                id: "2",
                name: "Pika 2.5",
                category: "Video Editing",
                thumbnailURL: nil,
                isFeatured: false
            ),
            action: {}
        )
    }
    .padding()
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    LazyVGrid(columns: [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ], spacing: 12) {
        ModelGridCard(
            model: ModelPreview(
                id: "1",
                name: "Runway Gen-3",
                category: "Video Generation",
                thumbnailURL: nil,
                isFeatured: false
            ),
            action: {}
        )

        ModelGridCard(
            model: ModelPreview(
                id: "2",
                name: "Pika 2.5",
                category: "Video Editing",
                thumbnailURL: nil,
                isFeatured: false
            ),
            action: {}
        )
    }
    .padding()
    .preferredColorScheme(.dark)
}
