//
//  BenefitsTabView.swift
//  J Due
//
//  Created by Kehan Jin on 12/28/25.
//

import SwiftUI

struct BenefitsTabView: View {
    @Bindable var viewModel: CardViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack(spacing: 12) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                        
                        Text("Card Benefits")
                            .font(.system(size: 34, weight: .bold))
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Benefits Earned Summary Section
                    NavigationLink(destination: BenefitsEarnedDetailView(viewModel: viewModel)) {
                        BenefitsEarnedSummaryCard(
                            totalSavings: calculateTotalSavingsAllTime()
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    
                    // Benefits List
                    let benefits = viewModel.getUpcomingBenefits()
                    
                    if benefits.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "gift")
                                .font(.system(size: 64))
                                .foregroundColor(.gray.opacity(0.3))
                            
                            Text("No unused benefits")
                                .font(.system(size: 17))
                                .foregroundColor(.gray)
                            
                            Text("Add credit cards with benefits to see them here")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(benefits, id: \.benefit.id) { benefitInfo in
                                BenefitCardView(
                                    benefit: benefitInfo.benefit,
                                    card: benefitInfo.card,
                                    expirationDate: benefitInfo.expirationDate,
                                    daysUntilExpiration: benefitInfo.daysUntilExpiration,
                                    viewModel: viewModel
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private func calculateTotalSavingsAllTime() -> Double {
        let usedBenefits = viewModel.getUsedBenefits()
        return viewModel.calculateTotalSavings(from: usedBenefits)
    }
}

// MARK: - Benefits Earned Summary Card
struct BenefitsEarnedSummaryCard: View {
    let totalSavings: Double
    
    private var formattedSavings: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalSavings)) ?? "$0.00"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.green)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Benefits Earned")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(formattedSavings)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("All Time")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct BenefitCardView: View {
    let benefit: CardBenefit
    let card: CreditCard
    let expirationDate: Date
    let daysUntilExpiration: Int
    @Bindable var viewModel: CardViewModel
    @State private var showMarkAsUsedConfirmation = false
    @State private var showDetailSheet = false
    
