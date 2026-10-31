//
//  PushNotificationManager.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 09/03/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseMessaging
import UserNotifications

class PushNotificationManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
        
    let userID: String
    
    init(userID: String) {
        self.userID = userID
        super.init()
        
        // Set up messaging delegate immediately
        Messaging.messaging().delegate = self
    }
    
    private let database = Firestore.firestore()
    
    func registerForPushNotifications() {
        print("🔔 PushNotificationManager.registerForPushNotifications called for user: \(userID)")
        
        // For iOS 10 display notification (sent via APNS)
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        print("✅ Notification authorization granted")
                        UIApplication.shared.registerForRemoteNotifications()
                        self.updateFirestorePushTokenIfNeeded()
                    } else {
                        print("❌ Notification authorization denied")
                        if let error = error {
                            print("❌ Authorization error: \(error)")
                        }
                    }
                }
            }
        )
    }
    
    func updateFirestorePushTokenIfNeeded() {
        print("🔔 updateFirestorePushTokenIfNeeded called")
        Messaging.messaging().token { token, error in
            if let token = token {
                print("✅ FCM Token received: \(token)")
                self.saveTokenToFirestore(token)
            } else {
                print("❌ No FCM token available")
                if let error = error {
                    print("❌ FCM token error: \(error)")
                }
            }
        }
    }
    
    private func saveTokenToFirestore(_ token: String) {
        print("🔔 saveTokenToFirestore called for user: \(userID)")
        print("📱 Token: \(token)")
        
        let usersRef = self.database
            .collection("users")
            .document(self.userID)
        
        // First get current tokens to avoid duplicates
        usersRef.getDocument { document, error in
            if let error = error {
                print("❌ Error getting user document: \(error)")
                return
            }
            
            if let document = document, document.exists {
                let currentTokens = document.data()?["pushNotificationTokens"] as? [String] ?? []
                print("📱 Current tokens count: \(currentTokens.count)")
                
                if !currentTokens.contains(token) {
                    // Add new token
                    usersRef.updateData([
                        "pushNotificationTokens": FieldValue.arrayUnion([token])
                    ]) { error in
                        if let error = error {
                            print("❌ Error saving push token: \(error)")
                        } else {
                            print("✅ Push token saved successfully to Firestore")
                        }
                    }
                } else {
                    print("ℹ️ Token already exists for user")
                }
            } else {
                // User document doesn't exist, create with token
                usersRef.setData([
                    "pushNotificationTokens": [token]
                ], merge: true) { error in
                    if let error = error {
                        print("❌ Error creating user with push token: \(error)")
                    } else {
                        print("✅ User created with push token successfully")
                    }
                }
            }
        }
    }
    
    // MARK: - MessagingDelegate Methods
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM registration token updated: \(fcmToken ?? "nil")")
        if let token = fcmToken {
            saveTokenToFirestore(token)
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate Methods
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("Push notification received while app is in foreground: \(userInfo)")
        
        // Check app state - only show notifications when app is in background
        let appState = UIApplication.shared.applicationState
        if appState == .background || appState == .inactive {
            // App is in background/inactive - show notification
            completionHandler([.alert, .badge, .sound])
        } else {
            // App is in foreground - don't show notification
            completionHandler([])
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("Push notification tapped: \(userInfo)")
        
        // Handle notification tap
        if let notificationID = userInfo["notificationID"] as? String {
            EnhancedNotificationManager.shared.markNotificationAsRead(notificationID) { _ in }
        }
        
        completionHandler()
    }
    
    // MARK: - App Delegate Methods
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs device token received")
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
}
