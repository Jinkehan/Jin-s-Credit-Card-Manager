//
//  CreditCard.swift
//  Jin's Credit Card Manager
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
    var dueDate: Int // Day of the month (1-31)
    var colorHex: String
    
    init(id: String = UUID().uuidString, name: String, lastFourDigits: String, dueDate: Int, colorHex: String) {
        self.id = id
        self.name = name
        self.lastFourDigits = lastFourDigits
        self.dueDate = dueDate
        self.colorHex = colorHex
    }
    
    var color: Color {
        Color(hex: colorHex)
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