    var body: some View {
        Button(action: {
            showDetailSheet = true
        }) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showDetailSheet) {
            BenefitDetailView(
                benefit: benefit,
                card: card,
                expirationDate: expirationDate,
                daysUntilExpiration: daysUntilExpiration,
                viewModel: viewModel,
                isPresented: $showDetailSheet
            )
        }
    }
    
    private var cardContent: some View {
        HStack(spacing: 12) {
            // Card image
            CardImageView(card: card)
            
            // Benefit info
            VStack(alignment: .leading, spacing: 4) {
                Text(benefit.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(expirationDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .layoutPriority(1)
            
            Spacer(minLength: 8)
            
            // Days until expiration badge
            Text(getDaysText(daysUntilExpiration))
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(getBadgeColor(daysUntilExpiration))
                .foregroundColor(getTextColor(daysUntilExpiration))
                .cornerRadius(12)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(2)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func getDaysText(_ days: Int) -> String {
        if days == 0 { return "Today" }
        if days == 1 { return "1 day" }
        return "\(days) days"
    }
    
    private func getBadgeColor(_ days: Int) -> Color {
        if days <= 5 { return Color.red.opacity(0.15) }
        if days <= 15 { return Color.orange.opacity(0.15) }
        return Color.green.opacity(0.15)
    }
    
    private func getTextColor(_ days: Int) -> Color {
        if days <= 5 { return Color.red }
        if days <= 15 { return Color.orange }
        return Color.green
    }
}

// MARK: - Benefit Detail View
struct BenefitDetailView: View {
    let benefit: CardBenefit
    let card: CreditCard
    let expirationDate: Date
    let daysUntilExpiration: Int
    @Bindable var viewModel: CardViewModel
    @Binding var isPresented: Bool
    @State private var showMarkAsUsedConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Card Image and Name Section
                    VStack(spacing: 16) {
                        CardImageView(card: card)
                            .scaleEffect(1.5)
                            .frame(height: 80)
                        
                        Text(card.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    
                    // Benefit Name Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Benefit")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text(benefit.name)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal)
                    
                    // Benefit Details Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Details")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text(benefit.benefitDescription)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal)
                    
                    // Benefit Information
                    VStack(spacing: 12) {
                        if let amount = benefit.amount, amount > 0 {
                            InfoRow(
                                icon: "dollarsign.circle.fill",
                                label: "Value",
                                value: benefit.formattedAmount,
                                color: .green
                            )
                        }
                        
                        InfoRow(
                            icon: "tag.fill",
                            label: "Category",
                            value: benefit.category.capitalized,
                            color: .blue
                        )
                        
                        InfoRow(
                            icon: "calendar",
                            label: "Expires",
                            value: formatDate(expirationDate),
                            color: getExpirationColor(daysUntilExpiration)
                        )
                        
                        InfoRow(
                            icon: "clock.fill",
                            label: "Time Remaining",
                            value: getDaysText(daysUntilExpiration),
                            color: getExpirationColor(daysUntilExpiration)
                        )
                        
                        InfoRow(
                            icon: "arrow.clockwise",
                            label: "Reset Period",
                            value: benefit.resetPeriod?.capitalized.replacingOccurrences(of: "_", with: " ") ?? "N/A",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                    
                    // Mark as Used Button
                    Button(action: {
                        showMarkAsUsedConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                            Text("Mark as Used")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Benefit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            .alert("Mark Benefit as Used", isPresented: $showMarkAsUsedConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Mark as Used", role: .destructive) {
                    markBenefitAsUsed()
                }
            } message: {
                Text("Are you sure you want to mark \"\(benefit.name)\" as used? It will be removed from the benefits list.")
            }
        }
    }
    
    private func markBenefitAsUsed() {
        viewModel.markBenefitAsUsed(benefit)
        isPresented = false
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func getDaysText(_ days: Int) -> String {
        if days == 0 { return "Expires today" }
        if days == 1 { return "1 day" }
        return "\(days) days"
    }
    
    private func getExpirationColor(_ days: Int) -> Color {
        if days == 0 { return .red }
        if days <= 7 { return .orange }
        if days <= 30 { return .yellow }
        return .green
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Benefits Earned Detail View
struct BenefitsEarnedDetailView: View {
    @Bindable var viewModel: CardViewModel
    
    @State private var timeFilter: BenefitsTimeFilter = .allTime
    @State private var selectedCardId: String? = nil
    
    private var filteredBenefits: [(record: BenefitUsageRecord, card: CreditCard)] {
        viewModel.getUsedBenefits(timeFilter: timeFilter, cardId: selectedCardId)
    }
    
    private var totalSavings: Double {
        viewModel.calculateTotalSavings(from: filteredBenefits)
    }
    
    private var cardsWithBenefits: [CreditCard] {
        viewModel.getCardsWithUsedBenefits()
    }
    
    private var formattedSavings: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalSavings)) ?? "$0.00"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Total Savings Summary
                VStack(spacing: 12) {
                    Text("Total Savings")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(formattedSavings)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Filters Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Filters")
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.horizontal)
                    
                    // Time Filter
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time Period")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Picker("Time Period", selection: $timeFilter) {
                            ForEach(BenefitsTimeFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                    }
                    
                    // Card Filter
                    if !cardsWithBenefits.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Card")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            Menu {
                                Button("All Cards") {
                                    selectedCardId = nil
                                }
                                
                                ForEach(cardsWithBenefits, id: \.id) { card in
                                    Button(card.name) {
                                        selectedCardId = card.id
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedCardId == nil ? "All Cards" : cardsWithBenefits.first(where: { $0.id == selectedCardId })?.name ?? "All Cards")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Benefits List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Benefits Used")
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.horizontal)
                    
                    if filteredBenefits.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "gift")
                                .font(.system(size: 64))
                                .foregroundColor(.gray.opacity(0.3))
                            
                            Text("No benefits used")
                                .font(.system(size: 17))
                                .foregroundColor(.gray)
                            
                            Text("Mark benefits as used to see them here")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        ForEach(filteredBenefits, id: \.record.id) { benefitInfo in
                            UsedBenefitCardView(
                                record: benefitInfo.record,
                                card: benefitInfo.card
                            )
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Benefits Earned")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Used Benefit Card View
struct UsedBenefitCardView: View {
    let record: BenefitUsageRecord
    let card: CreditCard
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: record.usedDate)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Card image
            CardImageView(card: card)
            
            // Benefit info
            VStack(alignment: .leading, spacing: 6) {
                Text(record.benefitName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(card.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .layoutPriority(1)
            
            Spacer(minLength: 8)
            
            // Amount
            if let amount = record.amount, amount > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(record.formattedAmount)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.green)
                    
                    Text("Saved")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .layoutPriority(2)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

