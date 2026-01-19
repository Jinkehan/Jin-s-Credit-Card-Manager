//
//  CardBenefitsService.swift
//  J Due
//
//  Created by Kehan Jin on 12/25/25.
//

import Foundation
import Network
import Combine

@MainActor
class CardBenefitsService: ObservableObject {
    static let shared = CardBenefitsService()
    
    @Published var predefinedCards: [PredefinedCard] = []
    @Published var isLoading = false
    @Published var lastFetchDate: Date?
    @Published var errorMessage: String?
    
    private let githubRawURL = "https://raw.githubusercontent.com/Jinkehan/Jin-s-Credit-Card-Manager/main/card-benefits.json"
    private let cacheKey = "cardBenefitsCache"
    private let lastFetchKey = "cardBenefitsLastFetch"
    private let cacheVersionKey = "cardBenefitsVersion"
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var isNetworkAvailable = false
    
    private init() {
        startNetworkMonitoring()
        loadCachedData()
    }
    
    // MARK: - Network Monitoring
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isAvailable = path.status == .satisfied
            Task { @MainActor [weak self] in
                self?.isNetworkAvailable = isAvailable
            }
        }
        monitor.start(queue: queue)
    }
    
    // MARK: - Cache Management
    
    private func loadCachedData() {
        // Load cached predefined cards
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let response = try? JSONDecoder().decode(CardBenefitsResponse.self, from: data) {
            self.predefinedCards = response.predefinedCards
        }
        
        // Load last fetch date
        if let dateData = UserDefaults.standard.object(forKey: lastFetchKey) as? Date {
            self.lastFetchDate = dateData
        }
    }
    
    private func saveToCache(_ response: CardBenefitsResponse) {
        if let data = try? JSONEncoder().encode(response) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: lastFetchKey)
            UserDefaults.standard.set(response.schemaVersion, forKey: cacheVersionKey)
        }
    }
    
    // MARK: - Fetch from GitHub
    
    func fetchCardBenefits(forceRefresh: Bool = false) async {
        // Check if we should fetch (only if network is available and enough time has passed)
        guard isNetworkAvailable else {
            return
        }
        
        // Don't fetch too frequently - at most once per day (unless forceRefresh is true)
        if !forceRefresh, let lastFetch = lastFetchDate {
            let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
            let minInterval: TimeInterval = 86400 // 24 hours (1 day)
            if timeSinceLastFetch < minInterval {
                return
            }
        }
        
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: githubRawURL) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        do {
            // Create a custom URLSession with fresh configuration to avoid caching
            let config = URLSessionConfiguration.default
            config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            config.urlCache = nil
            let session = URLSession(configuration: config)
            
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let decoder = JSONDecoder()
            let cardBenefitsResponse = try decoder.decode(CardBenefitsResponse.self, from: data)
            
            self.predefinedCards = cardBenefitsResponse.predefinedCards
            self.lastFetchDate = Date()
            
            saveToCache(cardBenefitsResponse)
            
            // Force refetch card images after loading benefits to ensure updated pictures are downloaded
            // This clears the cache and downloads fresh images from GitHub
            await ImageCacheService.shared.refetchImages(for: cardBenefitsResponse.predefinedCards)
            
            // Post notification that benefits were updated whenever fetch succeeds
            // This ensures existing cards get synced with updated benefits data
            NotificationCenter.default.post(name: .cardBenefitsUpdated, object: nil)
            
        } catch {
            errorMessage = "Failed to fetch card benefits: \(error.localizedDescription)"
            // If fetch fails, we still have cached data
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    func getPredefinedCard(byId id: String) -> PredefinedCard? {
        return predefinedCards.first { $0.id == id }
    }
    
    func searchPredefinedCards(query: String) -> [PredefinedCard] {
        guard !query.isEmpty else { return predefinedCards }
        let lowercasedQuery = query.lowercased()
        return predefinedCards.filter { card in
            card.name.lowercased().contains(lowercasedQuery) ||
            card.issuer.lowercased().contains(lowercasedQuery) ||
            card.category.lowercased().contains(lowercasedQuery)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let cardBenefitsUpdated = Notification.Name("cardBenefitsUpdated")
}

