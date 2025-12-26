//
//  MainTabView.swift
//  Jin's Credit Card Manager
//
//  Created by Kehan Jin on 12/25/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var viewModel = CardViewModel()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView {
            ReminderTabView(viewModel: viewModel)
                .tabItem {
                    Label("Reminders", systemImage: "bell.fill")
                }
            
            CardsTabView(viewModel: viewModel)
                .tabItem {
                    Label("Cards", systemImage: "creditcard.fill")
                }
            
            SettingsTabView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .accentColor(.blue)
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [CreditCard.self, AppSettings.self], inMemory: true)
}

