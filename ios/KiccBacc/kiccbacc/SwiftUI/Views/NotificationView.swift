//
//  NotificationView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct NotificationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationManager = EnhancedNotificationManager.shared
    @StateObject private var settingsManager = NotificationSettingsManager.shared
    
    @State private var selectedFilter: NotificationFilter = .all
    @State private var showingSettings = false

    @State private var isLoading = false
    
    enum NotificationFilter: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
        case messages = "Messages"
        case events = "Events"
        case stories = "Stories"
        case follows = "Follows"
        
        var icon: String {
            switch self {
            case .all: return "bell.fill"
            case .unread: return "circle.fill"
            case .messages: return "message.fill"
            case .events: return "calendar"
            case .stories: return "photo.fill"
            case .follows: return "person.2.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(NotificationFilter.allCases, id: \.self) { filter in
                            FilterButton(
                                filter: filter,
                                isSelected: selectedFilter == filter,
                                count: getCountForFilter(filter)
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                // Notifications list
                if notificationManager.allNotifications.isEmpty {
                    EmptyNotificationView()
                } else {
                    List {
                        ForEach(filteredNotifications, id: \.notificationID) { notification in
                            NotificationRowView(
                                notification: notification,
                                onTap: {
                                    handleNotificationTap(notification)
                                },
                                onMarkAsRead: {
                                    markNotificationAsRead(notification)
                                }
                            )
                        }
                        .onDelete(perform: deleteNotification)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button("Done") {
                            dismiss()
                        }
                        
                        // Show unread count badge
                        if notificationManager.unreadNotifications.count > 0 {
                            Text("(\(notificationManager.unreadNotifications.count))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {

                        
                        Button {
                            // Send test notification
                            notificationManager.sendTestNotification { success in
                                print("Test notification sent: \(success)")
                            }
                        } label: {
                            Text("Test")
                                .font(.caption)
                        }
                        
                        Button {
                            markAllAsRead()
                        } label: {
                            Text("Mark All Read")
                                .font(.caption)
                        }
                        .disabled(notificationManager.unreadNotifications.isEmpty)
                        
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            NotificationSettingsView()
        }

        .onAppear {
            notificationManager.loadNotifications()
        }
    }
    
    private var filteredNotifications: [EnhancedNotification] {
        let notifications = notificationManager.allNotifications
        
        switch selectedFilter {
        case .all:
            return notifications
        case .unread:
            return notifications.filter { !$0.isRead }
        case .messages:
            return notifications.filter { $0.type == .newMessage }
        case .events:
            return notifications.filter { 
                [.eventJoin, .eventComment, .eventInvite, .eventUpdate, .eventReminder, .eventMilestone, .eventCancellation, .customHostNotification].contains($0.type)
            }
        case .stories:
            return notifications.filter { 
                [.newStory, .storyReply, .storyUploadPrompt, .storyLike].contains($0.type)
            }
        case .follows:
            return notifications.filter { $0.type == .userFollow }
        }
    }
    
    private func getCountForFilter(_ filter: NotificationFilter) -> Int {
        switch filter {
        case .all:
            return notificationManager.allNotifications.count
        case .unread:
            return notificationManager.unreadNotifications.count
        case .messages:
            return notificationManager.allNotifications.filter { $0.type == .newMessage }.count
        case .events:
            return notificationManager.allNotifications.filter { 
                [.eventJoin, .eventComment, .eventInvite, .eventUpdate, .eventReminder, .eventMilestone, .eventCancellation, .customHostNotification].contains($0.type)
            }.count
        case .stories:
            return notificationManager.allNotifications.filter { 
                [.newStory, .storyReply, .storyUploadPrompt, .storyLike].contains($0.type)
            }.count
        case .follows:
            return notificationManager.allNotifications.filter { $0.type == .userFollow }.count
        }
    }
    
    private func handleNotificationTap(_ notification: EnhancedNotification) {
        // Mark as read
        markNotificationAsRead(notification)
        
        // Handle navigation based on notification type
        switch notification.type {
        case .newMessage:
            // Navigate to chat
            break
        case .eventJoin, .eventComment, .eventInvite, .eventUpdate, .eventReminder, .eventMilestone, .eventCancellation, .customHostNotification:
            // Navigate to event
            break
        case .newStory, .storyReply:
            // Navigate to story
            break
        case .userFollow:
            // Navigate to user profile
            break
        case .userMention:
            // Navigate to context where mention occurred
            break
        default:
            break
        }
    }
    
    private func markNotificationAsRead(_ notification: EnhancedNotification) {
        notificationManager.markNotificationAsRead(notification.notificationID) { _ in }
    }
    
    private func markAllAsRead() {
        notificationManager.markAllNotificationsAsRead { _ in }
    }
    
    private func deleteNotification(at offsets: IndexSet) {
        for index in offsets {
            let notification = filteredNotifications[index]
            notificationManager.deleteNotification(notification.notificationID) { _ in }
        }
    }
}

// MARK: - Filter Button
struct FilterButton: View {
    let filter: NotificationView.NotificationFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 12))
                
                Text(filter.rawValue)
                    .font(.system(size: 14, weight: .medium))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - Notification Row View
struct NotificationRowView: View {
    let notification: EnhancedNotification
    let onTap: () -> Void
    let onMarkAsRead: () -> Void
    
    @State private var sender: User?
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                if let sender = sender {
                    PfpView(user: sender, size: 40, cornerRadius: 0, isRound: true, strokeWidth: 0)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: getNotificationIcon())
                                .foregroundColor(.gray)
                        )
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if !notification.isRead {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(notification.body)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(notification.createdAt.getRelativeDate(from: Date()))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // Action button
                if notification.type.requiresUserAction {
                    Button(action: onMarkAsRead) {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.blue)
                            .font(.system(size: 20))
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if let senderID = notification.senderID {
                UserManager.shared.getUser(withUserID: senderID) { user in
                    sender = user
                }
            }
        }
    }
    
    private func getNotificationIcon() -> String {
        switch notification.type {
        case .newMessage:
            return "message.fill"
        case .eventJoin, .eventComment, .eventInvite, .eventUpdate, .eventReminder, .eventMilestone, .eventCancellation, .customHostNotification:
            return "calendar"
        case .newStory, .storyReply, .storyUploadPrompt:
            return "photo.fill"
        case .userFollow:
            return "person.2.fill"
        case .userMention:
            return "at"
        default:
            return "bell.fill"
        }
    }
}

// MARK: - Empty State View
struct EmptyNotificationView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Notifications")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("You're all caught up! New notifications will appear here.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settingsManager = NotificationSettingsManager.shared

    
    var body: some View {
        NavigationView {
            List {
                Section("General") {
                    Toggle("Push Notifications", isOn: $settingsManager.notificationSettings.pushNotificationsEnabled)
                    Toggle("In-App Notifications", isOn: $settingsManager.notificationSettings.inAppNotificationsEnabled)
                    Toggle("Sound", isOn: $settingsManager.notificationSettings.soundEnabled)
                    Toggle("Vibration", isOn: $settingsManager.notificationSettings.vibrationEnabled)
                }
                
                Section("Quiet Hours") {
                    Toggle("Enable Quiet Hours", isOn: $settingsManager.notificationSettings.quietHoursEnabled)
                    
                    if settingsManager.notificationSettings.quietHoursEnabled {
                        DatePicker("Start Time", selection: $settingsManager.notificationSettings.quietHoursStart, displayedComponents: .hourAndMinute)
                        DatePicker("End Time", selection: $settingsManager.notificationSettings.quietHoursEnd, displayedComponents: .hourAndMinute)
                    }
                }
                
                Section("Notification Types") {
                    ForEach(NotificationType.allCases, id: \.self) { type in
                        Toggle(type.displayName, isOn: Binding(
                            get: { settingsManager.notificationSettings.isNotificationTypeEnabled(type) },
                            set: { settingsManager.updateNotificationType(type, enabled: $0) }
                        ))
                    }
                }
                

                
                Section {
                    Button("Reset to Defaults") {
                        settingsManager.resetToDefaults()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }

    }
}

// MARK: - Preview
struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView()
    }
}
