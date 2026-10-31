// Firebase Cloud Functions for Push Notifications
// This file should be deployed to Firebase Functions

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

// Send push notification to a single user
exports.sendPushNotification = functions.firestore
    .document('notifications/{notificationId}')
    .onCreate(async (snap, context) => {
        const notification = snap.data();
        
        try {
            // Get user's push tokens
            const userDoc = await admin.firestore()
                .collection('users')
                .doc(notification.receiverID)
                .get();
            
            if (!userDoc.exists) {
                console.log('User not found:', notification.receiverID);
                return null;
            }
            
            const userData = userDoc.data();
            const tokens = userData.pushNotificationTokens || [];
            
            if (tokens.length === 0) {
                console.log('No push tokens found for user:', notification.receiverID);
                return null;
            }
            
            // Create notification payload
            const payload = {
                notification: {
                    title: notification.title,
                    body: notification.body,
                    sound: 'default'
                },
                data: {
                    notificationID: notification.notificationID,
                    type: notification.type,
                    senderID: notification.senderID || '',
                    eventID: notification.eventID || '',
                    click_action: 'FLUTTER_NOTIFICATION_CLICK'
                }
            };
            
            // Send to all user's devices
            const responses = await Promise.all(
                tokens.map(token => 
                    admin.messaging().send({
                        token: token,
                        ...payload
                    })
                )
            );
            
            console.log('Push notifications sent:', responses.length);
            return { success: true, sentCount: responses.length };
            
        } catch (error) {
            console.error('Error sending push notification:', error);
            return { success: false, error: error.message };
        }
    });

// Send notification to multiple users (for story notifications)
exports.sendStoryNotificationToFollowers = functions.firestore
    .document('stories/{storyId}')
    .onCreate(async (snap, context) => {
        const story = snap.data();
        
        try {
            // Get story creator's followers
            const followersQuery = await admin.firestore()
                .collection('users')
                .doc(story.creatorID)
                .collection('followers')
                .get();
            
            const followerIds = followersQuery.docs.map(doc => doc.id);
            
            if (followerIds.length === 0) {
                console.log('No followers found for user:', story.creatorID);
                return null;
            }
            
            // Get creator's user data
            const creatorDoc = await admin.firestore()
                .collection('users')
                .doc(story.creatorID)
                .get();
            
            if (!creatorDoc.exists) {
                console.log('Story creator not found:', story.creatorID);
                return null;
            }
            
            const creatorData = creatorDoc.data();
            
            // Create notification for each follower
            const notifications = followerIds.map(followerId => ({
                notificationID: admin.firestore().collection('notifications').doc().id,
                type: 'new_story',
                title: 'New Story',
                body: `${creatorData.fullName} posted a new story`,
                senderID: story.creatorID,
                receiverID: followerId,
                eventID: story.eventID,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false
            }));
            
            // Batch write notifications
            const batch = admin.firestore().batch();
            notifications.forEach(notification => {
                const docRef = admin.firestore()
                    .collection('notifications')
                    .doc(notification.notificationID);
                batch.set(docRef, notification);
            });
            
            await batch.commit();
            
            console.log('Story notifications created for', notifications.length, 'followers');
            return { success: true, createdCount: notifications.length };
            
        } catch (error) {
            console.error('Error creating story notifications:', error);
            return { success: false, error: error.message };
        }
    });

// Send event milestone notifications
exports.sendEventMilestoneNotification = functions.firestore
    .document('events/{eventId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();
        
        // Check if interested count reached a milestone
        const milestones = [20, 50, 100];
        const interestedCount = after.interestedUserIDs?.length || 0;
        
        const reachedMilestone = milestones.find(milestone => 
            (before.interestedUserIDs?.length || 0) < milestone && interestedCount >= milestone
        );
        
        if (!reachedMilestone) {
            return null;
        }
        
        try {
            // Create milestone notification
            const notification = {
                notificationID: admin.firestore().collection('notifications').doc().id,
                type: 'event_milestone',
                title: 'Event Milestone Reached!',
                body: `Your event "${after.name}" has reached ${reachedMilestone} interested people!`,
                senderID: null,
                receiverID: after.creatorID,
                eventID: after.eventID,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                milestoneType: reachedMilestone.toString(),
                milestoneCount: reachedMilestone
            };
            
            // Save notification
            await admin.firestore()
                .collection('notifications')
                .doc(notification.notificationID)
                .set(notification);
            
            console.log('Milestone notification created for event:', after.eventID);
            return { success: true, milestone: reachedMilestone };
            
        } catch (error) {
            console.error('Error creating milestone notification:', error);
            return { success: false, error: error.message };
        }
    });

