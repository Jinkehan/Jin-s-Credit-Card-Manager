//
//  ImageCacheService.swift
//  J Due
//
//  Created by Kehan Jin on 12/28/25.
//

import SwiftUI
import Foundation
import Combine

@MainActor
class ImageCacheService: ObservableObject {
    static let shared = ImageCacheService()
    
    @Published private(set) var cachedImages: [String: UIImage] = [:]
    @Published private(set) var isLoading: [String: Bool] = [:]
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Create cache directory in Documents
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentsPath.appendingPathComponent("CardImageCache", isDirectory: true)
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Load cached images on init
        loadCachedImages()
    }
    
    // MARK: - Public Methods
    
    /// Fetch image from URL or return cached version
    func fetchImage(for imageId: String, from urlString: String?) async -> UIImage? {
        // Check if already in memory cache
        if let cachedImage = cachedImages[imageId] {
            return cachedImage
        }
        
        // Check if exists in disk cache
        if let diskImage = loadImageFromDisk(imageId: imageId) {
            cachedImages[imageId] = diskImage
            return diskImage
        }
        
        // If no URL provided, return nil
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            return nil
        }
        
        // Set loading state
        isLoading[imageId] = true
        defer { isLoading[imageId] = false }
        
        // Fetch from network
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let image = UIImage(data: data) else {
                print("❌ Failed to download image for \(imageId)")
                return nil
            }
            
            // Cache the image
            cachedImages[imageId] = image
            saveImageToDisk(image: image, imageId: imageId)
            
            print("✅ Successfully downloaded and cached image: \(imageId)")
            return image
            
        } catch {
            print("❌ Error downloading image for \(imageId): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Get cached image synchronously (for SwiftUI views)
    func getCachedImage(for imageId: String) -> UIImage? {
        return cachedImages[imageId]
    }
    
    /// Check if image is currently loading
    func isImageLoading(_ imageId: String) -> Bool {
        return isLoading[imageId] ?? false
    }
    
    /// Clear all cached images
    func clearCache() {
        cachedImages.removeAll()
        
        // Clear disk cache
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
            print("✅ Cache cleared successfully")
        } catch {
            print("❌ Error clearing cache: \(error.localizedDescription)")
        }
    }
    
    /// Prefetch images for multiple cards
    func prefetchImages(for cards: [PredefinedCard]) async {
        await withTaskGroup(of: Void.self) { group in
            for card in cards {
                guard let imageUrl = card.imageUrl else { continue }
                
                group.addTask {
                    _ = await self.fetchImage(for: card.id, from: imageUrl)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadCachedImages() {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            
            for file in files {
                guard file.pathExtension == "jpg" || file.pathExtension == "png" else { continue }
                
                let imageId = file.deletingPathExtension().lastPathComponent
                if let imageData = try? Data(contentsOf: file),
                   let image = UIImage(data: imageData) {
                    cachedImages[imageId] = image
                }
            }
            
            print("✅ Loaded \(cachedImages.count) cached images")
        } catch {
            print("❌ Error loading cached images: \(error.localizedDescription)")
        }
    }
    
    private func loadImageFromDisk(imageId: String) -> UIImage? {
        let fileURL = cacheDirectory.appendingPathComponent("\(imageId).jpg")
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) else {
            return nil
        }
        
        return image
    }
    
    private func saveImageToDisk(image: UIImage, imageId: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(imageId).jpg")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert image to JPEG data")
            return
        }
        
        do {
            try imageData.write(to: fileURL)
            print("✅ Saved image to disk: \(imageId)")
        } catch {
            print("❌ Error saving image to disk: \(error.localizedDescription)")
        }
    }
    
    /// Get the local file URL for an image (for debugging)
    func getLocalImageURL(for imageId: String) -> URL? {
        let fileURL = cacheDirectory.appendingPathComponent("\(imageId).jpg")
        return fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
}

