//
//  EnhancedNotification.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import Foundation
import FirebaseFirestore

struct EnhancedNotification: Codable, Identifiable {
    var id: String { notificationID }
    
    var notificationID: String
    var type: NotificationType
    var title: String
    var body: String
    var imageUrl: String?
    var senderID: String?
    var receiverID: String
    var eventID: String?
    var createdAt: Date
    var scheduledFor: Date?
    var isRead: Bool = false
    var metadata: [String: String]?
    
    // For milestone notifications
    var milestoneType: MilestoneType?
    var milestoneCount: Int?
    
    // For host notifications
    var isHostNotification: Bool = false
    var targetAudience: NotificationAudience = .eventJoinees
    
    // Custom decoder to handle Timestamp conversion
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        notificationID = try container.decode(String.self, forKey: .notificationID)
        type = try container.decode(NotificationType.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        senderID = try container.decodeIfPresent(String.self, forKey: .senderID)
        receiverID = try container.decode(String.self, forKey: .receiverID)
        eventID = try container.decodeIfPresent(String.self, forKey: .eventID)
        isRead = try container.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)
        milestoneType = try container.decodeIfPresent(MilestoneType.self, forKey: .milestoneType)
        milestoneCount = try container.decodeIfPresent(Int.self, forKey: .milestoneCount)
        isHostNotification = try container.decodeIfPresent(Bool.self, forKey: .isHostNotification) ?? false
        targetAudience = try container.decodeIfPresent(NotificationAudience.self, forKey: .targetAudience) ?? .eventJoinees
        scheduledFor = try container.decodeIfPresent(Date.self, forKey: .scheduledFor)
        
        // Handle createdAt date conversion
        if let timeInterval = try? container.decode(TimeInterval.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: timeInterval)
        } else {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }
    }
    
    init(notificationID: String, type: NotificationType, title: String, body: String, senderID: String?, receiverID: String, eventID: String? = nil) {
        self.notificationID = notificationID
        self.type = type
        self.title = title
        self.body = body
        self.imageUrl = nil
        self.senderID = senderID
        self.receiverID = receiverID
        self.eventID = eventID
        self.createdAt = Date()
        self.scheduledFor = nil
        self.isRead = false
        self.metadata = nil
        self.milestoneType = nil
        self.milestoneCount = nil
        self.isHostNotification = false
        self.targetAudience = .eventJoinees
    }
    
    init(notificationID: String, type: NotificationType, title: String, body: String, senderID: String?, receiverID: String, eventID: String?, scheduledFor: Date?) {
        self.init(notificationID: notificationID, type: type, title: title, body: body, senderID: senderID, receiverID: receiverID, eventID: eventID)
        self.scheduledFor = scheduledFor
    }
    
    init(notificationID: String, type: NotificationType, title: String, body: String, senderID: String?, receiverID: String, eventID: String?, milestoneType: MilestoneType, milestoneCount: Int) {
        self.init(notificationID: notificationID, type: type, title: title, body: body, senderID: senderID, receiverID: receiverID, eventID: eventID)
        self.milestoneType = milestoneType
        self.milestoneCount = milestoneCount
    }
}

enum NotificationAudience: String, Codable, CaseIterable {
    case eventJoinees = "event_joinees"
    case everyone = "everyone"
    case specificUsers = "specific_users"
    
    var displayName: String {
        switch self {
        case .eventJoinees:
            return "Event Joinees Only"
        case .everyone:
            return "Everyone"
        case .specificUsers:
            return "Specific Users"
        }
    }
    
    var description: String {
        switch self {
        case .eventJoinees:
            return "Send to people who have shown interest in the event"
        case .everyone:
            return "Send to all users of the app"
        case .specificUsers:
            return "Send to specific users you select"
        }
    }
}

struct HostNotificationSettings: Codable {
    var eventID: String
    var hostID: String
    var enabledTypes: [NotificationType]
    var defaultAudience: NotificationAudience
    var autoMilestoneNotifications: Bool = true
    var storyUploadPrompts: Bool = true
    var customNotificationText: String?
    var lastUpdated: Date
    
    init(eventID: String, hostID: String) {
        self.eventID = eventID
        self.hostID = hostID
        self.enabledTypes = NotificationType.allCases
        self.defaultAudience = .eventJoinees
        self.autoMilestoneNotifications = true
        self.storyUploadPrompts = true
        self.customNotificationText = nil
        self.lastUpdated = Date()
    }
}

struct ScheduledNotification: Codable, Identifiable {
    var id: String { notificationID }
    
    var notificationID: String
    var eventID: String
    var hostID: String
    var title: String
    var body: String
    var scheduledFor: Date
    var targetAudience: NotificationAudience
    var targetUserIDs: [String]?
    var isSent: Bool = false
    var createdAt: Date
    
    init(notificationID: String, eventID: String, hostID: String, title: String, body: String, scheduledFor: Date, targetAudience: NotificationAudience, targetUserIDs: [String]? = nil) {
        self.notificationID = notificationID
        self.eventID = eventID
        self.hostID = hostID
        self.title = title
        self.body = body
        self.scheduledFor = scheduledFor
        self.targetAudience = targetAudience
        self.targetUserIDs = targetUserIDs
        self.isSent = false
        self.createdAt = Date()
    }
}
