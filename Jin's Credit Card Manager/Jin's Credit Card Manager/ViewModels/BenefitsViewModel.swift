//
//  BenefitsViewModel.swift
//  J Due
//
//  Created by Kehan Jin on 12/25/25.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class BenefitsViewModel {
    var benefits: [CardBenefit] = []
    var card: CreditCard?
    
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func loadBenefits(for card: CreditCard) {
        self.card = card
        guard let context = modelContext else { return }
        
        // Use relationship-based fetch instead of predicate with captured variable
        // SwiftData predicates have limitations with external variable capture
        let descriptor = FetchDescriptor<CardBenefit>()
        let allBenefits = (try? context.fetch(descriptor)) ?? []
        benefits = allBenefits.filter { $0.cardId == card.id }
    }
    
    func addCustomBenefit(
        name: String,
        description: String,
        category: String,
        amount: Double?,
        currency: String,
        benefitType: String,
        reminderType: String,
        reminderDay: Int?,
        reminderDate: Date?,
        reminderMessage: String,
        resetPeriod: String?
    ) {
        guard let context = modelContext, let card = card else { return }
        
        let benefit = CardBenefit(
            cardId: card.id,
            name: name,
            benefitDescription: description,
            category: category,
            amount: amount,
            currency: currency,
            benefitType: benefitType,
            reminderType: reminderType,
            reminderDay: reminderDay,
            reminderDate: reminderDate,
            reminderMessage: reminderMessage,
            isFromPredefined: false,
            isCustom: true,
            resetPeriod: resetPeriod,
            cardAnniversaryDate: card.cardAnniversaryDate
        )
        
        benefit.card = card
        context.insert(benefit)
        try? context.save()
        loadBenefits(for: card)
        
        // Schedule notifications for the new benefit
        Task {
            await NotificationManager.shared.scheduleBenefitReminders(for: benefit)
        }
    }
    
    func updateBenefit(
        _ benefit: CardBenefit,
        name: String,
        description: String,
        category: String,
        amount: Double?,
        currency: String,
        benefitType: String,
        reminderType: String,
        reminderDay: Int?,
        reminderDate: Date?,
        reminderMessage: String,
        isActive: Bool,
        resetPeriod: String?
    ) {
        guard let context = modelContext else { return }
        
        benefit.name = name
        benefit.benefitDescription = description
        benefit.category = category
        benefit.amount = amount
        benefit.currency = currency
        benefit.benefitType = benefitType
        benefit.reminderType = reminderType
        benefit.reminderDay = reminderDay
        benefit.reminderDate = reminderDate
        benefit.reminderMessage = reminderMessage
        benefit.isActive = isActive
        benefit.resetPeriod = resetPeriod
        
        try? context.save()
        if let card = card {
            loadBenefits(for: card)
        }
        
        // Reschedule notifications
        Task {
            await NotificationManager.shared.cancelBenefitReminders(for: benefit)
            if benefit.isActive {
                await NotificationManager.shared.scheduleBenefitReminders(for: benefit)
            }
        }
    }
    
    func deleteBenefit(_ benefit: CardBenefit) {
        guard let context = modelContext else { return }
        
        // Cancel notifications
        Task {
            await NotificationManager.shared.cancelBenefitReminders(for: benefit)
        }
        
        context.delete(benefit)
        try? context.save()
        
        if let card = card {
            loadBenefits(for: card)
        }
    }
    
    func toggleBenefitActive(_ benefit: CardBenefit) {
        guard let context = modelContext else { return }
        
        benefit.isActive.toggle()
        try? context.save()
        
        if let card = card {
            loadBenefits(for: card)
        }
        
        // Update notifications
        Task {
            if benefit.isActive {
                await NotificationManager.shared.scheduleBenefitReminders(for: benefit)
            } else {
                await NotificationManager.shared.cancelBenefitReminders(for: benefit)
            }
        }
    }
    
    func markBenefitAsUsed(_ benefit: CardBenefit) {
        guard let context = modelContext else { return }
        let usedDate = Date()
        benefit.lastUsedDate = usedDate

        let record = BenefitUsageRecord(
            benefitId: benefit.id,
            cardId: benefit.cardId,
            usedDate: usedDate,
            amount: benefit.amount,
            currency: benefit.currency,
            benefitName: benefit.name
        )
        context.insert(record)
        try? context.save()

        if let card = card {
            loadBenefits(for: card)
        }
    }
}

