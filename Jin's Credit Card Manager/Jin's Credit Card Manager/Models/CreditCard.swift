//
//  CreditCard.swift
//  J Due
//
//  Created by Kehan Jin on 12/25/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class CreditCard {
    var id: String
    var name: String
    var lastFourDigits: String
    var dueDate: Int // Day of the month (1-31, or 0 for last day of month)
    var colorHex: String
    var cardType: String? // Optional: Specific card type (e.g., "Amex Gold", "Chase Sapphire Reserve") for benefits tracking
    var reminderDaysAhead: Int // Days before due date to show reminder
    var predefinedCardId: String? // If user selected a predefined card from JSON
    var cardAnniversaryDate: Date? // For annual benefit calculations
    
    // Relationship to benefits
    @Relationship(deleteRule: .cascade) var benefits: [CardBenefit]?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        lastFourDigits: String,
        dueDate: Int,
        colorHex: String,
        cardType: String? = nil,
        reminderDaysAhead: Int = 5,
        predefinedCardId: String? = nil,
        cardAnniversaryDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.lastFourDigits = lastFourDigits
        self.dueDate = dueDate
        self.colorHex = colorHex
        self.cardType = cardType
        self.reminderDaysAhead = reminderDaysAhead
        self.predefinedCardId = predefinedCardId
        self.cardAnniversaryDate = cardAnniversaryDate
    }
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    var isLastDayOfMonth: Bool {
        dueDate == 0
    }
    
    var dueDateDescription: String {
        if isLastDayOfMonth {
            return "last day"
        } else {
            return "\(dueDate)\(getOrdinalSuffix(dueDate))"
        }
    }
    
    private func getOrdinalSuffix(_ day: Int) -> String {
        switch day {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }
    
    var isPredefinedCard: Bool {
        predefinedCardId != nil
    }
    
    var hasCustomBenefits: Bool {
        benefits?.contains { $0.isCustom } ?? false
    }
    
    var activeBenefits: [CardBenefit] {
        benefits?.filter { $0.isActive } ?? []
    }
}

// Extension to convert hex string to Color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

