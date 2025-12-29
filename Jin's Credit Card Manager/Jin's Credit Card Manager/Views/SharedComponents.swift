//
//  SharedComponents.swift
//  J Due
//
//  Created by Kehan Jin on 12/28/25.
//

import SwiftUI

// MARK: - Shared Card Image View
struct CardImageView: View {
    let card: CreditCard
    @StateObject private var imageCache = ImageCacheService.shared
    @StateObject private var benefitsService = CardBenefitsService.shared
    @State private var loadedImage: UIImage?
    
    var body: some View {
        Group {
            if let image = loadedImage {
                // Display card image
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 38)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else if imageCache.isImageLoading(card.id) {
                // Loading indicator
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 60, height: 38)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.7)
                    )
            } else {
                // Default fallback
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 38)
                    .overlay(
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 20))
                    )
            }
        }
        .onAppear {
            loadCardImage()
        }
        .onChange(of: card.predefinedCardId) { _, _ in
            loadCardImage()
        }
        .onChange(of: imageCache.cachedImages[card.id]) { _, newImage in
            if let newImage = newImage {
                loadedImage = newImage
            }
        }
    }
    
    private func loadCardImage() {
        // Try to get cached image first
        if let cached = imageCache.getCachedImage(for: card.id) {
            loadedImage = cached
            return
        }
        
        // If card has predefinedCardId, fetch from network
        if let predefinedCardId = card.predefinedCardId,
           let predefinedCard = benefitsService.getPredefinedCard(byId: predefinedCardId),
           let imageUrl = predefinedCard.imageUrl {
            Task {
                if let image = await imageCache.fetchImage(for: card.id, from: imageUrl) {
                    loadedImage = image
                }
            }
        }
    }
}

// MARK: - Shared Predefined Card Image View (for TestBenefitsView)
struct PredefinedCardImageView: View {
    let cardId: String
    let imageUrl: String?
    @ObservedObject var imageCache: ImageCacheService
    @State private var loadedImage: UIImage?
    
    var body: some View {
        Group {
            if let image = loadedImage {
                // Display cached/loaded image
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 38)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else if imageCache.isImageLoading(cardId) {
                // Loading indicator
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 60, height: 38)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.7)
                    )
            } else {
                // Fallback icon if no image
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 38)
                    .overlay(
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 20))
                    )
            }
        }
        .onAppear {
            // Try to get cached image first
            if let cached = imageCache.getCachedImage(for: cardId) {
                loadedImage = cached
            } else if let urlString = imageUrl {
                // Fetch from network
                Task {
                    if let image = await imageCache.fetchImage(for: cardId, from: urlString) {
                        loadedImage = image
                    }
                }
            }
        }
        .onChange(of: imageCache.cachedImages[cardId]) { oldImage, newImage in
            if let newImage = newImage {
                loadedImage = newImage
            }
        }
    }
}

