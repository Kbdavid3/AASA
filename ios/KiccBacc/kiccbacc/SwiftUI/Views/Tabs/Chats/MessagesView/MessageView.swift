//
//  MessageView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import Combine
//import SDWebImageSwiftUI

struct MessageView: View {
    
    @Environment(\.presentationMode) private var presentation
    
    @StateObject private var viewModel = MessagesViewViewModel()
    
    var user: User
    var chatroom: ChatRoom
    
    @State private var currentUser: User?
    @State private var newMessage: String = ""
    @State private var showStoryView: Bool = false
    @State private var viewItem: ViewItem?
    @State private var isMessageEntered: Bool = false
    @State private var scrollViewYOffset: CGFloat = 0
    @State private var scrollTarget: String?
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    Button {
                        presentation.wrappedValue.dismiss()
                    } label: {
                        Assets.UI.arrowLeft
                            .foregroundColor(.labelColor)
                    }

                    Button {
                        let profileView = NavigationView {
                            UserProfileView(user: user)
                        }
                        viewItem = ViewItem(AnyView(profileView), _presentationStyle: .fullScreen)
                    } label: {
                        HStack(spacing: 8) {
                            // Profile Picture
                            PfpView(user: user, size: 32, isRound: true, strokeWidth: 1)
                            
                            // User Name
                            Text(user.fullName)
                                .font(.system(size: 16, weight: .bold, design: .default))
                                .foregroundColor(.labelColor)
                            
                            Spacer()
                        }
                    }
                    .contentShape(Rectangle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
            }
            .background(Color.clear)
            
            // Messages Area
            if let messages = viewModel.messages, messages.count > 0 {
                ScrollView(.vertical, showsIndicators: false) {
                    ScrollViewReader { scrollView in
                        VStack(spacing: 8) {
                            ForEach(Array(messages.enumerated()), id: \.element.messageID) { index, message in
                                let previousMessage = index > 0 ? messages[index - 1] : nil
                                
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
                                    MessageComponent(message: message, viewItem: $viewItem, formatTime: formatMessageTime)
                                }
                            }
                            .offset(y: -scrollViewYOffset)
                            .onChange(of: scrollTarget) { target in
                                withAnimation {
                                    scrollView.scrollTo(target, anchor: .bottom)
                                }
                            }
                            .onChange(of: keyboardHeight){ target in
                                if let scrollTarget = scrollTarget {
                                    withAnimation {
                                        scrollView.scrollTo(scrollTarget, anchor: .bottom)
                                    }
                                }
                            }
                            .onAppear {
                                withAnimation {
                                    scrollView.scrollTo(messages[messages.endIndex - 1], anchor: .bottom)
                                }
                            }
                            .onReceive(viewModel.$messages) { messages in
                                if let messages = messages {
                                    if messages.count > 0 {
                                        withAnimation {
                                            scrollView.scrollTo(messages.last!.messageID, anchor: .bottom)
                                        }
                                        self.scrollTarget = messages.last!.messageID
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                    }
                }
            } else {
                // Empty state
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "message.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No messages yet")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text("Start a conversation!")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray.opacity(0.7))
                    
                    Spacer()
                }
            }
            
