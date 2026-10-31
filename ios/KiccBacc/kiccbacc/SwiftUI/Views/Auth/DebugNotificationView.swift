//
//  DebugNotificationView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import UserNotifications

struct DebugNotificationView: View {
    @StateObject private var notificationManager = EnhancedNotificationManager.shared
    @State private var permissionsGranted = false
    @State private var testResult = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Notification Debug")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: permissionsGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(permissionsGranted ? .green : .red)
                        Text("Notification Permissions")
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "bell.fill")
                        Text("Unread Notifications: \(notificationManager.unreadNotifications.count)")
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("Total Notifications: \(notificationManager.allNotifications.count)")
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                VStack(spacing: 15) {
                    Button("Check Permissions") {
                        checkPermissions()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Run Diagnostic") {
                        runDiagnostic()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                    
                    Button("Send Test Notification") {
                        sendTestNotification()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                    
                    Button("Send Event Join Test") {
                        sendEventJoinTest()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                    
                    Button("Clear All Notifications") {
                        clearAllNotifications()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                }
                
                if !testResult.isEmpty {
                    Text(testResult)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Debug")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                checkPermissions()
            }
        }
    }
    
    private func checkPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                permissionsGranted = settings.authorizationStatus == .authorized
                testResult = permissionsGranted ? "Permissions granted ✅" : "Permissions denied ❌"
            }
        }
    }
    
    private func sendTestNotification() {
        isLoading = true
        testResult = "Sending test notification..."
        
        notificationManager.sendTestNotification { success in
            DispatchQueue.main.async {
                isLoading = false
                testResult = success ? "Test notification sent successfully! ✅" : "Failed to send test notification ❌"
            }
        }
    }
    
    private func sendEventJoinTest() {
        isLoading = true
        testResult = "Sending event join test..."
        
        guard let currentUserID = UserManager.shared.currentUserID else {
            DispatchQueue.main.async {
                isLoading = false
                testResult = "No current user ID found ❌"
            }
            return
        }
        
        // Send event join notification
        notificationManager.sendEventJoinNotification(
            eventID: "test_event_123",
            joinerID: currentUserID,
            eventTitle: "Test Event"
        ) { success in
            DispatchQueue.main.async {
                isLoading = false
                testResult = success ? "Event join notification sent successfully! ✅" : "Failed to send event join notification ❌"
            }
        }
    }
    
    private func clearAllNotifications() {
        isLoading = true
        testResult = "Clearing all notifications..."
        
        notificationManager.clearAllNotifications { success in
            DispatchQueue.main.async {
                isLoading = false
                testResult = success ? "All notifications cleared successfully! ✅" : "Failed to clear notifications ❌"
            }
        }
    }
    
    private func runDiagnostic() {
        isLoading = true
        testResult = "Running diagnostic..."
        
        var results: [String] = []
        
        // Check permissions
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                results.append("📱 Permissions: \(settings.authorizationStatus == .authorized ? "✅ Granted" : "❌ Denied")")
                
                // Check app badge
                let badgeCount = UIApplication.shared.applicationIconBadgeNumber
                results.append("🏷️ App Badge: \(badgeCount)")
                
                // Check notification counts
                results.append("📊 App Notifications: \(self.notificationManager.allNotifications.count) total, \(self.notificationManager.unreadNotifications.count) unread")
                
                // Check user authentication
                if let userID = UserManager.shared.currentUserID {
                    results.append("👤 User ID: ✅ \(userID)")
                } else {
                    results.append("👤 User ID: ❌ Not authenticated")
                }
                
                // Check notification center
                UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                    DispatchQueue.main.async {
                        results.append("📬 Notification Center: \(notifications.count) delivered")
                        
                        // Final analysis
                        results.append("\n🎯 ANALYSIS:")
                        if badgeCount > 0 && self.notificationManager.allNotifications.isEmpty {
                            results.append("❌ ISSUE: Badge shows \(badgeCount) but no notifications loaded")
                            results.append("💡 SOLUTION: Check notification loading/decoding")
                        } else if settings.authorizationStatus != .authorized {
                            results.append("❌ ISSUE: Permissions not granted")
                            results.append("💡 SOLUTION: Grant permissions in Settings")
                        } else if notifications.isEmpty && badgeCount > 0 {
                            results.append("❌ ISSUE: No push notifications received")
                            results.append("💡 SOLUTION: Check FCM token and Firebase Functions")
                        } else {
                            results.append("✅ All systems working")
                        }
                        
                        self.isLoading = false
                        self.testResult = results.joined(separator: "\n")
                    }
                }
            }
        }
    }
}

struct DebugNotificationView_Previews: PreviewProvider {
    static var previews: some View {
        DebugNotificationView()
    }
}
