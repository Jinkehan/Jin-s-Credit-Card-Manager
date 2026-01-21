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
        
        // If predefined card changed, update benefits and clear image cache
        if oldPredefinedCardId != predefinedCardId {
            // Clear the cached image for this card so the new card image will be fetched
            Task { @MainActor in
                ImageCacheService.shared.invalidateImage(for: card.id)
            }
            
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
        
        // Reset benefits that should be reset based on their reset period
        resetBenefitsIfNeeded()
        
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
        let todayStart = calendar.startOfDay(for: today)
        let currentYear = calendar.component(.year, from: today)
        let currentMonth = calendar.component(.month, from: today)
        
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
            // For monthly benefits, expiration is the last day of the current month
            guard let lastDayOfCurrentMonth = lastDayOfMonth(year: currentYear, month: currentMonth) else {
                return nil
            }
            
            // If the last day of current month has passed, get the last day of next month
            if calendar.startOfDay(for: lastDayOfCurrentMonth) < todayStart {
                // Move to next month
                let nextMonth = currentMonth == 12 ? 1 : currentMonth + 1
                let nextYear = currentMonth == 12 ? currentYear + 1 : currentYear
                return lastDayOfMonth(year: nextYear, month: nextMonth)
            }
            
            return lastDayOfCurrentMonth
            
        case "annual":
            // For annual benefits, expiration is December 31 of the current year
            guard let dec31ThisYear = calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31)) else {
                return nil
            }
            
            // If December 31 of this year has passed, return December 31 of next year
            if calendar.startOfDay(for: dec31ThisYear) < todayStart {
                return calendar.date(from: DateComponents(year: currentYear + 1, month: 12, day: 31))
            }
            
            return dec31ThisYear
            
        case "quarterly":
            // For quarterly benefits, expiration is the last day of the current quarter
            // Q1: January-March (expires March 31)
            // Q2: April-June (expires June 30)
            // Q3: July-September (expires September 30)
            // Q4: October-December (expires December 31)
            
            let currentQuarter = (currentMonth - 1) / 3 // 0-based: 0=Q1, 1=Q2, 2=Q3, 3=Q4
            let quarterEndMonth = (currentQuarter + 1) * 3 // Q1->3 (Mar), Q2->6 (Jun), Q3->9 (Sep), Q4->12 (Dec)
            
            guard let lastDayOfQuarter = lastDayOfMonth(year: currentYear, month: quarterEndMonth) else {
                return nil
            }
            
            // If the last day of current quarter has passed, get the last day of next quarter
            if calendar.startOfDay(for: lastDayOfQuarter) < todayStart {
                // Move to next quarter
                let nextQuarterEndMonth = quarterEndMonth + 3
                if nextQuarterEndMonth > 12 {
                    // Next quarter is in next year
                    return lastDayOfMonth(year: currentYear + 1, month: nextQuarterEndMonth - 12)
                } else {
                    return lastDayOfMonth(year: currentYear, month: nextQuarterEndMonth)
                }
            }
            
            return lastDayOfQuarter
            
        case "semi_annual":
            // For semi-annual benefits, expiration is June 30 or December 31
            // H1: January-June (expires June 30)
            // H2: July-December (expires December 31)
            
            if currentMonth <= 6 {
                // Currently in first half of year
                guard let june30 = calendar.date(from: DateComponents(year: currentYear, month: 6, day: 30)) else {
                    return nil
                }
                
                if calendar.startOfDay(for: june30) >= todayStart {
                    return june30
                }
                // June 30 has passed, return December 31
                return calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31))
            } else {
                // Currently in second half of year
                guard let dec31 = calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31)) else {
                    return nil
                }
                
                if calendar.startOfDay(for: dec31) >= todayStart {
                    return dec31
                }
                // December 31 has passed, return June 30 of next year
                return calendar.date(from: DateComponents(year: currentYear + 1, month: 6, day: 30))
            }
            
        case "one_time":
            // For one-time benefits, use the reminder date
            return benefit.reminderDate
            
        default:
            return nil
        }
    }
    
    // MARK: - Benefit Reset Logic
    
    /// Resets benefits that should be reset based on their reset period
    private func resetBenefitsIfNeeded() {
        guard let context = modelContext else { return }
        let today = Date()
        let calendar = Calendar.current
        var needsSave = false
        
        for card in cards {
            guard let benefits = card.benefits else { continue }
            
            for benefit in benefits {
                guard let lastUsedDate = benefit.lastUsedDate,
                      let resetPeriod = benefit.resetPeriod else { continue }
                
                var shouldReset = false
                
                switch resetPeriod {
                case "monthly":
                    // Reset if lastUsedDate is from a previous month
                    let lastUsedMonth = calendar.component(.month, from: lastUsedDate)
                    let lastUsedYear = calendar.component(.year, from: lastUsedDate)
                    let currentMonth = calendar.component(.month, from: today)
                    let currentYear = calendar.component(.year, from: today)
                    
                    shouldReset = (lastUsedYear < currentYear) || 
                                 (lastUsedYear == currentYear && lastUsedMonth < currentMonth)
                    
                case "annual":
                    // Reset if lastUsedDate is from a previous year
                    let lastUsedYear = calendar.component(.year, from: lastUsedDate)
                    let currentYear = calendar.component(.year, from: today)
                    shouldReset = lastUsedYear < currentYear
                    
                case "semi_annual":
                    // Reset if lastUsedDate is from a previous semi-annual period
                    // Check if it's been more than 6 months
                    if let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: today) {
                        shouldReset = lastUsedDate < sixMonthsAgo
                    }
                    
                case "quarterly":
                    // Reset if lastUsedDate is from a previous quarter
                    // Check if it's been more than 3 months
                    if let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: today) {
                        shouldReset = lastUsedDate < threeMonthsAgo
                    }
                    
                default:
                    break
                }
                
                if shouldReset {
                    benefit.lastUsedDate = nil
                    needsSave = true
                }
            }
        }
        
        if needsSave {
            try? context.save()
            loadData()
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
    
    /// Counts the number of unpaid card dues where the reminder date has arrived
    /// Simple logic: For each card, find next unpaid due date, calculate reminder date (due date - reminderDaysAhead)
    /// If today >= reminder date AND card is unpaid, count it
    func getUnpaidOverdueNotificationCount() -> Int {
        let today = Date()
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: today)
        var count = 0
        
        for card in cards {
            // Find the next unpaid due date for this card
            let currentMonth = calendar.component(.month, from: today)
            let currentYear = calendar.component(.year, from: today)
            
            // Check current month and up to 12 months forward
            for monthOffset in 0..<12 {
                let dueDate: Date
                
                if card.isLastDayOfMonth {
                    // Get the last day of the target month
                    guard let targetMonth = calendar.date(byAdding: .month, value: monthOffset, to: calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!),
                          let nextMonth = calendar.date(byAdding: .month, value: 1, to: targetMonth) else {
                        continue
                    }
                    dueDate = calendar.date(byAdding: .day, value: -1, to: nextMonth)!
                } else {
                    guard let targetDate = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: card.dueDate)),
                          let calculatedDueDate = calendar.date(byAdding: .month, value: monthOffset, to: targetDate) else {
                        continue
                    }
                    dueDate = calculatedDueDate
                }
                
                let dueDateStart = calendar.startOfDay(for: dueDate)
                
                // Check if this due date has already been paid
                let isPaid: Bool
                if let lastPaidDate = card.lastPaidDate {
                    let lastPaidDateStart = calendar.startOfDay(for: lastPaidDate)
                    isPaid = dueDateStart <= lastPaidDateStart
                } else {
                    isPaid = false
                }
                
                // If this due date hasn't been paid, this is our next unpaid due
                if !isPaid {
                    // Calculate the reminder date (due date - reminderDaysAhead)
                    guard let reminderDate = calendar.date(byAdding: .day, value: -card.reminderDaysAhead, to: dueDate) else {
                        break
                    }
                    
                    let reminderDateStart = calendar.startOfDay(for: reminderDate)
                    
                    // Check if today is on or after the reminder date
                    if todayStart >= reminderDateStart {
                        count += 1
                    }
                    
                    break // We found the next unpaid due for this card, move to next card
                }
            }
        }
        
        return count
    }
    
    /// Counts the number of benefits expiring within 5 days
    /// Simple logic: For each active unused benefit, calculate expiration date, check if it's within 5 days
    func getBenefitsExpiringWithin5DaysCount() -> Int {
        let today = Date()
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: today)
        var count = 0
        
        // Calculate the date that is 5 days from now
        guard let fiveDaysFromNow = calendar.date(byAdding: .day, value: 5, to: todayStart) else {
            return 0
        }
        
        for card in cards {
            guard let benefits = card.benefits else { continue }
            
            for benefit in benefits {
                // Only count active benefits that haven't been used
                guard benefit.isActive && benefit.lastUsedDate == nil else { continue }
                
                // Calculate next expiration date based on reminder type
                if let expirationDate = calculateNextExpirationDate(for: benefit, card: card) {
                    let expirationDateStart = calendar.startOfDay(for: expirationDate)
                    
                    // Count if expiration date is today or within the next 5 days
                    // (expirationDate >= today AND expirationDate <= today + 5 days)
                    if expirationDateStart >= todayStart && expirationDateStart <= fiveDaysFromNow {
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
    
    /// Syncs all existing cards with predefined card IDs to their updated predefined benefits
    func syncAllPredefinedCards() {
        guard let context = modelContext else { return }
        
        for card in cards {
            guard let predefinedCardId = card.predefinedCardId,
                  let predefinedCard = CardBenefitsService.shared.getPredefinedCard(byId: predefinedCardId) else {
                continue
            }
            
            LocalBenefitsStore.shared.syncBenefitsForPredefinedCard(
                card: card,
                predefinedCard: predefinedCard,
                context: context
            )
        }
        
        // Reload data to reflect changes
        loadData()
        
        // Reschedule benefit reminders for all cards
        Task {
            for card in cards {
                if let benefits = card.benefits {
                    for benefit in benefits where benefit.isActive {
                        await NotificationManager.shared.scheduleBenefitReminders(for: benefit)
                    }
                }
            }
        }
    }
}

// MARK: - Benefits Time Filter Enum
enum BenefitsTimeFilter: String, CaseIterable {
    case allTime = "All Time"
    case currentYear = "Current Year"
}

