//
//  StoriesView.swift
//  KiccBacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import Combine
import SDWebImageSwiftUI

// MARK: - StoriesView
struct StoriesView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentation
    
    let stories: [Story]
    
    init(stories: [Story]) {
        self.stories = stories
    }
    
    var body: some View {
        StoriesContentView(stories: stories)
            .preferredColorScheme(.dark)
    }
}

// MARK: - StoriesContentView
struct StoriesContentView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentation
    
    let stories: [Story]
    
    // MARK: - State Management
    @StateObject private var viewModel = StoriesViewModel()
    @State private var viewItem: ViewItem?
    
    init(stories: [Story]) {
        self.stories = stories
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            if viewModel.isLoading {
                LoadingView()
            } else if let currentStory = viewModel.currentStory {
                StoryDisplayView(
                    story: currentStory,
                    user: viewModel.currentUser,
                    progress: viewModel.progress,
                    totalStories: stories.count,
                    currentIndex: viewModel.currentIndex,
                    onDismiss: { presentation.wrappedValue.dismiss() },
                    onPrevious: viewModel.previousStory,
                    onNext: viewModel.nextStory,
                    onReply: viewModel.sendReply,
                    onDelete: viewModel.deleteStory,
                    isCreator: viewModel.isCurrentUserCreator,
                    viewers: viewModel.storyViewers,
                    onPauseTimer: viewModel.pauseTimer,
                    onResumeTimer: viewModel.resumeTimer,
                    onLikeToggle: { viewModel.refreshCurrentStory() }
                )
            } else if viewModel.currentStory == nil && !viewModel.isLoading {
                // Stories are exhausted, dismiss the view
                Color.clear
                    .onAppear {
                        presentation.wrappedValue.dismiss()
                    }
            } else {
                ErrorView(
                    message: "Unable to load stories",
                    onRetry: viewModel.retryLoading,
                    onDismiss: { presentation.wrappedValue.dismiss() }
                )
            }
        }
        .onAppear {
            viewModel.initialize(with: stories)
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .fullScreenCover(item: $viewItem) { viewItem in
            viewItem.viewToPresent
        }
    }
}

