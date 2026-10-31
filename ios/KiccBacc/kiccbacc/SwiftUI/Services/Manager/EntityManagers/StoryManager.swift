//
//  StoryManager.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 03/03/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation
import SDWebImage
import Combine
import FirebaseFirestore

// MARK: - StoryManagerError
enum StoryManagerError: Error, LocalizedError {
    case invalidStoryID
    case invalidCreatorID
    case invalidEventID
    case invalidImageURL
    case networkError(String)
    case uploadFailed(String)
    case storyNotFound
    case permissionDenied
    case rateLimitExceeded
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidStoryID:
            return "Invalid story ID"
        case .invalidCreatorID:
            return "Invalid creator ID"
        case .invalidEventID:
            return "Invalid event ID"
        case .invalidImageURL:
            return "Invalid image URL"
        case .networkError(let message):
            return "Network error: \(message)"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .storyNotFound:
            return "Story not found"
        case .permissionDenied:
            return "Permission denied"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - StoryManager
@MainActor
class StoryManager: ObservableObject {
    
    static let shared = StoryManager()
    
    private let repository = StoriesDataRepository()
    private let imageCache = NSCache<NSString, UIImage>()
    private let prefetcher = SDWebImagePrefetcher.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var uploadProgress: Double = 0.0
    
    // MARK: - Configuration
    private let maxConcurrentUploads = 3
    private let maxImageSize: Int64 = 10 * 1024 * 1024 // 10MB
    private let uploadTimeout: TimeInterval = 60.0
    private let retryAttempts = 3
    
    // MARK: - State Management
    private var isGettingStories = false
    
    private init() {
        setupImageCache()
    }
    
    // MARK: - Setup
    private func setupImageCache() {
        imageCache.countLimit = 100
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        prefetcher.maxConcurrentPrefetchCount = 4
        prefetcher.options = [.highPriority, .retryFailed, .refreshCached]
    }
    
    // MARK: - Story Upload
    func uploadStoryImage(
        with data: Data,
        withStoryId: String,
        progress: @escaping (Double) -> Void = { _ in },
        completion: @escaping (Result<FirebaseStorageUploadStatus, StoryManagerError>) -> Void
    ) {
        // Validate input
        guard !withStoryId.isEmpty else {
            completion(.failure(.invalidStoryID))
            return
        }
        
        guard !data.isEmpty else {
            completion(.failure(.uploadFailed("Empty image data")))
            return
        }
        
        guard data.count <= maxImageSize else {
            completion(.failure(.uploadFailed("Image size exceeds 10MB limit")))
            return
        }
        
        isLoading = true
        uploadProgress = 0.0
        
        // Create upload task with timeout
        let uploadTask = DispatchWorkItem {
            self.repository.uploadStoryImage(with: data, withStoryId: withStoryId) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.uploadProgress = 1.0
                    
                    switch result {
                    case .success(let status):
                        completion(.success(status))
                    case .failure(let error):
                        completion(.failure(.uploadFailed(error.localizedDescription)))
                    }
                }
            }
        }
        
        // Execute on background queue to prevent main thread blocking
        DispatchQueue.global(qos: .userInitiated).async {
            uploadTask.perform()
        }
        