            // Message Input Area
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $newMessage)
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
                    
                    if isMessageEntered {
                        Button {
                            sendMessage()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.appColor)
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .scaleEffect(isMessageEntered ? 1.0 : 0.8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isMessageEntered)
                    } else {
                        // Placeholder button when no text
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color.clear)
            .padding(.bottom, 100) // Add padding to account for tab bar
        }
        .padding(.bottom, keyboardHeight)
        .onReceive(Publishers.keyboardHeight) {
            self.keyboardHeight = $0 / 15
            self.scrollViewYOffset = $0 / 10
        }
        .onChange(of: newMessage) { newValue in
            if newValue.count > 0 {
                withAnimation { isMessageEntered = true }
            } else if isMessageEntered {
                withAnimation { isMessageEntered = false }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $viewItem) { fullScreenViewItem in
            fullScreenViewItem.viewToPresent
        }
        .onAppear {
            viewModel.fetchMessages(in: chatroom.roomID)
            
            guard let currentUserID = UserManager.shared.currentUserID else {
                return
            }

            UserManager.shared.getUser(withUserID: currentUserID) { user in
                self.currentUser = user
            }
        }
    }
    
    private struct MessageComponent: View {
        
        var message: Message
        @Binding var viewItem: ViewItem?
        let formatTime: (Date) -> String
        
        @State private var story: Story?
        
        var body: some View {
            if message.senderID == UserManager.shared.currentUserID {
                SentMessageView(message: message, viewItem: $viewItem, formatTime: formatTime)
            } else {
                ReceivedMessageView(message: message, viewItem: $viewItem, formatTime: formatTime)
            }
        }
        
        private struct ReceivedMessageView : View {
            
            var message: Message
            @Binding var viewItem: ViewItem?
            let formatTime: (Date) -> String
            
            @State private var story: Story?
            
            var body: some View {
                VStack(alignment: .leading, spacing: 10) {
                    if let story = story, let url = URL(string: story.imageUrlString) {
                        Button {
                            viewItem = ViewItem(AnyView(
                                StoriesView(stories: [story])
                            ), _presentationStyle: .fullScreen)
                        } label: {
                            KBImage(url: url, resizeMode: .fill)
                                .frame(minWidth: 0, maxWidth: UIScreen.main.bounds.width / 3, minHeight: 0, maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        Text("replied to your story")
                            .font(.system(size: 12, weight: .light, design: .default))
                            .foregroundColor(.gray)
                            .padding(.leading, 5)
                    }
                    
                    HStack {
                        if message.content.count > 20 {
                            
                            Text(message.content)
                                .padding()
                                .background(Color.secondaryBgColor)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .font(.system(size: 15, weight: .regular, design: .default))
                        } else {
                            
                            Text(message.content)
                                .padding()
                                .background(Color.secondaryBgColor)
                                .clipShape(Capsule())
                                .font(.system(size: 15, weight: .regular, design: .default))
                        }
                        
                        Spacer()
                    }
                    
                    // Message timestamp
                    Text(formatTime(message.createdAt))
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.gray)
                        .padding(.leading, 8)
                }
                .onAppear {
                    if let storyID = message.storyID {
                        StoryManager.shared.getStory(withStoryID: storyID) { story in
                            withAnimation {
                                self.story = story
                            }
                        }
                    }
                }
            }
        }
        
        private struct SentMessageView : View {
            
            var message: Message
            @Binding var viewItem: ViewItem?
            let formatTime: (Date) -> String
            
            @State private var story: Story?
            
            var body: some View {
                VStack(alignment: .trailing, spacing: 10) {
                    if let story = story, let url = URL(string: story.imageUrlString) {
                        Button {
                            viewItem = ViewItem(AnyView(
                                StoriesView(stories: [story])
                            ), _presentationStyle: .fullScreen)
                        } label: {
                            KBImage(url: url, resizeMode: .fill)
                                .frame(minWidth: 0, maxWidth: UIScreen.main.bounds.width / 3, minHeight: 0, maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        Text("you replied to their story")
                            .font(.system(size: 12, weight: .light, design: .default))
                            .foregroundColor(.gray)
                            .padding(.leading, 5)
                    }
                    
                    HStack {
                        Spacer()
                        
                        if message.content.count > 20 {
                            
                            Text(message.content)
                                .padding()
                                .background(Color.buttonBgColor)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .font(.system(size: 15, weight: .regular, design: .default))
                                .foregroundColor(.white)
                        } else {
                            
                            Text(message.content)
                                .padding()
                                .background(Color.buttonBgColor)
                                .clipShape(Capsule())
                                .font(.system(size: 15, weight: .regular, design: .default))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Message timestamp
                    Text(formatTime(message.createdAt))
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.gray)
                        .padding(.trailing, 8)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .onAppear {
                    if let storyID = message.storyID {
                        StoryManager.shared.getStory(withStoryID: storyID) { story in
                            withAnimation {
                                self.story = story
                            }
                        }
                    }
                }
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
    
    private func sendMessage() {
        guard let currentUserID = UserManager.shared.currentUserID else {
            return
        }
        
        let messageID = UUID().uuidString
        let senderID = currentUserID
        let receiverID = user.userID
        
        let message = Message(messageID: messageID, senderID: senderID, receiverID: receiverID, content: newMessage)
        
        do {
            // Notification functionality removed as requested
            // var pushNotification: PushNotification!
            
            // if let sender = currentUser {
            //     pushNotification = PushNotification(title: "[\(user.username)] \(sender.fullName)", body: message.content, sendToToken: "-")
            // } else {
            //     pushNotification = PushNotification(title: "You received a new message", body: message.content, sendToToken: "-")
            // }
            
            // Create a placeholder for pushNotification since it's required by the method signature
            let placeholderNotification = "placeholder"
            try MessageManager.shared.create(in: chatroom, with: message, pushNotification: placeholderNotification, to: user)
            
            // Update the last message in the chat room
            MessageDataRepository.shared.updateLastMessage(in: chatroom, lastMessage: newMessage, lastMessageTime: Date())
            
            self.newMessage = ""
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(user: User(), chatroom: ChatRoom())
            .preferredColorScheme(.dark)
    }
}

// keyboard shift
extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map { $0.keyboardHeight }
        
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
        
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

extension Notification {
    var keyboardHeight: CGFloat {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
    }
}
