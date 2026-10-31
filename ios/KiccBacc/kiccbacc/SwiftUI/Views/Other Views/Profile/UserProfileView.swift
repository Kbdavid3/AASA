//
//  UserProfileView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI

struct NavigationLinkViewItem: Identifiable, Hashable {
    
    static func == (lhs: NavigationLinkViewItem, rhs: NavigationLinkViewItem) -> Bool {
        lhs.tag == rhs.tag
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }
    
    var id: String {
        UUID().uuidString
    }
    
    var viewToPresent: AnyView
    var tag: Int
    
    init(_ view: AnyView, _ tag: Int) {
        self.viewToPresent = view
        self.tag = tag
    }
}


struct UserProfileView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentation
    
    var user: User
    
    @State private var events: [Event]?
    @State private var viewItem: ViewItem?
    @State private var isFollowing: Bool = false
    @State private var followers: [User]?
    @State private var navLinkViewItem: NavigationLinkViewItem?
    @State private var isFollowLoading: Bool = false
    @State private var isViewDismissible: Bool = true
    
    var body: some View {
        if user.userID == UserManager.shared.currentUserID {
            SelfProfileView()
        } else {
            ZStack {
                // Background color for entire view
                Color.bgColor.ignoresSafeArea()
                
                // Overlay to prevent interaction during loading
                if isFollowLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
                
                VStack {
                    HStack {
                        Button {
                            print("UserProfileView: Back button pressed")
                            presentation.wrappedValue.dismiss()
                        } label: {
                            Assets.UI.arrowLeft
                                .foregroundColor(.labelColor)
                        }
                        
                        Text("@ \(user.username)")
                            .font(.system(size: 22, weight: .bold, design: .default))
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .center, spacing: 30) {
                            // Add verification badge to profile picture
                            ZStack(alignment: .bottomTrailing) {
                                PfpView(user: user, size: 185, cornerRadius: 0, isRound: true, strokeWidth: 0)
                                
                                // Add verification badge if user is verified
                                if user.verified == true {
                                    Image("Verified")
                                        .resizable()
                                        .frame(width: 100, height: 100)
                                        .offset(x: 25, y: 25)
                                }
                            }
                            
                            VStack(alignment: .center, spacing: 4) {
                                // Add small "verified" text next to user's name
                                HStack(alignment: .center, spacing: 5) {
                                    Text("\(user.fullName)")
                                        .font(.system(size: 30, weight: .bold, design: .default))
                                    
                                    if user.verified == true {
                                        Text("verified")
                                            .font(.system(size: 12, weight: .medium, design: .default))
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                //                        Text("user.preferredLocation")
                                //                            .font(.system(size: 20, weight: .medium, design: .default))
                                
                                Text("\(user.bio)")
                                    .font(.system(size: 14, weight: .regular, design: .default))
                                
                                // Social Media Links
                                SocialMediaLinksView(user: user)
                                    .padding(.bottom, 24)
                                
                                // Interests Tags
                                InterestsTagsView(user: user, isCurrentUser: user.userID == UserManager.shared.currentUserID)
                            }
                            
                            HStack(alignment: .center, spacing: -15) {
                                if let followers = followers {
                                    HStack(alignment: .center, spacing: -15) {
                                        ForEach(followers, id: \.userID) { follower in
                                            PfpView(user: follower, size: 40, isRound: true)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.bgColor, lineWidth: 4)
                                                )
                                        }
                                    }
                                    .padding(.trailing, 25)
                                }
                                
                                HStack(alignment: .center, spacing: 15) {
                                    NavigationLink {
                                        ListOfUsersView(userIDs: user.followerIDs, usersKind: .followers, isHost: false, eventID: "")
                                            .navigationTitle("Followers")
                                    } label: {
                                        VStack {
                                            Text("\(user.followerCounter)")
                                                .font(.system(size: 20, weight: .bold, design: .default))
                                            
                                            Text("Followers")
                                                .font(.system(size: 10, weight: .medium, design: .default))
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    NavigationLink {
                                        ListOfUsersView(userIDs: user.followingIDs, usersKind: .following, isHost: false, eventID: "")
                                            .navigationTitle("Following")
                                    } label: {
                                        VStack {
                                            Text("\(user.followingCounter)")
                                                .font(.system(size: 20, weight: .bold, design: .default))
                                            
                                            Text("Following")
                                                .font(.system(size: 10, weight: .medium, design: .default))
                                        }
                                    }
                                }
                                .foregroundColor(.labelColor)
                            }
                            
                            HStack {
                                Button {
                                    print("UserProfileView: Follow/Unfollow button pressed")
                                    print("UserProfileView: Current isFollowing state: \(isFollowing)")
                                    print("UserProfileView: Current isFollowLoading state: \(isFollowLoading)")
                                    
                                    // Prevent multiple rapid taps
                                    guard !user.userID.isEmpty && !isFollowLoading else { 
                                        print("UserProfileView: Button press blocked - userID empty or already loading")
                                        return 
                                    }
                                    
                                    // Provide haptic feedback
                                    HapticGenerator.light.impactOccurred()
                                    
                                    print("UserProfileView: Setting loading states")
                                    isFollowLoading = true
                                    isViewDismissible = false
                                    
                                    if isFollowing {
                                        print("UserProfileView: Starting unfollow operation")
                                        UserManager.shared.unFollow(userToUnFollow: user) { isUnFollowed in
                                            DispatchQueue.main.async {
                                                print("UserProfileView: Unfollow operation completed - success: \(isUnFollowed)")
                                                print("UserProfileView: Setting dismissible to true")
                                                self.isFollowLoading = false
                                                self.isViewDismissible = true
                                                withAnimation { self.isFollowing = !isUnFollowed }
                                            }
                                        }
                                    } else {
                                        print("UserProfileView: Starting follow operation")
                                        UserManager.shared.follow(userToFollow: user) { isFollowed in
                                            DispatchQueue.main.async {
                                                print("UserProfileView: Follow operation completed - success: \(isFollowed)")
                                                print("UserProfileView: Setting dismissible to true")
                                                self.isFollowLoading = false
                                                self.isViewDismissible = true
                                                withAnimation { self.isFollowing = isFollowed }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        if isFollowLoading {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .foregroundColor(isFollowing ? .labelColor : .white)
                                        } else {
                                            Text(isFollowing ? "Following" : "Follow")
                                        }
                                    }
                                    .padding()
                                    .padding(.horizontal, 50)
                                    .if(!isFollowing) { view in
                                        view
                                            .foregroundColor(.white)
                                            .background(Color.buttonBgColor)
                                    }
                                    .cornerRadius(15)
                                    .font(.system(size: 14, weight: .bold, design: .default))
                                    .if(isFollowing) { view in
                                        view
                                            .foregroundColor(.labelColor)
                                            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.appColor, lineWidth: 1))
                                    }
                                }
                                .disabled(isFollowLoading)
                                .buttonStyle(PlainButtonStyle()) // Prevent gesture interference
                                .contentShape(Rectangle()) // Ensure the entire button area is tappable
                                .allowsHitTesting(!isFollowLoading) // Prevent any touch events during loading
                                
                                Button {
                                    // Create or find existing chat room and navigate to message view
                                    guard let currentUserID = UserManager.shared.currentUserID,
                                          !user.userID.isEmpty else {
                                        return
                                    }
                                    
                                    ChatroomManager.shared.getChatRooms(whereField: "participantsIDs", withValues: [currentUserID, user.userID]) { rooms in
                                        DispatchQueue.main.async {
                                            if let rooms = rooms, rooms.count > 0, let room = rooms.first {
                                                // Existing chat room found, navigate to it
                                                let messageView = MessageView(user: user, chatroom: room)
                                                viewItem = ViewItem(AnyView(messageView), _presentationStyle: .fullScreen)
                                            } else {
                                                // Create a new chat room
                                                let room = ChatRoom(roomID: UUID().uuidString, participantsIDs: [currentUserID, user.userID])
                                                
                                                do {
                                                    try ChatroomManager.shared.create(room: room)
                                                    // Navigate to the new chat room
                                                    let messageView = MessageView(user: user, chatroom: room)
                                                    viewItem = ViewItem(AnyView(messageView), _presentationStyle: .fullScreen)
                                                } catch {
                                                    print("Error creating chat room: \(error.localizedDescription)")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color.secondaryBgColor)
                                        
                                        Assets.UI.mail
                                            .foregroundColor(.labelColor)
                                    }
                                    .frame(width: 60, height: 60)
                                }
                                .buttonStyle(PlainButtonStyle()) // Prevent gesture interference
                                .contentShape(Rectangle()) // Ensure the entire button area is tappable
                            }
                            
                            HStack {
                                Text("Upcoming events by @ \(user.username)")
                                    .font(.system(size: 15, weight: .bold, design: .default))
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            if let events = events, events.count > 0 {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(alignment: .center, spacing: 20) {
                                        Spacer(minLength: 16)
                                        ForEach(events, id: \.eventID) { event in
                                            NavigationLink {
                                                if #available(iOS 16.0, *) {
                                                    EventDetailView(event: event)
                                                        .padding(.top)
                                                }
                                            } label: {
                                                DiscoverView.EventCard2(event: event)
                                                    .frame(width: 280, height: 340)
                                            }
                                            .buttonStyle(FlatLinkStyle())
                                        }
                                        Spacer(minLength: 16)
                                    }
                                    .padding(.vertical, 10)
                                }
                            } else if events?.count == 0 {
                                Text("No events.")
                                    .padding()
                                    .foregroundColor(.secondary)
                            } else if events == nil {
                                ProgressView()
                                    .padding()
                            }
                        }
                        .padding(.top)
                    }
                }
                .navigationBarHidden(true)
                .interactiveDismissDisabled(!isViewDismissible)
                .onChange(of: isViewDismissible) { newValue in
                    print("UserProfileView: isViewDismissible changed to: \(newValue)")
                }
                .gesture(
                    DragGesture()
                        .onChanged { _ in
                            if isFollowLoading {
                                print("UserProfileView: Drag gesture blocked during loading")
                            }
                        }
                        .onEnded { _ in
                            if isFollowLoading {
                                print("UserProfileView: Drag gesture ended during loading")
                            }
                        }
                )
                .onAppear {
                    print("UserProfileView: View appeared for user: \(user.username)")
                    
                    fetchEvents()
                    
                    // check if current user is following this user
                    UserManager.shared.isFollowing(user: user) { isFollowing in
                        print("UserProfileView: Initial following state: \(isFollowing)")
                        withAnimation { self.isFollowing = isFollowing }
                    }
                    
                    // fetch followers
                    UserManager.shared.getTopFourFollowers(of: user) { users in
                        self.followers = users
                    }
                }
                .onDisappear {
                    print("UserProfileView: View disappeared for user: \(user.username)")
                    print("UserProfileView: Stack trace: \(Thread.callStackSymbols)")
                }
                .fullScreenCover(item: $viewItem) { viewItem in
                    viewItem.viewToPresent
                }
                .background (
                    VStack {
                        if let navLinkViewItem = navLinkViewItem {
                            NavigationLink(destination: navLinkViewItem.viewToPresent, tag: navLinkViewItem, selection: $navLinkViewItem) {
                                EmptyView()
                            }
                        }
                    }
                )
            }
        }
    }
    
    private func fetchEvents() {
        EventManager.shared.getEvents(whereField: "hostIDs", arrayContains: user.userID) { events in
            self.events = events
        }
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(user: User())
            .preferredColorScheme(.dark)
    }
}

