//
//  SettingsView.swift
//  J Due
//
//  Created by Kehan Jin on 12/27/25.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                // Placeholder for future settings
                Section {
                    HStack {
                        Image(systemName: "bell.badge")
                            .foregroundColor(.gray)
                            .font(.title3)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notifications")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Text("Coming soon")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                    
                    HStack {
                        Image(systemName: "paintbrush")
                            .foregroundColor(.gray)
                            .font(.title3)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Appearance")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Text("Coming soon")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                } header: {
                    Text("Preferences")
                }
                
                // Card Database Section
                Section {
                    NavigationLink(destination: TestBenefitsView()) {
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
                
                // About Section
                Section {
                    VStack(alignment: .center, spacing: 8) {
                        Text("About")
                            .font(.callout)
                            .bold()
                            .foregroundColor(.secondary)
                        
                        Text("Never miss a credit card benefit again! J Due helps you track and maximize all your credit card perks, from annual travel credits to monthly dining bonuses. Set custom reminders for each benefit and stay on top of expiring credits before they reset.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("2025 Jin Kehan")
                            .font(.caption2)
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                    .padding(.vertical, 2)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}

