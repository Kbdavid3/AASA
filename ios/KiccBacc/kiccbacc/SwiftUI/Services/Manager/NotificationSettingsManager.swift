//
//  NotificationSettingsManager.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import Foundation
import FirebaseFirestore
import UserNotifications

class NotificationSettingsManager: ObservableObject {
    static let shared = NotificationSettingsManager()
    
    private let database = Firestore.firestore()
    
    @Published var notificationSettings: NotificationSettings = NotificationSettings()
    @Published var isLoading: Bool = false
    
    private init() {
        loadNotificationSettings()
    }
    
    // MARK: - Notification Settings Model
    struct NotificationSettings: Codable {
        var userID: String = ""
        var enabledTypes: [NotificationType] = NotificationType.allCases
        var pushNotificationsEnabled: Bool = true
        var inAppNotificationsEnabled: Bool = true
        var soundEnabled: Bool = true
        var vibrationEnabled: Bool = true
        var quietHoursEnabled: Bool = false
        var quietHoursStart: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
        var quietHoursEnd: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
        var lastUpdated: Date = Date()
        
        // Specific notification preferences
        var eventJoinNotifications: Bool = true
        var followNotifications: Bool = true
        var messageNotifications: Bool = true
        var storyNotifications: Bool = true
        var eventCommentNotifications: Bool = true
        var storyReplyNotifications: Bool = true
        var storyLikeNotifications: Bool = true
        var mentionNotifications: Bool = true
        var eventInviteNotifications: Bool = true
        var eventUpdateNotifications: Bool = true
        var eventReminderNotifications: Bool = true
        var eventMilestoneNotifications: Bool = true
        var storyUploadPromptNotifications: Bool = true
        var customHostNotifications: Bool = true
        var eventLeaveNotifications: Bool = true
        var groupChatRemovalNotifications: Bool = true
        var groupChatMessageNotifications: Bool = true
        var groupChatInvitationNotifications: Bool = true
        var groupChatJoinNotifications: Bool = true
        
        func isNotificationTypeEnabled(_ type: NotificationType) -> Bool {
            switch type {
            case .eventJoin:
                return eventJoinNotifications
            case .userFollow:
                return followNotifications
            case .newMessage:
                return messageNotifications
            case .newStory:
                return storyNotifications
            case .eventComment:
                return eventCommentNotifications
            case .storyReply:
                return storyReplyNotifications
            case .storyLike:
                return storyLikeNotifications
            case .userMention:
                return mentionNotifications
            case .eventInvite:
                return eventInviteNotifications
            case .eventUpdate:
                return eventUpdateNotifications
            case .eventReminder:
                return eventReminderNotifications
            case .eventMilestone:
                return eventMilestoneNotifications
            case .storyUploadPrompt:
                return storyUploadPromptNotifications
            case .customHostNotification:
                return customHostNotifications
            case .eventLike:
                return true // Always enabled
            case .eventCancellation:
                return true // Always enabled
            case .eventLeave:
                return eventLeaveNotifications
            case .groupChatRemoval:
                return groupChatRemovalNotifications
            case .groupChatMessage:
                return groupChatMessageNotifications
            case .groupChatInvitation:
                return groupChatInvitationNotifications
            case .groupChatJoin:
                return groupChatJoinNotifications
            }
        }
        
        mutating func setNotificationType(_ type: NotificationType, enabled: Bool) {
            switch type {
            case .eventJoin:
                eventJoinNotifications = enabled
            case .userFollow:
                followNotifications = enabled
            case .newMessage:
                messageNotifications = enabled
            case .newStory:
                storyNotifications = enabled
            case .eventComment:
                eventCommentNotifications = enabled
            case .storyReply:
                storyReplyNotifications = enabled
            case .storyLike:
                storyLikeNotifications = enabled
            case .userMention:
                mentionNotifications = enabled
            case .eventInvite:
                eventInviteNotifications = enabled
            case .eventUpdate:
                eventUpdateNotifications = enabled
            case .eventReminder:
                eventReminderNotifications = enabled
            case .eventMilestone:
                eventMilestoneNotifications = enabled
            case .storyUploadPrompt:
                storyUploadPromptNotifications = enabled
            case .customHostNotification:
                customHostNotifications = enabled
            case .eventLike, .eventCancellation:
                break // These are always enabled
            case .eventLeave:
                eventLeaveNotifications = enabled
            case .groupChatRemoval:
                groupChatRemovalNotifications = enabled
            case .groupChatMessage:
                groupChatMessageNotifications = enabled
            case .groupChatInvitation:
                groupChatInvitationNotifications = enabled
            case .groupChatJoin:
                groupChatJoinNotifications = enabled
            }
        }
        
