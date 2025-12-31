//
//  PerplexityService.swift
//  J Due
//
//  Created by Kehan Jin on 12/30/25.
//

import Foundation

struct PerplexityMessage: Codable {
    let role: String
    let content: String
}

struct PerplexityRequest: Codable {
    let model: String
    let messages: [PerplexityMessage]
    let temperature: Double
    let max_tokens: Int
}

struct PerplexityChoice: Codable {
    let message: PerplexityMessage
}

struct PerplexityResponse: Codable {
    let choices: [PerplexityChoice]
}

struct CardRecommendation: Identifiable {
    let id = UUID()
    let cardName: String
    let reason: String
    let estimatedReward: String
    let pointValue: String? // For points-based rewards, e.g., "~1.5-2 cent per point"
}

class PerplexityService {
    static let shared = PerplexityService()
    
    private var apiKey: String
    private let baseURL = "https://api.perplexity.ai/chat/completions"
    
    private init() {
        // You'll need to add your API key here or load it from a secure location
        // For now, we'll use a placeholder
        self.apiKey = UserDefaults.standard.string(forKey: "perplexity_api_key") ?? ""
    }
    
    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "perplexity_api_key")
        apiKey = key  // Update the instance property
    }
    
    func deleteAPIKey() {
        UserDefaults.standard.removeObject(forKey: "perplexity_api_key")
        apiKey = ""  // Clear the instance property
    }
    
    func hasAPIKey() -> Bool {
        return !apiKey.isEmpty
    }
    
    func verifyAPIKey(_ key: String) async throws -> Bool {
        guard !key.isEmpty else {
            throw PerplexityError.noAPIKey
        }
        
        // Send a simple test message to verify the API key works
        let messages = [
            PerplexityMessage(role: "system", content: "You are a helpful assistant."),
            PerplexityMessage(role: "user", content: "Hi")
        ]
        
        let request = PerplexityRequest(
            model: "sonar-pro",
            messages: messages,
            temperature: 0.2,
            max_tokens: 50
        )
        
        guard let url = URL(string: baseURL) else {
            throw PerplexityError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let requestBody = try JSONEncoder().encode(request)
        urlRequest.httpBody = requestBody
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PerplexityError.invalidResponse
        }
        
        // Check if the API key is valid (200 status code)
        if httpResponse.statusCode == 200 {
            // Verify we got a valid response structure
            let perplexityResponse = try JSONDecoder().decode(PerplexityResponse.self, from: data)
            return perplexityResponse.choices.first?.message.content != nil
        } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw PerplexityError.invalidAPIKey
        } else {
            throw PerplexityError.apiError(statusCode: httpResponse.statusCode)
        }
    }
    
    func getRecommendation(for store: String, with cards: [CreditCard]) async throws -> [CardRecommendation] {
        guard !apiKey.isEmpty else {
            throw PerplexityError.noAPIKey
        }
        
        // Build a mapping of predefined card names to user's custom names
        var cardNameMapping: [String: String] = [:]
        
        // Build the prompt with user's cards
        let cardsList = cards.map { card in
            // Use predefined card name if available (more accurate for AI), otherwise use user-defined name
            let cardName: String
            if let predefinedCardId = card.predefinedCardId,
               let predefinedCard = CardBenefitsService.shared.getPredefinedCard(byId: predefinedCardId) {
                cardName = predefinedCard.name
                // Map predefined name to user's custom name
                cardNameMapping[cardName] = card.name
            } else {
                cardName = card.name
            }
            return "- \(cardName)"
        }.joined(separator: "\n")
        
        let prompt = """
        I'm shopping at \(store) and I have the following credit cards:
        
        \(cardsList)
        
        Based on these cards and their benefits, which card should I use to maximize my rewards or cashback at \(store)? 
        Please provide:
        1. The recommended card name
        2. A brief reason why (e.g., category bonus, specific merchant bonus)
        3. Estimated reward in a standardized format:
           - For cashback cards: "X% cashback" (e.g., "5% cashback", "2% cashback")
           - For points cards: "Xx Points" (e.g., "5x Points", "3x Points")
        4. For points-based rewards ONLY, also provide the approximate cent per point value in the format "~X-X cent per point" (e.g., "~1.5-2 cent per point", "~1-1.5 cent per point")
        
        If multiple cards could work well, list up to 3 recommendations in order of best to worst.
        Format your response as a JSON array with objects containing:
        - "cardName": string
        - "reason": string
        - "estimatedReward": string (format: "X% cashback" OR "Xx Points")
        - "pointValue": string or null (format: "~X-X cent per point" for points cards, null for cashback cards)
        """
        
        let messages = [
            PerplexityMessage(role: "system", content: "You are a helpful assistant that provides credit card recommendations based on rewards optimization. Always respond with valid JSON."),
            PerplexityMessage(role: "user", content: prompt)
        ]
        
        let request = PerplexityRequest(
            model: "sonar-pro",
            messages: messages,
            temperature: 0.2,
            max_tokens: 1000
        )
        
        guard let url = URL(string: baseURL) else {
            throw PerplexityError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let requestBody = try JSONEncoder().encode(request)
        urlRequest.httpBody = requestBody
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PerplexityError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PerplexityError.apiError(statusCode: httpResponse.statusCode)
        }
        
        let perplexityResponse = try JSONDecoder().decode(PerplexityResponse.self, from: data)
        
        guard let content = perplexityResponse.choices.first?.message.content else {
            throw PerplexityError.noResponse
        }
        
        // Parse the JSON response from the AI and map back to user's custom names
        return try parseRecommendations(from: content, cardNameMapping: cardNameMapping)
    }
    
    private func parseRecommendations(from content: String, cardNameMapping: [String: String]) throws -> [CardRecommendation] {
        // Try to extract JSON from the response
        // Sometimes the AI wraps JSON in markdown code blocks
        var jsonString = content
        
        // Remove markdown code blocks if present
        if let startRange = content.range(of: "```json"),
           let endRange = content.range(of: "```", range: startRange.upperBound..<content.endIndex) {
            jsonString = String(content[startRange.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let startRange = content.range(of: "["),
                  let endRange = content.range(of: "]", options: .backwards) {
            // Ensure endRange is after startRange and both are valid
            guard endRange.lowerBound >= startRange.upperBound,
                  endRange.upperBound <= content.endIndex,
                  startRange.lowerBound >= content.startIndex else {
                throw PerplexityError.parseError
            }
            jsonString = String(content[startRange.lowerBound...endRange.lowerBound])
        }
        
        struct RecommendationJSON: Codable {
            let cardName: String
            let reason: String
            let estimatedReward: String
            let pointValue: String?
        }
        
        guard let data = jsonString.data(using: .utf8) else {
            throw PerplexityError.parseError
        }
        
        let recommendations = try JSONDecoder().decode([RecommendationJSON].self, from: data)
        
        return recommendations.map { rec in
            // Map the predefined card name back to the user's custom name
            let displayName = cardNameMapping[rec.cardName] ?? rec.cardName
            
            return CardRecommendation(
                cardName: displayName,
                reason: rec.reason,
                estimatedReward: rec.estimatedReward,
                pointValue: rec.pointValue
            )
        }
    }
}

enum PerplexityError: LocalizedError {
    case noAPIKey
    case invalidAPIKey
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
    case noResponse
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured. Please add your Perplexity API key in Settings."
        case .invalidAPIKey:
            return "Invalid API key. Please check your key and try again."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let statusCode):
            return "API error with status code: \(statusCode)"
        case .noResponse:
            return "No response from AI"
        case .parseError:
            return "Failed to parse AI response"
        }
    }
}

