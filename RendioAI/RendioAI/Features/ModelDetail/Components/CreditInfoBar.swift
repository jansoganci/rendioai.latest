//
//  CreditInfoBar.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct CreditInfoBar: View {
    let cost: Int
    let creditsRemaining: Int
    
    private var hasSufficientCredits: Bool {
        creditsRemaining >= cost
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "creditcard.fill")
                .foregroundColor(Color("BrandPrimary"))
                .font(.body)
            
            Text(String(
                format: NSLocalizedString("model_detail.cost_info", comment: "Cost info message"),
                cost
            ))
            .font(.body)
            .foregroundColor(Color("TextPrimary"))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            hasSufficientCredits
                ? Color("AccentSuccess").opacity(0.1)
                : Color("AccentWarning").opacity(0.1)
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    hasSufficientCredits
                        ? Color("AccentSuccess").opacity(0.3)
                        : Color("AccentWarning").opacity(0.3),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Preview

#Preview("Sufficient Credits") {
    VStack(spacing: 16) {
        CreditInfoBar(cost: 4, creditsRemaining: 10)
        CreditInfoBar(cost: 4, creditsRemaining: 5)
        CreditInfoBar(cost: 4, creditsRemaining: 4)
    }
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}

#Preview("Insufficient Credits") {
    VStack(spacing: 16) {
        CreditInfoBar(cost: 4, creditsRemaining: 3)
        CreditInfoBar(cost: 4, creditsRemaining: 2)
        CreditInfoBar(cost: 4, creditsRemaining: 0)
    }
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.dark)
}