        // Custom coding keys for Date encoding/decoding
        enum CodingKeys: String, CodingKey {
            case userID, enabledTypes, pushNotificationsEnabled, inAppNotificationsEnabled
            case soundEnabled, vibrationEnabled, quietHoursEnabled, quietHoursStart, quietHoursEnd, lastUpdated
            case eventJoinNotifications, followNotifications, messageNotifications, storyNotifications
            case eventCommentNotifications, storyReplyNotifications, storyLikeNotifications, mentionNotifications, eventInviteNotifications
            case eventUpdateNotifications, eventReminderNotifications, eventMilestoneNotifications
            case storyUploadPromptNotifications, customHostNotifications, eventLeaveNotifications, groupChatRemovalNotifications, groupChatMessageNotifications, groupChatInvitationNotifications, groupChatJoinNotifications
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            userID = try container.decode(String.self, forKey: .userID)
            enabledTypes = try container.decode([NotificationType].self, forKey: .enabledTypes)
            pushNotificationsEnabled = try container.decode(Bool.self, forKey: .pushNotificationsEnabled)
            inAppNotificationsEnabled = try container.decode(Bool.self, forKey: .inAppNotificationsEnabled)
            soundEnabled = try container.decode(Bool.self, forKey: .soundEnabled)
            vibrationEnabled = try container.decode(Bool.self, forKey: .vibrationEnabled)
            quietHoursEnabled = try container.decode(Bool.self, forKey: .quietHoursEnabled)
            
            // Decode dates as TimeInterval
            let startTimeInterval = try container.decode(TimeInterval.self, forKey: .quietHoursStart)
            quietHoursStart = Date(timeIntervalSince1970: startTimeInterval)
            
            let endTimeInterval = try container.decode(TimeInterval.self, forKey: .quietHoursEnd)
            quietHoursEnd = Date(timeIntervalSince1970: endTimeInterval)
            
            let lastUpdatedTimeInterval = try container.decode(TimeInterval.self, forKey: .lastUpdated)
            lastUpdated = Date(timeIntervalSince1970: lastUpdatedTimeInterval)
            
            eventJoinNotifications = try container.decode(Bool.self, forKey: .eventJoinNotifications)
            followNotifications = try container.decode(Bool.self, forKey: .followNotifications)
            messageNotifications = try container.decode(Bool.self, forKey: .messageNotifications)
            storyNotifications = try container.decode(Bool.self, forKey: .storyNotifications)
            eventCommentNotifications = try container.decode(Bool.self, forKey: .eventCommentNotifications)
            storyReplyNotifications = try container.decode(Bool.self, forKey: .storyReplyNotifications)
            storyLikeNotifications = try container.decodeIfPresent(Bool.self, forKey: .storyLikeNotifications) ?? true
            mentionNotifications = try container.decode(Bool.self, forKey: .mentionNotifications)
            eventInviteNotifications = try container.decode(Bool.self, forKey: .eventInviteNotifications)
            eventUpdateNotifications = try container.decode(Bool.self, forKey: .eventUpdateNotifications)
            eventReminderNotifications = try container.decode(Bool.self, forKey: .eventReminderNotifications)
            eventMilestoneNotifications = try container.decode(Bool.self, forKey: .eventMilestoneNotifications)
            storyUploadPromptNotifications = try container.decode(Bool.self, forKey: .storyUploadPromptNotifications)
            customHostNotifications = try container.decode(Bool.self, forKey: .customHostNotifications)
            eventLeaveNotifications = try container.decodeIfPresent(Bool.self, forKey: .eventLeaveNotifications) ?? true
            groupChatRemovalNotifications = try container.decodeIfPresent(Bool.self, forKey: .groupChatRemovalNotifications) ?? true
            groupChatMessageNotifications = try container.decodeIfPresent(Bool.self, forKey: .groupChatMessageNotifications) ?? true
            groupChatInvitationNotifications = try container.decodeIfPresent(Bool.self, forKey: .groupChatInvitationNotifications) ?? true
            groupChatJoinNotifications = try container.decodeIfPresent(Bool.self, forKey: .groupChatJoinNotifications) ?? true
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(userID, forKey: .userID)
            try container.encode(enabledTypes, forKey: .enabledTypes)
            try container.encode(pushNotificationsEnabled, forKey: .pushNotificationsEnabled)
            try container.encode(inAppNotificationsEnabled, forKey: .inAppNotificationsEnabled)
            try container.encode(soundEnabled, forKey: .soundEnabled)
            try container.encode(vibrationEnabled, forKey: .vibrationEnabled)
            try container.encode(quietHoursEnabled, forKey: .quietHoursEnabled)
            
