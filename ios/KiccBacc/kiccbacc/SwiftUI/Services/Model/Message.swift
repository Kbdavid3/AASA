//
//  Message.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 22/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation
import FirebaseFirestore

struct Message: Codable, Hashable, Identifiable {
    @DocumentID var id: String? = UUID().uuidString
    var storyID: String?
    var messageID: String
    var senderID: String
    var receiverID: String
    var content: String
    var createdAt: Date
}

extension Message {
    init() {
        self.init(storyID: nil, messageID: "faskjhfjk", senderID: "fkjwfk", receiverID: "fsfjkh", content: "This a demo Message", createdAt: Date())
    }

    init(messageID: String, senderID: String, receiverID: String, content: String) {
        self.init(messageID: messageID, senderID: senderID, receiverID: receiverID, content: content, createdAt: Date())
    }
    
    init(storyID: String, messageID: String, senderID: String, receiverID: String, content: String) {
        self.init(storyID: storyID, messageID: messageID, senderID: senderID, receiverID: receiverID, content: content, createdAt: Date())
    }
}
