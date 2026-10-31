//
//  ProfilePictureCacheManager.swift
//  kiccbacc
//
//  Created by Assistant on 2025-01-27.
//  Copyright © 2025 APPLE. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage

class ProfilePictureCacheManager {
    static let shared = ProfilePictureCacheManager()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Configure memory cache
        cache.countLimit = 100 // Maximum 100 profile pictures in memory
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
        
        // Setup disk cache directory with safe unwrap
        guard let documentsPath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            print("⚠️ Failed to get caches directory, using temporary directory")
            cacheDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("ProfilePictures")
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            setupSDWebImageCache()
            return
        }
        
        cacheDirectory = documentsPath.appendingPathComponent("ProfilePictures")
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Setup SDWebImage cache configuration for profile pictures
        setupSDWebImageCache()
    }
    
    private func setupSDWebImageCache() {
        // Configure SDWebImage cache for profile pictures
        let cacheConfig = SDImageCacheConfig()
        cacheConfig.maxMemoryCost = 50 * 1024 * 1024 // 50MB memory cache
        cacheConfig.maxDiskSize = 100 * 1024 * 1024 // 100MB disk cache
        cacheConfig.maxDiskAge = 7 * 24 * 60 * 60 // 7 days
        
        // Create a separate cache instance for profile pictures
        let profileCache = SDImageCache(config: cacheConfig)
        SDImageCache.shared = profileCache
    }
    
    // MARK: - Public Methods
    
    /// Preload a profile picture URL for faster loading
    func preloadProfilePicture(url: URL, completion: @escaping (Bool) -> Void) {
        SDWebImagePrefetcher.shared.prefetchURLs([url], options: [.highPriority, .retryFailed]) { _, _ in
            completion(true)
        }
    }
    
    /// Preload multiple profile pictures
    func preloadProfilePictures(urls: [URL], completion: @escaping () -> Void) {
        let options: SDWebImageOptions = [.highPriority, .retryFailed, .scaleDownLargeImages]
        SDWebImagePrefetcher.shared.prefetchURLs(urls, options: options) { _, _ in
            completion()
        }
    }
    
    /// Check if a profile picture is cached
    func isProfilePictureCached(url: URL) -> Bool {
        return SDImageCache.shared.diskImageExists(withKey: url.absoluteString)
    }
    
    /// Get cached profile picture
    func getCachedProfilePicture(url: URL, completion: @escaping (UIImage?) -> Void) {
        SDImageCache.shared.queryImage(forKey: url.absoluteString, options: [], context: nil) { image, _, _ in
            completion(image)
        }
    }
    
    /// Clear all profile picture caches
    func clearAllCaches() {
        // Clear memory cache
        cache.removeAllObjects()
        
        // Clear SDWebImage cache
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk()
        
        // Clear disk cache
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    /// Clear cache for specific URL
    func clearCache(for url: URL) {
        SDImageCache.shared.removeImage(forKey: url.absoluteString)
    }
    
    /// Get cache size information
    func getCacheSizeInfo() -> (memorySize: Int, diskSize: Int) {
        let memorySize = SDImageCache.shared.totalCost()
        var diskSize: Int = 0
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            diskSize = contents.reduce(0) { sum, url in
                let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                return sum + (size ?? 0)
            }
        } catch {
            print("Error getting cache size: \(error)")
        }
        
        return (memorySize, diskSize)
    }
    
    // MARK: - Automatic Cache Management
    
    /// Setup automatic cache cleanup
    func setupAutomaticCacheCleanup() {
        // Clean up old cache entries periodically
        Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { _ in
            self.cleanupOldCacheEntries()
        }
    }
    
    private func cleanupOldCacheEntries() {
        // Remove cache entries older than 7 days
        let cutoffDate = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey])
            
            for url in contents {
                if let creationDate = try? url.resourceValues(forKeys: [.creationDateKey]).creationDate,
                   creationDate < cutoffDate {
                    try? fileManager.removeItem(at: url)
                }
            }
        } catch {
            print("Error cleaning up cache: \(error)")
        }
    }
}
