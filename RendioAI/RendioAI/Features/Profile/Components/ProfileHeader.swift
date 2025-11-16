//
//  ProfileHeader.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct ProfileHeader: View {
    let userName: String
    let email: String

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            avatarView
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(userName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("TextPrimary"))
                
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(Color("TextSecondary"))
            }
            
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color("SurfaceCard"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .padding(.horizontal, 16)
    }
    
    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color("BrandPrimary").opacity(0.8), Color("BrandPrimary")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
            
            Image(systemName: "person.fill")
                .font(.title3)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview

#Preview("Guest User") {
    ProfileHeader(
        userName: "Guest User",
        email: "—"
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}

#Preview("Registered User") {
    ProfileHeader(
        userName: "John Doe",
        email: "john.doe@privaterelay.appleid.com"
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.dark)
}

#Preview("With Long Email") {
    ProfileHeader(
        userName: "Jane Smith",
        email: "jane.smith@example.com"
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}
