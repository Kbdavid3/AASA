//
//  SimpleNotificationView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI

struct SimpleNotificationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationManager = EnhancedNotificationManager.shared
    @State private var selectedFilter: NotificationFilter = .all
    
    enum NotificationFilter: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
        case messages = "Messages"
        case events = "Events"
        
        var icon: String {
            switch self {
            case .all: return "bell.fill"
            case .unread: return "circle.fill"
            case .messages: return "message.fill"
            case .events: return "calendar"
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
                            SimpleFilterButton(
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
                    SimpleEmptyNotificationView()
                } else {
                    List {
                        ForEach(filteredNotifications, id: \.notificationID) { notification in
                            SimpleNotificationRowView(notification: notification)
                        }
                        .onDelete(perform: deleteNotification)
                    }
                    .listStyle(PlainListStyle())
                    .scrollIndicators(.hidden) // Hide scroll indicators
                }
            }
            .padding(.bottom, 100) // Add padding to account for tab bar
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            markAllAsRead()
                        } label: {
                            Text("Mark All Read")
                                .font(.caption)
                                .foregroundColor(.appColor)
                        }
                        .disabled(notificationManager.unreadNotifications.isEmpty)
                        
                        Button {
                            // Force reload notifications
                            notificationManager.refreshNotifications()
                        } label: {
                            Text("Refresh")
                                .font(.caption)
                                .foregroundColor(.appColor)
                        }
                        
                        Button {
                            // Clear all notifications
                            notificationManager.allNotifications.removeAll()
                            notificationManager.unreadNotifications.removeAll()
                            notificationManager.unreadCount = 0
                        } label: {
                            Text("Clear")
                                .font(.caption)
                                .foregroundColor(.appColor)
                        }
                    }
                }
            }
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
        }
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

// MARK: - Simple Filter Button
struct SimpleFilterButton: View {
    let filter: SimpleNotificationView.NotificationFilter
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
                        .background(Color.appColor)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.appColor.opacity(0.1) : Color.clear)
            .foregroundColor(isSelected ? .appColor : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.appColor : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - Simple Notification Row View
struct SimpleNotificationRowView: View {
    let notification: EnhancedNotification
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: getNotificationIcon())
                        .foregroundColor(.gray)
                )
            
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
                            .fill(Color.appColor)
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
                    .onAppear {
                        print("🔍 Debug notification time:")
                        print("   Notification ID: \(notification.notificationID)")
                        print("   Created At: \(notification.createdAt)")
                        print("   Current Date: \(Date())")
                        print("   Time Difference: \(Date().timeIntervalSince(notification.createdAt)) seconds")
                        print("   Relative Date: \(notification.createdAt.getRelativeDate(from: Date()))")
                    }
            }
        }
        .padding(.vertical, 8)
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

// MARK: - Simple Empty State View
struct SimpleEmptyNotificationView: View {
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

// MARK: - Preview
struct SimpleNotificationView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleNotificationView()
    }
}
