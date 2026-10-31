//
//  EnhancedNotificationRepository.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import Foundation
import FirebaseFirestore

class EnhancedNotificationRepository {
    
    private let database = Firestore.firestore()
    private let enhancedNotificationsCollection = "enhancedNotifications"
    private let hostSettingsCollection = "hostNotificationSettings"
    private let scheduledNotificationsCollection = "scheduledNotifications"
    
    // MARK: - Enhanced Notifications
    
    func create(notification: EnhancedNotification, completion: @escaping (Bool) -> Void) {
        do {
            try FirestoreService.createDocumentInCollection(
                object: notification,
                id: notification.notificationID,
                collectionName: enhancedNotificationsCollection
            )
            completion(true)
        } catch {
            print("Error creating enhanced notification: \(error)")
            completion(false)
        }
    }
    
    func getEnhancedNotificationsForUser(userID: String, completion: @escaping ([EnhancedNotification]?) -> Void) {
        Task {
            do {
                let snapshot = try await database
                    .collection(enhancedNotificationsCollection)
                    .whereField("receiverID", isEqualTo: userID)
                    .order(by: "createdAt", descending: true)
                    .getDocuments()
                
                let notifications = snapshot.documents.compactMap { document in
                    try? document.data(as: EnhancedNotification.self)
                }
                
                completion(notifications)
            } catch {
                print("Error fetching enhanced notifications: \(error)")
                completion(nil)
            }
        }
    }
    
    func markAsRead(notificationID: String, completion: @escaping (Bool) -> Void) {
        let docRef = database
            .collection(enhancedNotificationsCollection)
            .document(notificationID)
        
        docRef.updateData([
            "isRead": true
        ]) { error in
            if let error = error {
                print("Error marking notification as read: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func delete(notification: EnhancedNotification, completion: @escaping (Bool) -> Void) {
        database
            .collection(enhancedNotificationsCollection)
            .document(notification.notificationID)
            .delete { error in
                if let error = error {
                    print("Error deleting enhanced notification: \(error)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
    }
    
    // MARK: - Host Notification Settings
    
    func updateHostNotificationSettings(_ settings: HostNotificationSettings, completion: @escaping (Bool) -> Void) {
        let docID = "\(settings.eventID)_\(settings.hostID)"
        
        do {
            try FirestoreService.createDocumentInCollection(
                object: settings,
                id: docID,
                collectionName: hostSettingsCollection
            )
            completion(true)
        } catch {
            print("Error updating host notification settings: \(error)")
            completion(false)
        }
    }
    
    func getHostNotificationSettings(eventID: String, hostID: String, completion: @escaping (HostNotificationSettings?) -> Void) {
        let docID = "\(eventID)_\(hostID)"
        
        FirestoreService.getDocument(inCollection: hostSettingsCollection, withID: docID) { (settings: HostNotificationSettings?) in
            completion(settings)
        }
    }
    
    // MARK: - Scheduled Notifications
    
    func scheduleNotification(_ scheduledNotification: ScheduledNotification, completion: @escaping (Bool) -> Void) {
        do {
            try FirestoreService.createDocumentInCollection(
                object: scheduledNotification,
                id: scheduledNotification.notificationID,
                collectionName: scheduledNotificationsCollection
            )
            completion(true)
        } catch {
            print("Error scheduling notification: \(error)")
            completion(false)
        }
    }
    
    func getScheduledNotifications(for eventID: String, completion: @escaping ([ScheduledNotification]?) -> Void) {
        Task {
            do {
                let snapshot = try await database
                    .collection(scheduledNotificationsCollection)
                    .whereField("eventID", isEqualTo: eventID)
                    .whereField("isSent", isEqualTo: false)
                    .order(by: "scheduledFor")
                    .getDocuments()
                
                let notifications = snapshot.documents.compactMap { document in
                    try? document.data(as: ScheduledNotification.self)
                }
                
                completion(notifications)
            } catch {
                print("Error fetching scheduled notifications: \(error)")
                completion(nil)
            }
        }
    }
    
    func markScheduledNotificationAsSent(notificationID: String, completion: @escaping (Bool) -> Void) {
        let docRef = database
            .collection(scheduledNotificationsCollection)
            .document(notificationID)
        
        docRef.updateData([
            "isSent": true
        ]) { error in
            if let error = error {
                print("Error marking scheduled notification as sent: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func deleteScheduledNotification(notificationID: String, completion: @escaping (Bool) -> Void) {
        database
            .collection(scheduledNotificationsCollection)
            .document(notificationID)
            .delete { error in
                if let error = error {
                    print("Error deleting scheduled notification: \(error)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
    }
    
    // MARK: - Utility Methods
    
    func getPendingScheduledNotifications(completion: @escaping ([ScheduledNotification]?) -> Void) {
        Task {
            do {
                let now = Date()
                let snapshot = try await database
                    .collection(scheduledNotificationsCollection)
                    .whereField("scheduledFor", isLessThanOrEqualTo: now)
                    .whereField("isSent", isEqualTo: false)
                    .getDocuments()
                
                let notifications = snapshot.documents.compactMap { document in
                    try? document.data(as: ScheduledNotification.self)
                }
                
                completion(notifications)
            } catch {
                print("Error fetching pending scheduled notifications: \(error)")
                completion(nil)
            }
        }
    }
    
    func cleanupOldNotifications(olderThan days: Int, completion: @escaping (Bool) -> Void) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        Task {
            do {
                let snapshot = try await database
                    .collection(enhancedNotificationsCollection)
                    .whereField("createdAt", isLessThan: cutoffDate)
                    .getDocuments()
                
                let batch = database.batch()
                
                for document in snapshot.documents {
                    batch.deleteDocument(document.reference)
                }
                
                try await batch.commit()
                completion(true)
            } catch {
                print("Error cleaning up old notifications: \(error)")
                completion(false)
            }
        }
    }
}
