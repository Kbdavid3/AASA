//
//  Story.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 22/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation
import SwiftUI

struct Story: Codable, Equatable {
    var storyID: String
    var creatorID: String
    var eventID: String
    var viewedByUserIDs: [String]
    var imageUrlString: String
    var visibleTill: Date
    var createdAt: Date
    var isFeatured: Bool = false // New field for featured stories
    var likedByUserIDs: [String]? = [] // New field for users who liked the story
    
    var imageURL: URL? {
        return URL(string: imageUrlString)
    }
    
    // Computed property for like count (following seen by pattern)
    var likeCount: Int {
        return likedByUserIDs?.count ?? 0
    }
    
    // Computed property to check if current user has liked this story
    var isLikedByCurrentUser: Bool {
        guard let currentUserID = UserManager.shared.currentUserID,
              let likedByUserIDs = likedByUserIDs else { 
            return false 
        }
        return likedByUserIDs.contains(currentUserID)
    }
}

extension Story {
    init() {
        self.init(storyID: "sajhfkahfkwhefwg81748918wudj", creatorID: "v85ircMMQYhtBr6U2QWtl7dl04E0", eventID: "5A2403C5-CFDD-4CA8-BFDD-1C40FD2F3ADF", viewedByUserIDs: ["v85ircMMQ0E2"], imageUrlString: "https://firebasestorage.googleapis.com/v0/b/kiccbacc-b538e.appspot.com/o/stories%2F505A505D-0B1E-491B-81CB-2B199DDF82A4%2F505A505D-0B1E-491B-81CB-2B199DDF82A4.png?alt=media&token=f99ff0af-9c5f-4a63-9b74-661383751d40", visibleTill: Date(), createdAt: Date(), isFeatured: false, likedByUserIDs: [])
    }
}

struct StoriesByUser: Identifiable, Equatable {
    var id: String? = UUID().uuidString
    var userID: String
    var stories: [Story]
}

extension StoriesByUser {
    init() {
        self.init(userID: "v85ircMMQYhtBr6U2QWtl7dl04E2", stories: [Story(), Story()])
    }
}
