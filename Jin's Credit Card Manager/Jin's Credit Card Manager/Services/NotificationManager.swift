//
//  NotificationManager.swift
//  J Due
//
//  Created by Kehan Jin on 12/25/25.
//

import Foundation
import UserNotifications
import Combine

@MainActor
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // You can handle notification tap here if needed
        // For example, navigate to a specific card
        let userInfo = response.notification.request.content.userInfo
        if let cardId = userInfo["cardId"] as? String {
            print("User tapped notification for card: \(cardId)")
            // You could post a notification to navigate to this card
        }
        if let benefitId = userInfo["benefitId"] as? String {
            print("User tapped notification for benefit: \(benefitId)")
            // You could post a notification to navigate to this benefit
        }
        completionHandler()
    }
    
    // Request notification permissions
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }
    
    // Check current authorization status
    func checkAuthorizationStatus() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let authorized = settings.authorizationStatus == .authorized
        await MainActor.run {
            self.isAuthorized = authorized
        }
        return authorized
    }
    
    // Schedule notifications for a credit card
    func scheduleNotifications(for card: CreditCard) async {
        // First check if we have permission
        let authorized = await checkAuthorizationStatus()
        guard authorized else {
            print("Notifications not authorized")
            return
        }
        
        // Cancel existing notifications for this card
        await cancelNotifications(for: card)
        
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate the reminder date (due date - reminderDaysAhead)
        // We'll schedule notifications for the next 12 months
        for monthOffset in 0..<12 {
            guard let targetMonth = calendar.date(byAdding: .month, value: monthOffset, to: today) else { continue }
            
            let year = calendar.component(.year, from: targetMonth)
            let month = calendar.component(.month, from: targetMonth)
            
            // Calculate the due date for this month
            var dueDate: Date
            if card.isLastDayOfMonth {
                // Get the last day of the month
                let nextMonth = calendar.date(byAdding: .month, value: 1, to: calendar.date(from: DateComponents(year: year, month: month, day: 1))!)!
                dueDate = calendar.date(byAdding: .day, value: -1, to: nextMonth)!
            } else {
                guard let calculatedDueDate = calendar.date(from: DateComponents(year: year, month: month, day: card.dueDate)) else { continue }
                dueDate = calculatedDueDate
            }
            
            // Calculate the reminder date (due date - reminderDaysAhead)
            guard let reminderDate = calendar.date(byAdding: .day, value: -card.reminderDaysAhead, to: dueDate) else { continue }
            
            // Skip if the reminder date is in the past
            if reminderDate < today {
                continue
            }
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "Credit Card Payment Due"
            content.body = "\(card.name) (•••• \(card.lastFourDigits)) payment is due in \(card.reminderDaysAhead) day\(card.reminderDaysAhead == 1 ? "" : "s")"
            content.sound = .default
            content.categoryIdentifier = "CARD_REMINDER"
            content.userInfo = ["cardId": card.id]
            
            // Set up the trigger for 8 AM on the reminder date
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: reminderDate)
            dateComponents.hour = 8
            dateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            // Create unique identifier for this notification
            let identifier = "\(card.id)_\(year)_\(month)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            // Schedule the notification
            do {
                try await UNUserNotificationCenter.current().add(request)
                print("Scheduled notification for \(card.name) on \(reminderDate) at 8 AM")
            } catch {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    // Cancel all notifications for a specific card
    func cancelNotifications(for card: CreditCard) async {
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()
        
        // Find all notification identifiers that start with the card's ID
        let identifiersToCancel = pendingRequests
            .filter { $0.identifier.starts(with: card.id) }
            .map { $0.identifier }
        
        center.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        print("Cancelled \(identifiersToCancel.count) notifications for card: \(card.name)")
    }
    
    // Reschedule all notifications for all cards
    func rescheduleAllNotifications(for cards: [CreditCard]) async {
        for card in cards {
            await scheduleNotifications(for: card)
        }
    }
    
    // Cancel all notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("Cancelled all pending notifications")
    }
    
    // Get pending notifications count
    func getPendingNotificationsCount() async -> Int {
        let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return pendingRequests.count
    }
    
    // MARK: - Benefit Reminders
    
    // Schedule notifications for a card benefit
    func scheduleBenefitReminders(for benefit: CardBenefit) async {
        guard benefit.isActive else { return }
        
        let authorized = await checkAuthorizationStatus()
        guard authorized else {
            print("Notifications not authorized")
            return
        }
        
        // Cancel existing notifications for this benefit
        await cancelBenefitReminders(for: benefit)
        
        let calendar = Calendar.current
        let today = Date()
        
        switch benefit.reminderType {
        case "monthly":
            scheduleMonthlyBenefitReminders(for: benefit, calendar: calendar, today: today)
            
        case "annual":
            scheduleAnnualBenefitReminders(for: benefit, calendar: calendar, today: today)
            
        case "quarterly":
            scheduleQuarterlyBenefitReminders(for: benefit, calendar: calendar, today: today)
            
        case "semi_annual":
            scheduleSemiAnnualBenefitReminders(for: benefit, calendar: calendar, today: today)
            
        case "one_time":
            scheduleOneTimeBenefitReminder(for: benefit, calendar: calendar, today: today)
            
        default:
            print("Unknown reminder type: \(benefit.reminderType)")
        }
    }
    
    private func scheduleMonthlyBenefitReminders(for benefit: CardBenefit, calendar: Calendar, today: Date) {
        let reminderDay = benefit.reminderDay ?? 1
        
        // Schedule for next 12 months
        for monthOffset in 0..<12 {
            guard let targetMonth = calendar.date(byAdding: .month, value: monthOffset, to: today) else { continue }
            
            let year = calendar.component(.year, from: targetMonth)
            let month = calendar.component(.month, from: targetMonth)
            
            // Calculate the reminder date
            guard let reminderDate = calendar.date(from: DateComponents(year: year, month: month, day: reminderDay)) else { continue }
            
            // Skip if in the past
            if reminderDate < today {
                continue
            }
            
            scheduleBenefitNotification(for: benefit, on: reminderDate, identifier: "benefit_\(benefit.id)_\(year)_\(month)")
        }
    }
    
    private func scheduleAnnualBenefitReminders(for benefit: CardBenefit, calendar: Calendar, today: Date) {
        guard let cardAnniversary = benefit.cardAnniversaryDate ?? benefit.card?.cardAnniversaryDate else {
            print("No card anniversary date for annual benefit")
            return
        }
        
        let daysBefore = 30 // Default to 30 days before
        
        // Schedule for next 3 years
        for yearOffset in 0..<3 {
            guard let targetYear = calendar.date(byAdding: .year, value: yearOffset, to: cardAnniversary) else { continue }
            
            var components = calendar.dateComponents([.year, .month, .day], from: targetYear)
            components.day = (components.day ?? 1) - daysBefore
            
            guard let reminderDate = calendar.date(from: components), reminderDate >= today else { continue }
            
            let year = calendar.component(.year, from: targetYear)
            scheduleBenefitNotification(for: benefit, on: reminderDate, identifier: "benefit_\(benefit.id)_annual_\(year)")
        }
    }
    
    private func scheduleQuarterlyBenefitReminders(for benefit: CardBenefit, calendar: Calendar, today: Date) {
        let currentQuarter = (calendar.component(.month, from: today) - 1) / 3
        
        // Schedule for next 4 quarters
        for quarterOffset in 0..<4 {
            let targetQuarter = (currentQuarter + quarterOffset) % 4
            let targetMonth = targetQuarter * 3 + 1
            let targetYear = calendar.component(.year, from: today) + (currentQuarter + quarterOffset) / 4
            
            guard let reminderDate = calendar.date(from: DateComponents(year: targetYear, month: targetMonth, day: 1)),
                  reminderDate >= today else { continue }
            
            scheduleBenefitNotification(for: benefit, on: reminderDate, identifier: "benefit_\(benefit.id)_Q\(targetQuarter + 1)_\(targetYear)")
        }
    }
    
    private func scheduleSemiAnnualBenefitReminders(for benefit: CardBenefit, calendar: Calendar, today: Date) {
        let currentMonth = calendar.component(.month, from: today)
        let periods = [(1, 6), (7, 12)] // Jan-Jun, Jul-Dec
        
        for periodOffset in 0..<2 {
            let period = periods[(currentMonth <= 6 ? 0 : 1 + periodOffset) % 2]
            let targetYear = calendar.component(.year, from: today) + (currentMonth > 6 && periodOffset > 0 ? 1 : 0)
            
            guard let reminderDate = calendar.date(from: DateComponents(year: targetYear, month: period.0, day: 1)),
                  reminderDate >= today else { continue }
            
            scheduleBenefitNotification(for: benefit, on: reminderDate, identifier: "benefit_\(benefit.id)_\(period.0)_\(targetYear)")
        }
    }
    
    private func scheduleOneTimeBenefitReminder(for benefit: CardBenefit, calendar: Calendar, today: Date) {
        guard let reminderDate = benefit.reminderDate, reminderDate >= today else { return }
        
        scheduleBenefitNotification(for: benefit, on: reminderDate, identifier: "benefit_\(benefit.id)_onetime")
    }
    
    private func scheduleBenefitNotification(for benefit: CardBenefit, on date: Date, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "Card Benefit Reminder"
        content.body = benefit.reminderMessage.isEmpty ? "Don't forget to use your \(benefit.name)!" : benefit.reminderMessage
        content.sound = .default
        content.categoryIdentifier = "BENEFIT_REMINDER"
        content.userInfo = [
            "benefitId": benefit.id,
            "cardId": benefit.cardId
        ]
        
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = 9 // 9 AM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        Task {
            do {
                try await UNUserNotificationCenter.current().add(request)
                print("Scheduled benefit reminder for \(benefit.name) on \(date)")
            } catch {
                print("Error scheduling benefit reminder: \(error)")
            }
        }
    }
    
    // Cancel all notifications for a specific benefit
    func cancelBenefitReminders(for benefit: CardBenefit) async {
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()
        
        // Find all notification identifiers that start with the benefit's ID
        let identifiersToCancel = pendingRequests
            .filter { $0.identifier.contains("benefit_\(benefit.id)") }
            .map { $0.identifier }
        
        center.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        print("Cancelled \(identifiersToCancel.count) benefit reminders for: \(benefit.name)")
    }
    
    // MARK: - Testing Helper
    
    /// Test function to schedule a notification in 10 seconds for immediate preview
    /// Use this for testing only - remove or comment out in production
    func scheduleTestNotification(for card: CreditCard) async {
        let authorized = await checkAuthorizationStatus()
        guard authorized else {
            print("Notifications not authorized")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Credit Card Payment Due"
        content.body = "\(card.name) (•••• \(card.lastFourDigits)) payment is due in \(card.reminderDaysAhead) day\(card.reminderDaysAhead == 1 ? "" : "s")"
        content.sound = .default
        content.categoryIdentifier = "CARD_REMINDER"
        content.userInfo = ["cardId": card.id]
        
        // Trigger in 10 seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        
        let identifier = "test_\(card.id)_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Test notification scheduled! Will appear in 10 seconds.")
        } catch {
            print("❌ Error scheduling test notification: \(error)")
        }
    }
}