// MARK: - StoriesViewModel
@MainActor
class StoriesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentStory: Story?
    @Published var currentUser: User?
    @Published var currentIndex: Int = 0
    @Published var progress: Double = 0.0
    @Published var isLoading: Bool = true
    @Published var storyViewers: [User] = []
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var stories: [Story] = []
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var imageCache: [String: Bool] = [:]
    private let storyDuration: TimeInterval = 15.0
    private var isPaused: Bool = false
    
    // MARK: - Computed Properties
    var isCurrentUserCreator: Bool {
        guard let currentStory = currentStory,
              let currentUserID = UserManager.shared.currentUserID else {
            return false
        }
        return currentStory.creatorID == currentUserID
    }
    
    // MARK: - Initialization
    func initialize(with stories: [Story]) {
        self.stories = stories.filter { !$0.storyID.isEmpty }
        
        guard !self.stories.isEmpty else {
            self.isLoading = false
            self.errorMessage = "No stories available"
            return
        }
        
        loadCurrentStory()
        preloadImages()
    }
    
    // MARK: - Story Loading
    private func loadCurrentStory() {
        guard currentIndex < stories.count else {
            dismiss()
            return
        }
        
        let storyID = stories[currentIndex].storyID
        print("🔔 Loading current story at index \(currentIndex) with ID: \(storyID)")
        
        // Fetch fresh story data from Firestore
        FirestoreService.getDocument(inCollection: "stories", withID: storyID) { [weak self] (story: Story?) in
            DispatchQueue.main.async {
                guard let self = self, let story = story else {
                    print("❌ Failed to load story with ID: \(storyID)")
                    self?.isLoading = false
                    return
                }
                
                print("✅ Loaded fresh story data for \(storyID) - likeCount: \(story.likeCount), likedBy: \(story.likedByUserIDs)")
                self.currentStory = story
                
                // Load user data
                self.loadUserData(for: story.creatorID)
                
                // Mark as seen
                self.markStoryAsSeen(story)
                
                // Load viewers if creator
                if self.isCurrentUserCreator {
                    self.loadStoryViewers(for: story)
                }
                
                // Start timer
                self.startTimer()
                
                self.isLoading = false
            }
        }
    }
    
    private func loadUserData(for userID: String) {
        UserManager.shared.getUser(withUserID: userID) { [weak self] user in
            DispatchQueue.main.async {
                self?.currentUser = user
            }
        }
    }
    
    private func loadStoryViewers(for story: Story) {
        UserManager.shared.getFourUsers(withuserIDs: story.viewedByUserIDs) { [weak self] users in
            DispatchQueue.main.async {
                self?.storyViewers = users ?? []
            }
        }
    }
    
    private func markStoryAsSeen(_ story: Story) {
        guard let currentUserID = UserManager.shared.currentUserID else { return }
        
        StoryManager.shared.isStory(story, seenBy: currentUserID) { error in
            if let error = error {
                print("Failed to mark story as seen: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Navigation
    func nextStory() {
        stopTimer()
        
        if currentIndex + 1 < stories.count {
            currentIndex += 1
            loadCurrentStory()
        } else {
            dismiss()
        }
    }
    
    func previousStory() {
        stopTimer()
        
        if currentIndex > 0 {
            currentIndex -= 1
            loadCurrentStory()
        }
    }
    
    func refreshCurrentStory() {
        print("🔔 Refreshing current story after like toggle")
        loadCurrentStory()
    }
    
    private func dismiss() {
        // This method is called when stories are exhausted
        // The parent view will handle the actual dismissal
        // We just need to signal that we're done
        isLoading = false
        currentStory = nil
    }
    
    // MARK: - Timer Management
    private func startTimer() {
        stopTimer()
        
        progress = 0.0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateProgress() {
        guard !isPaused else { return }
        
        progress += 0.1 / storyDuration
        
        if progress >= 1.0 {
            nextStory()
        }
    }
    
    func pauseTimer() {
        isPaused = true
    }
    
    func resumeTimer() {
        isPaused = false
    }
    
    // MARK: - Image Preloading
    private func preloadImages() {
        let urls = stories.compactMap { URL(string: $0.imageUrlString) }
        
        let prefetcher = SDWebImagePrefetcher.shared
        prefetcher.maxConcurrentPrefetchCount = 3
        
        prefetcher.prefetchURLs(urls, options: [.highPriority, .retryFailed], context: nil) { [weak self] _, _ in
            DispatchQueue.main.async {
                for story in self?.stories ?? [] {
                    self?.imageCache[story.storyID] = true
                }
            }
        }
    }
    
    // MARK: - Actions
    func sendReply(_ message: String) {
        // Validate all required data
        guard let currentStory = currentStory else {
            print("❌ Story reply failed: No current story")
            return
        }
        
        guard let currentUserID = UserManager.shared.currentUserID else {
            print("❌ Story reply failed: No current user ID")
            return
        }
        
        guard let receiverID = currentUser?.userID, !receiverID.isEmpty else {
            print("❌ Story reply failed: Invalid receiver ID - currentUser: \(String(describing: currentUser)), userID: \(String(describing: currentUser?.userID))")
            return
        }
        
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("❌ Story reply failed: Empty message")
            return
        }
        
        print("✅ Story reply validation passed - Sending reply to user: \(receiverID)")
        
        let messageID = UUID().uuidString
        let reply = Message(
            storyID: currentStory.storyID,
            messageID: messageID,
            senderID: currentUserID,
            receiverID: receiverID,
            content: message,
            createdAt: Date()
        )
        
        // Send reply
        sendMessage(reply)
        
        // Send notification
        EnhancedNotificationManager.shared.sendStoryReplyNotification(
            replierID: currentUserID,
            storyID: currentStory.storyID,
            replyContent: message
        ) { success in
            if !success {
                print("Failed to send story reply notification")
            }
        }
    }
    
    private func sendMessage(_ message: Message) {
        guard let senderUserID = UserManager.shared.currentUserID else {
            print("❌ Send message failed: No sender user ID")
            return
        }
        
        guard let receiverUserID = currentUser?.userID, !receiverUserID.isEmpty else {
            print("❌ Send message failed: Invalid receiver user ID - currentUser: \(String(describing: currentUser))")
            return
        }
        
        print("✅ Send message validation passed - Sender: \(senderUserID), Receiver: \(receiverUserID)")
        
        ChatroomManager.shared.getChatRooms(
            whereField: "participantsIDs",
            withValues: [senderUserID, receiverUserID]
        ) { [weak self] rooms in
            if let rooms = rooms, let room = rooms.first {
                print("✅ Found existing chat room: \(room.roomID)")
                self?.send(message: message, to: room)
            } else {
                // Create new room
                let roomID = UUID().uuidString
                let room = ChatRoom(
                    roomID: roomID,
                    participantsIDs: [senderUserID, receiverUserID]
                )
                
                print("🔄 Creating new chat room: \(roomID)")
                
                do {
                    try ChatroomManager.shared.create(room: room)
                    self?.send(message: message, to: room)
                } catch {
                    print("❌ Failed to create chat room: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func send(message: Message, to chatRoom: ChatRoom) {
        UserManager.shared.getCurrentUser { [weak self] sender in
            guard let self = self else {
                print("❌ Send failed: Self is nil")
                return
            }
            
            guard let sender = sender else {
                print("❌ Send failed: Sender is nil")
                return
            }
            
            guard let currentUser = self.currentUser else {
                print("❌ Send failed: Current user is nil")
                return
            }
            
            print("✅ Send validation passed - Sending message to chat room: \(chatRoom.roomID)")
            
            do {
                // Use createWithoutNotification to avoid sending message notification
                // Story reply notification is handled separately
                try MessageManager.shared.createWithoutNotification(
                    in: chatRoom,
                    with: message,
                    to: currentUser
                )
                print("✅ Story reply message sent successfully (no message notification)")
            } catch {
                print("❌ Failed to send story reply message: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteStory() {
        guard let currentStory = currentStory else { return }
        
        StoryManager.shared.delete(story: currentStory) { [weak self] isDeleted in
            DispatchQueue.main.async {
                if isDeleted {
                    // Remove from local array
                    self?.stories.removeAll { $0.storyID == currentStory.storyID }
                    
                    if let stories = self?.stories, stories.isEmpty {
                        self?.dismiss()
                    } else {
                        // Adjust index if needed
                        if let currentIndex = self?.currentIndex,
                           currentIndex >= (self?.stories.count ?? 0) {
                            self?.currentIndex = max(0, (self?.stories.count ?? 1) - 1)
                        }
                        self?.loadCurrentStory()
                    }
                }
            }
        }
    }
    
    func retryLoading() {
        isLoading = true
        errorMessage = nil
        loadCurrentStory()
    }
    
    // MARK: - Cleanup
    func cleanup() {
        stopTimer()
        cancellables.removeAll()
        imageCache.removeAll()
    }
}

// MARK: - StoryDisplayView
struct StoryDisplayView: View {
    
    let story: Story
    let user: User?
    let progress: Double
    let totalStories: Int
    let currentIndex: Int
    let onDismiss: () -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onReply: (String) -> Void
    let onDelete: () -> Void
    let isCreator: Bool
    let viewers: [User]
    let onPauseTimer: () -> Void
    let onResumeTimer: () -> Void
    let onLikeToggle: () -> Void
    
    @State private var message: String = ""
    @State private var isMessageEntered: Bool = false
    @State private var isViewersViewPresenting: Bool = false
    @State private var isLeftSidePaused: Bool = false
    @State private var isRightSideHeld: Bool = false
    @State private var isProfilePresenting: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Story Image
                StoryImageView(story: story)
                
                // Navigation overlay - excludes header and footer areas
                VStack(spacing: 0) {
                    // Top spacer - no navigation
                    Color.clear
                        .frame(height: 120) // Space for header
                        .zIndex(0)
                    
                    // Middle area - navigation enabled
                    HStack {
                        // Left side - First tap pauses timer, second tap goes to previous
                        Color.clear
                            .frame(width: UIScreen.main.bounds.width / 2)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isLeftSidePaused {
                                    // Second tap - go to previous story
                                    onPrevious()
                                    isLeftSidePaused = false
                                } else {
                                    // First tap - pause timer
                                    isLeftSidePaused = true
                                    onPauseTimer()
                                    print("🔍 Left side tapped - Timer paused")
                                }
                            }
                        
                        // Right side - Hold to pause timer, tap to go to next
                        Color.clear
                            .frame(width: UIScreen.main.bounds.width / 2)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if !isRightSideHeld {
                                    // Single tap - go to next story
                                    onNext()
                                }
                            }
                            .onLongPressGesture(minimumDuration: 0.1) {
                                // Hold gesture - pause timer
                                isRightSideHeld = true
                                onPauseTimer()
                                print("🔍 Right side held - Timer paused")
                            } onPressingChanged: { pressing in
                                if !pressing {
                                    // Released - resume timer
                                    isRightSideHeld = false
                                    onResumeTimer()
                                    print("🔍 Right side released - Timer resumed")
                                }
                            }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(1) // Below UI elements but above story image
                    
                    // Bottom spacer - no navigation
                    Color.clear
                        .frame(height: 120) // Space for footer
                        .zIndex(0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // UI Elements Overlay
                VStack(spacing: 0) {
                    // Header - Above navigation
                    StoryHeaderView(
                        user: user,
                        story: story,
                        progress: progress,
                        totalStories: totalStories,
                        currentIndex: currentIndex,
                        onDismiss: onDismiss,
                        onDelete: onDelete,
                        isCreator: isCreator,
                        isProfilePresenting: $isProfilePresenting
                    )
                    .zIndex(5) // Above everything
                    
                    // Middle spacer
                    Spacer()
                        .zIndex(2) // Above navigation
                    
                    // Footer - Above navigation
                    VStack {
                        Spacer()
                        
                        if isCreator {
                            StoryViewersView(
                                viewers: viewers,
                                onViewersTap: { 
                                    print("🔍 Seen button tapped! isViewersViewPresenting was: \(isViewersViewPresenting)")
                                    isViewersViewPresenting = true 
                                    print("🔍 Seen button tapped! isViewersViewPresenting is now: \(isViewersViewPresenting)")
                                }
                            )
                            .zIndex(10) // Much higher z-index
                            .allowsHitTesting(true)
                            .background(Color.clear) // Ensure it's not transparent
                        } else {
                            StoryReplyView(
                                message: $message,
                                isMessageEntered: $isMessageEntered,
                                onReply: onReply
                            )
                            .zIndex(4) // Above navigation
                        }
                    }
                    .zIndex(3) // Above navigation
                }
                
                // Like Button - Positioned above everything
                VStack {
                    Spacer()
                    
                    HStack {
                        StoryLikeView(
                            story: story,
                            isCreator: isCreator,
                            onLikeToggle: onLikeToggle
                        )
                        
                        Spacer()
                    }
                    .padding(.leading, 20)
                    .offset(y: -100) // Position above footer
                }
                .zIndex(6) // Above everything including header
            }
        }
        .fullScreenCover(isPresented: $isViewersViewPresenting) {
            ListOfUsersView(
                userIDs: story.viewedByUserIDs,
                usersKind: .seenBy,
                isHost: false,
                eventID: ""
            )
            .onAppear {
                print("🔍 ListOfUsersView appeared!")
            }
        }
        .fullScreenCover(isPresented: $isProfilePresenting) {
            if let user = user, !user.userID.isEmpty, !user.fullName.isEmpty {
                NavigationView {
                    UserProfileView(user: user)
                        .navigationBarHidden(true)
                }
                .onDisappear {
                    print("🔍 Profile view disappeared")
                }
            } else {
                // Fallback view in case of invalid user data
                VStack {
                    Text("Unable to load profile")
                        .foregroundColor(.white)
                        .padding()
                    
                    Button("Close") {
                        isProfilePresenting = false
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            }
        }
        .onChange(of: isViewersViewPresenting) { newValue in
            print("🔍 isViewersViewPresenting changed to: \(newValue)")
        }
        .onChange(of: isProfilePresenting) { newValue in
            print("🔍 isProfilePresenting changed to: \(newValue)")
            if !newValue {
                // Reset left side pause state when profile is dismissed
                isLeftSidePaused = false
                print("✅ Profile dismissed, state reset")
            }
        }
        .onChange(of: message) { newValue in
            withAnimation {
                isMessageEntered = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }
    }
}

// MARK: - StoryImageView
struct StoryImageView: View {
    
    let story: Story
    @State private var isImageLoaded: Bool = false
    
    var body: some View {
        if let url = URL(string: story.imageUrlString) {
            WebImage(url: url)
                .onSuccess { _, _, _ in
                    isImageLoaded = true
                }
                .onFailure { error in
                    print("Image failed to load: \(error)")
                }
                .resizable()
                .indicator(.activity)
                .transition(.fade(duration: 0.2))
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all, edges: .all)
        } else {
            Color.black.ignoresSafeArea()
        }
    }
}

// MARK: - StoryHeaderView
struct StoryHeaderView: View {
    
    let user: User?
    let story: Story
    let progress: Double
    let totalStories: Int
    let currentIndex: Int
    let onDismiss: () -> Void
    let onDelete: () -> Void
    let isCreator: Bool
    @Binding var isProfilePresenting: Bool
    
    @State private var lastTapTime: Date = .distantPast
    
    var body: some View {
        VStack {
            HStack {
                if let user = user {
                    Button {
                        // Debounce: Prevent rapid taps (minimum 0.5 seconds between taps)
                        let now = Date()
                        guard now.timeIntervalSince(lastTapTime) > 0.5 else {
                            print("⚠️ Tap ignored - too fast (debounced)")
                            return
                        }
                        lastTapTime = now
                        
                        // Safety checks to prevent crashes
                        guard !isProfilePresenting else { 
                            print("⚠️ Profile already presenting, ignoring tap")
                            return 
                        }
                        
                        // Validate user data before opening profile
                        guard !user.userID.isEmpty else {
                            print("⚠️ Cannot open profile: User ID is empty")
                            return
                        }
                        
                        guard !user.fullName.isEmpty else {
                            print("⚠️ Cannot open profile: User name is empty")
                            return
                        }
                        
                        print("✅ Opening profile for user: \(user.fullName) (ID: \(user.userID))")
                        isProfilePresenting = true
                    } label: {
                        HStack {
                            PfpView(user: user, size: 40, cornerRadius: 0, isRound: true, strokeWidth: 0)
                            
                            Text(user.fullName)
                                .font(.system(size: 16, weight: .bold, design: .default))
                                .foregroundColor(.labelColor)
                                .lineLimit(1)
                        }
                    }
                    
                    Text("·")
                    
                    Text(Date().getRelativeDate(from: story.createdAt))
                        .font(.system(size: 13, weight: .regular, design: .default))
                }
                
                Spacer()
                
                HStack(alignment: .center, spacing: 0) {
                    if isCreator {
                        Menu {
                            Button("Delete", role: .destructive, action: onDelete)
                        } label: {
                            HStack(alignment: .center, spacing: 2) {
                                Group {
                                    Circle()
                                        .fill(Color.labelColor)
                                    Circle()
                                        .fill(Color.labelColor)
                                    Circle()
                                        .fill(Color.labelColor)
                                }
                                .frame(width: 4, height: 4)
                            }
                            .padding(10)
                        }
                        .zIndex(8) // Above everything
                        .allowsHitTesting(true)
                        .onTapGesture {
                            print("🔍 Three dots menu tapped!")
                        }
                    }
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .foregroundColor(.labelColor)
                            .padding(10)
                    }
                }
            }
            
            // Progress Indicators
            HStack(spacing: 4) {
                ForEach(0..<totalStories, id: \.self) { index in
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 10)
                                .frame(height: 2.5)
                                .foregroundColor(.appColor.opacity(0.3))
                            
                            // Progress
                            if index < currentIndex {
                                // Completed
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(height: 2.5)
                                    .foregroundColor(.appColor)
                            } else if index == currentIndex {
                                // Current
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: geometry.size.width * progress, height: 2.5)
                                    .foregroundColor(.appColor)
                                    .animation(.linear, value: progress)
                            }
                        }
                    }
                    .frame(height: 2.5)
                }
            }
            .padding(.horizontal, 10)
        }
        .padding()
        .background(BlurView(style: .systemThinMaterial))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

// MARK: - StoryReplyView
struct StoryReplyView: View {
    
    @Binding var message: String
    @Binding var isMessageEntered: Bool
    let onReply: (String) -> Void
    
    var body: some View {
        HStack {
            TextField("Leave a reply ...", text: $message)
                .padding(10)
                .padding(.leading, 10)
                .background(BlurView(style: .systemThinMaterial))
                .clipShape(Capsule())
            
            if isMessageEntered {
                Button {
                    onReply(message)
                    message = ""
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 40, height: 40)
                            .background(BlurView(style: .systemThinMaterial))
                            .clipShape(Circle())
                        
                        Assets.UI.sendMessage
                            .foregroundColor(.labelColor)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 60)
        .allowsHitTesting(true)
        .zIndex(4) // Ensure reply area is above everything
    }
}

// MARK: - StoryViewersView
struct StoryViewersView: View {
    
    let viewers: [User]
    let onViewersTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .center, spacing: 5) {
                HStack(alignment: .center, spacing: (viewers.count > 1) ? 0 : -15) {
                    ForEach(viewers, id: \.userID) { user in
                        PfpView(user: user, size: 30, isRound: true, strokeWidth: 0)
                    }
                }
                
                HStack(spacing: 4) {
                    Text("Seen by")
                        .font(.system(size: 13, weight: .regular, design: .default))
                        .foregroundColor(.labelColor)
                    
                    Text("\(viewers.count)")
                        .font(.system(size: 13, weight: .bold, design: .default))
                        .foregroundColor(.appColor)
                }
            }
            .padding(.vertical)
            
            Spacer()
        }
        .padding()
        .padding(.leading, 10)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 60)
        .padding(.vertical)
        .background(Color.black.opacity(0.3))
        .background(BlurView(style: .systemThinMaterialDark))
        .cornerRadius(10, corners: [.topLeft, .topRight])
        .allowsHitTesting(true)
        .contentShape(Rectangle()) // Ensure entire area is tappable
        .onTapGesture {
            print("🔍 StoryViewersView tapped!")
            onViewersTap()
        }
    }
}

// MARK: - LoadingView
struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            
            Text("Loading stories...")
                .foregroundColor(.white)
                .padding(.top)
        }
    }
}

// MARK: - ErrorView
struct ErrorView: View {
    
    let message: String
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text(message)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 20) {
                Button("Retry", action: onRetry)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
                
                Button("Close", action: onDismiss)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.gray)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}

// MARK: - Preview
struct StoriesView_Previews: PreviewProvider {
    static var previews: some View {
        StoriesView(stories: [Story(), Story()])
    }
}
