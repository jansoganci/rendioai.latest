//
//  SkeletonProfileView.swift
//  RendioAI
//
//  Created by Rendio AI Team
//  Skeleton placeholder for Profile page loading states
//

import SwiftUI

/// Skeleton placeholder for the entire Profile page structure
struct SkeletonProfileView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header Skeleton
                SkeletonProfileHeader()

                // Credit Info Section Skeleton
                SkeletonCreditInfo()

                // Account Section Skeleton
                SkeletonAccountSection()

                // Settings Section Skeleton
                SkeletonSettingsSection()
            }
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Profile Header Skeleton

private struct SkeletonProfileHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            // Name skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(Color("TextSecondary").opacity(0.1))
                .frame(width: 150, height: 22)

            // Email skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(Color("TextSecondary").opacity(0.1))
                .frame(width: 200, height: 16)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color("SurfaceCard"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .padding(.horizontal, 16)
        .shimmer()
    }
}

// MARK: - Credit Info Skeleton

private struct SkeletonCreditInfo: View {
    var body: some View {
        VStack(spacing: 16) {
            // Credit display skeleton
            HStack(spacing: 8) {
                Image(systemName: "creditcard.fill")
                    .font(.title3)
                    .foregroundColor(Color("TextSecondary").opacity(0.3))

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("TextSecondary").opacity(0.1))
                    .frame(width: 100, height: 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

            // Action buttons skeleton
            HStack(spacing: 12) {
                // Buy credits button skeleton
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("TextSecondary").opacity(0.1))
                    .frame(height: 44)

                // View history button skeleton
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("TextSecondary").opacity(0.1))
                    .frame(height: 44)
            }
        }
        .padding(16)
        .background(Color("SurfaceCard"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .padding(.horizontal, 16)
        .shimmer()
    }
}

// MARK: - Account Section Skeleton

private struct SkeletonAccountSection: View {
    var body: some View {
        VStack(spacing: 12) {
            // Section header
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("TextSecondary").opacity(0.1))
                    .frame(width: 100, height: 18)
                Spacer()
            }
            .padding(.horizontal, 16)

            // Account options skeleton (3 rows)
            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { index in
                    HStack(spacing: 12) {
                        // Icon skeleton
                        Circle()
                            .fill(Color("TextSecondary").opacity(0.1))
                            .frame(width: 24, height: 24)

                        // Label skeleton
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color("TextSecondary").opacity(0.1))
                            .frame(width: 120, height: 14)

                        Spacer()

                        // Chevron skeleton
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Color("TextSecondary").opacity(0.3))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)

                    if index < 2 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(Color("SurfaceCard"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            .padding(.horizontal, 16)
        }
        .shimmer()
    }
}

// MARK: - Settings Section Skeleton

private struct SkeletonSettingsSection: View {
    var body: some View {
        VStack(spacing: 12) {
            // Section header
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("TextSecondary").opacity(0.1))
                    .frame(width: 80, height: 18)
                Spacer()
            }
            .padding(.horizontal, 16)

            // Settings options skeleton (3 rows)
            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { index in
                    HStack(spacing: 12) {
                        // Icon skeleton
                        Circle()
                            .fill(Color("TextSecondary").opacity(0.1))
                            .frame(width: 24, height: 24)

                        // Label skeleton
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color("TextSecondary").opacity(0.1))
                            .frame(width: 100, height: 14)

                        Spacer()

                        // Value skeleton
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color("TextSecondary").opacity(0.1))
                            .frame(width: 60, height: 14)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)

                    if index < 2 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(Color("SurfaceCard"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            .padding(.horizontal, 16)
        }
        .shimmer()
    }
}

// MARK: - Preview

#Preview("Skeleton Profile View") {
    NavigationStack {
        ZStack {
            Color("SurfaceBase")
                .ignoresSafeArea()

            SkeletonProfileView()
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("profile.title".localized)
    }
}

#Preview("Skeleton Profile View - Dark") {
    NavigationStack {
        ZStack {
            Color("SurfaceBase")
                .ignoresSafeArea()

            SkeletonProfileView()
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("profile.title".localized)
    }
    .preferredColorScheme(.dark)
}
