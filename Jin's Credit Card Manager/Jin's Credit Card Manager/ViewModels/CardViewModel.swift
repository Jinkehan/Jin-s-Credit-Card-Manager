//
//  CardViewModel.swift
//  J Due
//
//  Created by Kehan Jin on 12/25/25.
//

import Foundation
import SwiftUI
import SwiftData

@Observable
class CardViewModel {
    var cards: [CreditCard] = []
    
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadData()
    }
    
    func loadData() {
        guard let context = modelContext else { return }
        
        // Load cards
        let cardDescriptor = FetchDescriptor<CreditCard>()
        cards = (try? context.fetch(cardDescriptor)) ?? []
    }
    
    func addCard(name: String, lastFourDigits: String, dueDate: Int, colorHex: String, reminderDaysAhead: Int = 5) {
        guard let context = modelContext else { return }
        
        let newCard = CreditCard(
            name: name,
            lastFourDigits: lastFourDigits,
            dueDate: dueDate,
            colorHex: colorHex,
            reminderDaysAhead: reminderDaysAhead
        )
        
        context.insert(newCard)
        try? context.save()
        loadData()
        
        // Schedule notifications for the new card
        Task {
            await NotificationManager.shared.scheduleNotifications(for: newCard)
        }
    }
    
    func updateCard(_ card: CreditCard, name: String, lastFourDigits: String, dueDate: Int, colorHex: String, reminderDaysAhead: Int) {
        guard let context = modelContext else { return }
        
        card.name = name
        card.lastFourDigits = lastFourDigits
        card.dueDate = dueDate
        card.colorHex = colorHex
        card.reminderDaysAhead = reminderDaysAhead
        
        try? context.save()
        loadData()
        
        // Reschedule notifications for the updated card
        Task {
            await NotificationManager.shared.scheduleNotifications(for: card)
        }
    }
    
    func deleteCard(_ card: CreditCard) {
        guard let context = modelContext else { return }
        
        // Cancel notifications for the card before deleting
        Task {
            await NotificationManager.shared.cancelNotifications(for: card)
        }
        
        context.delete(card)
        try? context.save()
        loadData()
    }
    
    func getUpcomingReminders() -> [(card: CreditCard, dueDate: Date, daysUntilDue: Int)] {
        let today = Date()
        let calendar = Calendar.current
        var reminders: [(card: CreditCard, dueDate: Date, daysUntilDue: Int)] = []
        
        for card in cards {
            let currentMonth = calendar.component(.month, from: today)
            let currentYear = calendar.component(.year, from: today)
            
            // Check current month's due date
            var dueDate: Date
            if card.isLastDayOfMonth {
                // Get the last day of the current month
                let nextMonth = calendar.date(byAdding: .month, value: 1, to: calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!)!
                dueDate = calendar.date(byAdding: .day, value: -1, to: nextMonth)!
            } else {
                dueDate = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: card.dueDate))!
            }
            
            var daysUntilDue = calendar.dateComponents([.day], from: calendar.startOfDay(for: today), to: calendar.startOfDay(for: dueDate)).day ?? 0
            
            // If due date has passed, check next month
            if daysUntilDue < 0 {
                if card.isLastDayOfMonth {
                    // Get the last day of next month
                    let monthAfterNext = calendar.date(byAdding: .month, value: 2, to: calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!)!
                    dueDate = calendar.date(byAdding: .day, value: -1, to: monthAfterNext)!
                } else {
                    dueDate = calendar.date(byAdding: .month, value: 1, to: dueDate)!
                }
                daysUntilDue = calendar.dateComponents([.day], from: calendar.startOfDay(for: today), to: calendar.startOfDay(for: dueDate)).day ?? 0
            }
            
            // Only show if within reminder window (using per-card reminder setting)
            if daysUntilDue >= 0 && daysUntilDue <= card.reminderDaysAhead {
                reminders.append((card: card, dueDate: dueDate, daysUntilDue: daysUntilDue))
            }
        }
        
        // Sort by days until due
        return reminders.sorted { $0.daysUntilDue < $1.daysUntilDue }
    }
}