// Clean up invalid push tokens
exports.cleanupInvalidTokens = functions.pubsub
    .schedule('every 24 hours')
    .onRun(async (context) => {
        try {
            const usersSnapshot = await admin.firestore()
                .collection('users')
                .get();
            
            let cleanedCount = 0;
            
            for (const userDoc of usersSnapshot.docs) {
                const userData = userDoc.data();
                const tokens = userData.pushNotificationTokens || [];
                
                if (tokens.length === 0) continue;
                
                // Test each token
                const validTokens = [];
                for (const token of tokens) {
                    try {
                        await admin.messaging().send({
                            token: token,
                            data: { test: 'test' }
                        });
                        validTokens.push(token);
                    } catch (error) {
                        if (error.code === 'messaging/invalid-registration-token' ||
                            error.code === 'messaging/registration-token-not-registered') {
                            console.log('Removing invalid token:', token);
                        }
                    }
                }
                
                // Update user with valid tokens only
                if (validTokens.length !== tokens.length) {
                    await userDoc.ref.update({
                        pushNotificationTokens: validTokens
                    });
                    cleanedCount += (tokens.length - validTokens.length);
                }
            }
            
            console.log('Cleaned up', cleanedCount, 'invalid tokens');
            return { success: true, cleanedCount };
            
        } catch (error) {
            console.error('Error cleaning up tokens:', error);
            return { success: false, error: error.message };
        }
    });

// Send scheduled notifications
exports.sendScheduledNotifications = functions.pubsub
    .schedule('every 1 hours')
    .onRun(async (context) => {
        try {
            const now = admin.firestore.Timestamp.now();
            
            // Get scheduled notifications that are due
            const scheduledNotifications = await admin.firestore()
                .collection('scheduledNotifications')
                .where('scheduledFor', '<=', now)
                .where('isSent', '==', false)
                .get();
            
            let sentCount = 0;
            
            for (const doc of scheduledNotifications.docs) {
                const scheduledNotification = doc.data();
                
                try {
                    // Create actual notification
                    const notification = {
                        notificationID: admin.firestore().collection('notifications').doc().id,
                        type: scheduledNotification.type || 'custom_host_notification',
                        title: scheduledNotification.title,
                        body: scheduledNotification.body,
                        senderID: scheduledNotification.hostID,
                        receiverID: '', // Will be set for each target user
                        eventID: scheduledNotification.eventID,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        isRead: false
                    };
                    
                    // Get target users based on audience
                    let targetUserIDs = [];
                    
                    switch (scheduledNotification.targetAudience) {
                        case 'event_joinees':
                            const eventDoc = await admin.firestore()
                                .collection('events')
                                .doc(scheduledNotification.eventID)
                                .get();
                            if (eventDoc.exists) {
                                targetUserIDs = eventDoc.data().interestedUserIDs || [];
                            }
                            break;
                        case 'specific_users':
                            targetUserIDs = scheduledNotification.targetUserIDs || [];
                            break;
                        case 'everyone':
                            const allUsers = await admin.firestore()
                                .collection('users')
                                .get();
                            targetUserIDs = allUsers.docs.map(doc => doc.id);
                            break;
                    }
                    
                    // Create notifications for each target user
                    const batch = admin.firestore().batch();
                    
                    targetUserIDs.forEach(userID => {
                        const userNotification = { ...notification };
                        userNotification.receiverID = userID;
                        userNotification.notificationID = admin.firestore().collection('notifications').doc().id;
                        
                        const docRef = admin.firestore()
                            .collection('notifications')
                            .doc(userNotification.notificationID);
                        batch.set(docRef, userNotification);
                    });
                    
                    await batch.commit();
                    
                    // Mark scheduled notification as sent
                    await doc.ref.update({ isSent: true });
                    
                    sentCount += targetUserIDs.length;
                    
                } catch (error) {
                    console.error('Error processing scheduled notification:', error);
                }
            }
            
            console.log('Sent', sentCount, 'scheduled notifications');
            return { success: true, sentCount };
            
        } catch (error) {
            console.error('Error sending scheduled notifications:', error);
            return { success: false, error: error.message };
        }
    });
