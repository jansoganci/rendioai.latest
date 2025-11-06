//
//  ContentView.swift
//  RendioAI
//
//  Created by Can Soğancı on 4.11.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label(
                    "tab.home".localized,
                    systemImage: "house.fill"
                )
            }
            .tag(0)
            
            // History Tab
            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label(
                    "tab.history".localized,
                    systemImage: "clock.fill"
                )
            }
            .tag(1)
            
            // Profile Tab
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label(
                    "tab.profile".localized,
                    systemImage: "person.fill"
                )
            }
            .tag(2)
        }
        .tint(Color("BrandPrimary"))
        .id(localizationManager.currentLanguage) // Refresh when language changes
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}
