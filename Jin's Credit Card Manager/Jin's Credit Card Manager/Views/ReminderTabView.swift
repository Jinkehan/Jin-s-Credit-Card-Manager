//
//  ReminderTabView.swift
//  J Due
//
//  Created by Kehan Jin on 12/25/25.
//

import SwiftUI

struct ReminderTabView: View {
    @Bindable var viewModel: CardViewModel
    
    var body: some View {
        let reminders = viewModel.getUpcomingReminders()
        
        if reminders.isEmpty {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                        
                        Text("Payment Dues")
                            .font(.system(size: 34, weight: .bold))
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
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
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
        } else {
            List {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    
                    Text("Payment Dues")
                        .font(.system(size: 34, weight: .bold))
                }
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                // Reminders List
                ForEach(reminders, id: \.card.id) { reminder in
                    ReminderCardView(
                        card: reminder.card,
                        dueDate: reminder.dueDate,
                        daysUntilDue: reminder.daysUntilDue,
                        viewModel: viewModel
                    )
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct ReminderCardView: View {
    let card: CreditCard
    let dueDate: Date
    let daysUntilDue: Int
    let viewModel: CardViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Card image
            CardImageView(card: card)
            
            // Card info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(card.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    if !card.lastFourDigits.isEmpty {
                        Text(card.lastFourDigits)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(dueDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
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
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                viewModel.markCardAsPaid(card, forDueDate: dueDate)
            } label: {
                Label("Mark as Paid", systemImage: "checkmark.circle.fill")
            }
            .tint(.green)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func getDaysText(_ days: Int) -> String {
        if days == 0 { return "Today" }
        if days == 1 { return "1 day" }
        return "\(days) days"
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

