//
//  Notification.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 20/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import SwiftUI

struct InAppNotification: Codable, Hashable {
    var notificationID: String
    var title: String?
    var body: String
    var imageUrl: String?
    var senderID: String?
    var receiverID: String
    var createdAt: Date
}

extension InAppNotification {
    init(notificationID: String, title: String, body: String, senderID: String?, receiverID: String) {
        self.init(notificationID: notificationID, title: title, body: body, imageUrl: nil, senderID: senderID, receiverID: receiverID, createdAt: Date())
    }
    
    init(notificationID: String, body: String, senderID: String?, receiverID: String) {
        self.init(notificationID: notificationID, title: nil, body: body, imageUrl: nil, senderID: senderID, receiverID: receiverID, createdAt: Date())
    }
}

extension InAppNotification {
    var notificationTime: String {
        Date().getRelativeDate(from: self.createdAt)
    }
}
