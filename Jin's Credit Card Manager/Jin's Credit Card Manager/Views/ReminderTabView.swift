//
//  ReminderTabView.swift
//  J Due
//
//  Created by Kehan Jin on 12/25/25.
//

import SwiftUI

struct ReminderTabView: View {
    @Bindable var viewModel: CardViewModel
    @State private var showTestAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    
                    Text("Payment Reminders")
                        .font(.system(size: 34, weight: .bold))
                    
                    Spacer()
                    
                    // Test Notification Button (for development)
                    Button(action: {
                        showTestAlert = true
                    }) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.orange)
                            .padding(8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Reminders List
                let reminders = viewModel.getUpcomingReminders()
                
                if reminders.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar")
                            .font(.system(size: 64))
                            .foregroundColor(.gray.opacity(0.3))
                        
                        Text("No upcoming payments")
                            .font(.system(size: 17))
                            .foregroundColor(.gray)
                        
                        Text("Add credit cards to see payment reminders")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    VStack(spacing: 12) {
                        ForEach(reminders, id: \.card.id) { reminder in
                            ReminderCardView(
                                card: reminder.card,
                                dueDate: reminder.dueDate,
                                daysUntilDue: reminder.daysUntilDue
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .alert("Test Notification", isPresented: $showTestAlert) {
            Button("Cancel", role: .cancel) { }
            if let firstCard = viewModel.cards.first {
                Button("Send Test (10 sec)") {
                    Task {
                        await NotificationManager.shared.scheduleTestNotification(for: firstCard)
                    }
                }
            }
        } message: {
            if viewModel.cards.isEmpty {
                Text("Please add a card first to test notifications.")
            } else {
                Text("A test notification will appear in 10 seconds for your first card. Make sure notifications are enabled!")
            }
        }
    }
}

struct ReminderCardView: View {
    let card: CreditCard
    let dueDate: Date
    let daysUntilDue: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Card color indicator
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(card.color)
                    .frame(width: 64, height: 64)
                
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            
            // Card info
            VStack(alignment: .leading, spacing: 4) {
                Text(card.name)
                    .font(.system(size: 17, weight: .semibold))
                
                Text("•••• \(card.lastFourDigits)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text(formatDate(dueDate))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Days until due badge
            Text(getDaysText(daysUntilDue))
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(getBadgeColor(daysUntilDue))
                .foregroundColor(getTextColor(daysUntilDue))
                .cornerRadius(12)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func getDaysText(_ days: Int) -> String {
        if days == 0 { return "Due today" }
        if days == 1 { return "Due tomorrow" }
        return "Due in \(days) days"
    }
    
    private func getBadgeColor(_ days: Int) -> Color {
        if days == 0 { return Color.red.opacity(0.15) }
        if days <= 3 { return Color.orange.opacity(0.15) }
        return Color.blue.opacity(0.15)
    }
    
    private func getTextColor(_ days: Int) -> Color {
        if days == 0 { return Color.red }
        if days <= 3 { return Color.orange }
        return Color.blue
    }
}

