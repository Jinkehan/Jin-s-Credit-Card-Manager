//
//  RewardsViewModel.swift
//  J Due
//
//  Created by Kehan Jin on 12/30/25.
//

import Foundation
import SwiftUI

@Observable
class RewardsViewModel {
    var storeInput: String = ""
    var recommendations: [CardRecommendation] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var showingAPIKeySetup: Bool = false
    
    private let perplexityService = PerplexityService.shared
    
    func hasAPIKey() -> Bool {
        return perplexityService.hasAPIKey()
    }
    
    func setAPIKey(_ key: String) {
        perplexityService.setAPIKey(key)
        showingAPIKeySetup = false
    }
    
    func getRecommendation(for cards: [CreditCard]) async {
        guard !storeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a store name"
            return
        }
        
        guard !cards.isEmpty else {
            errorMessage = "Please add some credit cards first"
            return
        }
        
        isLoading = true
        errorMessage = nil
        recommendations = []
        
        do {
            recommendations = try await perplexityService.getRecommendation(
                for: storeInput,
                with: cards
            )
            
            if recommendations.isEmpty {
                errorMessage = "No recommendations found. Try a different store."
            }
        } catch let error as PerplexityError {
            errorMessage = error.errorDescription
            if case .noAPIKey = error {
                showingAPIKeySetup = true
            }
        } catch {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func clearRecommendations() {
        recommendations = []
        errorMessage = nil
    }
}

