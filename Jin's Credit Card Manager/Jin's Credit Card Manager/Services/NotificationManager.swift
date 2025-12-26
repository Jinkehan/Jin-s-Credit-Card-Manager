//
//  NotificationManager.swift
//  J Due
//
//  Created by Kehan Jin on 12/25/25.
//

import Foundation
import UserNotifications
import SwiftUI
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

