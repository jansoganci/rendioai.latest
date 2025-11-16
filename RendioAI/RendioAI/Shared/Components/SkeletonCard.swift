//
//  SkeletonCard.swift
//  RendioAI
//
//  Created by Rendio AI Team
//  Skeleton placeholder for loading states
//

import SwiftUI

/// Skeleton placeholder card that mimics the HistoryCard structure
struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail skeleton
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("TextSecondary").opacity(0.1))
                .frame(height: 200)
                .overlay(
                    Image(systemName: "photo.fill")
                        .font(.largeTitle)
                        .foregroundColor(Color("TextSecondary").opacity(0.3))
                )

            VStack(alignment: .leading, spacing: 8) {
                // Theme name skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("TextSecondary").opacity(0.1))
                    .frame(width: 120, height: 16)

                // Prompt skeleton (2 lines)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("TextSecondary").opacity(0.1))
                    .frame(height: 14)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("TextSecondary").opacity(0.1))
                    .frame(width: 180, height: 14)

                HStack(spacing: 16) {
                    // Status badge skeleton
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("TextSecondary").opacity(0.1))
                        .frame(width: 80, height: 24)

                    Spacer()

                    // Date skeleton
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("TextSecondary").opacity(0.1))
                        .frame(width: 100, height: 12)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color("SurfaceCard"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .shimmer() // Apply shimmer effect
    }
}

// MARK: - Shimmer Effect Modifier

/// Shimmer animation effect for skeleton screens
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 400 // Move shimmer across view
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerEffect())
    }
}

// MARK: - Preview

#Preview("Single Skeleton Card") {
    SkeletonCard()
        .padding()
        .background(Color("SurfaceBase"))
}

#Preview("Multiple Skeleton Cards") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonCard()
            }
        }
        .padding()
    }
    .background(Color("SurfaceBase"))
}
