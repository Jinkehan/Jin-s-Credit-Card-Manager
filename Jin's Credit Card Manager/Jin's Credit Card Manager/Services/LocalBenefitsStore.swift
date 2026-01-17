//
//  LocalBenefitsStore.swift
//  J Due
//
//  Created by Kehan Jin on 12/25/25.
//

import Foundation
import SwiftData

class LocalBenefitsStore {
    static let shared = LocalBenefitsStore()
    
    private init() {}
    
    // MARK: - Convert Predefined Benefits to CardBenefits
    
    func createBenefitsFromPredefined(
        predefinedCard: PredefinedCard,
        for card: CreditCard,
        context: ModelContext
    ) {
        let cardId = card.id
        let cardAnniversary = card.cardAnniversaryDate ?? Date()
        
        for predefinedBenefit in predefinedCard.defaultBenefits {
            let benefit = convertPredefinedBenefitToCardBenefit(
                predefinedBenefit: predefinedBenefit,
                cardId: cardId,
                cardAnniversary: cardAnniversary
            )
            benefit.card = card
            context.insert(benefit)
        }
        
        try? context.save()
    }
    
    private func convertPredefinedBenefitToCardBenefit(
        predefinedBenefit: PredefinedBenefit,
        cardId: String,
        cardAnniversary: Date
    ) -> CardBenefit {
        let reminder = predefinedBenefit.reminder
        let value = predefinedBenefit.value
        
        // Calculate reminder date based on type
        var reminderDate: Date? = nil
        var reminderDay: Int? = nil
        
        switch reminder.type {
        case "monthly":
            reminderDay = reminder.dayOfMonth ?? 1
            
        case "annual":
            // Calculate date based on card anniversary
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: cardAnniversary)
            if let daysBefore = reminder.daysBefore {
                components.day = (components.day ?? 1) - daysBefore
            }
            reminderDate = calendar.date(from: components)
            
        case "one_time":
            if let dateString = reminder.date {
                let formatter = ISO8601DateFormatter()
                reminderDate = formatter.date(from: dateString)
            }
            
        case "quarterly":
            // First day of each quarter
            reminderDay = 1
            
        case "semi_annual":
            // First day of each semi-annual period
            reminderDay = 1
            
        default:
            break
        }
        
        return CardBenefit(
            cardId: cardId,
            benefitId: predefinedBenefit.id,
            name: predefinedBenefit.name,
            benefitDescription: predefinedBenefit.description,
            category: predefinedBenefit.category,
            amount: value.amount,
            currency: value.currency,
            benefitType: value.type,
            reminderType: reminder.type,
            reminderDay: reminderDay,
            reminderDate: reminderDate,
            reminderMessage: reminder.message,
            isFromPredefined: true,
            isCustom: false,
            isActive: true,
            resetPeriod: predefinedBenefit.usageTracking?.resetPeriod,
            cardAnniversaryDate: cardAnniversary
        )
    }
    
    // MARK: - Sync Benefits for Predefined Card
    
    func syncBenefitsForPredefinedCard(
        card: CreditCard,
        predefinedCard: PredefinedCard,
        context: ModelContext
    ) {
        guard let existingBenefits = card.benefits else { return }
        
        let cardId = card.id
        let cardAnniversary = card.cardAnniversaryDate ?? Date()
        
        // Get existing predefined benefit IDs
        let existingPredefinedIds = Set(existingBenefits
            .filter { $0.isFromPredefined && !$0.isCustom }
            .compactMap { $0.benefitId })
        
        // Get new predefined benefit IDs
        let newPredefinedIds = Set(predefinedCard.defaultBenefits.map { $0.id })
        
        // Find benefits to add (new in predefined, not in existing)
        let benefitsToAdd = newPredefinedIds.subtracting(existingPredefinedIds)
        for benefitId in benefitsToAdd {
            if let predefinedBenefit = predefinedCard.defaultBenefits.first(where: { $0.id == benefitId }) {
                let benefit = convertPredefinedBenefitToCardBenefit(
                    predefinedBenefit: predefinedBenefit,
                    cardId: cardId,
                    cardAnniversary: cardAnniversary
                )
                benefit.card = card
                context.insert(benefit)
            }
        }
        
        // Update existing benefits if their details changed (but preserve user modifications to custom fields)
        // CRITICAL: Only update benefits that haven't been used (no lastUsedDate) to preserve benefits earned history
        // Used benefits (with lastUsedDate) are NEVER modified - they remain as historical records
        let benefitsToUpdate = existingPredefinedIds.intersection(newPredefinedIds)
        for benefit in existingBenefits {
            // First check: Skip if benefit has been used - preserve history completely
            guard benefit.lastUsedDate == nil else {
                // This benefit was used - do NOT modify it in any way to preserve history
                continue
            }
            
            guard let benefitId = benefit.benefitId,
                  benefitsToUpdate.contains(benefitId),
                  let predefinedBenefit = predefinedCard.defaultBenefits.first(where: { $0.id == benefitId }),
                  benefit.isFromPredefined && !benefit.isCustom else {
                continue
            }
            
            // Update benefit details from predefined (only if it's a predefined benefit and hasn't been used)
            benefit.name = predefinedBenefit.name
            benefit.benefitDescription = predefinedBenefit.description
            benefit.category = predefinedBenefit.category
            benefit.amount = predefinedBenefit.value.amount
            benefit.currency = predefinedBenefit.value.currency
            benefit.benefitType = predefinedBenefit.value.type
            benefit.resetPeriod = predefinedBenefit.usageTracking?.resetPeriod
            
            // Update reminder information
            let reminder = predefinedBenefit.reminder
            benefit.reminderType = reminder.type
            benefit.reminderMessage = reminder.message
            
            // Recalculate reminder date/day based on type
            var reminderDate: Date? = nil
            var reminderDay: Int? = nil
            
            switch reminder.type {
            case "monthly":
                reminderDay = reminder.dayOfMonth ?? 1
            case "annual":
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day], from: cardAnniversary)
                if let daysBefore = reminder.daysBefore {
                    components.day = (components.day ?? 1) - daysBefore
                }
                reminderDate = calendar.date(from: components)
            case "one_time":
                if let dateString = reminder.date {
                    let formatter = ISO8601DateFormatter()
                    reminderDate = formatter.date(from: dateString)
                }
            case "quarterly":
                reminderDay = 1
            case "semi_annual":
                reminderDay = 1
            default:
                break
            }
            
            benefit.reminderDate = reminderDate
            benefit.reminderDay = reminderDay
        }
        
        // Mark benefits as inactive if they're no longer in predefined (but don't delete custom ones)
        // CRITICAL: Only deactivate unused benefits to preserve benefits earned history
        // Used benefits (with lastUsedDate) are NEVER deactivated - they remain as historical records
        let benefitsToDeactivate = existingPredefinedIds.subtracting(newPredefinedIds)
        for benefit in existingBenefits {
            // First check: Skip if benefit has been used - preserve history completely
            guard benefit.lastUsedDate == nil else {
                // This benefit was used - do NOT deactivate it to preserve history
                continue
            }
            
            if let benefitId = benefit.benefitId,
               benefitsToDeactivate.contains(benefitId) {
                benefit.isActive = false
            }
        }
        
        try? context.save()
    }
}

