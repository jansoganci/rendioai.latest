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
        VStack(spacing: 8) {
            // Name
            Text(userName)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color("TextPrimary"))

            // Email
            Text(email)
                .font(.body)
                .foregroundColor(Color("TextSecondary"))
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color("SurfaceCard"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .padding(.horizontal, 16)
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
