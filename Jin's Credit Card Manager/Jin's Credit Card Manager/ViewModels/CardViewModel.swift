//
//  CardViewModel.swift
//  Jin's Credit Card Manager
//
//  Created by Kehan Jin on 12/25/25.
//

import Foundation
import SwiftUI
import SwiftData

@Observable
class CardViewModel {
    var cards: [CreditCard] = []
    var settings: AppSettings?
    
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
        
        // Load or create settings
        let settingsDescriptor = FetchDescriptor<AppSettings>()
        let existingSettings = try? context.fetch(settingsDescriptor)
        
        if let first = existingSettings?.first {
            settings = first
        } else {
            let newSettings = AppSettings()
            context.insert(newSettings)
            settings = newSettings
            try? context.save()
        }
    }
    
    func addCard(name: String, lastFourDigits: String, dueDate: Int, colorHex: String) {
        guard let context = modelContext else { return }
        
        let newCard = CreditCard(
            name: name,
            lastFourDigits: lastFourDigits,
            dueDate: dueDate,
            colorHex: colorHex
        )
        
        context.insert(newCard)
        try? context.save()
        loadData()
    }
    
    func deleteCard(_ card: CreditCard) {
        guard let context = modelContext else { return }
        
        context.delete(card)
        try? context.save()
        loadData()
    }
    
    func updateReminderDaysAhead(_ days: Int) {
        guard let context = modelContext, let settings = settings else { return }
        
        settings.reminderDaysAhead = days
        try? context.save()
    }
    
    func getUpcomingReminders() -> [(card: CreditCard, dueDate: Date, daysUntilDue: Int)] {
        guard let settings = settings else { return [] }
        
        let today = Date()
        let calendar = Calendar.current
        var reminders: [(card: CreditCard, dueDate: Date, daysUntilDue: Int)] = []
        
        for card in cards {
            let currentMonth = calendar.component(.month, from: today)
            let currentYear = calendar.component(.year, from: today)
            
            // Check current month's due date
            var dueDate = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: card.dueDate))!
            var daysUntilDue = calendar.dateComponents([.day], from: calendar.startOfDay(for: today), to: calendar.startOfDay(for: dueDate)).day ?? 0
            
            // If due date has passed, check next month
            if daysUntilDue < 0 {
                dueDate = calendar.date(byAdding: .month, value: 1, to: dueDate)!
                daysUntilDue = calendar.dateComponents([.day], from: calendar.startOfDay(for: today), to: calendar.startOfDay(for: dueDate)).day ?? 0
            }
            
            // Only show if within reminder window
            if daysUntilDue >= 0 && daysUntilDue <= settings.reminderDaysAhead {
                reminders.append((card: card, dueDate: dueDate, daysUntilDue: daysUntilDue))
            }
        }
        
        // Sort by days until due
        return reminders.sorted { $0.daysUntilDue < $1.daysUntilDue }
    }
}