            // Encode dates as TimeInterval
            try container.encode(quietHoursStart.timeIntervalSince1970, forKey: .quietHoursStart)
            try container.encode(quietHoursEnd.timeIntervalSince1970, forKey: .quietHoursEnd)
            try container.encode(lastUpdated.timeIntervalSince1970, forKey: .lastUpdated)
            
            try container.encode(eventJoinNotifications, forKey: .eventJoinNotifications)
            try container.encode(followNotifications, forKey: .followNotifications)
            try container.encode(messageNotifications, forKey: .messageNotifications)
            try container.encode(storyNotifications, forKey: .storyNotifications)
            try container.encode(eventCommentNotifications, forKey: .eventCommentNotifications)
            try container.encode(storyReplyNotifications, forKey: .storyReplyNotifications)
            try container.encode(storyLikeNotifications, forKey: .storyLikeNotifications)
            try container.encode(mentionNotifications, forKey: .mentionNotifications)
            try container.encode(eventInviteNotifications, forKey: .eventInviteNotifications)
            try container.encode(eventUpdateNotifications, forKey: .eventUpdateNotifications)
            try container.encode(eventReminderNotifications, forKey: .eventReminderNotifications)
            try container.encode(eventMilestoneNotifications, forKey: .eventMilestoneNotifications)
            try container.encode(storyUploadPromptNotifications, forKey: .storyUploadPromptNotifications)
            try container.encode(customHostNotifications, forKey: .customHostNotifications)
            try container.encode(eventLeaveNotifications, forKey: .eventLeaveNotifications)
            try container.encode(groupChatRemovalNotifications, forKey: .groupChatRemovalNotifications)
            try container.encode(groupChatMessageNotifications, forKey: .groupChatMessageNotifications)
            try container.encode(groupChatInvitationNotifications, forKey: .groupChatInvitationNotifications)
            try container.encode(groupChatJoinNotifications, forKey: .groupChatJoinNotifications)
        }
        
        init() {
            // Default initializer
        }
    }
    
    // MARK: - Public Methods
    
