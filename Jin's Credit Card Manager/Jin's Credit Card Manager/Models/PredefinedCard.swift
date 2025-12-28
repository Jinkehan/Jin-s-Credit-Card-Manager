//
//  PredefinedCard.swift
//  J Due
//
//  Created by Kehan Jin on 12/25/25.
//

import Foundation

// MARK: - Root JSON Structure
struct CardBenefitsResponse: Codable {
    let schemaVersion: String
    let lastUpdated: String
    let predefinedCards: [PredefinedCard]
}

// MARK: - Predefined Card
struct PredefinedCard: Codable, Identifiable {
    let id: String
    let name: String
    let issuer: String
    let cardNetwork: String
    let category: String
    let defaultBenefits: [PredefinedBenefit]
}

// MARK: - Predefined Benefit
struct PredefinedBenefit: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let category: String
    let value: BenefitValue
    let reminder: BenefitReminder
    let usageTracking: BenefitUsageTracking?
}

// MARK: - Benefit Value
struct BenefitValue: Codable {
    let amount: Double?
    let currency: String
    let type: String // "credit", "membership", "bonus", etc.
    let frequency: String? // "monthly", "annual", "semi_annual", etc.
    let validityPeriod: String? // e.g., "4_years"
    let maxSpend: Double? // For bonus categories
    let maxReward: Double? // For bonus categories
    let specialMonths: [String: Double]? // Month-specific amounts (e.g., "12": 35 for December)
}

// MARK: - Benefit Reminder
struct BenefitReminder: Codable {
    let type: String // "monthly", "annual", "one_time", "quarterly", "semi_annual"
    let startDate: String? // "card_anniversary" or specific date
    let daysBefore: Int? // Days before to remind
    let dayOfMonth: Int? // For monthly reminders
    let date: String? // For one-time reminders (ISO 8601)
    let message: String
    let periods: [SemiAnnualPeriod]? // For semi-annual reminders
    let condition: String? // For conditional reminders
}

// MARK: - Semi-Annual Period
struct SemiAnnualPeriod: Codable {
    let startMonth: Int
    let endMonth: Int
}

// MARK: - Benefit Usage Tracking
struct BenefitUsageTracking: Codable {
    let enabled: Bool
    let resetPeriod: String // "monthly", "annual", "semi_annual", etc.
}

