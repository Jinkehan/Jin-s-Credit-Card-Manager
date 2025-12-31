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
        if days == 0 { return "Expires today" }
        if days == 1 { return "Expires tomorrow" }
        return "Expires in \(days) days"
    }
    
    private func getBadgeColor(_ days: Int) -> Color {
        if days == 0 { return Color.red.opacity(0.15) }
        if days <= 7 { return Color.orange.opacity(0.15) }
        if days <= 30 { return Color.yellow.opacity(0.15) }
        return Color.green.opacity(0.15)
    }
    
    private func getTextColor(_ days: Int) -> Color {
        if days == 0 { return Color.red }
        if days <= 7 { return Color.orange }
        if days <= 30 { return Color.yellow.opacity(0.8) }
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