        // Execute with timeout
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + uploadTimeout) {
            if !uploadTask.isCancelled {
                uploadTask.cancel()
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(.failure(.uploadFailed("Upload timeout")))
                }
            }
        }
    }
    
    // MARK: - Story Creation
    func create(story: Story) async throws {
        // Validate story data
        try validateStory(story)
        
        isLoading = true
        errorMessage = nil
        
        do {
            try repository.create(story: story)
            
            // Send notification asynchronously
            Task {
                await sendStoryNotification(for: story)
            }
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw StoryManagerError.unknownError(error.localizedDescription)
        }
    }
    
    private func validateStory(_ story: Story) throws {
        guard !story.storyID.isEmpty else {
            throw StoryManagerError.invalidStoryID
        }
        
        guard !story.creatorID.isEmpty else {
            throw StoryManagerError.invalidCreatorID
        }
        
        guard !story.eventID.isEmpty else {
            throw StoryManagerError.invalidEventID
        }
        
        guard !story.imageUrlString.isEmpty,
              URL(string: story.imageUrlString) != nil else {
            throw StoryManagerError.invalidImageURL
        }
    }
    
    private func sendStoryNotification(for story: Story) async {
        // Send notification asynchronously without blocking the main upload process
        Task.detached {
            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    // Add timeout to prevent hanging
                    let timeoutTask = Task {
                        try await Task.sleep(nanoseconds: 10_000_000_000) // 10 second timeout
                        continuation.resume(throwing: StoryManagerError.unknownError("Notification timeout"))
                    }
                    
                    EnhancedNotificationManager.shared.sendNewStoryNotification(
                        storyCreatorID: story.creatorID,
                        storyID: story.storyID
                    ) { success in
                        timeoutTask.cancel()
                        if success {
                            continuation.resume()
                        } else {
                            continuation.resume(throwing: StoryManagerError.unknownError("Failed to send story notification"))
                        }
                    }
                }
            } catch {
                print("Failed to send story notification: \(error)")
            }
        }
    }
    
    // MARK: - Story Retrieval
    func getStory(withStoryID: String) async throws -> Story {
        guard !withStoryID.isEmpty else {
            throw StoryManagerError.invalidStoryID
        }
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Story, Error>) in
            repository.getStory(withStoryID: withStoryID) { story in
                if let story = story {
                    continuation.resume(returning: story)
                } else {
                    continuation.resume(throwing: StoryManagerError.storyNotFound)
                }
            }
        }
    }
    
    func getStories(withEventID: String) async throws -> [Story] {
        guard !withEventID.isEmpty else {
            throw StoryManagerError.invalidEventID
        }
        
        // Prevent multiple simultaneous calls
        guard !isGettingStories else {
            return []
        }
        
        isGettingStories = true
        defer { isGettingStories = false }
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Story], Error>) in
            repository.getStories(withEventID: withEventID) { stories in
                continuation.resume(returning: stories ?? [])
            }
        }
    }
    
    func getFeaturedStories() async throws -> [Story] {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Story], Error>) in
            repository.getFeaturedStories { stories in
                continuation.resume(returning: stories ?? [])
            }
        }
    }
    
    func getValidStories(withEventID: String) async throws -> [Story] {
        guard !withEventID.isEmpty else {
            throw StoryManagerError.invalidEventID
        }
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Story], Error>) in
            repository.getValidStories(withEventID: withEventID) { stories in
                if let stories = stories {
                    // Prefetch images for better performance
                    self.prefetchStoryImages(stories)
                    continuation.resume(returning: stories)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    // MARK: - Story Management
    func delete(story: Story) async throws -> Bool {
        guard !story.storyID.isEmpty else {
            throw StoryManagerError.invalidStoryID
        }
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            repository.delete(story: story) { isDeleted in
                continuation.resume(returning: isDeleted)
            }
        }
    }
    
    func markStoryAsSeen(_ story: Story, by userID: String) async throws {
        guard !story.storyID.isEmpty else {
            throw StoryManagerError.invalidStoryID
        }
        
        guard !userID.isEmpty else {
            throw StoryManagerError.invalidCreatorID
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            repository.isStory(story, seenBy: userID) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Like/Unlike Story (Following Seen By Pattern)
    func likeStory(_ story: Story, by userID: String) async throws {
        guard !story.storyID.isEmpty else {
            throw StoryManagerError.invalidStoryID
        }
        
        guard !userID.isEmpty else {
            throw StoryManagerError.invalidCreatorID
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            repository.likeStory(story, by: userID) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    // Send story like notification after successful like
                    self.sendStoryLikeNotification(likerID: userID, story: story)
                    continuation.resume()
                }
            }
        }
    }
    
    func unlikeStory(_ story: Story, by userID: String) async throws {
        guard !story.storyID.isEmpty else {
            throw StoryManagerError.invalidStoryID
        }
        
        guard !userID.isEmpty else {
            throw StoryManagerError.invalidCreatorID
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            repository.unlikeStory(story, by: userID) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Real-time Story Updates
    func addStoryListener(storyID: String, completion: @escaping (Story?) -> Void) -> FirebaseFirestore.ListenerRegistration {
        return repository.addStoryListener(storyID: storyID, completion: completion)
    }
    
    // MARK: - Image Management
    func prefetchStoryImages(_ stories: [Story]) {
        let urls = stories.compactMap { URL(string: $0.imageUrlString) }
        
        guard !urls.isEmpty else { return }
        
        prefetcher.prefetchURLs(urls) { [weak self] finishedCount, skippedCount in
            print("Prefetched \(finishedCount) images, skipped \(skippedCount)")
        }
    }
    
    func preloadStoryImage(for story: Story) {
        guard let url = URL(string: story.imageUrlString) else { return }
        
        SDWebImageManager.shared.loadImage(
            with: url,
            options: [.highPriority, .retryFailed, .refreshCached],
            context: nil,
            progress: nil
        ) { [weak self] image, _, _, _, _, _ in
            if let image = image {
                self?.imageCache.setObject(image, forKey: story.storyID as NSString)
            }
        }
    }
    
    func getCachedImage(for storyID: String) -> UIImage? {
        return imageCache.object(forKey: storyID as NSString)
    }
    
    func clearImageCache() {
        imageCache.removeAllObjects()
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk {
            print("Image cache cleared successfully")
        }
    }
    
    // MARK: - Error Handling
    func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Rate Limiting
    private var lastUploadTime: Date = Date.distantPast
    private let uploadCooldown: TimeInterval = 1.0 // 1 second between uploads
    
    private func checkRateLimit() -> Bool {
        let now = Date()
        if now.timeIntervalSince(lastUploadTime) < uploadCooldown {
            return false
        }
        lastUploadTime = now
        return true
    }
    
    // MARK: - Cleanup
    func cleanup() {
        cancellables.removeAll()
        imageCache.removeAllObjects()
        isLoading = false
        errorMessage = nil
        uploadProgress = 0.0
    }
    
    deinit {
        Task { @MainActor in
            cleanup()
        }
    }
}

// MARK: - Legacy Support (for backward compatibility)
extension StoryManager {
    
    // Legacy methods for backward compatibility
    func uploadStoryImage(with data: Data, withStoryId: String, completion: @escaping (Result<FirebaseStorageUploadStatus,Error>) -> Void) {
        uploadStoryImage(with: data, withStoryId: withStoryId) { result in
            switch result {
            case .success(let status):
                completion(.success(status))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func create(story: Story) throws {
        // This is a legacy method that should not be used in new code
        // Use the async version instead
        // Use async create(story:) method instead
        print("⚠️ StoryManager: Deprecated sync create method called. Use async version instead.")
        return
    }
    
    func getStory(withStoryID: String, completion: @escaping (Story?) -> ()) {
        Task {
            do {
                let story = try await getStory(withStoryID: withStoryID)
                completion(story)
            } catch {
                completion(nil)
            }
        }
    }
    
    func getStories(withEventID: String, completion: @escaping ([Story]?) -> ()) {
        // Prevent multiple simultaneous calls to avoid continuation misuse
        guard !isGettingStories else {
            completion(nil)
            return
        }
        
        Task {
            do {
                let stories = try await getStories(withEventID: withEventID)
                completion(stories)
            } catch {
                completion(nil)
            }
        }
    }
    
    func getFeaturedStories(completion: @escaping ([Story]?) -> ()) {
        Task {
            do {
                let stories = try await getFeaturedStories()
                completion(stories)
            } catch {
                completion(nil)
            }
        }
    }
    
    func getValidStories(withEventID: String, completion: @escaping ([Story]?) -> ()) {
        Task {
            do {
                let stories = try await getValidStories(withEventID: withEventID)
                completion(stories)
            } catch {
                completion(nil)
            }
        }
    }
    
    func delete(story: Story, completion: @escaping (Bool) -> ()) {
        Task {
            do {
                let isDeleted = try await delete(story: story)
                completion(isDeleted)
            } catch {
                completion(false)
            }
        }
    }
    
    func isStory(_ story: Story, seenBy userID: String, completion: @escaping (Error?) -> ()) {
        Task {
            do {
                try await markStoryAsSeen(story, by: userID)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    func likeStory(_ story: Story, completion: @escaping (Error?) -> ()) {
        guard let currentUserID = UserManager.shared.currentUserID else {
            completion(StoryManagerError.permissionDenied)
            return
        }
        
        guard !story.storyID.isEmpty else {
            completion(StoryManagerError.invalidStoryID)
            return
        }
        
        Task {
            do {
                try await likeStory(story, by: currentUserID)
                await MainActor.run {
                    completion(nil)
                }
            } catch {
                await MainActor.run {
                    completion(error)
                }
            }
        }
    }
    
    func unlikeStory(_ story: Story, completion: @escaping (Error?) -> ()) {
        guard let currentUserID = UserManager.shared.currentUserID else {
            completion(StoryManagerError.permissionDenied)
            return
        }
        
        guard !story.storyID.isEmpty else {
            completion(StoryManagerError.invalidStoryID)
            return
        }
        
        Task {
            do {
                try await unlikeStory(story, by: currentUserID)
                await MainActor.run {
                    completion(nil)
                }
            } catch {
                await MainActor.run {
                    completion(error)
                }
            }
        }
    }
    
    // MARK: - Story Like Notifications
    private func sendStoryLikeNotification(likerID: String, story: Story) {
        // Don't send notification if user likes their own story
        guard likerID != story.creatorID else {
            print("🔔 Skipping notification: User liked their own story")
            return
        }
        
        print("🔔 Sending story like notification - Liker: \(likerID), Creator: \(story.creatorID), Story: \(story.storyID)")
        
        // Send notification using EnhancedNotificationManager
        EnhancedNotificationManager.shared.sendStoryLikeNotification(
            likerID: likerID,
            storyCreatorID: story.creatorID,
            storyID: story.storyID
        ) { success in
            if success {
                print("✅ Story like notification sent successfully")
            } else {
                print("❌ Failed to send story like notification")
            }
        }
    }
}
