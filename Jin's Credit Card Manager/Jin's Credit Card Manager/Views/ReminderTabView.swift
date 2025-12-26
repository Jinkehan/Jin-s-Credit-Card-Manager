//
//  ReminderTabView.swift
//  Jin's Credit Card Manager
//
//  Created by Kehan Jin on 12/25/25.
//

import SwiftUI

struct ReminderTabView: View {
    @Bindable var viewModel: CardViewModel
    
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
                    .frame(width: 48, height: 48)
                
                Text("••••")
                    .font(.system(size: 18))
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

