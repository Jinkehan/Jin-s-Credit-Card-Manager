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
    
    func addCard(
        name: String,
        lastFourDigits: String,
        dueDate: Int,
        reminderDaysAhead: Int = 5,
        predefinedCardId: String? = nil,
        cardAnniversaryDate: Date? = nil
    ) {
        guard let context = modelContext else { return }
        
        let newCard = CreditCard(
            name: name,
            lastFourDigits: lastFourDigits,
            dueDate: dueDate,
            reminderDaysAhead: reminderDaysAhead,
            predefinedCardId: predefinedCardId,
            cardAnniversaryDate: cardAnniversaryDate ?? Date()
        )
        
        context.insert(newCard)
        try? context.save()
        loadData()
        
        // If predefined card, create benefits
        if let predefinedCardId = predefinedCardId,
           let predefinedCard = CardBenefitsService.shared.getPredefinedCard(byId: predefinedCardId) {
            LocalBenefitsStore.shared.createBenefitsFromPredefined(
                predefinedCard: predefinedCard,
                for: newCard,
                context: context
            )
        }
        
        // Schedule notifications for the new card
        Task {
            await NotificationManager.shared.scheduleNotifications(for: newCard)
            
            // Schedule benefit reminders
            if let benefits = newCard.benefits {
                for benefit in benefits where benefit.isActive {
                    await NotificationManager.shared.scheduleBenefitReminders(for: benefit)
                }
            }
        }
    }
    
    func updateCard(_ card: CreditCard, name: String, lastFourDigits: String, dueDate: Int, reminderDaysAhead: Int, predefinedCardId: String? = nil) {
        guard let context = modelContext else { return }
        
        let oldPredefinedCardId = card.predefinedCardId
        
        card.name = name
        card.lastFourDigits = lastFourDigits
        card.dueDate = dueDate
        card.reminderDaysAhead = reminderDaysAhead
        card.predefinedCardId = predefinedCardId
        
        try? context.save()
        loadData()
        
        // If predefined card changed, update benefits
        if oldPredefinedCardId != predefinedCardId {
            if let predefinedCardId = predefinedCardId,
               let predefinedCard = CardBenefitsService.shared.getPredefinedCard(byId: predefinedCardId) {
                LocalBenefitsStore.shared.createBenefitsFromPredefined(
                    predefinedCard: predefinedCard,
                    for: card,
                    context: context
                )
            }
        }
        
        // Reschedule notifications for the updated card
        Task {
            await NotificationManager.shared.scheduleNotifications(for: card)
            
            // Reschedule benefit reminders
            if let benefits = card.benefits {
                for benefit in benefits where benefit.isActive {
                    await NotificationManager.shared.scheduleBenefitReminders(for: benefit)
                }
            }
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
            
            // Always show the next due date for all cards in the Reminders tab
            // The reminderDaysAhead setting is only used for notification scheduling
            reminders.append((card: card, dueDate: dueDate, daysUntilDue: daysUntilDue))
        }
        
        // Sort by days until due (earliest to latest)
        return reminders.sorted { $0.daysUntilDue < $1.daysUntilDue }
    }
    
    func getUpcomingBenefits() -> [(benefit: CardBenefit, card: CreditCard, expirationDate: Date, daysUntilExpiration: Int)] {
        let today = Date()
        let calendar = Calendar.current
        var upcomingBenefits: [(benefit: CardBenefit, card: CreditCard, expirationDate: Date, daysUntilExpiration: Int)] = []
        
        for card in cards {
            guard let benefits = card.benefits else { continue }
            
            for benefit in benefits {
                // Only show active benefits that haven't been used
                guard benefit.isActive && benefit.lastUsedDate == nil else { continue }
                
                // Calculate next expiration date based on reminder type
                if let expirationDate = calculateNextExpirationDate(for: benefit, card: card) {
                    let daysUntilExpiration = calendar.dateComponents([.day], from: calendar.startOfDay(for: today), to: calendar.startOfDay(for: expirationDate)).day ?? 0
                    
                    // Only show benefits that haven't expired yet
                    if daysUntilExpiration >= 0 {
                        upcomingBenefits.append((benefit: benefit, card: card, expirationDate: expirationDate, daysUntilExpiration: daysUntilExpiration))
                    }
                }
            }
        }
        
        // Sort by days until expiration (earliest to latest)
        return upcomingBenefits.sorted { $0.daysUntilExpiration < $1.daysUntilExpiration }
    }
    
    private func calculateNextExpirationDate(for benefit: CardBenefit, card: CreditCard) -> Date? {
        let calendar = Calendar.current
        let today = Date()
        
        switch benefit.reminderType {
        case "monthly":
            // For monthly benefits, calculate next occurrence based on reminderDay
            guard let reminderDay = benefit.reminderDay else { return nil }
            
            let currentMonth = calendar.component(.month, from: today)
            let currentYear = calendar.component(.year, from: today)
            
            var expirationDate = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: reminderDay))!
            
            // If the date has passed this month, move to next month
            if expirationDate < today {
                expirationDate = calendar.date(byAdding: .month, value: 1, to: expirationDate)!
            }
            
            return expirationDate
            
        case "annual":
            // For annual benefits, use card anniversary date
            guard let anniversaryDate = benefit.cardAnniversaryDate ?? card.cardAnniversaryDate else { return nil }
            
            let currentYear = calendar.component(.year, from: today)
            let anniversaryMonth = calendar.component(.month, from: anniversaryDate)
            let anniversaryDay = calendar.component(.day, from: anniversaryDate)
            
            var expirationDate = calendar.date(from: DateComponents(year: currentYear, month: anniversaryMonth, day: anniversaryDay))!
            
            // If the date has passed this year, move to next year
            if expirationDate < today {
                expirationDate = calendar.date(byAdding: .year, value: 1, to: expirationDate)!
            }
            
            return expirationDate
            
        case "quarterly":
            // For quarterly benefits, calculate based on card anniversary
            guard let anniversaryDate = benefit.cardAnniversaryDate ?? card.cardAnniversaryDate else { return nil }
            
            let anniversaryMonth = calendar.component(.month, from: anniversaryDate)
            let anniversaryDay = calendar.component(.day, from: anniversaryDate)
            let currentYear = calendar.component(.year, from: today)
            
            // Calculate all quarterly dates for current year
            let quarterMonths = [anniversaryMonth, (anniversaryMonth + 3) % 12, (anniversaryMonth + 6) % 12, (anniversaryMonth + 9) % 12]
            
            for month in quarterMonths {
                if let date = calendar.date(from: DateComponents(year: currentYear, month: month == 0 ? 12 : month, day: anniversaryDay)),
                   date >= today {
                    return date
                }
            }
            
            // If no date found this year, return first quarter of next year
            return calendar.date(from: DateComponents(year: currentYear + 1, month: anniversaryMonth, day: anniversaryDay))
            
        case "semi_annual":
            // For semi-annual benefits
            guard let anniversaryDate = benefit.cardAnniversaryDate ?? card.cardAnniversaryDate else { return nil }
            
            let anniversaryMonth = calendar.component(.month, from: anniversaryDate)
            let anniversaryDay = calendar.component(.day, from: anniversaryDate)
            let currentYear = calendar.component(.year, from: today)
            
            // Calculate both semi-annual dates
            let firstDate = calendar.date(from: DateComponents(year: currentYear, month: anniversaryMonth, day: anniversaryDay))!
            let secondDate = calendar.date(byAdding: .month, value: 6, to: firstDate)!
            
            if firstDate >= today {
                return firstDate
            } else if secondDate >= today {
                return secondDate
            } else {
                // Move to next year
                return calendar.date(byAdding: .year, value: 1, to: firstDate)
            }
            
        case "one_time":
            // For one-time benefits, use the reminder date
            return benefit.reminderDate
            
        default:
            return nil
        }
    }
    
    func markBenefitAsUsed(_ benefit: CardBenefit) {
        guard let context = modelContext else { return }
        benefit.lastUsedDate = Date()
        try? context.save()
        loadData()
    }
}

