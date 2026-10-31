//
//  StoryLikeView.swift
//  KiccBacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import Combine
import CoreHaptics

// MARK: - StoryLikeView (Following Seen By Pattern)
struct StoryLikeView: View {
    
    let story: Story
    let isCreator: Bool
    let onLikeToggle: () -> Void
    
    @State private var showLikedUsers: Bool = false
    @State private var likedUsers: [User] = []
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Like Button
            Button(action: {
                print("🔔 Like button tapped!")
                handleLikeToggle()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: story.isLikedByCurrentUser ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(story.isLikedByCurrentUser ? .red : .white)
                        .scaleEffect(story.isLikedByCurrentUser ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: story.isLikedByCurrentUser)
                }
            }
            .disabled(isLoading)
            .scaleEffect(isLoading ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isLoading)
            
            // Like Count
            Button(action: {
                if isCreator {
                    loadLikedUsers()
                    showLikedUsers = true
                }
            }) {
                Text("\(story.likeCount)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(!isCreator || story.likeCount == 0)
            .opacity(story.likeCount == 0 ? 0.6 : 1.0)
            .onTapGesture {
                if isCreator && story.likeCount > 0 {
                    loadLikedUsers()
                    showLikedUsers = true
                }
            }
        }
        .sheet(isPresented: $showLikedUsers) {
            LikedUsersView(users: likedUsers)
        }
    }
    
    // MARK: - Private Methods (Following Seen By Pattern)
    private func loadLikedUsers() {
        // Load users who liked the story (similar to loadStoryViewers in StoriesViewModel)
        guard let likedByUserIDs = story.likedByUserIDs, !likedByUserIDs.isEmpty else {
            print("⚠️ No users have liked this story yet")
            return
        }
        
        UserManager.shared.getFourUsers(withuserIDs: likedByUserIDs) { users in
            DispatchQueue.main.async {
                self.likedUsers = users ?? []
            }
        }
    }
    
    private func handleLikeToggle() {
        print("🔔 StoryLikeView.handleLikeToggle called")
        
        // Prevent multiple simultaneous operations
        guard !isLoading else {
            print("⚠️ Like operation already in progress, ignoring tap")
            return
        }
        
        guard let currentUserID = UserManager.shared.currentUserID else { 
            print("❌ No current user ID found")
            return 
        }
        
        guard !story.storyID.isEmpty else {
            print("❌ Invalid story ID")
            return
        }
        
        print("📊 Current user ID: \(currentUserID)")
        print("📊 Story ID: \(story.storyID)")
        print("📊 Current like state: \(story.isLikedByCurrentUser)")
        
        isLoading = true
        
        // Use Task to properly handle async operations
        Task {
            do {
                if story.isLikedByCurrentUser {
                    // Unlike the story
                    try await StoryManager.shared.unlikeStory(story, by: currentUserID)
                    print("✅ Story unliked successfully")
                } else {
                    // Like the story
                    try await StoryManager.shared.likeStory(story, by: currentUserID)
                    print("✅ Story liked successfully")
                }
                
                // Update UI on main thread
                await MainActor.run {
                    self.isLoading = false
                    self.safeHapticFeedback()
                    self.onLikeToggle()
                }
                
            } catch {
                print("❌ Story like/unlike failed: \(error.localizedDescription)")
                
                // Update UI on main thread
                await MainActor.run {
                    self.isLoading = false
                    // Could show an error alert here if needed
                }
            }
        }
    }
    
    // Safe haptic feedback that won't crash
    private func safeHapticFeedback() {
        // Check if haptic feedback is available
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("⚠️ Haptic feedback not supported on this device")
            return
        }
        
        // Use a try-catch to prevent crashes
        do {
            HapticGenerator.light.impactOccurred()
        } catch {
            print("⚠️ Haptic feedback failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - LikedUsersView
struct LikedUsersView: View {
    
    let users: [User]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(users, id: \.userID) { user in
                HStack(spacing: 12) {
                    // Profile Image
                    if let pfpUrl = user.profileImageUrlString, let url = URL(string: pfpUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.appColor)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(user.getInitials())
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    // User Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.fullName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("@\(user.username)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Liked by")
            .navigationBarTitleDisplayMode(.inline)
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
struct StoryLikeView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Spacer()
                
                HStack {
                    StoryLikeView(
                        story: Story(),
                        isCreator: false,
                        onLikeToggle: {}
                    )
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}

