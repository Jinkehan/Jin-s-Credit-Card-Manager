//
//  RewardsTabView.swift
//  J Due
//
//  Created by Kehan Jin on 12/30/25.
//

import SwiftUI

struct RewardsTabView: View {
    @Bindable var viewModel: CardViewModel
    @State private var rewardsViewModel = RewardsViewModel()
    @State private var apiKeyInput: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                        
                        Text("Maximize Rewards")
                            .font(.system(size: 34, weight: .bold))
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Store Input Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Where are you shopping?")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Image(systemName: "storefront.fill")
                                .foregroundColor(.blue)
                            
                            TextField("Enter store name (e.g., Target, Amazon)", text: $rewardsViewModel.storeInput)
                                .textFieldStyle(.plain)
                                .submitLabel(.search)
                                .onSubmit {
                                    Task {
                                        await rewardsViewModel.getRecommendation(for: viewModel.cards)
                                    }
                                }
                            
                            if !rewardsViewModel.storeInput.isEmpty {
                                Button(action: {
                                    rewardsViewModel.storeInput = ""
                                    rewardsViewModel.clearRecommendations()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        
                        Button(action: {
                            Task {
                                await rewardsViewModel.getRecommendation(for: viewModel.cards)
                            }
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Get Recommendation")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(rewardsViewModel.isLoading || rewardsViewModel.storeInput.isEmpty)
                        .opacity(rewardsViewModel.isLoading || rewardsViewModel.storeInput.isEmpty ? 0.6 : 1.0)
                    }
                    .padding(.horizontal)
                    
                    // Loading Indicator
                    if rewardsViewModel.isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Analyzing your cards...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                    
                    // Error Message
                    if let errorMessage = rewardsViewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(errorMessage)
                                .font(.subheadline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Recommendations
                    if !rewardsViewModel.recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recommended Cards")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(Array(rewardsViewModel.recommendations.enumerated()), id: \.element.id) { index, recommendation in
                                RecommendationCard(
                                    recommendation: recommendation,
                                    rank: index + 1
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Empty State
                    if !rewardsViewModel.isLoading && rewardsViewModel.recommendations.isEmpty && rewardsViewModel.errorMessage == nil {
                        VStack(spacing: 16) {
                            Image(systemName: "creditcard.and.123")
                                .font(.system(size: 64))
                                .foregroundColor(.gray.opacity(0.3))
                            
                            Text("Enter a store name above")
                                .font(.system(size: 17))
                                .foregroundColor(.gray)
                            
                            Text("We'll recommend the best card from your wallet to maximize rewards")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    }
                    
                    // Cards Info
                    if !viewModel.cards.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Cards (\(viewModel.cards.count))")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.cards, id: \.id) { card in
                                        CardChip(card: card)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.gray.opacity(0.3))
                            
                            Text("No cards added yet")
                                .font(.system(size: 17))
                                .foregroundColor(.gray)
                            
                            Text("Add your credit cards in Settings to get personalized recommendations")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        rewardsViewModel.showingAPIKeySetup = true
                    }) {
                        Image(systemName: "key.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $rewardsViewModel.showingAPIKeySetup) {
                APIKeySetupView(
                    apiKeyInput: $apiKeyInput,
                    onSave: {
                        rewardsViewModel.setAPIKey(apiKeyInput)
                    }
                )
            }
        }
    }
}

struct RecommendationCard: View {
    let recommendation: CardRecommendation
    let rank: Int
    
    var rankColor: Color {
        switch rank {
        case 1: return .green
        case 2: return .blue
        case 3: return .orange
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("#\(rank)")
                    .font(.headline)
                    .foregroundColor(rankColor)
                
                Spacer()
                
                // Reward badge with optional point value
                VStack(alignment: .trailing, spacing: 2) {
                    Text(recommendation.estimatedReward)
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    if let pointValue = recommendation.pointValue {
                        Text(pointValue)
                            .font(.caption2)
                            .foregroundColor(.green.opacity(0.8))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            Text(recommendation.cardName)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(recommendation.reason)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: rankColor.opacity(0.2), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(rankColor.opacity(0.3), lineWidth: 2)
        )
    }
}

struct CardChip: View {
    let card: CreditCard
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "creditcard.fill")
                .font(.caption)
            
            Text(card.name)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(20)
    }
}

struct APIKeySetupView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var apiKeyInput: String
    let onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(.blue)
                                .font(.title)
                            
                            VStack(alignment: .leading) {
                                Text("Perplexity API Key")
                                    .font(.headline)
                                Text("Required for AI recommendations")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        TextField("Enter your API key", text: $apiKeyInput)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                } header: {
                    Text("API Configuration")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How to get your API key:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("1. Visit perplexity.ai")
                            .font(.caption)
                        Text("2. Sign up or log in to your account")
                            .font(.caption)
                        Text("3. Navigate to API settings")
                            .font(.caption)
                        Text("4. Generate a new API key")
                            .font(.caption)
                        Text("5. Copy and paste it above")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                } header: {
                    Text("Instructions")
                }
                
                Section {
                    Text("Your API key is stored securely on your device and is only used to communicate with Perplexity's API for card recommendations.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Privacy")
                }
            }
            .navigationTitle("API Key Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    RewardsTabView(viewModel: CardViewModel())
}

