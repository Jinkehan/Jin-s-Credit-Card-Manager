//
//  MainTabView.swift
//  J Due
//
//  Created by Kehan Jin on 12/25/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var viewModel = CardViewModel()
    @Environment(\.modelContext) private var modelContext
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        let unpaidCount = viewModel.getUnpaidOverdueNotificationCount()
        let benefitsExpiringCount = viewModel.getBenefitsExpiringWithin5DaysCount()
        
        TabView {
            reminderTabView(unpaidCount: unpaidCount)
            
            benefitsTabView(expiringCount: benefitsExpiringCount)
            
            RewardsTabView(viewModel: viewModel)
                .tabItem {
                    Label("Rewards", systemImage: "sparkles.rectangle.stack.fill")
                }
            
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .accentColor(.blue)
        .onAppear {
            viewModel.setModelContext(modelContext)
            
            // Schedule notifications for all existing cards when app launches
            Task {
                // Wait a bit to ensure authorization is complete
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                if notificationManager.isAuthorized {
                    await NotificationManager.shared.rescheduleAllNotifications(for: viewModel.cards)
                }
            }
        }
    }
    
    @ViewBuilder
    private func reminderTabView(unpaidCount: Int) -> some View {
        if unpaidCount > 0 {
            ReminderTabView(viewModel: viewModel)
                .tabItem {
                    Label("Dues", systemImage: "calendar.badge.clock")
                }
                .badge(unpaidCount)
        } else {
            ReminderTabView(viewModel: viewModel)
                .tabItem {
                    Label("Dues", systemImage: "calendar.badge.clock")
                }
        }
    }
    
    @ViewBuilder
    private func benefitsTabView(expiringCount: Int) -> some View {
        if expiringCount > 0 {
            BenefitsTabView(viewModel: viewModel)
                .tabItem {
                    Label("Benefits", systemImage: "gift.fill")
                }
                .badge(expiringCount)
        } else {
            BenefitsTabView(viewModel: viewModel)
                .tabItem {
                    Label("Benefits", systemImage: "gift.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [CreditCard.self], inMemory: true)
}

