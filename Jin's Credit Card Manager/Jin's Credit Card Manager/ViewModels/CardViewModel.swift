//
//  CardViewModel.swift
//  J Due
//
//  Created by Kehan Jin on 12/25/25.
//

import Foundation
import SwiftUI
import SwiftData
import UserNotifications

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
        
        // Capture card ID for notification cancellation
        let cardId = card.id
        
        // Manually delete benefits first to avoid cascade delete issues
        if let benefits = card.benefits {
            for benefit in benefits {
                context.delete(benefit)
            }
        }
        
        // Delete the card itself
        context.delete(card)
        try? context.save()
        loadData()
        
        // Cancel notifications in the background AFTER card is deleted
        Task {
            let center = UNUserNotificationCenter.current()
            let pendingRequests = await center.pendingNotificationRequests()
            let identifiersToCancel = pendingRequests
                .filter { $0.identifier.starts(with: cardId) }
                .map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        }
    }
    
    func getUpcomingReminders() -> [(card: CreditCard, dueDate: Date, daysUntilDue: Int)] {
        let today = Date()
        let calendar = Calendar.current
        var reminders: [(card: CreditCard, dueDate: Date, daysUntilDue: Int)] = []
        
        for card in cards {
            let currentMonth = calendar.component(.month, from: today)
            let currentYear = calendar.component(.year, from: today)
            
            // Start checking from current month
            var monthOffset = 0
            var dueDate: Date
            
            // Find the next unpaid due date
            while monthOffset < 12 { // Safety limit to avoid infinite loop
                if card.isLastDayOfMonth {
                    // Get the last day of the target month
                    let targetMonth = calendar.date(byAdding: .month, value: monthOffset, to: calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!)!
                    let nextMonth = calendar.date(byAdding: .month, value: 1, to: targetMonth)!
                    dueDate = calendar.date(byAdding: .day, value: -1, to: nextMonth)!
                } else {
                    let targetDate = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: card.dueDate))!
                    dueDate = calendar.date(byAdding: .month, value: monthOffset, to: targetDate)!
                }
                
                // Check if this due date has already been paid
                if let lastPaidDate = card.lastPaidDate {
                    let dueDateStart = calendar.startOfDay(for: dueDate)
                    let lastPaidDateStart = calendar.startOfDay(for: lastPaidDate)
                    
                    // If this due date is on or before the last paid date, skip to next month
                    if dueDateStart <= lastPaidDateStart {
                        monthOffset += 1
                        continue
                    }
                }
                
                // Calculate days until due
                let daysUntilDue = calendar.dateComponents([.day], from: calendar.startOfDay(for: today), to: calendar.startOfDay(for: dueDate)).day ?? 0
                
                // Only show if the due date hasn't passed (or if it's today)
                if daysUntilDue >= 0 {
                    reminders.append((card: card, dueDate: dueDate, daysUntilDue: daysUntilDue))
                    break
                } else {
                    // Due date has passed, check next month
                    monthOffset += 1
                }
            }
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
        
        // Helper function to get the last day of a given month and year
        func lastDayOfMonth(year: Int, month: Int) -> Date? {
            guard let firstDayOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
                  let firstDayOfNextMonth = calendar.date(byAdding: .month, value: 1, to: firstDayOfMonth),
                  let lastDay = calendar.date(byAdding: .day, value: -1, to: firstDayOfNextMonth) else {
                return nil
            }
            return lastDay
        }
        
        switch benefit.reminderType {
        case "monthly":
            // For monthly benefits, expiration is the last day of the month
            let currentMonth = calendar.component(.month, from: today)
            let currentYear = calendar.component(.year, from: today)
            
            // Get the first day of the current month
            guard let firstDayOfMonth = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1)) else {
                return nil
            }
            
            // Get the last day of the current month by going to the first day of next month and subtracting 1 day
            guard let firstDayOfNextMonth = calendar.date(byAdding: .month, value: 1, to: firstDayOfMonth),
                  let lastDayOfCurrentMonth = calendar.date(byAdding: .day, value: -1, to: firstDayOfNextMonth) else {
                return nil
            }
            
            // If the last day of current month has passed, get the last day of next month
            if lastDayOfCurrentMonth < today {
                guard let firstDayOfNextMonth2 = calendar.date(byAdding: .month, value: 1, to: firstDayOfNextMonth),
                      let lastDayOfNextMonth = calendar.date(byAdding: .day, value: -1, to: firstDayOfNextMonth2) else {
                    return nil
                }
                return lastDayOfNextMonth
            }
            
            return lastDayOfCurrentMonth
            
        case "annual":
            // For annual benefits, expiration is the last day of the anniversary month
            guard let anniversaryDate = benefit.cardAnniversaryDate ?? card.cardAnniversaryDate else { return nil }
            
            let currentYear = calendar.component(.year, from: today)
            let anniversaryMonth = calendar.component(.month, from: anniversaryDate)
            
            // Get the last day of the anniversary month this year
            guard let expirationDate = lastDayOfMonth(year: currentYear, month: anniversaryMonth) else {
                return nil
            }
            
            // If the date has passed this year, get the last day of next year's anniversary month
            if expirationDate < today {
                return lastDayOfMonth(year: currentYear + 1, month: anniversaryMonth)
            }
            
            return expirationDate
            
        case "quarterly":
            // For quarterly benefits, expiration is the last day of each quarter month
            guard let anniversaryDate = benefit.cardAnniversaryDate ?? card.cardAnniversaryDate else { return nil }
            
            let currentYear = calendar.component(.year, from: today)
            
            // Calculate each quarter by adding 0, 3, 6, 9 months to anniversary date
            // Then get the last day of that month
            for quarterOffset in [0, 3, 6, 9] {
                guard let quarterDate = calendar.date(byAdding: .month, value: quarterOffset, to: anniversaryDate) else {
                    continue
                }
                
                let quarterYear = calendar.component(.year, from: quarterDate)
                let quarterMonth = calendar.component(.month, from: quarterDate)
                
                // Only check quarters in current or future years
                if quarterYear < currentYear {
                    continue
                }
                
                if let expirationDate = lastDayOfMonth(year: quarterYear, month: quarterMonth),
                   expirationDate >= today {
                    return expirationDate
                }
            }
            
            // If no date found, calculate first quarter of next cycle (12 months from anniversary)
            guard let nextCycleDate = calendar.date(byAdding: .year, value: 1, to: anniversaryDate) else {
                return nil
            }
            let nextCycleYear = calendar.component(.year, from: nextCycleDate)
            let nextCycleMonth = calendar.component(.month, from: nextCycleDate)
            return lastDayOfMonth(year: nextCycleYear, month: nextCycleMonth)
            
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
    
    func markCardAsPaid(_ card: CreditCard, forDueDate dueDate: Date) {
        guard let context = modelContext else { return }
        
        // Update the last paid date to the due date that was just paid
        card.lastPaidDate = dueDate
        try? context.save()
        loadData()
    }
    
    /// Counts the number of unpaid card dues where the notification date has passed
    /// The notification date is calculated as: dueDate - reminderDaysAhead
    /// Only counts one per card (the earliest unpaid due that has passed its notification date)
    func getUnpaidOverdueNotificationCount() -> Int {
        let today = Date()
        let calendar = Calendar.current
        var count = 0
        
        for card in cards {
            let currentMonth = calendar.component(.month, from: today)
            let currentYear = calendar.component(.year, from: today)
            
            // Check from current month backwards to find the earliest unpaid due date
            // We'll check up to 2 months back to catch any missed dues
            for monthOffset in -2..<12 { // Check 2 months back and 12 months forward
                let dueDate: Date
                
                if card.isLastDayOfMonth {
                    // Get the last day of the target month
                    guard let targetMonth = calendar.date(byAdding: .month, value: monthOffset, to: calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!) else {
                        continue
                    }
                    guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: targetMonth) else {
                        continue
                    }
                    dueDate = calendar.date(byAdding: .day, value: -1, to: nextMonth)!
                } else {
                    guard let targetDate = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: card.dueDate)) else {
                        continue
                    }
                    guard let calculatedDueDate = calendar.date(byAdding: .month, value: monthOffset, to: targetDate) else {
                        continue
                    }
                    dueDate = calculatedDueDate
                }
                
                // Check if this due date has already been paid
                var isPaid = false
                if let lastPaidDate = card.lastPaidDate {
                    let dueDateStart = calendar.startOfDay(for: dueDate)
                    let lastPaidDateStart = calendar.startOfDay(for: lastPaidDate)
                    
                    // If this due date is on or before the last paid date, it's been paid
                    if dueDateStart <= lastPaidDateStart {
                        isPaid = true
                        continue
                    }
                }
                
                // Calculate the notification date (dueDate - reminderDaysAhead)
                guard let notificationDate = calendar.date(byAdding: .day, value: -card.reminderDaysAhead, to: dueDate) else {
                    continue
                }
                
                let notificationDateStart = calendar.startOfDay(for: notificationDate)
                let todayStart = calendar.startOfDay(for: today)
                
                // If notification date has passed and the due date hasn't been paid, count it
                if notificationDateStart < todayStart && !isPaid {
                    count += 1
                    break // Only count one per card (the earliest unpaid overdue)
                }
                
                // If we're checking future months and notification date hasn't passed yet, we can stop
                // (we've already checked past months)
                if monthOffset >= 0 && notificationDateStart >= todayStart {
                    break
                }
            }
        }
        
        return count
    }
    
    /// Counts the number of benefits expiring within 5 days
    /// Only counts active benefits that haven't been used
    func getBenefitsExpiringWithin5DaysCount() -> Int {
        let today = Date()
        let calendar = Calendar.current
        var count = 0
        
        for card in cards {
            guard let benefits = card.benefits else { continue }
            
            for benefit in benefits {
                // Only count active benefits that haven't been used
                guard benefit.isActive && benefit.lastUsedDate == nil else { continue }
                
                // Calculate next expiration date based on reminder type
                if let expirationDate = calculateNextExpirationDate(for: benefit, card: card) {
                    let daysUntilExpiration = calendar.dateComponents([.day], from: calendar.startOfDay(for: today), to: calendar.startOfDay(for: expirationDate)).day ?? 0
                    
                    // Count benefits expiring within 5 days (0 to 5 days inclusive)
                    if daysUntilExpiration >= 0 && daysUntilExpiration <= 5 {
                        count += 1
                    }
                }
            }
        }
        
        return count
    }
    
    // MARK: - Benefits Earned Functions
    
    /// Gets all used benefits (where lastUsedDate is not nil)
    func getUsedBenefits() -> [(benefit: CardBenefit, card: CreditCard)] {
        var usedBenefits: [(benefit: CardBenefit, card: CreditCard)] = []
        
        for card in cards {
            guard let benefits = card.benefits else { continue }
            
            for benefit in benefits {
                if benefit.lastUsedDate != nil {
                    usedBenefits.append((benefit: benefit, card: card))
                }
            }
        }
        
        // Sort by lastUsedDate, most recent first
        return usedBenefits.sorted { benefit1, benefit2 in
            let date1 = benefit1.benefit.lastUsedDate ?? Date.distantPast
            let date2 = benefit2.benefit.lastUsedDate ?? Date.distantPast
            return date1 > date2
        }
    }
    
    /// Gets used benefits filtered by time period
    func getUsedBenefits(timeFilter: BenefitsTimeFilter) -> [(benefit: CardBenefit, card: CreditCard)] {
        let allUsed = getUsedBenefits()
        let calendar = Calendar.current
        let today = Date()
        
        switch timeFilter {
        case .allTime:
            return allUsed
        case .currentYear:
            let currentYear = calendar.component(.year, from: today)
            return allUsed.filter { benefitInfo in
                guard let lastUsedDate = benefitInfo.benefit.lastUsedDate else { return false }
                let benefitYear = calendar.component(.year, from: lastUsedDate)
                return benefitYear == currentYear
            }
        }
    }
    
    /// Gets used benefits filtered by card
    func getUsedBenefits(cardId: String?) -> [(benefit: CardBenefit, card: CreditCard)] {
        let allUsed = getUsedBenefits()
        
        guard let cardId = cardId else {
            return allUsed
        }
        
        return allUsed.filter { $0.card.id == cardId }
    }
    
    /// Gets used benefits with both time and card filters
    func getUsedBenefits(timeFilter: BenefitsTimeFilter, cardId: String?) -> [(benefit: CardBenefit, card: CreditCard)] {
        var filtered = getUsedBenefits(timeFilter: timeFilter)
        
        if let cardId = cardId {
            filtered = filtered.filter { $0.card.id == cardId }
        }
        
        return filtered
    }
    
    /// Calculates total savings from used benefits
    func calculateTotalSavings(from benefits: [(benefit: CardBenefit, card: CreditCard)]) -> Double {
        return benefits.reduce(0.0) { total, benefitInfo in
            let amount = benefitInfo.benefit.amount ?? 0.0
            return total + amount
        }
    }
    
    /// Gets all cards that have at least one used benefit
    func getCardsWithUsedBenefits() -> [CreditCard] {
        let usedBenefits = getUsedBenefits()
        let cardIds = Set(usedBenefits.map { $0.card.id })
        return cards.filter { cardIds.contains($0.id) }
    }
}

// MARK: - Benefits Time Filter Enum
enum BenefitsTimeFilter: String, CaseIterable {
    case allTime = "All Time"
    case currentYear = "Current Year"
}

