//
//  Chat.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 22/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation

struct ChatRoom: Codable, Hashable {
    var roomID: String
    var participantsIDs: [String]
    var lastMessage: String?
    var lastMessageTime: Date?
    var createdAt: Date
}

extension ChatRoom {
    init() {
        self.init(roomID: "93B995AE-4208-4759-BA22-68F7DA73CE20", participantsIDs: ["9WTd6YoKSBU5oUUz8dogkbem1S02", "v85ircMMQYhtBr6U2QWtl7dl04E2"], lastMessage: "InitialisationHelper.string", lastMessageTime: Date(), createdAt: Date())
    }
    
    // without optionals
    init(roomID: String, participantsIDs: [String]) {
        self.init(roomID: roomID, participantsIDs: participantsIDs, createdAt: Date())
    }
}

extension ChatRoom {
    var otherUserID: String? {
        if let currentUserID = UserManager.shared.currentUserID {
            let ids = participantsIDs.filter {
                $0 != currentUserID
            }
            
            return ids.first
        }
        
        return nil
    }
    
    /// Returns true if this is a group chat (event-based chat with multiple participants)
    var isGroupChat: Bool {
        return roomID.hasPrefix("event-") || participantsIDs.count > 2
    }
    
    /// Returns true if this is a direct message (1-on-1 chat)
    var isDirectMessage: Bool {
        return !isGroupChat && participantsIDs.count == 2
    }
}
