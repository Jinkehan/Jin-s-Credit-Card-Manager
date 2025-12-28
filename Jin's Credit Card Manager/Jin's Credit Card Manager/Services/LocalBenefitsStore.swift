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
        
        // Mark benefits as inactive if they're no longer in predefined (but don't delete custom ones)
        let benefitsToDeactivate = existingPredefinedIds.subtracting(newPredefinedIds)
        for benefit in existingBenefits {
            if let benefitId = benefit.benefitId, benefitsToDeactivate.contains(benefitId) {
                benefit.isActive = false
            }
        }
        
        try? context.save()
    }
}

