//
//  PromptInputField.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct PromptInputField: View {
    @Binding var text: String
    let placeholder: String
    var minLines: Int = 5
    var maxLines: Int = 10
    var isEnabled: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("model_detail.prompt_label", comment: "Prompt input label"))
                .font(.headline)
                .foregroundColor(Color("TextPrimary"))
            
            TextField(
                placeholder,
                text: $text,
                axis: .vertical
            )
            .font(.body)
            .foregroundColor(Color("TextPrimary"))
            .lineLimit(minLines...maxLines)
            .submitLabel(.return)
            .onSubmit {
                hideKeyboard()
            }
            .padding(12)
            .background(Color("SurfaceCard"))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color("TextSecondary").opacity(0.2), lineWidth: 1)
            )
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1.0 : 0.6)
        }
    }
}

// MARK: - Preview

#Preview("Light Mode") {
            PromptInputField(
            text: .constant(""),
            placeholder: NSLocalizedString("model_detail.prompt_placeholder", comment: "Prompt placeholder")
        )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}

#Preview("With Text") {
            PromptInputField(
            text: .constant("A beautiful sunset over the ocean with dolphins jumping"),
            placeholder: NSLocalizedString("model_detail.prompt_placeholder", comment: "Prompt placeholder")
        )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.dark)
}

#Preview("Disabled") {
            PromptInputField(
            text: .constant("A beautiful sunset"),
            placeholder: NSLocalizedString("model_detail.prompt_placeholder", comment: "Prompt placeholder"),
            isEnabled: false
        )
    .padding()
    .background(Color("SurfaceBase"))
}
