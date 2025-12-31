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
    var isVerifyingAPIKey: Bool = false
    var verificationError: String?
    var showingDeleteConfirmation: Bool = false
    var hasAPIKeyStored: Bool = false
    
    private let perplexityService = PerplexityService.shared
    
    init() {
        hasAPIKeyStored = perplexityService.hasAPIKey()
    }
    
    func hasAPIKey() -> Bool {
        return hasAPIKeyStored
    }
    
    func deleteAPIKey() {
        perplexityService.deleteAPIKey()
        hasAPIKeyStored = false
        clearRecommendations()
    }
    
    func verifyAndSetAPIKey(_ key: String) async -> Bool {
        isVerifyingAPIKey = true
        verificationError = nil
        
        do {
            let isValid = try await perplexityService.verifyAPIKey(key)
            
            if isValid {
                perplexityService.setAPIKey(key)
                hasAPIKeyStored = true
                isVerifyingAPIKey = false
                return true
            } else {
                verificationError = "Unable to verify API key"
                isVerifyingAPIKey = false
                return false
            }
        } catch let error as PerplexityError {
            verificationError = error.errorDescription
            isVerifyingAPIKey = false
            return false
        } catch {
            verificationError = "Verification failed: \(error.localizedDescription)"
            isVerifyingAPIKey = false
            return false
        }
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

