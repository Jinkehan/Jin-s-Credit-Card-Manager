//
//  AllCardsView.swift
//  J Due
//
//  Created by Kehan Jin on 12/27/25.
//

import SwiftUI

struct AllCardsView: View {
    @StateObject private var benefitsService = CardBenefitsService.shared
    @StateObject private var imageCache = ImageCacheService.shared
    @State private var searchText = ""
    
    var filteredCards: [PredefinedCard] {
        if searchText.isEmpty {
            return benefitsService.predefinedCards
        } else {
            return benefitsService.predefinedCards.filter { card in
                card.name.localizedCaseInsensitiveContains(searchText) ||
                card.issuer.localizedCaseInsensitiveContains(searchText) ||
                card.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if benefitsService.isLoading {
                    ProgressView("Loading card benefits...")
                } else {
                    VStack(spacing: 0) {
                        // Status Section
                        statusSection
                            .padding()
                        
                        // Cards List
                        if benefitsService.predefinedCards.isEmpty {
                            emptyStateView
                        } else if filteredCards.isEmpty {
                            noResultsView
                        } else {
                            ScrollView {
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16)
                                ], spacing: 16) {
                                    ForEach(filteredCards) { card in
                                        NavigationLink(destination: CardDetailView(card: card, imageCache: imageCache)) {
                                            CompactCardView(card: card, imageCache: imageCache)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
            .navigationTitle("All Available Cards")
            .searchable(text: $searchText, prompt: "Search cards...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await benefitsService.fetchCardBenefits(forceRefresh: true)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(benefitsService.isLoading)
                }
            }
            .onAppear {
                Task {
                    await benefitsService.fetchCardBenefits()
                }
            }
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("Data Source Status")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Total Cards:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(benefitsService.predefinedCards.count)")
                        .bold()
                }
                
                if let lastFetch = benefitsService.lastFetchDate {
                    HStack {
                        Text("Last Fetched:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatDate(lastFetch))
                            .font(.caption)
                    }
                }
                
                if let error = benefitsService.errorMessage {
                    HStack {
                        Text("Error:")
                            .foregroundColor(.red)
                        Spacer()
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .padding(.leading, 24)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - No Results View
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Cards Found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Try searching with a different term")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.trianglebadge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Card Data Available")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Tap the refresh button to fetch card benefits from GitHub")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                Task {
                    await benefitsService.fetchCardBenefits(forceRefresh: true)
                }
            }) {
                Label("Fetch Data", systemImage: "arrow.clockwise")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    // MARK: - Helper Functions
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Compact Card View

struct CompactCardView: View {
    let card: PredefinedCard
    @ObservedObject var imageCache: ImageCacheService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Card Image
            PredefinedCardImageView(
                cardId: card.id,
                imageUrl: card.imageUrl,
                imageCache: imageCache
            )
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Card Info
            VStack(alignment: .leading, spacing: 4) {
                Text(card.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(card.issuer)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "gift.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("\(card.defaultBenefits.count) benefits")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Card Detail View

struct CardDetailView: View {
    let card: PredefinedCard
    @ObservedObject var imageCache: ImageCacheService
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Card Image Header
                PredefinedCardImageView(
                    cardId: card.id,
                    imageUrl: card.imageUrl,
                    imageCache: imageCache,
                    contentMode: .fit
                )
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
                
                // Card Information
                VStack(alignment: .leading, spacing: 16) {
                    // Basic Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Card Information")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            CardInfoRow(label: "Card Name", value: card.name)
                            CardInfoRow(label: "Issuer", value: card.issuer)
                            CardInfoRow(label: "Network", value: card.cardNetwork)
                            CardInfoRow(label: "Category", value: card.category.replacingOccurrences(of: "_", with: " ").capitalized)
                            CardInfoRow(label: "Card ID", value: card.id)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Benefits Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Default Benefits")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(card.defaultBenefits.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        if card.defaultBenefits.isEmpty {
                            Text("No default benefits configured")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(card.defaultBenefits) { benefit in
                                AllCardsBenefitRowView(benefit: benefit)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - All Cards Benefit Row View

struct AllCardsBenefitRowView: View {
    let benefit: PredefinedBenefit
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Main benefit header - clickable to expand
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(benefit.name)
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.primary)
                        
                        Text(benefit.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(isExpanded ? nil : 2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        if let amount = benefit.value.amount, amount > 0 {
                            Text(formatAmount(amount, currency: benefit.value.currency))
                                .font(.caption)
                                .bold()
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
            }
            
            // Quick info badges
            HStack {
                Label(benefit.category, systemImage: "tag.fill")
                    .font(.caption2)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Label(benefit.value.type.capitalized, systemImage: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
                
                Label(benefit.reminder.type.capitalized, systemImage: "bell.fill")
                    .font(.caption2)
                    .foregroundColor(.purple)
            }
            
            // Expanded details section
            if isExpanded {
                Divider()
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Benefit Details")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.blue)
                    
                    // Benefit ID
                    BenefitDetailRow(label: "ID", value: benefit.id)
                    
                    // Category
                    BenefitDetailRow(label: "Category", value: benefit.category)
                    
                    // Value details
                    if let amount = benefit.value.amount {
                        BenefitDetailRow(label: "Amount", value: formatAmount(amount, currency: benefit.value.currency))
                    }
                    
                    BenefitDetailRow(label: "Currency", value: benefit.value.currency)
                    BenefitDetailRow(label: "Type", value: benefit.value.type)
                    
                    if let frequency = benefit.value.frequency {
                        BenefitDetailRow(label: "Frequency", value: frequency.replacingOccurrences(of: "_", with: " ").capitalized)
                    }
                    
                    if let validityPeriod = benefit.value.validityPeriod {
                        BenefitDetailRow(label: "Validity", value: validityPeriod.replacingOccurrences(of: "_", with: " "))
                    }
                    
                    if let maxSpend = benefit.value.maxSpend {
                        BenefitDetailRow(label: "Max Spend", value: formatAmount(maxSpend, currency: benefit.value.currency))
                    }
                    
                    if let maxReward = benefit.value.maxReward {
                        BenefitDetailRow(label: "Max Reward", value: formatAmount(maxReward, currency: benefit.value.currency))
                    }
                    
                    if let specialMonths = benefit.value.specialMonths, !specialMonths.isEmpty {
                        BenefitDetailRow(label: "Special Months", value: formatSpecialMonths(specialMonths))
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Reminder details
                    Text("Reminder Details")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.purple)
                    
                    BenefitDetailRow(label: "Type", value: benefit.reminder.type)
                    BenefitDetailRow(label: "Message", value: benefit.reminder.message)
                    
                    if let startDate = benefit.reminder.startDate {
                        BenefitDetailRow(label: "Start Date", value: startDate)
                    }
                    
                    if let daysBefore = benefit.reminder.daysBefore {
                        BenefitDetailRow(label: "Days Before", value: "\(daysBefore)")
                    }
                    
                    if let dayOfMonth = benefit.reminder.dayOfMonth {
                        BenefitDetailRow(label: "Day of Month", value: "\(dayOfMonth)")
                    }
                    
                    if let date = benefit.reminder.date {
                        BenefitDetailRow(label: "Date", value: date)
                    }
                    
                    if let periods = benefit.reminder.periods, !periods.isEmpty {
                        BenefitDetailRow(label: "Periods", value: formatPeriods(periods))
                    }
                    
                    // Usage tracking
                    if let tracking = benefit.usageTracking {
                        Divider()
                            .padding(.vertical, 4)
                        
                        Text("Usage Tracking")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.green)
                        
                        BenefitDetailRow(label: "Enabled", value: tracking.enabled ? "Yes" : "No")
                        BenefitDetailRow(label: "Reset Period", value: tracking.resetPeriod.replacingOccurrences(of: "_", with: " ").capitalized)
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func formatAmount(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
    
    private func formatSpecialMonths(_ months: [String: Double]) -> String {
        months.map { month, amount in
            let monthName = DateFormatter().monthSymbols[Int(month)! - 1]
            return "\(monthName): $\(Int(amount))"
        }.joined(separator: ", ")
    }
    
    private func formatPeriods(_ periods: [SemiAnnualPeriod]) -> String {
        periods.map { period in
            let startMonth = DateFormatter().monthSymbols[period.startMonth - 1]
            let endMonth = DateFormatter().monthSymbols[period.endMonth - 1]
            return "\(startMonth)-\(endMonth)"
        }.joined(separator: ", ")
    }
}

// MARK: - Benefit Detail Row View

struct BenefitDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label + ":")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)
            
            Text(value)
                .font(.caption2)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Card Info Row View

struct CardInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .bold()
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

#Preview {
    AllCardsView()
}

