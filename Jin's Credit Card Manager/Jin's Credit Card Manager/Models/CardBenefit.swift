//
//  CardBenefit.swift
//  J Due
//
//  Created by Kehan Jin on 12/25/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class CardBenefit {
    var id: String = UUID().uuidString
    var cardId: String = "" // Links to CreditCard
    var benefitId: String? // If from predefined card, stores the predefined benefit ID
    var name: String = ""
    var benefitDescription: String = ""
    var category: String = "Other"
    var amount: Double?
    var currency: String = "USD"
    var benefitType: String = "other" // "credit", "membership", "bonus", etc.
    var reminderType: String = "monthly" // "monthly", "annual", "one_time", "quarterly", "semi_annual"
    var reminderDay: Int? // For monthly reminders (day of month)
    var reminderDate: Date? // For one-time reminders
    var reminderMessage: String = ""
    var isFromPredefined: Bool = false // True if synced from predefined card
    var isCustom: Bool = false // True if user created manually
    var isActive: Bool = true // User can disable benefits
    var lastUsedDate: Date? // For usage tracking
    var resetPeriod: String? // "monthly", "annual", "semi_annual", etc.
    var cardAnniversaryDate: Date? // For annual benefit calculations
    
    // Relationship - nullify (not cascade) to avoid circular cascade delete issues
    @Relationship(deleteRule: .nullify, inverse: \CreditCard.benefits) var card: CreditCard?
    
    init(
        id: String = UUID().uuidString,
        cardId: String,
        benefitId: String? = nil,
        name: String,
        benefitDescription: String,
        category: String,
        amount: Double? = nil,
        currency: String = "USD",
        benefitType: String,
        reminderType: String,
        reminderDay: Int? = nil,
        reminderDate: Date? = nil,
        reminderMessage: String,
        isFromPredefined: Bool = false,
        isCustom: Bool = false,
        isActive: Bool = true,
        lastUsedDate: Date? = nil,
        resetPeriod: String? = nil,
        cardAnniversaryDate: Date? = nil
    ) {
        self.id = id
        self.cardId = cardId
        self.benefitId = benefitId
        self.name = name
        self.benefitDescription = benefitDescription
        self.category = category
        self.amount = amount
        self.currency = currency
        self.benefitType = benefitType
        self.reminderType = reminderType
        self.reminderDay = reminderDay
        self.reminderDate = reminderDate
        self.reminderMessage = reminderMessage
        self.isFromPredefined = isFromPredefined
        self.isCustom = isCustom
        self.isActive = isActive
        self.lastUsedDate = lastUsedDate
        self.resetPeriod = resetPeriod
        self.cardAnniversaryDate = cardAnniversaryDate
    }
    
    var formattedAmount: String {
        guard let amount = amount, amount > 0 else {
            return "N/A"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
    
    var reminderDescription: String {
        switch reminderType {
        case "monthly":
            if let day = reminderDay {
                return "Reminds on the \(day)\(ordinalSuffix(day)) of each month"
            }
            return "Monthly reminder"
        case "annual":
            return "Annual reminder"
        case "quarterly":
            return "Quarterly reminder"
        case "semi_annual":
            return "Semi-annual reminder"
        case "one_time":
            if let date = reminderDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "One-time reminder on \(formatter.string(from: date))"
            }
            return "One-time reminder"
        default:
            return "Custom reminder"
        }
    }
    
    private func ordinalSuffix(_ day: Int) -> String {
        switch day {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }
}

