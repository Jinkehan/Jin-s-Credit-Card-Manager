//
//  SettingsView.swift
//  J Due
//
//  Created by Kehan Jin on 12/27/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Bindable var viewModel: CardViewModel
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @State private var cloudKitStatus = CloudKitStatusService.shared
    
    var body: some View {
        NavigationStack {
            List {
                // My Cards Section
                Section {
                    NavigationLink(destination: CardsTabView(viewModel: viewModel)) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("My Cards")
                                    .font(.body)
                                
                                Text("View and manage your credit cards")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if !viewModel.cards.isEmpty {
                                Text("\(viewModel.cards.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Cards")
                }
                
                // Placeholder for future settings
                Section {
                    HStack {
                        Image(systemName: "bell.badge")
                            .foregroundColor(notificationsEnabled ? .blue : .gray)
                            .font(.title3)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notifications")
                                .font(.body)
                            
                            Text(notificationsEnabled ? "Enabled" : "Disabled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $notificationsEnabled)
                            .onChange(of: notificationsEnabled) { oldValue, newValue in
                                handleNotificationToggleChanged(from: oldValue, to: newValue)
                            }
                    }
                    .padding(.vertical, 2)
                } header: {
                    Text("Preferences")
                }
                
                // Card Database Section
                Section {
                    NavigationLink(destination: AllCardsView()) {
                        HStack {
                            Image(systemName: "creditcard.and.123")
                                .foregroundColor(.blue)
                                .font(.title3)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("All Available Cards")
                                    .font(.body)
                                
                                Text("Browse all preset cards and their default benefits")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Card Database")
                }
                
                // iCloud Status Section (moved to bottom)
                Section {
                    HStack {
                        Image(systemName: cloudKitStatus.statusIcon)
                            .foregroundColor(cloudKitStatus.statusColor)
                            .font(.title3)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("iCloud Sync")
                                .font(.body)
                            
                            Text(cloudKitStatus.statusMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if cloudKitStatus.isCheckingStatus {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Button {
                                Task {
                                    await cloudKitStatus.checkAccountStatus()
                                }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                    
                    if !cloudKitStatus.isAvailable {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("To enable iCloud sync:")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            Text("1. Open Settings app\n2. Tap your name at the top\n3. Tap iCloud\n4. Enable iCloud Drive")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Sync")
                } footer: {
                    Text("When iCloud sync is enabled, your cards and reminders will automatically sync across all your devices signed in with the same Apple ID.")
                        .font(.caption)
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    // MARK: - Notification Toggle Handler
    
    private func handleNotificationToggleChanged(from oldValue: Bool, to newValue: Bool) {
        if newValue {
            // If enabling notifications, check and request authorization if needed
            Task {
                let isAuthorized = await NotificationManager.shared.checkAuthorizationStatus()
                if !isAuthorized {
                    _ = await NotificationManager.shared.requestAuthorization()
                }
            }
        } else {
            // If disabling notifications, cancel all pending notifications
            NotificationManager.shared.cancelAllNotifications()
        }
    }
}

#Preview {
    SettingsView(viewModel: CardViewModel())
        .modelContainer(for: [CreditCard.self], inMemory: true)
}