    func loadNotificationSettings() {
        guard let currentUserID = UserManager.shared.currentUserID else { return }
        
        isLoading = true
        
        database.collection("notificationSettings")
            .document(currentUserID)
            .getDocument { [weak self] document, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let document = document, document.exists {
                        do {
                            let data = document.data() ?? [:]
                            let jsonData = try JSONSerialization.data(withJSONObject: data)
                            let settings = try JSONDecoder().decode(NotificationSettings.self, from: jsonData)
                            self?.notificationSettings = settings
                        } catch {
                            print("Error decoding notification settings: \(error)")
                            self?.createDefaultSettings()
                        }
                    } else {
                        self?.createDefaultSettings()
                    }
                }
            }
    }
    
    func saveNotificationSettings() {
        guard let currentUserID = UserManager.shared.currentUserID else { return }
        
        notificationSettings.userID = currentUserID
        notificationSettings.lastUpdated = Date()
        
        do {
            let data = try JSONEncoder().encode(notificationSettings)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            database.collection("notificationSettings")
                .document(currentUserID)
                .setData(dict) { error in
                    if let error = error {
                        print("Error saving notification settings: \(error)")
                    }
                }
        } catch {
            print("Error encoding notification settings: \(error)")
        }
    }
    
    func updateNotificationType(_ type: NotificationType, enabled: Bool) {
        var updatedSettings = notificationSettings
        updatedSettings.setNotificationType(type, enabled: enabled)
        notificationSettings = updatedSettings
        saveNotificationSettings()
    }
    
    func updatePushNotificationsEnabled(_ enabled: Bool) {
        var updatedSettings = notificationSettings
        updatedSettings.pushNotificationsEnabled = enabled
        notificationSettings = updatedSettings
        saveNotificationSettings()
    }
    
    func updateInAppNotificationsEnabled(_ enabled: Bool) {
        var updatedSettings = notificationSettings
        updatedSettings.inAppNotificationsEnabled = enabled
        notificationSettings = updatedSettings
        saveNotificationSettings()
    }
    
    func updateSoundEnabled(_ enabled: Bool) {
        var updatedSettings = notificationSettings
        updatedSettings.soundEnabled = enabled
        notificationSettings = updatedSettings
        saveNotificationSettings()
    }
    
    func updateVibrationEnabled(_ enabled: Bool) {
        var updatedSettings = notificationSettings
        updatedSettings.vibrationEnabled = enabled
        notificationSettings = updatedSettings
        saveNotificationSettings()
    }
    
    func updateQuietHoursEnabled(_ enabled: Bool) {
        var updatedSettings = notificationSettings
        updatedSettings.quietHoursEnabled = enabled
        notificationSettings = updatedSettings
        saveNotificationSettings()
    }
    
    func updateQuietHours(start: Date, end: Date) {
        var updatedSettings = notificationSettings
        updatedSettings.quietHoursStart = start
        updatedSettings.quietHoursEnd = end
        notificationSettings = updatedSettings
        saveNotificationSettings()
    }
    
    func shouldSendNotification(_ type: NotificationType) -> Bool {
        // Check if notifications are globally enabled
        guard notificationSettings.pushNotificationsEnabled || notificationSettings.inAppNotificationsEnabled else {
            return false
        }
        
        // Check if this specific notification type is enabled
        guard notificationSettings.isNotificationTypeEnabled(type) else {
            return false
        }
        
        // Check quiet hours
        if notificationSettings.quietHoursEnabled {
            let now = Date()
            let calendar = Calendar.current
            let currentTime = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
            let startTime = calendar.component(.hour, from: notificationSettings.quietHoursStart) * 60 + calendar.component(.minute, from: notificationSettings.quietHoursStart)
            let endTime = calendar.component(.hour, from: notificationSettings.quietHoursEnd) * 60 + calendar.component(.minute, from: notificationSettings.quietHoursEnd)
            
            if startTime > endTime {
                // Quiet hours span midnight
                if currentTime >= startTime || currentTime <= endTime {
                    return false
                }
            } else {
                // Quiet hours within same day
                if currentTime >= startTime && currentTime <= endTime {
                    return false
                }
            }
        }
        
        return true
    }
    
    func getNotificationPresentationOptions() -> UNNotificationPresentationOptions {
        var options: UNNotificationPresentationOptions = []
        
        if notificationSettings.inAppNotificationsEnabled {
            options.insert(.banner)
        }
        
        if notificationSettings.soundEnabled {
            options.insert(.sound)
        }
        
        if notificationSettings.vibrationEnabled {
            options.insert(.badge)
        }
        
        return options
    }
    
    // MARK: - Private Methods
    
    private func createDefaultSettings() {
        guard let currentUserID = UserManager.shared.currentUserID else { return }
        
        var defaultSettings = NotificationSettings()
        defaultSettings.userID = currentUserID
        
        notificationSettings = defaultSettings
        saveNotificationSettings()
    }
    
    func resetToDefaults() {
        createDefaultSettings()
    }
    
    func exportSettings() -> [String: Any] {
        do {
            let data = try JSONEncoder().encode(notificationSettings)
            return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        } catch {
            print("Error exporting notification settings: \(error)")
            return [:]
        }
    }
    
    func importSettings(_ settings: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: settings)
            let importedSettings = try JSONDecoder().decode(NotificationSettings.self, from: jsonData)
            notificationSettings = importedSettings
            saveNotificationSettings()
        } catch {
            print("Error importing notification settings: \(error)")
        }
    }
}
