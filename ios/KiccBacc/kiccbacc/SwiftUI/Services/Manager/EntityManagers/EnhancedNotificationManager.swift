//
//  EnhancedNotificationManager.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 09/03/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseMessaging
import UserNotifications
import UIKit

// MARK: - Notification Audience
enum NotificationAudience: String, Codable, CaseIterable {
    case eventJoinees = "event_joinees"
    case everyone = "everyone"
    case specificUsers = "specific_users"
}

// MARK: - Enhanced Notification Structure
struct EnhancedNotification: Codable, Identifiable {
    var id: String { notificationID }
    
    var notificationID: String
    var type: NotificationType
    var title: String
    var body: String
    var senderID: String?
    var receiverID: String
    var eventID: String?
    var createdAt: Date
    var isRead: Bool
    
    init(notificationID: String, type: NotificationType, title: String, body: String, senderID: String?, receiverID: String, eventID: String? = nil) {
        self.notificationID = notificationID
        self.type = type
        self.title = title
        self.body = body
        self.senderID = senderID
        self.receiverID = receiverID
        self.eventID = eventID
        self.createdAt = Date()
        self.isRead = false
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
    var isSent: Bool
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

// MARK: - Enhanced Notification Manager
class EnhancedNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = EnhancedNotificationManager()
    
    private let database = Firestore.firestore()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    @Published var unreadNotifications: [EnhancedNotification] = []
    @Published var allNotifications: [EnhancedNotification] = []
    @Published var unreadCount: Int = 0
    
    private override init() {
        super.init()
        setupNotificationCenter()
        loadNotifications()
    }
    
    // MARK: - Setup
    private func setupNotificationCenter() {
        notificationCenter.delegate = self
        requestNotificationPermissions()
    }
    
    private func requestNotificationPermissions() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                    print("Notification permissions granted")
                } else {
                    print("Notification permissions denied")
                }
            }
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    // MARK: - Notification Creation and Sending
    
    /// Send notification when someone joins an event
    func sendEventJoinNotification(eventID: String, joinerID: String, eventTitle: String, completion: @escaping (Bool) -> Void) {
        print("🔔 sendEventJoinNotification called with eventID: \(eventID), joinerID: \(joinerID), eventTitle: \(eventTitle)")
        
        // Get the event to find the host
        EventManager.shared.getEvent(with: eventID) { event in
            guard let event = event, let hostID = event.hostIDs.first else {
                print("❌ Failed to get event or hostID for event: \(eventID)")
                completion(false)
                return
            }
            
            print("✅ Found event host: \(hostID)")
            print("🔍 Current user ID: \(UserManager.shared.currentUserID ?? "nil")")
            print("🔍 Is notification for current user? \(hostID == UserManager.shared.currentUserID)")
            
            UserManager.shared.getUser(withUserID: joinerID) { joiner in
                guard let joiner = joiner else {
                    print("❌ Failed to get joiner user: \(joinerID)")
                    completion(false)
                    return
                }
                
                print("✅ Found joiner: \(joiner.fullName)")
                
                let notification = EnhancedNotification(
                    notificationID: UUID().uuidString,
                    type: .eventJoin,
                    title: "New Event Join",
                    body: "\(joiner.fullName) joined your event '\(eventTitle)'",
                    senderID: joinerID,
                    receiverID: hostID,
                    eventID: eventID
                )
                
                print("📝 Created notification: \(notification.notificationID)")
                print("📊 Notification details: sender=\(notification.senderID ?? "nil"), receiver=\(notification.receiverID), event=\(notification.eventID ?? "nil")")
                
                self.createAndSendNotification(notification) { success in
                    print("📤 Notification send result: \(success)")
                    
                    // Force reload notifications after sending
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("🔄 Force reloading notifications after sending")
                        self.loadNotifications()
                    }
                    
                    completion(success)
                }
            }
        }
    }
    
    /// Send notification when someone leaves an event
    func sendEventLeaveNotification(eventID: String, leaverID: String, eventTitle: String, completion: @escaping (Bool) -> Void) {
        print("🔔 sendEventLeaveNotification called with eventID: \(eventID), leaverID: \(leaverID), eventTitle: \(eventTitle)")
        
        // Get the event to find the host
        EventManager.shared.getEvent(with: eventID) { event in
            guard let event = event, let hostID = event.hostIDs.first else {
                print("❌ Failed to get event or hostID for event: \(eventID)")
                completion(false)
                return
            }
            
            // Don't send notification if the host is leaving their own event
            guard hostID != leaverID else {
                print("ℹ️ Host is leaving their own event, no notification needed")
                completion(true)
                return
            }
            
            UserManager.shared.getUser(withUserID: leaverID) { leaver in
                guard let leaver = leaver else {
                    print("❌ Failed to get leaver user: \(leaverID)")
                    completion(false)
                    return
                }
                
                print("✅ Found leaver: \(leaver.fullName)")
                
                let notification = EnhancedNotification(
                    notificationID: UUID().uuidString,
                    type: .eventLeave,
                    title: "Event Leave",
                    body: "\(leaver.fullName) left your event '\(eventTitle)'",
                    senderID: leaverID,
                    receiverID: hostID,
                    eventID: eventID
                )
                
                print("📝 Created leave notification: \(notification.notificationID)")
                
                self.createAndSendNotification(notification) { success in
                    print("📤 Leave notification send result: \(success)")
                    
                    // Force reload notifications after sending
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.loadNotifications()
                    }
                    
                    completion(success)
                }
            }
        }
    }
    
    /// Send notification when someone follows a user
    func sendFollowNotification(followerID: String, followedUserID: String, completion: @escaping (Bool) -> Void) {
        UserManager.shared.getUser(withUserID: followerID) { follower in
            guard let follower = follower else {
                completion(false)
                return
            }
            
            let notification = EnhancedNotification(
                notificationID: UUID().uuidString,
                type: .userFollow,
                title: "New Follower",
                body: "\(follower.fullName) started following you",
                senderID: followerID,
                receiverID: followedUserID
            )
            
            self.createAndSendNotification(notification) { success in
                completion(success)
            }
        }
    }
    
    /// Send notification when someone sends a message
    func sendMessageNotification(senderID: String, receiverID: String, messageContent: String, completion: @escaping (Bool) -> Void) {
        UserManager.shared.getUser(withUserID: senderID) { sender in
            guard let sender = sender else {
                completion(false)
                return
            }
            
            let truncatedMessage = messageContent.count > 50 ? String(messageContent.prefix(50)) + "..." : messageContent
            
            let notification = EnhancedNotification(
                notificationID: UUID().uuidString,
                type: .newMessage,
                title: "New Message from \(sender.fullName)",
                body: truncatedMessage,
                senderID: senderID,
                receiverID: receiverID
            )
            
            self.createAndSendNotification(notification) { success in
                completion(success)
            }
        }
    }
    
    /// Send notification when someone posts a new story
    func sendNewStoryNotification(storyCreatorID: String, storyID: String, completion: @escaping (Bool) -> Void) {
        UserManager.shared.getUser(withUserID: storyCreatorID) { creator in
            guard let creator = creator else {
                completion(false)
                return
            }
            
            let notification = EnhancedNotification(
                notificationID: UUID().uuidString,
                type: .newStory,
                title: "New Story",
                body: "\(creator.fullName) posted a new story",
                senderID: storyCreatorID,
                receiverID: "", // Will be set for each follower
                eventID: nil
            )
            
            // Get all followers of the story creator and send notifications
            self.getFollowersAndSendNotification(notification, creatorID: storyCreatorID) { success in
                completion(success)
            }
        }
    }
    
    /// Send notification when someone comments on an event
    func sendEventCommentNotification(commenterID: String, eventID: String, eventTitle: String, comment: String, completion: @escaping (Bool) -> Void) {
        UserManager.shared.getUser(withUserID: commenterID) { commenter in
            guard let commenter = commenter else {
                completion(false)
                return
            }
            
            let truncatedComment = comment.count > 50 ? String(comment.prefix(50)) + "..." : comment
            
            let notification = EnhancedNotification(
                notificationID: UUID().uuidString,
                type: .eventComment,
                title: "New Comment on '\(eventTitle)'",
                body: "\(commenter.fullName): \(truncatedComment)",
                senderID: commenterID,
                receiverID: "", // Will be set for event creator
                eventID: eventID
            )
            
            self.createAndSendNotification(notification) { success in
                completion(success)
            }
        }
    }
    
    /// Send notification when someone replies to a story
    func sendStoryReplyNotification(replierID: String, storyID: String, replyContent: String, completion: @escaping (Bool) -> Void) {
        // First get the replier's info
        UserManager.shared.getUser(withUserID: replierID) { replier in
            guard let replier = replier else {
                print("❌ Story reply notification failed: Replier not found")
                completion(false)
                return
            }
            
            // Then get the story to find the creator - dispatch to main actor
            Task { @MainActor in
                StoryManager.shared.getStory(withStoryID: storyID) { story in
                    guard let story = story else {
                        print("❌ Story reply notification failed: Story not found")
                        completion(false)
                        return
                    }
                    
                    let truncatedReply = replyContent.count > 50 ? String(replyContent.prefix(50)) + "..." : replyContent
                    
                    let notification = EnhancedNotification(
                        notificationID: UUID().uuidString,
                        type: .storyReply,
                        title: "Story Reply",
                        body: "\(replier.fullName) replied to your story: \(truncatedReply)",
                        senderID: replierID,
                        receiverID: story.creatorID, // Use the actual story creator ID
                        eventID: story.eventID
                    )
                    
                    print("✅ Story reply notification created - Receiver: \(story.creatorID)")
                    
                    self.createAndSendNotification(notification) { success in
                        completion(success)
                    }
                }
            }
        }
    }
    
    /// Send notification when someone mentions a user
    func sendUserMentionNotification(mentionerID: String, mentionedUserID: String, context: String, completion: @escaping (Bool) -> Void) {
        UserManager.shared.getUser(withUserID: mentionerID) { mentioner in
            guard let mentioner = mentioner else {
                completion(false)
                return
            }
            
            let notification = EnhancedNotification(
                notificationID: UUID().uuidString,
                type: .userMention,
                title: "You were mentioned",
                body: "\(mentioner.fullName) mentioned you: \(context)",
                senderID: mentionerID,
                receiverID: mentionedUserID
            )
            
            self.createAndSendNotification(notification) { success in
                completion(success)
            }
        }
    }
    
    /// Send notification when someone likes a story
    func sendStoryLikeNotification(likerID: String, storyCreatorID: String, storyID: String, completion: @escaping (Bool) -> Void) {
        print("🔔 EnhancedNotificationManager.sendStoryLikeNotification called")
        print("📊 Liker ID: \(likerID)")
        print("📊 Story Creator ID: \(storyCreatorID)")
        print("📊 Story ID: \(storyID)")
        
        // Validate inputs
        guard !likerID.isEmpty else {
            print("❌ Liker ID is empty")
            completion(false)
            return
        }
        
        guard !storyCreatorID.isEmpty else {
            print("❌ Story Creator ID is empty")
            completion(false)
            return
        }
        
        guard !storyID.isEmpty else {
            print("❌ Story ID is empty")
            completion(false)
            return
        }
        
        UserManager.shared.getUser(withUserID: likerID) { liker in
            guard let liker = liker else {
                print("❌ Story like notification failed: Liker not found")
                completion(false)
                return
            }
            
            print("✅ Found liker: \(liker.fullName)")
            
            let notification = EnhancedNotification(
                notificationID: UUID().uuidString,
                type: .storyLike,
                title: "Story Like",
                body: "\(liker.fullName) liked your story",
                senderID: likerID,
                receiverID: storyCreatorID,
                eventID: nil
            )
            
            print("✅ Story like notification created - Receiver: \(storyCreatorID)")
            print("📝 Notification details: \(notification.notificationID)")
            print("📝 Notification receiverID: \(notification.receiverID)")
            
            self.createAndSendNotification(notification) { success in
                print("📤 createAndSendNotification result: \(success)")
                completion(success)
            }
        }
    }
    
    /// Send notification when a user is removed from a group chat
    func sendGroupChatRemovalNotification(removedUserID: String, eventName: String, removerID: String, completion: @escaping (Bool) -> Void) {
        print("🔄 Sending group chat removal notification")
        print("📊 Removed User ID: \(removedUserID)")
        print("📊 Event Name: \(eventName)")
        print("📊 Remover ID: \(removerID)")
        
        // Validate inputs
        guard !removedUserID.isEmpty else {
            print("❌ Removed user ID is empty")
            completion(false)
            return
        }
        
        guard !eventName.isEmpty else {
            print("❌ Event name is empty")
            completion(false)
            return
        }
        
        guard !removerID.isEmpty else {
            print("❌ Remover ID is empty")
            completion(false)
            return
        }
        
        UserManager.shared.getUser(withUserID: removerID) { remover in
            guard let remover = remover else {
                print("❌ Group chat removal notification failed: Remover not found")
                completion(false)
                return
            }
            
            print("✅ Found remover: \(remover.fullName)")
            
            let notification = EnhancedNotification(
                notificationID: UUID().uuidString,
                type: .groupChatRemoval,
                title: "Removed from Group Chat",
                body: "\(remover.fullName) removed you from the \(eventName) group chat",
                senderID: removerID,
                receiverID: removedUserID,
                eventID: nil
            )
            
            print("✅ Group chat removal notification created - Receiver: \(removedUserID)")
            print("📝 Notification details: \(notification.notificationID)")
            print("📝 Notification receiverID: \(notification.receiverID)")
            
            self.createAndSendNotification(notification) { success in
                print("📤 createAndSendNotification result: \(success)")
                completion(success)
            }
        }
    }
    
    /// Send notification when a new message is sent in a group chat
    func sendGroupChatMessageNotification(senderID: String, eventName: String, messageContent: String, participantIDs: [String], completion: @escaping (Bool) -> Void) {
        print("🔄 Sending group chat message notifications")
        print("📊 Sender ID: \(senderID)")
        print("📊 Event Name: \(eventName)")
        print("📊 Message: \(messageContent)")
        print("📊 Participants: \(participantIDs.count)")
        
        // Validate inputs
        guard !senderID.isEmpty else {
            print("❌ Sender ID is empty")
            completion(false)
            return
        }
        
        guard !eventName.isEmpty else {
            print("❌ Event name is empty")
            completion(false)
            return
        }
        
        guard !messageContent.isEmpty else {
            print("❌ Message content is empty")
            completion(false)
            return
        }
        
        UserManager.shared.getUser(withUserID: senderID) { sender in
            guard let sender = sender else {
                print("❌ Group chat message notification failed: Sender not found")
                completion(false)
                return
            }
            
            print("✅ Found sender: \(sender.fullName)")
            
            // Send notification to all participants except the sender
            let recipients = participantIDs.filter { $0 != senderID }
            var successCount = 0
            let totalRecipients = recipients.count
            
            if totalRecipients == 0 {
                print("ℹ️ No recipients to notify")
                completion(true)
                return
            }
            
            for recipientID in recipients {
                let notification = EnhancedNotification(
                    notificationID: UUID().uuidString,
                    type: .groupChatMessage,
                    title: "New Message in \(eventName)",
                    body: "\(sender.fullName): \(messageContent)",
                    senderID: senderID,
                    receiverID: recipientID,
                    eventID: nil
                )
                
                self.createAndSendNotification(notification) { success in
                    if success {
                        successCount += 1
                    }
                    
                    // Check if all notifications are complete
                    if successCount + (totalRecipients - successCount) == totalRecipients {
                        let overallSuccess = successCount > 0
                        print("📤 Group chat message notifications: \(successCount)/\(totalRecipients) sent")
                        completion(overallSuccess)
                    }
                }
            }
        }
    }
    
    /// Send notification when someone is invited to a group chat
    func sendGroupChatInvitationNotification(invitedUserID: String, eventName: String, inviterID: String, completion: @escaping (Bool) -> Void) {
        print("🔄 Sending group chat invitation notification")
        print("📊 Invited User ID: \(invitedUserID)")
        print("📊 Event Name: \(eventName)")
        print("📊 Inviter ID: \(inviterID)")
        
        // Validate inputs
        guard !invitedUserID.isEmpty else {
            print("❌ Invited user ID is empty")
            completion(false)
            return
        }
        
        guard !eventName.isEmpty else {
            print("❌ Event name is empty")
            completion(false)
            return
        }
        
        guard !inviterID.isEmpty else {
            print("❌ Inviter ID is empty")
            completion(false)
            return
        }
        
        UserManager.shared.getUser(withUserID: inviterID) { inviter in
            guard let inviter = inviter else {
                print("❌ Group chat invitation notification failed: Inviter not found")
                completion(false)
                return
            }
            
            print("✅ Found inviter: \(inviter.fullName)")
            
            let notification = EnhancedNotification(
                notificationID: UUID().uuidString,
                type: .groupChatInvitation,
                title: "Group Chat Invitation",
                body: "\(inviter.fullName) added you to the \(eventName) group chat",
                senderID: inviterID,
                receiverID: invitedUserID,
                eventID: nil
            )
            
            print("✅ Group chat invitation notification created - Receiver: \(invitedUserID)")
            print("📝 Notification details: \(notification.notificationID)")
            print("📝 Notification receiverID: \(notification.receiverID)")
            
            self.createAndSendNotification(notification) { success in
                print("📤 createAndSendNotification result: \(success)")
                completion(success)
            }
        }
    }
    
    /// Send notification when someone joins a group chat
    func sendGroupChatJoinNotification(joinedUserID: String, eventName: String, participantIDs: [String], completion: @escaping (Bool) -> Void) {
        print("🔄 Sending group chat join notifications")
        print("📊 Joined User ID: \(joinedUserID)")
        print("📊 Event Name: \(eventName)")
        print("📊 Participants: \(participantIDs.count)")
        
        // Validate inputs
        guard !joinedUserID.isEmpty else {
            print("❌ Joined user ID is empty")
            completion(false)
            return
        }
        
        guard !eventName.isEmpty else {
            print("❌ Event name is empty")
            completion(false)
            return
        }
        
        UserManager.shared.getUser(withUserID: joinedUserID) { joinedUser in
            guard let joinedUser = joinedUser else {
                print("❌ Group chat join notification failed: Joined user not found")
                completion(false)
                return
            }
            
            print("✅ Found joined user: \(joinedUser.fullName)")
            
            // Send notification to all participants except the person who joined
            let recipients = participantIDs.filter { $0 != joinedUserID }
            var successCount = 0
            let totalRecipients = recipients.count
            
            if totalRecipients == 0 {
                print("ℹ️ No recipients to notify")
                completion(true)
                return
            }
            
            for recipientID in recipients {
                let notification = EnhancedNotification(
                    notificationID: UUID().uuidString,
                    type: .groupChatJoin,
                    title: "New Group Chat Member",
                    body: "\(joinedUser.fullName) joined the \(eventName) group chat",
                    senderID: joinedUserID,
                    receiverID: recipientID,
                    eventID: nil
                )
                
                self.createAndSendNotification(notification) { success in
                    if success {
                        successCount += 1
                    }
                    
                    // Check if all notifications are complete
                    if successCount + (totalRecipients - successCount) == totalRecipients {
                        let overallSuccess = successCount > 0
                        print("📤 Group chat join notifications: \(successCount)/\(totalRecipients) sent")
                        completion(overallSuccess)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func createAndSendNotification(_ notification: EnhancedNotification, completion: @escaping (Bool) -> Void) {
        print("🔄 createAndSendNotification called for notification: \(notification.notificationID)")
        print("📊 Notification details: sender=\(notification.senderID ?? "nil"), receiver=\(notification.receiverID), type=\(notification.type.rawValue)")
        
        // Validate notification data
        guard !notification.receiverID.isEmpty else {
            print("❌ Notification receiverID is empty - cannot send notification")
            completion(false)
            return
        }
        
        guard !notification.notificationID.isEmpty else {
            print("❌ Notification ID is empty - cannot save notification")
            completion(false)
            return
        }
        
        // Save to Firestore
        saveNotificationToFirestore(notification) { [weak self] success in
            if success {
                print("✅ Notification saved to Firestore successfully")
                
                // Send push notification
                self?.sendPushNotification(notification)
                
                // Update local state
                DispatchQueue.main.async {
                    self?.allNotifications.insert(notification, at: 0)
                    if !notification.isRead {
                        self?.unreadNotifications.insert(notification, at: 0)
                        self?.updateUnreadCount()
                    }
                    print("✅ Local notification state updated")
                    print("📈 Total notifications: \(self?.allNotifications.count ?? 0)")
                    print("📈 Unread notifications: \(self?.unreadNotifications.count ?? 0)")
                }
            } else {
                print("❌ Failed to save notification to Firestore")
            }
            completion(success)
        }
    }
    
    private func getFollowersAndSendNotification(_ notification: EnhancedNotification, creatorID: String, completion: @escaping (Bool) -> Void) {
        // Get followers of the story creator
        UserManager.shared.getFollowers(forUserID: creatorID) { followers in
            var successCount = 0
            let totalFollowers = followers.count
            
            if totalFollowers == 0 {
                completion(true)
                return
            }
            
            for follower in followers {
                var followerNotification = notification
                followerNotification.receiverID = follower.userID
                followerNotification.notificationID = UUID().uuidString
                
                self.createAndSendNotification(followerNotification) { success in
                    if success {
                        successCount += 1
                    }
                    
                    if successCount == totalFollowers {
                        completion(true)
                    }
                }
            }
        }
    }
    
    private func saveNotificationToFirestore(_ notification: EnhancedNotification, completion: @escaping (Bool) -> Void) {
        do {
            let data = try JSONEncoder().encode(notification)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            // Convert Date to Timestamp for Firestore
            var firestoreDict = dict
            firestoreDict["createdAt"] = Timestamp(date: notification.createdAt)
            
            // Ensure all required fields are present
            firestoreDict["notificationID"] = notification.notificationID
            firestoreDict["type"] = notification.type.rawValue
            firestoreDict["title"] = notification.title
            firestoreDict["body"] = notification.body
            firestoreDict["senderID"] = notification.senderID ?? ""
            firestoreDict["receiverID"] = notification.receiverID
            firestoreDict["eventID"] = notification.eventID ?? ""
            firestoreDict["isRead"] = notification.isRead
            
            print("💾 Saving notification to Firestore: \(notification.notificationID)")
            print("📊 Notification data: \(firestoreDict)")
            
            database.collection("notifications")
                .document(notification.notificationID)
                .setData(firestoreDict) { error in
                    if let error = error {
                        print("❌ Error saving notification: \(error)")
                        completion(false)
                    } else {
                        print("✅ Notification saved successfully: \(notification.notificationID)")
                        completion(true)
                    }
                }
        } catch {
            print("Error encoding notification: \(error)")
            completion(false)
        }
    }
    
    private func sendPushNotification(_ notification: EnhancedNotification) {
        // Get user's push tokens
        UserManager.shared.getUser(withUserID: notification.receiverID) { user in
            guard let user = user, let tokens = user.pushNotificationTokens, !tokens.isEmpty else {
                print("No push tokens found for user: \(notification.receiverID)")
                return
            }
            
            // Note: Push notifications are automatically sent by Firebase Functions
            // when a notification is created in Firestore (sendPushNotification function)
            // No need to manually send here to avoid duplicates
            print("Push notification will be sent automatically by Firebase Functions")
        }
    }
    
    private func sendPushNotificationToToken(_ token: String, notification: EnhancedNotification) {
        // This function is no longer needed since Firebase Functions handles push notifications automatically
        // Keeping for reference but not calling it to avoid duplicates
        print("Push notification handled automatically by Firebase Functions")
    }
    
    // MARK: - Notification Loading and Management
    
    func loadNotifications() {
        guard let currentUserID = UserManager.shared.currentUserID else { 
            print("❌ No current user ID found")
            return 
        }
        
        print("🔄 Loading notifications for user: \(currentUserID)")
        
        // Use snapshot listener for real-time updates (without ordering to avoid index requirement)
        database.collection("notifications")
            .whereField("receiverID", isEqualTo: currentUserID)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error loading notifications: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("ℹ️ No notification documents found")
                    return
                }
                
                print("📋 Found \(documents.count) notifications")
                
                // Debug: Print all notification IDs and types
                for (index, doc) in documents.enumerated() {
                    let data = doc.data()
                    let type = data["type"] as? String ?? "unknown"
                    let receiver = data["receiverID"] as? String ?? "unknown"
                    print("📄 Notification \(index + 1): ID=\(doc.documentID), Type=\(type), Receiver=\(receiver)")
                }
                
                let notifications = documents.compactMap { document -> EnhancedNotification? in
                    do {
                        let data = document.data()
                        
                        // Convert Timestamp to Date
                        var jsonData = data
                        if let timestamp = data["createdAt"] as? Timestamp {
                            jsonData["createdAt"] = timestamp.dateValue().timeIntervalSince1970
                            print("🔍 Converting timestamp: \(timestamp) to date: \(timestamp.dateValue())")
                        }
                        
                        // Ensure required fields exist
                        if jsonData["notificationID"] == nil {
                            jsonData["notificationID"] = document.documentID
                        }
                        
                        if jsonData["isRead"] == nil {
                            jsonData["isRead"] = false
                        }
                        
                        let jsonSerialized = try JSONSerialization.data(withJSONObject: jsonData)
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .secondsSince1970
                        let notification = try decoder.decode(EnhancedNotification.self, from: jsonSerialized)

                        
                        return notification
                        
                    } catch {
                        print("Error decoding notification \(document.documentID): \(error)")
                        
                        // Try to create a basic notification as fallback
                        let data = document.data()
                        let notificationID = document.documentID
                        let typeString = data["type"] as? String ?? "new_message"
                        let title = data["title"] as? String ?? "Notification"
                        let body = data["body"] as? String ?? "You have a new notification"
                        let senderID = data["senderID"] as? String
                        let receiverID = data["receiverID"] as? String ?? currentUserID
                        let eventID = data["eventID"] as? String
                        let isRead = data["isRead"] as? Bool ?? false
                        
                        if let type = NotificationType(rawValue: typeString) {
                            var notification = EnhancedNotification(
                                notificationID: notificationID,
                                type: type,
                                title: title,
                                body: body,
                                senderID: senderID,
                                receiverID: receiverID,
                                eventID: eventID
                            )
                            notification.isRead = isRead
                            
                            return notification
                        } else {
                            return nil
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    // Sort notifications by createdAt date (newest first)
                    let sortedNotifications = notifications.sorted { $0.createdAt > $1.createdAt }
                    self?.allNotifications = sortedNotifications
                    self?.unreadNotifications = sortedNotifications.filter { !$0.isRead }
                    self?.updateUnreadCount()
                    print("Updated notifications: \(sortedNotifications.count) total, \(self?.unreadNotifications.count ?? 0) unread")
                }
            }
    }
    
    private func updateUnreadCount() {
        unreadCount = unreadNotifications.count
        // Update app badge
        UIApplication.shared.applicationIconBadgeNumber = unreadCount
    }
    
    // MARK: - Manual Refresh Method
    func refreshNotifications() {
        guard let currentUserID = UserManager.shared.currentUserID else { 
            print("❌ No current user ID found for refresh")
            return 
        }
        
        print("🔄 Manual refresh for user: \(currentUserID)")
        
        // One-time fetch to ensure we get the latest data (without ordering to avoid index requirement)
        database.collection("notifications")
            .whereField("receiverID", isEqualTo: currentUserID)
            .limit(to: 50)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error in manual refresh: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("ℹ️ No notification documents found in manual refresh")
                    return
                }
                
                print("📋 Manual refresh found \(documents.count) notifications")
                
                let notifications = documents.compactMap { document -> EnhancedNotification? in
                    do {
                        let data = document.data()
                        
                        // Convert Timestamp to Date
                        var jsonData = data
                        if let timestamp = data["createdAt"] as? Timestamp {
                            jsonData["createdAt"] = timestamp.dateValue().timeIntervalSince1970
                            print("🔍 Manual refresh - Converting timestamp: \(timestamp) to date: \(timestamp.dateValue())")
                        }
                        
                        // Ensure required fields exist
                        if jsonData["notificationID"] == nil {
                            jsonData["notificationID"] = document.documentID
                        }
                        
                        if jsonData["isRead"] == nil {
                            jsonData["isRead"] = false
                        }
                        
                        let jsonSerialized = try JSONSerialization.data(withJSONObject: jsonData)
                        let notification = try JSONDecoder().decode(EnhancedNotification.self, from: jsonSerialized)
                        
                        return notification
                        
                    } catch {
                        print("❌ Error decoding notification \(document.documentID) in manual refresh: \(error)")
                        return nil
                    }
                }
                
                DispatchQueue.main.async {
                    // Sort notifications by createdAt date (newest first)
                    let sortedNotifications = notifications.sorted { $0.createdAt > $1.createdAt }
                    self?.allNotifications = sortedNotifications
                    self?.unreadNotifications = sortedNotifications.filter { !$0.isRead }
                    self?.updateUnreadCount()
                    print("✅ Manual refresh completed: \(sortedNotifications.count) total, \(self?.unreadNotifications.count ?? 0) unread")
                }
            }
    }
    
    func markNotificationAsRead(_ notificationID: String, completion: @escaping (Bool) -> Void) {
        database.collection("notifications")
            .document(notificationID)
            .updateData(["isRead": true]) { error in
                if let error = error {
                    print("Error marking notification as read: \(error)")
                    completion(false)
                } else {
                    // Update local state
                    DispatchQueue.main.async {
                        if let index = self.allNotifications.firstIndex(where: { $0.notificationID == notificationID }) {
                            self.allNotifications[index].isRead = true
                        }
                        if let index = self.unreadNotifications.firstIndex(where: { $0.notificationID == notificationID }) {
                            self.unreadNotifications.remove(at: index)
                        }
                        self.updateUnreadCount()
                    }
                    completion(true)
                }
            }
    }
    
    func markAllNotificationsAsRead(completion: @escaping (Bool) -> Void) {
        guard let currentUserID = UserManager.shared.currentUserID else {
            completion(false)
            return
        }
        
        let batch = database.batch()
        
        database.collection("notifications")
            .whereField("receiverID", isEqualTo: currentUserID)
            .whereField("isRead", isEqualTo: false)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion(false)
                    return
                }
                
                for document in documents {
                    batch.updateData(["isRead": true], forDocument: document.reference)
                }
                
                batch.commit { error in
                    if let error = error {
                        print("Error marking all notifications as read: \(error)")
                        completion(false)
                    } else {
                        // Update local state
                        DispatchQueue.main.async {
                            for index in self.allNotifications.indices {
                                self.allNotifications[index].isRead = true
                            }
                            self.unreadNotifications.removeAll()
                            self.updateUnreadCount()
                        }
                        completion(true)
                    }
                }
            }
    }
    
    func deleteNotification(_ notificationID: String, completion: @escaping (Bool) -> Void) {
        database.collection("notifications")
            .document(notificationID)
            .delete { error in
                if let error = error {
                    print("Error deleting notification: \(error)")
                    completion(false)
                } else {
                    // Update local state
                    DispatchQueue.main.async {
                        self.allNotifications.removeAll { $0.notificationID == notificationID }
                        self.unreadNotifications.removeAll { $0.notificationID == notificationID }
                        self.updateUnreadCount()
                    }
                    completion(true)
                }
            }
    }
    
    // MARK: - Legacy Support Methods
    
    func sendEventMilestoneNotification(eventID: String, milestoneType: String, milestoneCount: Int, to userID: String, completion: @escaping (Bool) -> Void) {
        let notification = EnhancedNotification(
            notificationID: UUID().uuidString,
            type: .eventMilestone,
            title: "Event Milestone Reached!",
            body: "Your event has reached \(milestoneCount) interested people!",
            senderID: nil,
            receiverID: userID,
            eventID: eventID
        )
        
        createAndSendNotification(notification, completion: completion)
    }
    
    func sendStoryUploadPromptNotification(to userID: String, completion: @escaping (Bool) -> Void) {
        let notification = EnhancedNotification(
            notificationID: UUID().uuidString,
            type: .storyUploadPrompt,
            title: "Share Your Experience",
            body: "Don't forget to upload stories from events you've attended!",
            senderID: nil,
            receiverID: userID
        )
        
        createAndSendNotification(notification, completion: completion)
    }
    
    func sendHostNotification(eventID: String, to userID: String, completion: @escaping (Bool) -> Void) {
        let notification = EnhancedNotification(
            notificationID: UUID().uuidString,
            type: .customHostNotification,
            title: "Event Update",
            body: "Your event host has sent you an update",
            senderID: nil,
            receiverID: userID,
            eventID: eventID
        )
        
        createAndSendNotification(notification, completion: completion)
    }
    
    // MARK: - Host Notification Methods
    
    func sendImmediateHostNotification(eventID: String, title: String, body: String, targetAudience: NotificationAudience, targetUserIDs: [String]? = nil, completion: @escaping (Bool) -> Void) {
        // Get target users based on audience
        getTargetUsers(eventID: eventID, targetAudience: targetAudience, targetUserIDs: targetUserIDs) { users in
            guard let users = users, !users.isEmpty else {
                completion(false)
                return
            }
            
            var successCount = 0
            let totalUsers = users.count
            
            for user in users {
                let notification = EnhancedNotification(
                    notificationID: UUID().uuidString,
                    type: .customHostNotification,
                    title: title,
                    body: body,
                    senderID: nil,
                    receiverID: user.userID,
                    eventID: eventID
                )
                
                self.createAndSendNotification(notification) { success in
                    if success {
                        successCount += 1
                    }
                    
                    if successCount == totalUsers {
                        completion(true)
                    }
                }
            }
        }
    }
    
    func scheduleHostNotification(_ scheduledNotification: ScheduledNotification, completion: @escaping (Bool) -> Void) {
        // Save scheduled notification to Firestore
        do {
            let data = try JSONEncoder().encode(scheduledNotification)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            // Convert Date to Timestamp for Firestore
            var firestoreDict = dict
            firestoreDict["createdAt"] = Timestamp(date: scheduledNotification.createdAt)
            firestoreDict["scheduledFor"] = Timestamp(date: scheduledNotification.scheduledFor)
            
            database.collection("scheduledNotifications")
                .document(scheduledNotification.notificationID)
                .setData(firestoreDict) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error)")
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
        } catch {
            print("Error encoding scheduled notification: \(error)")
            completion(false)
        }
    }
    
    private func getTargetUsers(eventID: String, targetAudience: NotificationAudience, targetUserIDs: [String]? = nil, completion: @escaping ([User]?) -> Void) {
        switch targetAudience {
        case .eventJoinees:
            // Get users who have shown interest in the event
            // This would typically query an event_joinees collection or similar
            completion([]) // Placeholder - implement based on your data structure
            
        case .everyone:
            // Get all users (with pagination for large datasets)
            UserManager.shared.getUsers(with: nil) { users in
                completion(users)
            }
            
        case .specificUsers:
            // Get specific users by IDs
            UserManager.shared.getUsers(with: targetUserIDs) { users in
                completion(users)
            }
        }
    }
    
    // MARK: - Test Methods
    
    /// Send a test notification to verify the system is working
    func sendTestNotification(completion: @escaping (Bool) -> Void) {
        guard let currentUserID = UserManager.shared.currentUserID else {
            print("No current user ID found for test notification")
            completion(false)
            return
        }
        
        let notification = EnhancedNotification(
            notificationID: UUID().uuidString,
            type: .newMessage,
            title: "Test Notification",
            body: "This is a test notification to verify the system is working properly",
            senderID: currentUserID,
            receiverID: currentUserID
        )
        
        print("Sending test notification: \(notification.notificationID)")
        
        createAndSendNotification(notification) { success in
            print("Test notification result: \(success)")
            completion(success)
        }
    }
    
    /// Clear all notifications for testing
    func clearAllNotifications(completion: @escaping (Bool) -> Void) {
        guard let currentUserID = UserManager.shared.currentUserID else {
            completion(false)
            return
        }
        
        database.collection("notifications")
            .whereField("receiverID", isEqualTo: currentUserID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error getting notifications to clear: \(error)")
                    completion(false)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(true)
                    return
                }
                
                let batch = self.database.batch()
                for document in documents {
                    batch.deleteDocument(document.reference)
                }
                
                batch.commit { error in
                    if let error = error {
                        print("Error clearing notifications: \(error)")
                        completion(false)
                    } else {
                        DispatchQueue.main.async {
                            self.allNotifications.removeAll()
                            self.unreadNotifications.removeAll()
                            self.updateUnreadCount()
                        }
                        completion(true)
                    }
                }
            }
    }
    
    // MARK: - UNUserNotificationCenterDelegate Methods
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Check app state - only show notifications when app is in background
        let appState = UIApplication.shared.applicationState
        if appState == .background || appState == .inactive {
            // App is in background/inactive - show notification
            completionHandler([.banner, .sound, .badge])
        } else {
            // App is in foreground - don't show notification
            completionHandler([])
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification tap
        if let notificationID = userInfo["notificationID"] as? String {
            markNotificationAsRead(notificationID) { _ in }
        }
        
        completionHandler()
    }
}
