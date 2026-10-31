# Notification System Setup Guide

This guide explains how to set up and use the comprehensive notification system for your KiccBacc app.

## Overview

The notification system includes:
- **Push Notifications**: Real-time notifications sent to user devices
- **In-App Notifications**: Notifications displayed within the app
- **Notification Settings**: User preferences for notification types and timing
- **Notification Management**: View, mark as read, and delete notifications

## Notification Types

The system supports the following notification types:

### Social Notifications
- **Event Join**: When someone joins your event
- **User Follow**: When someone follows you
- **New Message**: When you receive a new message
- **New Story**: When someone you follow posts a story
- **Story Reply**: When someone replies to your story
- **User Mention**: When someone mentions you

### Event Notifications
- **Event Comment**: When someone comments on your event
- **Event Invite**: When someone invites you to an event
- **Event Update**: When an event you're interested in is updated
- **Event Reminder**: Reminders about upcoming events
- **Event Milestone**: When your event reaches attendance milestones
- **Event Cancellation**: When an event is cancelled

### System Notifications
- **Story Upload Prompt**: Reminders to upload stories
- **Custom Host Notification**: Custom notifications from event hosts

## Setup Instructions

### 1. Firebase Configuration

Ensure your Firebase project has the following services enabled:
- **Firestore Database**: For storing notifications
- **Firebase Cloud Messaging**: For push notifications
- **Firebase Functions**: For server-side notification processing

### 2. iOS App Configuration

#### Add Required Capabilities
In your Xcode project:
1. Go to your target settings
2. Select "Signing & Capabilities"
3. Add the following capabilities:
   - Push Notifications
   - Background Modes (Remote notifications)

#### Update Info.plist
Add the following to your `Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

### 3. Firebase Functions Deployment

Deploy the Firebase Functions for server-side notification processing:

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase Functions (if not already done)
firebase init functions

# Copy the notification-service.js to your functions folder
# Deploy the functions
firebase deploy --only functions
```

### 4. App Integration

The notification system is already integrated into your existing managers:

#### UserManager
- Automatically sends follow notifications when users follow each other

#### MessageManager
- Automatically sends message notifications when messages are sent

#### StoryManager
- Automatically sends story notifications when stories are posted

#### EventManager
- Automatically sends event join notifications when users join events

## Usage

### Displaying Notifications

To show the notification view in your app:

```swift
import SwiftUI

struct ContentView: View {
    @State private var showingNotifications = false
    
    var body: some View {
        VStack {
            Button("Show Notifications") {
                showingNotifications = true
            }
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationView()
        }
    }
}
```

### Adding Notification Badge to Tab Bar

To add a notification badge to your tab bar:

```swift
TabView {
    HomeView()
        .tabItem {
            Image(systemName: "house.fill")
            Text("Home")
        }
        .notificationBadge() // This will show unread count
    
    NotificationView()
        .tabItem {
            Image(systemName: "bell.fill")
            Text("Notifications")
        }
}
```

### Sending Custom Notifications

To send custom notifications programmatically:

```swift
// Send a follow notification
EnhancedNotificationManager.shared.sendFollowNotification(
    followerID: "user123",
    followedUserID: "user456"
) { success in
    print("Follow notification sent: \(success)")
}

// Send a message notification
EnhancedNotificationManager.shared.sendMessageNotification(
    senderID: "user123",
    receiverID: "user456",
    messageContent: "Hello! How are you?"
) { success in
    print("Message notification sent: \(success)")
}

// Send a story notification
EnhancedNotificationManager.shared.sendNewStoryNotification(
    storyCreatorID: "user123",
    storyID: "story456"
) { success in
    print("Story notification sent: \(success)")
}
```

### Managing Notification Settings

Users can customize their notification preferences:

```swift
// Update notification type settings
NotificationSettingsManager.shared.updateNotificationType(.newMessage, enabled: true)
NotificationSettingsManager.shared.updateNotificationType(.userFollow, enabled: false)

// Update general settings
NotificationSettingsManager.shared.updatePushNotificationsEnabled(true)
NotificationSettingsManager.shared.updateInAppNotificationsEnabled(true)
NotificationSettingsManager.shared.updateSoundEnabled(true)
NotificationSettingsManager.shared.updateVibrationEnabled(true)

// Set quiet hours
NotificationSettingsManager.shared.updateQuietHoursEnabled(true)
NotificationSettingsManager.shared.updateQuietHours(
    start: Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date(),
    end: Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
)
```

## Database Schema

### Notifications Collection
```javascript
{
  notificationID: "string",
  type: "string", // One of the notification types
  title: "string",
  body: "string",
  imageUrl: "string?",
  senderID: "string?",
  receiverID: "string",
  eventID: "string?",
  createdAt: "timestamp",
  scheduledFor: "timestamp?",
  isRead: "boolean",
  metadata: "object?",
  milestoneType: "string?",
  milestoneCount: "number?",
  isHostNotification: "boolean",
  targetAudience: "string"
}
```

### Notification Settings Collection
```javascript
{
  userID: "string",
  enabledTypes: ["array"],
  pushNotificationsEnabled: "boolean",
  inAppNotificationsEnabled: "boolean",
  soundEnabled: "boolean",
  vibrationEnabled: "boolean",
  quietHoursEnabled: "boolean",
  quietHoursStart: "timestamp",
  quietHoursEnd: "timestamp",
  lastUpdated: "timestamp",
  // Individual notification type settings
  eventJoinNotifications: "boolean",
  followNotifications: "boolean",
  messageNotifications: "boolean",
  storyNotifications: "boolean",
  // ... other notification types
}
```

## Testing

### Test Push Notifications
1. Build and run the app on a physical device
2. Grant notification permissions when prompted
3. Use the Firebase Console to send test notifications
4. Verify notifications are received and displayed correctly

### Test In-App Notifications
1. Create test notifications using the manager methods
2. Verify notifications appear in the NotificationView
3. Test filtering and marking as read functionality

## Troubleshooting

### Common Issues

1. **Push notifications not working**
   - Check that Push Notifications capability is enabled
   - Verify Firebase configuration is correct
   - Ensure device has internet connection

2. **Notifications not appearing in app**
   - Check Firestore security rules allow read/write access
   - Verify notification settings are properly configured
   - Check console for any error messages

3. **Firebase Functions not deploying**
   - Ensure Firebase CLI is up to date
   - Check that you have proper permissions
   - Verify Node.js version compatibility

### Debug Tips

1. Enable verbose logging in the notification managers
2. Check Firebase Console for function execution logs
3. Monitor Firestore for notification document creation
4. Use Firebase Console to manually send test notifications

## Performance Considerations

1. **Batch Operations**: Use batch writes for multiple notifications
2. **Pagination**: Load notifications in chunks (50 at a time)
3. **Caching**: Cache frequently accessed notification data
4. **Cleanup**: Regularly clean up old notifications and invalid tokens

## Security

1. **Firestore Rules**: Implement proper security rules for notifications
2. **User Authentication**: Ensure only authenticated users can send/receive notifications
3. **Data Validation**: Validate all notification data before saving
4. **Rate Limiting**: Implement rate limiting for notification sending

## Future Enhancements

Potential improvements to consider:
- Rich notifications with images and actions
- Notification grouping and threading
- Advanced filtering and search
- Notification analytics and insights
- Cross-platform notification sync
- Custom notification sounds and vibrations
