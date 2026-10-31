//
//  ChatsView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI

struct ChatsView: View {
    
    @State private var showStoryUploadView: Bool = false
    @State private var showStoryView: Bool = false
    @State private var viewItem: ViewItem?
    @State private var chats: [ChatRoom]?
    @State private var isFetchingChats: Bool = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .center, spacing: 8) {
                if let chats = chats, chats.count > 0 {
                    ForEach(chats, id: \.roomID) { room in
                        ChatRow(room: room)
                            .padding(.horizontal, 16)
                    }
                } else if isFetchingChats {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading chats...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "message.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No chats yet")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text("Start a conversation with your friends!")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                }
            }
            .padding(.vertical, 16)
        }
        .onAppear {
            // Track screen view when this view appears
            AnalyticsManager.logScreenView(screenName: "Chats", screenClass: "ChatsView")
            
            // Track time spent in chats
            let timestamp = Date()
            AnalyticsManager.setUserProperty(value: "\(timestamp.timeIntervalSince1970)", forName: "last_chats_view_time")
            
            loadChats()
        }
        .onDisappear {
            // Calculate time spent in chats when view disappears
            if let lastViewTimeString = UserDefaults.standard.string(forKey: "last_chats_view_time"),
               let lastViewTime = Double(lastViewTimeString) {
                let currentTime = Date().timeIntervalSince1970
                let timeSpent = currentTime - lastViewTime
                
                // Track time spent in chats
                AnalyticsManager.logCustomEvent(name: "time_in_chats", parameters: [
                    "duration_seconds": timeSpent,
                    "chat_count": chats?.count ?? 0
                ])
            }
        }
        .fullScreenCover(item: $viewItem) { viewItem in
            viewItem.viewToPresent
        }
    }
    
    private func loadChats() {
        guard let currentUserID = UserManager.shared.currentUserID else {
            return
        }
        
        withAnimation { isFetchingChats = true }
        
        ChatroomManager.shared.getChatRooms(whereField: "participantsIDs", arrayContains: currentUserID) { rooms in
            // Filter out group chats - only show direct messages in the main chats list
            let directMessageRooms = rooms?.filter { room in
                room.isDirectMessage
            }
            
            self.chats = directMessageRooms
            
            // Track number of chat rooms
            AnalyticsManager.logCustomEvent(name: "chat_rooms_loaded", parameters: [
                "chat_count": directMessageRooms?.count,
                "total_rooms": rooms?.count,
                "group_chats_filtered": (rooms?.count ?? 0) - (directMessageRooms?.count ?? 0)
            ])
            
            withAnimation { isFetchingChats = false }
        }
    }
    
    struct ChatRow: View {
        
        var room: ChatRoom
        
        @State private var user: User?
        @State private var isFetchingUser: Bool = false
        
        var body: some View {
            if let user = user {
                NavigationLink {
                    MessageView(user: user, chatroom: room)
                } label: {
                    HStack(spacing: 12) {
                        // Profile Picture
                        PfpView(user: user, size: 50, isRound: true, strokeWidth: 1)
                        
                        // User Info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.fullName)
                                .font(.system(size: 17, weight: .bold, design: .default))
                                .foregroundColor(.labelColor)
                            
                            Text("@\(user.username)")
                                .font(.system(size: 14, weight: .light, design: .default))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Last message indicator (if available)
                        VStack(alignment: .trailing, spacing: 2) {
                            if let lastMessage = room.lastMessage, !lastMessage.isEmpty {
                                Text(lastMessage)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                    .frame(maxWidth: 100, alignment: .trailing)
                            }
                            
                            if let lastMessageTime = room.lastMessageTime {
                                Text(formatTimeAgo(from: lastMessageTime))
                                    .font(.system(size: 10, weight: .light))
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                        }
                        
                        // Arrow indicator to show it's clickable
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        let _ = print("roomID of \(room.lastMessage) -> \(room.roomID)")
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .opacity(0.3)
                    )
                    .contentShape(Rectangle())
                    .foregroundColor(.labelColor)
                }
                .buttonStyle(PlainButtonStyle())
                .onTapGesture {
                    // Track when user opens a specific chat
                    AnalyticsManager.logCustomEvent(name: "open_chat", parameters: [
                        "chat_room_id": room.roomID,
                        "other_user_id": user.userID,
                        "other_user_name": user.fullName
                    ])
                }
            } else {
                HStack(spacing: 12) {
                    // Loading profile picture placeholder
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Loading...")
                            .font(.system(size: 17, weight: .bold, design: .default))
                        Text("Fetching user...")
                            .font(.system(size: 14, weight: .light, design: .default))
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .redacted(reason: .placeholder)
                .onAppear {
                    fetchUser()
                }
            }
        }
        
        private func fetchUser() {
            withAnimation { isFetchingUser = true }
            
            guard let currentUserID = UserManager.shared.currentUserID else {
                withAnimation { isFetchingUser = false }
                return
            }
            
            // For direct messages, there should be exactly 2 participants
            let otherUserIDs = room.participantsIDs.filter { id in
                id != currentUserID
            }
            
            // Only proceed if this is a direct message (exactly 1 other user)
            if otherUserIDs.count == 1, let userID = otherUserIDs.first {
                UserManager.shared.getUser(withUserID: userID) { user in
                    withAnimation {
                        self.user = user
                        isFetchingUser = false
                    }
                }
            } else {
                // This shouldn't happen with our filter, but handle gracefully
                print("⚠️ Unexpected: Room has \(otherUserIDs.count) other participants, expected 1 for direct message")
                withAnimation { isFetchingUser = false }
            }
        }
        
        private func formatTimeAgo(from date: Date) -> String {
            let now = Date()
            let timeInterval = now.timeIntervalSince(date)
            
            if timeInterval < 60 {
                return "now"
            } else if timeInterval < 3600 {
                let minutes = Int(timeInterval / 60)
                return "\(minutes)m"
            } else if timeInterval < 86400 {
                let hours = Int(timeInterval / 3600)
                return "\(hours)h"
            } else if timeInterval < 604800 {
                let days = Int(timeInterval / 86400)
                return "\(days)d"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return formatter.string(from: date)
            }
        }
    }
}

struct ChatsView_Previews: PreviewProvider {
    static var previews: some View {
        ChatsView()
            .preferredColorScheme(.dark)
    }
}
