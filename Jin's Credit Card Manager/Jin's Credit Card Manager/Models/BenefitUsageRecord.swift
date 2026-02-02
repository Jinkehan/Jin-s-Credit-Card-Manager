//
//  BenefitUsageRecord.swift
//  J Due
//
//  Persistent record of a benefit being used. Preserves history across
//  monthly/annual resets so "benefits earned" is never lost.
//

import Foundation
import SwiftData

@Model
final class BenefitUsageRecord {
    var id: String = UUID().uuidString
    var benefitId: String = ""   // CardBenefit.id
    var cardId: String = ""
    var usedDate: Date = Date()
    var amount: Double?
    var currency: String = "USD"
    var benefitName: String = ""

    init(
        id: String = UUID().uuidString,
        benefitId: String,
        cardId: String,
        usedDate: Date,
        amount: Double?,
        currency: String,
        benefitName: String
    ) {
        self.id = id
        self.benefitId = benefitId
        self.cardId = cardId
        self.usedDate = usedDate
        self.amount = amount
        self.currency = currency
        self.benefitName = benefitName
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
}
