//
//  GroupChatView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI
import Combine

struct GroupChatView: View {
    
    let event: Event
    @Binding var groupChatRoom: ChatRoom?
    @Binding var groupChatMessages: [Message]
    @Binding var newGroupMessage: String
    @Binding var groupChatMembers: [User]
    @Binding var showInviteSheet: Bool
    @Binding var isHostOnly: Bool
    
    @State private var keyboardHeight: CGFloat = 0
    @State private var scrollTarget: String?
    @State private var messagesListener: ListenerRegistration?
    @State private var currentUser: User?
    @State private var showMembersList: Bool = false
    @State private var roomListener: ListenerRegistration?
    @State private var isTextFieldFocused: Bool = false
    @State private var shouldAutoScroll: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if let room = groupChatRoom {
                // Chat header with members and invite button
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Group Chat")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.labelColor)
                            
                            // Only show member count when keyboard is closed
                            if keyboardHeight == 0 {
                                Button(action: {
                                    showMembersList = true
                                }) {
                                    Text("\(groupChatMembers.count) member\(groupChatMembers.count == 1 ? "" : "s")")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Invite button (only show when keyboard is closed)
                        if keyboardHeight == 0 {
                            Button(action: {
                                print("🔄 Invite button tapped")
                                print("🔄 Current isHostOnly: \(isHostOnly)")
                                showInviteSheet = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Invite")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.appColor)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    // Members preview (only show when keyboard is closed)
                    if !groupChatMembers.isEmpty && keyboardHeight == 0 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: -8) {
                                ForEach(groupChatMembers.prefix(4), id: \.userID) { member in
                                    ZStack {
                                        PfpView(user: member, size: 32, isRound: true, strokeWidth: 2)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.bgColor, lineWidth: 2)
                                            )
                                    }
                                }
                                
                                if groupChatMembers.count > 4 {
                                    Button(action: {
                                        showMembersList = true
                                    }) {
                                        Text("+\(groupChatMembers.count - 4)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.gray)
                                            .frame(width: 32, height: 32)
                                            .background(Color.secondaryBgColor)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.bgColor, lineWidth: 2)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 8)
                    }
                    
                    Divider()
                }
                .background(Color.bgColor)
                .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
                
                // Messages area
                if groupChatMessages.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No messages yet")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text("Start the conversation!")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray.opacity(0.7))
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Messages list
                    ScrollView(.vertical, showsIndicators: false) {
                        ScrollViewReader { scrollView in
                            VStack(spacing: 8) {
                                ForEach(Array(groupChatMessages.enumerated()), id: \.element.messageID) { index, message in
                                    let previousMessage = index > 0 ? groupChatMessages[index - 1] : nil
                                    
                                    VStack(spacing: 8) {
                                        // Date separator
                                        if shouldShowDateSeparator(currentMessage: message, previousMessage: previousMessage) {
                                            HStack {
                                                Spacer()
                                                Text(formatDateSeparator(message.createdAt))
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.gray)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.secondaryBgColor.opacity(0.7))
                                                    .clipShape(Capsule())
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                        }
                                        
                                        // Message
                                        GroupChatMessageView(
                                            message: message,
                                            groupChatMembers: groupChatMembers,
                                            formatTime: formatMessageTime
                                        )
                                    }
                                    .id(message.messageID)
                                }
                                
                                // Bottom padding to ensure last message is visible above keyboard
                                Color.clear
                                    .frame(height: keyboardHeight > 0 ? 20 : 0)
                                    .id("bottomSpacer")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .onChange(of: scrollTarget) { target in
                                if let target = target {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        scrollView.scrollTo(target, anchor: .bottom)
                                    }
                                }
                            }
                            .onChange(of: groupChatMessages) { messages in
                                if let lastMessage = messages.last {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            scrollView.scrollTo(lastMessage.messageID, anchor: .bottom)
                                        }
                                    }
                                    scrollTarget = lastMessage.messageID
                                }
                            }
                            .onChange(of: keyboardHeight) { height in
                                if height > 0 && !groupChatMessages.isEmpty {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        if let lastMessage = groupChatMessages.last {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                scrollView.scrollTo(lastMessage.messageID, anchor: .bottom)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: geometry.size.height - keyboardHeight - 120) // Reduced from 200 to 120
                }
                
                // Message input area
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 12) {
                        TextField("Type a message...", text: $newGroupMessage)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .font(.system(size: 16, weight: .regular))
                            .textFieldStyle(PlainTextFieldStyle())
                            .onTapGesture {
                                isTextFieldFocused = true
                                shouldAutoScroll = true
                                
                                // Scroll to bottom when text field is tapped
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    self.scrollToBottom()
                                }
                            }
                            .onChange(of: isTextFieldFocused) { focused in
                                if focused {
                                    shouldAutoScroll = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        self.scrollToBottom()
                                    }
                                }
                            }
                        
                        Button(action: {
                            sendGroupMessage()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(newGroupMessage.isEmpty ? Color.gray.opacity(0.3) : Color.appColor)
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(newGroupMessage.isEmpty ? .gray : .white)
                            }
                        }
                        .disabled(newGroupMessage.isEmpty)
                        .scaleEffect(newGroupMessage.isEmpty ? 0.8 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: newGroupMessage.isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color.bgColor)
            } else {
                // No chat room available
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "lock.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("Group chat not available")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    
                    if isHostOnly {
                        Text("Only the host can access group chat")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            }
        }
        .onReceive(Publishers.keyboardHeight) { height in
            withAnimation(.easeInOut(duration: 0.3)) {
                keyboardHeight = height
            }
            
            // Scroll to bottom when keyboard appears if text field is focused
            if isTextFieldFocused && height > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.scrollToBottom()
                }
            }
            
            // Reset focus when keyboard hides
            if height == 0 {
                isTextFieldFocused = false
                shouldAutoScroll = false
            }
        }
        .sheet(isPresented: $showInviteSheet) {
            print("🔄 Opening invite sheet")
            return InviteToGroupChatView(
                event: event,
                groupChatRoom: $groupChatRoom,
                groupChatMembers: $groupChatMembers,
                isHostOnly: $isHostOnly
            )
        }
        .sheet(isPresented: $showMembersList) {
            GroupChatMembersListView(
                members: $groupChatMembers,
                event: event,
                groupChatRoom: $groupChatRoom
            )
        }
        .onTapGesture {
            // Dismiss keyboard and reset focus when tapping outside
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            isTextFieldFocused = false
            shouldAutoScroll = false
        }
        .onAppear {
            loadCurrentUser()
            setupMessagesListener()
            setupRoomListener()
        }
        .onDisappear {
            messagesListener?.remove()
            roomListener?.remove()
        }
    }
    
    private func isCurrentUserHost() -> Bool {
        guard let currentUserID = UserManager.shared.currentUserID else { 
            print("❌ Cannot check host status: No current user ID")
            return false 
        }
        let isHost = event.hostIDs.contains(currentUserID)
        print("🔄 Host check - Current user: \(currentUserID), Event hosts: \(event.hostIDs), Is host: \(isHost)")
        return isHost
    }
    
    private func loadCurrentUser() {
        guard let currentUserID = UserManager.shared.currentUserID else { return }
        
        UserManager.shared.getUser(withUserID: currentUserID) { user in
            DispatchQueue.main.async {
                self.currentUser = user
            }
        }
    }
    
    private func setupMessagesListener() {
        guard let room = groupChatRoom else { 
            print("❌ Cannot setup messages listener: No chat room")
            return 
        }
        
        print("🔄 Setting up messages listener for room: \(room.roomID)")
        
        let database = Firestore.firestore()
        messagesListener = database
            .collection("chatrooms")
            .document(room.roomID)
            .collection("messages")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error listening to messages: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { 
                    print("ℹ️ No messages found in snapshot")
                    return 
                }
                
                print("📨 Received \(documents.count) messages from listener")
                
                let messages = documents.compactMap { document in
                    try? document.data(as: Message.self)
                }
                
                DispatchQueue.main.async {
                    self.groupChatMessages = messages
                    print("✅ Updated group chat messages: \(messages.count) messages")
                }
            }
    }
    
    private func sendGroupMessage() {
        guard let room = groupChatRoom,
              let currentUserID = UserManager.shared.currentUserID,
              !newGroupMessage.isEmpty else { 
            print("❌ Cannot send group message: Missing room, user ID, or empty message")
            return 
        }
        
        let messageID = UUID().uuidString
        let message = Message(
            messageID: messageID,
            senderID: currentUserID,
            receiverID: room.roomID, // Use room ID as receiver for group chat
            content: newGroupMessage
        )
        
        print("🔄 Sending group message: \(newGroupMessage)")
        print("🔄 Message ID: \(messageID)")
        print("🔄 Room ID: \(room.roomID)")
        
        do {
            // Use the repository directly for group chat messages
            try MessageDataRepository.shared.create(in: room, with: message)
            print("✅ Message sent successfully")
            
            // Update the last message in the chat room
            MessageDataRepository.shared.updateLastMessage(
                in: room,
                lastMessage: newGroupMessage,
                lastMessageTime: Date()
            )
            
            // Send notifications to all participants except the sender
            EnhancedNotificationManager.shared.sendGroupChatMessageNotification(
                senderID: currentUserID,
                eventName: event.name,
                messageContent: newGroupMessage,
                participantIDs: room.participantsIDs
            ) { success in
                if !success {
                    print("Failed to send group chat message notifications")
                }
            }
            
            newGroupMessage = ""
            
            // Reset focus state
            isTextFieldFocused = false
            shouldAutoScroll = false
        } catch {
            print("❌ Error sending group message: \(error.localizedDescription)")
        }
    }
    
    private func setupRoomListener() {
        guard let room = groupChatRoom else { 
            print("❌ Cannot setup room listener: No chat room")
            return 
        }
        
        print("🔄 Setting up room listener for room: \(room.roomID)")
        
        let database = Firestore.firestore()
        roomListener = database
            .collection("chatrooms")
            .document(room.roomID)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error listening to room changes: \(error.localizedDescription)")
                    return
                }
                
                guard let document = snapshot, document.exists else { 
                    print("ℹ️ Room document no longer exists")
                    return 
                }
                
                do {
                    let updatedRoom = try document.data(as: ChatRoom.self)
                    print("📨 Room updated with \(updatedRoom.participantsIDs.count) participants")
                    
                    DispatchQueue.main.async {
                        // Check for new participants (join notifications)
                        if let oldRoom = self.groupChatRoom {
                            let newParticipants = updatedRoom.participantsIDs.filter { !oldRoom.participantsIDs.contains($0) }
                            
                            // Send join notifications for new participants
                            for newParticipantID in newParticipants {
                                EnhancedNotificationManager.shared.sendGroupChatJoinNotification(
                                    joinedUserID: newParticipantID,
                                    eventName: self.event.name,
                                    participantIDs: updatedRoom.participantsIDs
                                ) { success in
                                    if !success {
                                        print("Failed to send group chat join notification for \(newParticipantID)")
                                    }
                                }
                            }
                        }
                        
                        self.groupChatRoom = updatedRoom
                        self.loadGroupChatMembers()
                    }
                } catch {
                    print("❌ Error decoding updated room: \(error.localizedDescription)")
                }
            }
    }
    
    private func loadGroupChatMembers() {
        guard let room = groupChatRoom else { return }
        
        print("🔄 Loading group chat members for \(room.participantsIDs.count) participants")
        
        var loadedMembers: [User] = []
        let dispatchGroup = DispatchGroup()
        
        for participantID in room.participantsIDs {
            dispatchGroup.enter()
            UserManager.shared.getUser(withUserID: participantID) { user in
                if let user = user {
                    loadedMembers.append(user)
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.groupChatMembers = loadedMembers
            print("✅ Loaded \(loadedMembers.count) group chat members")
        }
    }
    
    private func scrollToBottom() {
        guard !groupChatMessages.isEmpty else { return }
        
        if let lastMessage = groupChatMessages.last {
            scrollTarget = lastMessage.messageID
            
            // Additional scroll attempts for reliability
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.scrollTarget = lastMessage.messageID
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.scrollTarget = lastMessage.messageID
            }
        }
    }
    
    // MARK: - WhatsApp-style Date Formatting
    
    private func formatDateSeparator(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.dateInterval(of: .weekOfYear, for: Date())?.contains(date) == true {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    private func formatMessageTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func shouldShowDateSeparator(currentMessage: Message, previousMessage: Message?) -> Bool {
        guard let previousMessage = previousMessage else { return true }
        
        let calendar = Calendar.current
        return !calendar.isDate(currentMessage.createdAt, inSameDayAs: previousMessage.createdAt)
    }
}

// MARK: - Group Chat Message View
struct GroupChatMessageView: View {
    let message: Message
    let groupChatMembers: [User]
    let formatTime: (Date) -> String
    
    @State private var sender: User?
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.senderID == UserManager.shared.currentUserID {
                // Sent message (right side)
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.appColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .font(.system(size: 15, weight: .regular))
                    
                    Text(formatTime(message.createdAt))
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.gray)
                        .padding(.trailing, 4)
                }
            } else {
                // Received message (left side)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        // Profile picture
                        if let sender = sender {
                            PfpView(user: sender, size: 28, isRound: true, strokeWidth: 1)
                        } else {
                            Circle()
                                .fill(Color.secondaryBgColor)
                                .frame(width: 28, height: 28)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            // Sender name
                            if let sender = sender {
                                Text(sender.fullName)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            
                            // Message content
                            Text(message.content)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.secondaryBgColor)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .font(.system(size: 15, weight: .regular))
                            
                            // Timestamp
                            Text(formatTime(message.createdAt))
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(.gray)
                                .padding(.leading, 4)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            loadSender()
        }
    }
    
    private func loadSender() {
        if let senderUser = groupChatMembers.first(where: { $0.userID == message.senderID }) {
            sender = senderUser
        } else {
            // Load sender if not in members list
            UserManager.shared.getUser(withUserID: message.senderID) { user in
                DispatchQueue.main.async {
                    self.sender = user
                }
            }
        }
    }
}

