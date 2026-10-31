//
// StoriesDataRepository.swift
// kiccbacc
//
// Created by Ankit Yadav on 03/03/22.
// Copyright © 2022 APPLE. All rights reserved.
//
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import CoreMedia
import SDWebImage

struct StoriesDataRepository {
    private let database = Firestore.firestore()
    private let collection = "stories"
    
    func uploadStoryImage(with data: Data, withStoryId: String, completion: @escaping (Result<FirebaseStorageUploadStatus,Error>) -> Void) {
        let fileName = "\(withStoryId).png"
        FirestoreService.uploadImage(with: data, fileName: fileName, withChild: "stories/\(withStoryId)/\(fileName)") { result in
            completion(result)
        }
    }
    
    func create(story: Story) throws {
        do {
            try FirestoreService.createDocumentInCollection(object: story, id: story.storyID, collectionName: collection)
        } catch {
            throw error
        }
    }
    
    func getStory(withStoryID: String, completion: @escaping (Story?) -> ()) {
        FirestoreService.getDocument(inCollection: collection, withID: withStoryID) { (story: Story?) in
            if let story = story, let url = URL(string: story.imageUrlString) {
                // Prefetch the image to ensure it's cached
                SDWebImagePrefetcher.shared.prefetchURLs([url])
            }
            completion(story)
        }
    }
    
    func getStories(withEventID: String, completion: @escaping ([Story]?) -> ()) {
        database
            .collection(collection)
            .whereField("eventID", isEqualTo: withEventID)
            .whereField("visibleTill", isGreaterThan: Date())
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot, error == nil else {
                    completion(nil)
                    return
                }
                let myData = snapshot.documents.compactMap { document in
                    try? document.data(as: Story.self)
                }
                // Prefetch all story images for faster loading
                let urls = myData.compactMap { URL(string: $0.imageUrlString) }
                SDWebImagePrefetcher.shared.prefetchURLs(urls)
                completion(myData)
            }
    }
    
    func getFeaturedStories(completion: @escaping ([Story]?) -> ()) {
        database
            .collection(collection)
            .whereField("visibleTill", isGreaterThan: Date())
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot, error == nil else {
                    completion(nil)
                    return
                }
                let allStories = snapshot.documents.compactMap { document in
                    try? document.data(as: Story.self)
                }
                
                // Filter stories that are explicitly marked as featured
                let featuredStories = allStories.filter { story in
                    return story.isFeatured == true
                }
                
                // Prefetch all story images for faster loading
                let urls = featuredStories.compactMap { URL(string: $0.imageUrlString) }
                SDWebImagePrefetcher.shared.prefetchURLs(urls)
                completion(featuredStories)
            }
    }
    
    func isStory(_ story: Story, seenBy userID: String, completion: @escaping (Error?) -> ()) {
        database
            .collection(collection)
            .document(story.storyID)
            .updateData([
                "viewedByUserIDs" : FieldValue.arrayUnion([userID])
            ]) { error in
                completion(error)
            }
    }
    
    func getValidStories(withEventID: String, completion: @escaping ([Story]?) -> ()) {
        Task {
            do {
                let snapshot = try await database
                    .collection(collection)
                    .whereField("eventID", isEqualTo: withEventID)
                    .whereField("visibleTill", isGreaterThan: Date())
                    .getDocuments()
                let stories = snapshot.documents.compactMap { document in
                    try? document.data(as: Story.self)
                }
                // Prefetch all story images for faster loading with options
                let urls = stories.compactMap { URL(string: $0.imageUrlString) }
                
                // Fix: Use SDWebImageOptions enum instead of SDWebImageOption
                let prefetcherOptions: SDWebImageOptions = [
                    .highPriority,
                    .retryFailed,
                    .scaleDownLargeImages
                ]
                
                SDWebImagePrefetcher.shared.prefetchURLs(urls, options: prefetcherOptions, context: nil) { _, _ in
                    // Images are now prefetched
                    DispatchQueue.main.async {
                        completion(stories)
                    }
                }
            } catch {
                completion(nil)
            }
        }
    }
    
    func delete(story: Story, completion: @escaping (Bool) -> ()) {
        database
            .collection(collection)
            .document(story.storyID)
            .delete()
        completion(true)
    }
    
    // MARK: - Like/Unlike Story (Following Seen By Pattern)
    func likeStory(_ story: Story, by userID: String, completion: @escaping (Error?) -> ()) {
        // Ensure we have a valid story ID
        guard !story.storyID.isEmpty else {
            completion(StoryManagerError.invalidStoryID)
            return
        }
        
        // Ensure we have a valid user ID
        guard !userID.isEmpty else {
            completion(StoryManagerError.invalidCreatorID)
            return
        }
        
        database
            .collection(collection)
            .document(story.storyID)
            .updateData([
                "likedByUserIDs": FieldValue.arrayUnion([userID])
            ]) { error in
                completion(error)
            }
    }
    
    func unlikeStory(_ story: Story, by userID: String, completion: @escaping (Error?) -> ()) {
        // Ensure we have a valid story ID
        guard !story.storyID.isEmpty else {
            completion(StoryManagerError.invalidStoryID)
            return
        }
        
        // Ensure we have a valid user ID
        guard !userID.isEmpty else {
            completion(StoryManagerError.invalidCreatorID)
            return
        }
        
        database
            .collection(collection)
            .document(story.storyID)
            .updateData([
                "likedByUserIDs": FieldValue.arrayRemove([userID])
            ]) { error in
                completion(error)
            }
    }
    
    // MARK: - Real-time Story Listener
    func addStoryListener(storyID: String, completion: @escaping (Story?) -> ()) -> FirebaseFirestore.ListenerRegistration {
        return database
            .collection(collection)
            .document(storyID)
            .addSnapshotListener { snapshot, error in
                guard let document = snapshot, error == nil else {
                    completion(nil)
                    return
                }
                
                do {
                    let story = try document.data(as: Story.self)
                    completion(story)
                } catch {
                    completion(nil)
                }
            }
    }
}
