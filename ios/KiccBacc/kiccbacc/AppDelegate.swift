//
//  AppDelegate.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseAnalytics
import FirebaseAppCheck // Add this import
import FirebaseMessaging
// import FirebaseInAppMessaging // Commented out as API is not available
import SquareInAppPaymentsSDK
import UserNotifications
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    private var pushNotificationManager: PushNotificationManager?

    // MARK: - App Life Cycle
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure App Check before Firebase initialization
        #if DEBUG
        // Use debug provider for development
        let providerFactory = AppCheckDebugProviderFactory()
        #else
        // Use device check provider for production
        let providerFactory = DeviceCheckProviderFactory()
        #endif
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Disable Firebase In-App Messaging to prevent 403 errors
        // Note: Firebase In-App Messaging API might have changed
        // Commenting out this line to prevent compilation errors
        // FirebaseInAppMessaging.inAppMessaging().isAutomaticDataCollectionEnabled = false
        
        // Configure Google Sign-In
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
            print("❌ CRITICAL ERROR: GoogleService-Info.plist not found. Google Sign-In will not be available.")
            // Continue app execution - Google Sign-In will be unavailable but app won't crash
            return true
        }
        guard let plist = NSDictionary(contentsOfFile: path) else {
            print("❌ CRITICAL ERROR: Unable to read GoogleService-Info.plist. Google Sign-In will not be available.")
            return true
        }
        guard let clientId = plist["CLIENT_ID"] as? String else {
            print("❌ CRITICAL ERROR: CLIENT_ID not found in GoogleService-Info.plist. Google Sign-In will not be available.")
            return true
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        
        // Enable Firebase Analytics
        Analytics.setAnalyticsCollectionEnabled(true)

        // Set up Square In-App Payments SDK
        SQIPInAppPaymentsSDK.squareApplicationID = "sq0idp-q9b1Mr_a45A7zUnLVYCfaQ"
        
        // Initialize notification managers
        setupNotifications()
        
        // Handle launch from notification
        if let notification = launchOptions?[.remoteNotification] as? [String: Any] {
            handleNotification(notification)
        }
        
        // Preload critical app data to improve startup performance
        preloadCriticalData()
        
        return true
    }

    // MARK: - UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    // MARK: - URL Handling for Google Sign-In
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("AppDelegate received URL: \(url.absoluteString)")
        print("URL Scheme: \(url.scheme ?? "nil")")
        print("URL Host: \(url.host ?? "nil")")
        
        // Handle Google Sign-In URL
        if GIDSignIn.sharedInstance.handle(url) {
            print("Google Sign-In handled the URL in AppDelegate")
            return true
        }
        
        // Handle other custom URL schemes if needed
        return false
    }
    
    // MARK: - Universal Links
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            if let url = userActivity.webpageURL {
                // Handle the URL
                print("Universal Link received: \(url)")
                handleUniversalLink(url: url)
            }
        }
        return true
    }
    
    private func handleUniversalLink(url: URL) {
        guard let sceneDelegate = window?.windowScene?.delegate as? SceneDelegate else {
            return
        }
        sceneDelegate.handleDeepLink(url: url)
    }
    
    // MARK: - Notification Setup
    private func setupNotifications() {
        // Set up notification center delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Initialize notification manager
        _ = EnhancedNotificationManager.shared
        
        // Set up push notification manager when user is authenticated
        if let userID = Auth.auth().currentUser?.uid {
            print("Setting up push notifications for authenticated user: \(userID)")
            pushNotificationManager = PushNotificationManager(userID: userID)
            pushNotificationManager?.registerForPushNotifications()
        } else {
            print("No authenticated user found, will set up notifications when user logs in")
        }
        
        // Listen for authentication state changes (only for push notifications)
        // Note: Main authentication state handling is done in SceneDelegate
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                print("AppDelegate: User authenticated, setting up push notifications: \(user.uid)")
                self?.pushNotificationManager = PushNotificationManager(userID: user.uid)
                self?.pushNotificationManager?.registerForPushNotifications()
            } else {
                print("AppDelegate: User signed out, clearing push notification manager")
                self?.pushNotificationManager = nil
            }
        }
    }
    
    private func handleNotification(_ userInfo: [String: Any]) {
        print("Handling notification: \(userInfo)")
        
        // Mark notification as read
        if let notificationID = userInfo["notificationID"] as? String {
            EnhancedNotificationManager.shared.markNotificationAsRead(notificationID) { _ in }
        }
        
        // Handle navigation based on notification type
        if let type = userInfo["type"] as? String {
            switch type {
            case "new_message":
                // Navigate to chat
                break
            case "event_join", "event_comment", "event_invite", "event_update", "event_reminder", "event_milestone", "event_cancellation":
                // Navigate to event
                break
            case "new_story", "story_reply":
                // Navigate to story
                break
            case "user_follow":
                // Navigate to user profile
                break
            case "user_mention":
                // Navigate to context where mention occurred
                break
            default:
                break
            }
        }
    }
    
    private func handleNotification(_ userInfo: [AnyHashable: Any]) {
        // Convert AnyHashable keys to String keys
        let stringUserInfo = userInfo.reduce(into: [String: Any]()) { result, element in
            if let key = element.key as? String {
                result[key] = element.value
            }
        }
        handleNotification(stringUserInfo)
    }
    
    // MARK: - Performance Optimization
    private func preloadCriticalData() {
        // Preload data on background queue to improve startup performance
        DispatchQueue.global(qos: .utility).async {
            // Preload user data if authenticated
            if let userID = Auth.auth().currentUser?.uid {
                print("🚀 AppDelegate: Preloading user data for faster startup")
                // This will cache the user data for faster access later
                UserManager.shared.getUserListener(withUserID: userID) { _ in
                    // Data cached for faster access
                }
            }
        }
    }
}

// MARK: - Push Notification Handling
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("Push Notification Received: \(userInfo)")
        
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
        print("Push Notification Clicked: \(userInfo)")
        
        // Handle notification tap
        handleNotification(userInfo)
        
        completionHandler()
    }
}

// MARK: - Remote Notification Handling
extension AppDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs device token received")
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Remote notification received: \(userInfo)")
        
        // Handle notification
        handleNotification(userInfo)
        
        completionHandler(.newData)
    }
}