// MARK: - Invite to Group Chat View
struct InviteToGroupChatView: View {
    let event: Event
    @Binding var groupChatRoom: ChatRoom?
    @Binding var groupChatMembers: [User]
    @Binding var isHostOnly: Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedUserIDs: [String] = []
    
    var body: some View {
        NavigationView {
            UserSelectionView(selectedUserIDs: $selectedUserIDs, event: event)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Invite") {
                            inviteSelectedUsers()
                        }
                        .disabled(selectedUserIDs.isEmpty)
                    }
                }
        }
    }
    
    private func inviteSelectedUsers() {
        guard let room = groupChatRoom else { 
            print("❌ Cannot invite users: No group chat room")
            return 
        }
        
        print("🔄 Inviting \(selectedUserIDs.count) users to group chat")
        print("🔄 Selected user IDs: \(selectedUserIDs)")
        
        var updatedParticipants = room.participantsIDs
        for userID in selectedUserIDs {
            if !updatedParticipants.contains(userID) {
                updatedParticipants.append(userID)
                print("✅ Adding user \(userID) to participants")
            } else {
                print("ℹ️ User \(userID) already in participants")
            }
        }
        
        print("🔄 Updated participants: \(updatedParticipants)")
        
        // Update the chat room in Firebase
        let database = Firestore.firestore()
        database.collection("chatrooms").document(room.roomID).updateData([
            "participantsIDs": updatedParticipants
        ]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error inviting users to group chat: \(error.localizedDescription)")
                } else {
                    print("✅ Successfully invited users to group chat")
                    
                    // Send notifications to all newly invited users
                    guard let currentUserID = UserManager.shared.currentUserID else { return }
                    
                    for userID in selectedUserIDs {
                        EnhancedNotificationManager.shared.sendGroupChatInvitationNotification(
                            invitedUserID: userID,
                            eventName: event.name,
                            inviterID: currentUserID
                        ) { success in
                            if !success {
                                print("Failed to send group chat invitation notification to \(userID)")
                            }
                        }
                    }
                    
                    // Update local room state
                    var updatedRoom = room
                    updatedRoom.participantsIDs = updatedParticipants
                    self.groupChatRoom = updatedRoom
                    self.isHostOnly = false // Allow all invited users to see the chat
                    self.dismiss()
                }
            }
        }
    }
}

