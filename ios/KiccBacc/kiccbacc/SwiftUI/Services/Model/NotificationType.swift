//
//  NotificationType.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import Foundation

enum NotificationType: String, Codable, CaseIterable {
    case eventLike = "event_like"
    case eventMilestone = "event_milestone"
    case storyUploadPrompt = "story_upload_prompt"
    case eventReminder = "event_reminder"
    case eventUpdate = "event_update"
    case eventCancellation = "event_cancellation"
    case customHostNotification = "custom_host_notification"
    
    // New notification types for comprehensive app notifications
    case eventJoin = "event_join"
    case eventLeave = "event_leave"
    case userFollow = "user_follow"
    case newMessage = "new_message"
    case newStory = "new_story"
    case eventInvite = "event_invite"
    case eventComment = "event_comment"
    case storyReply = "story_reply"
    case storyLike = "story_like"
    case userMention = "user_mention"
    case groupChatRemoval = "group_chat_removal"
    case groupChatMessage = "group_chat_message"
    case groupChatInvitation = "group_chat_invitation"
    case groupChatJoin = "group_chat_join"
    
    var displayName: String {
        switch self {
        case .eventLike:
            return "Event Likes"
        case .eventMilestone:
            return "Event Milestones"
        case .storyUploadPrompt:
            return "Story Upload Prompts"
        case .eventReminder:
            return "Event Reminders"
        case .eventUpdate:
            return "Event Updates"
        case .eventCancellation:
            return "Event Cancellations"
        case .customHostNotification:
            return "Custom Host Notifications"
        case .eventJoin:
            return "Event Joins"
        case .eventLeave:
            return "Event Leaves"
        case .userFollow:
            return "New Followers"
        case .newMessage:
            return "New Messages"
        case .newStory:
            return "New Stories"
        case .eventInvite:
            return "Event Invites"
        case .eventComment:
            return "Event Comments"
        case .storyReply:
            return "Story Replies"
        case .storyLike:
            return "Story Likes"
        case .userMention:
            return "User Mentions"
        case .groupChatRemoval:
            return "Group Chat Removals"
        case .groupChatMessage:
            return "Group Chat Messages"
        case .groupChatInvitation:
            return "Group Chat Invitations"
        case .groupChatJoin:
            return "Group Chat Joins"
        }
    }
    
    var description: String {
        switch self {
        case .eventLike:
            return "Get notified when someone likes your event"
        case .eventMilestone:
            return "Get notified when your event reaches attendance milestones"
        case .storyUploadPrompt:
            return "Get reminded to upload stories for events you're interested in"
        case .eventReminder:
            return "Get reminded about upcoming events"
        case .eventUpdate:
            return "Get notified about changes to events you're interested in"
        case .eventCancellation:
            return "Get notified if an event is cancelled"
        case .customHostNotification:
            return "Receive custom notifications from event hosts"
        case .eventJoin:
            return "Get notified when someone joins your event"
        case .eventLeave:
            return "Get notified when someone leaves your event"
        case .userFollow:
            return "Get notified when someone follows you"
        case .newMessage:
            return "Get notified when you receive a new message"
        case .newStory:
            return "Get notified when someone you follow posts a new story"
        case .eventInvite:
            return "Get notified when someone invites you to an event"
        case .eventComment:
            return "Get notified when someone comments on your event"
        case .storyReply:
            return "Get notified when someone replies to your story"
        case .storyLike:
            return "Get notified when someone likes your story"
        case .userMention:
            return "Get notified when someone mentions you"
        case .groupChatRemoval:
            return "Get notified when you're removed from a group chat"
        case .groupChatMessage:
            return "Get notified when someone sends a message in group chat"
        case .groupChatInvitation:
            return "Get notified when you're invited to a group chat"
        case .groupChatJoin:
            return "Get notified when someone joins a group chat"
        }
    }
    
    var defaultTitle: String {
        switch self {
        case .eventJoin:
            return "New Event Join"
        case .eventLeave:
            return "Event Leave"
        case .userFollow:
            return "New Follower"
        case .newMessage:
            return "New Message"
        case .newStory:
            return "New Story"
        case .eventInvite:
            return "Event Invitation"
        case .eventComment:
            return "New Comment"
        case .storyReply:
            return "Story Reply"
        case .storyLike:
            return "Story Like"
        case .userMention:
            return "You were mentioned"
        case .groupChatRemoval:
            return "Removed from Group Chat"
        case .groupChatMessage:
            return "New Group Chat Message"
        case .groupChatInvitation:
            return "Group Chat Invitation"
        case .groupChatJoin:
            return "New Group Chat Member"
        default:
            return "Notification"
        }
    }
    
    var requiresUserAction: Bool {
        switch self {
        case .newMessage, .eventInvite, .storyReply, .userMention:
            return true
        default:
            return false
        }
    }
}

enum MilestoneType: String, Codable, CaseIterable {
    case twenty = "20"
    case fifty = "50"
    case hundred = "100"
    
    var count: Int {
        switch self {
        case .twenty: return 20
        case .fifty: return 50
        case .hundred: return 100
        }
    }
    
    var displayName: String {
        return "\(count) people"
    }
    
    var message: String {
        switch self {
        case .twenty:
            return "🎉 Your event is gaining momentum! 20 people are interested. Consider sharing more details or photos to keep the excitement going!"
        case .fifty:
            return "🔥 Wow! 50 people are interested in your event! This is getting popular. Don't forget to upload some stories to keep everyone engaged!"
        case .hundred:
            return "🚀 AMAZING! 100 people are interested in your event! This is going to be epic. Share stories and updates to build the hype!"
        }
    }
}
