//
//  SettingsTabView.swift
//  Jin's Credit Card Manager
//
//  Created by Kehan Jin on 12/25/25.
//

import SwiftUI

struct SettingsTabView: View {
    @Bindable var viewModel: CardViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    
                    Text("Settings")
                        .font(.system(size: 34, weight: .bold))
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Settings Content
                VStack(spacing: 16) {
                    // Reminder Window Setting
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reminder Window")
                                    .font(.system(size: 17, weight: .semibold))
                                
                                Text("Show payment reminders this many days before the due date")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Days ahead: \(viewModel.settings?.reminderDaysAhead ?? 7)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Slider(
                                value: Binding(
                                    get: { Double(viewModel.settings?.reminderDaysAhead ?? 7) },
                                    set: { viewModel.updateReminderDaysAhead(Int($0)) }
                                ),
                                in: 1...30,
                                step: 1
                            )
                            .accentColor(.blue)
                            
                            HStack {
                                Text("1 day")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text("30 days")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Info box
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            
                            Text("You'll see reminders for payments due within the next **\(viewModel.settings?.reminderDaysAhead ?? 7) days**.")
                                .font(.system(size: 14))
                                .foregroundColor(.blue.opacity(0.9))
                        }
                        .padding(16)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    // App Info
                    VStack(spacing: 8) {
                        Text("Card Manager v1.0")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        Text("All data is stored locally on your device")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
    }
}