// MARK: - Group Chat Members List View
struct GroupChatMembersListView: View {
    @Binding var members: [User]
    let event: Event
    @Binding var groupChatRoom: ChatRoom?
    
    @Environment(\.dismiss) private var dismiss
    @State private var viewItem: ViewItem?
    @State private var membersToRemove: Set<String> = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with event info
                VStack(spacing: 8) {
                    Text("Group Chat Members")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.labelColor)
                    
                    Text("\(event.name)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text("\(members.count) member\(members.count == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 20)
                .background(Color.bgColor)
                
                Divider()
                
                // Members list
                List {
                    ForEach(members, id: \.userID) { member in
                        Button(action: {
                            // Navigate to user profile
                            let profileView = UserProfileView(user: member)
                            viewItem = ViewItem(AnyView(profileView), _presentationStyle: .fullScreen)
                        }) {
                            HStack(spacing: 12) {
                                // Profile picture
                                PfpView(user: member, size: 50, isRound: true, strokeWidth: 1)
                                
                                // User info
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(member.fullName)
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.labelColor)
                                    
                                    Text("@\(member.username)")
                                        .font(.system(size: 14, weight: .light))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                // Host indicator
                                if event.hostIDs.contains(member.userID) {
                                    Text("Host")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.appColor)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.appColor.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                                
                                // Arrow
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.bgColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowBackground(Color.bgColor)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            // Allow removal if user is not a host (anyone can remove non-hosts)
                            if !event.hostIDs.contains(member.userID) {
                                Button(role: .destructive) {
                                    removeMember(member)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.bgColor)
                .scrollContentBackground(.hidden)
            }
            .background(Color.bgColor)
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.appColor)
                }
            }
        }
        .fullScreenCover(item: $viewItem) { viewItem in
            viewItem.viewToPresent
        }
    }
    
    // MARK: - Helper Functions
    
    private func isCurrentUserHost() -> Bool {
        guard let currentUserID = UserManager.shared.currentUserID else { return false }
        return event.hostIDs.contains(currentUserID)
    }
    
    private func removeMember(_ member: User) {
        guard let room = groupChatRoom else {
            print("❌ Cannot remove member: No group chat room")
            return
        }
        
        print("🔄 Removing member: \(member.fullName) from group chat")
        
        // Remove the user from the participants list
        var updatedParticipants = room.participantsIDs
        updatedParticipants.removeAll { $0 == member.userID }
        
        // Update the chat room in Firebase
        let database = Firestore.firestore()
        database.collection("chatrooms").document(room.roomID).updateData([
            "participantsIDs": updatedParticipants
        ]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error removing member from group chat: \(error.localizedDescription)")
                } else {
                    print("✅ Successfully removed member from group chat")
                    
                    // Update local room state
                    var updatedRoom = room
                    updatedRoom.participantsIDs = updatedParticipants
                    self.groupChatRoom = updatedRoom
                    
                    // Remove from local members list
                    self.members.removeAll { $0.userID == member.userID }
                    
                    // Send notification to removed user
                    EnhancedNotificationManager.shared.sendGroupChatRemovalNotification(
                        removedUserID: member.userID,
                        eventName: self.event.name,
                        removerID: UserManager.shared.currentUserID ?? ""
                    ) { success in
                        if !success {
                            print("Failed to send group chat removal notification")
                        }
                    }
                }
            }
        }
    }
}


struct GroupChatView_Previews: PreviewProvider {
    static var previews: some View {
        GroupChatView(
            event: Event(),
            groupChatRoom: .constant(nil),
            groupChatMessages: .constant([]),
            newGroupMessage: .constant(""),
            groupChatMembers: .constant([]),
            showInviteSheet: .constant(false),
            isHostOnly: .constant(true)
        )
    }
}
