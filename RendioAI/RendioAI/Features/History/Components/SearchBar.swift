//
//  SearchBar.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct SearchBar: View {
    @Binding var searchQuery: String
    let placeholder: String
    
    init(
        searchQuery: Binding<String>,
        placeholder: String = NSLocalizedString("history.search_placeholder", comment: "Search placeholder")
    ) {
        self._searchQuery = searchQuery
        self.placeholder = placeholder
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color("TextSecondary"))
                .font(.body)
                .accessibilityHidden(true)
            
            TextField(
                placeholder,
                text: $searchQuery
            )
            .font(.body)
            .foregroundColor(Color("TextPrimary"))
            .accessibilityLabel(NSLocalizedString("history.search_placeholder", comment: "Search placeholder"))
            .accessibilityHint(NSLocalizedString("history.accessibility.search_hint", comment: "Search your video history by prompt text"))
            
            if !searchQuery.isEmpty {
                Button(action: {
                    searchQuery = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color("TextSecondary"))
                        .font(.body)
                }
                .accessibilityLabel(NSLocalizedString("common.accessibility.clear_search", comment: "Clear search"))
                .accessibilityHint(NSLocalizedString("common.accessibility.clear_search_hint", comment: "Double tap to clear search text"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color("SurfaceCard"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        SearchBar(searchQuery: .constant(""))
        
        SearchBar(searchQuery: .constant("sunset"))
    }
    .padding()
    .background(Color("SurfaceBase"))
}
