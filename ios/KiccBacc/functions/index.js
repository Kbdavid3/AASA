// Firebase Cloud Functions for Push Notifications
// This file handles all notification functionality for KiccBacc app

const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest, onCall } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { defineString } = require("firebase-functions/params");
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

// Define email configuration parameters
const gmailUser = defineString("GMAIL_USER");
const gmailPassword = defineString("GMAIL_APP_PASSWORD");
const smtpHost = defineString("SMTP_HOST", { default: "" });
const smtpPort = defineString("SMTP_PORT", { default: "" });
const emailService = defineString("EMAIL_SERVICE", { default: "gmail" });

// Initialize Firebase Admin SDK
admin.initializeApp();

// Set global options for cost control
setGlobalOptions({ maxInstances: 10 });

// Send push notification to a single user
exports.sendPushNotification = onDocumentCreated('notifications/{notificationId}', async (event) => {
    const notification = event.data.data();
    
    // Add null safety checks
    if (!notification) {
        console.log('❌ Notification data is null or undefined');
        return null;
    }
    
    if (!notification.receiverID) {
        console.log('❌ Notification receiverID is missing');
        return null;
    }
    
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
        
        // Create notification payload with safety checks
        const payload = {
            notification: {
                title: notification.title || 'Notification',
                body: notification.body || ''
            },
            data: {
                notificationID: notification.notificationID || '',
                type: notification.type || '',
                senderID: notification.senderID || '',
                eventID: notification.eventID || '',
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
            }
        };
        
        // Send to all user's devices and handle invalid tokens
        const validTokens = [];
        const invalidTokens = [];
        
        for (const token of tokens) {
            try {
                await admin.messaging().send({
                    token: token,
                    ...payload
                });
                validTokens.push(token);
            } catch (error) {
                if (error.code === 'messaging/registration-token-not-registered') {
                    console.log('Invalid token found:', token);
                    invalidTokens.push(token);
                } else {
                    console.error('Error sending to token:', token, error);
                }
            }
        }
        
        // Clean up invalid tokens
        if (invalidTokens.length > 0) {
            const updatedTokens = tokens.filter(token => !invalidTokens.includes(token));
            await admin.firestore()
                .collection('users')
                .doc(notification.receiverID)
                .update({
                    pushNotificationTokens: updatedTokens
                });
            console.log('Cleaned up', invalidTokens.length, 'invalid tokens for user:', notification.receiverID);
        }
        
        console.log('Push notifications sent:', validTokens.length, 'valid,', invalidTokens.length, 'invalid');
        return { success: true, sentCount: validTokens.length, invalidCount: invalidTokens.length };
        
    } catch (error) {
        console.error('Error sending push notification:', error);
        return { success: false, error: error.message };
    }
});

// Send notification to multiple users (for story notifications)
exports.sendStoryNotificationToFollowers = onDocumentCreated('stories/{storyId}', async (event) => {
    const story = event.data.data();
    
    // Add null safety checks
    if (!story) {
        console.log('❌ Story data is null or undefined');
        return null;
    }
    
    if (!story.creatorID) {
        console.log('❌ Story creatorID is missing');
        return null;
    }
    
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
exports.sendEventMilestoneNotification = onDocumentUpdated('events/{eventId}', async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    
    // Add null safety checks
    if (!before || !after) {
        console.log('❌ Event data is null or undefined');
        return null;
    }
    
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
exports.cleanupInvalidTokens = onSchedule('every 24 hours', async (event) => {
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

// Send event host notifications
exports.sendEventHostNotification = onDocumentCreated('notifications/{notificationId}', async (event) => {
    const notification = event.data.data();
    
    // Add null safety checks
    if (!notification) {
        console.log('❌ Notification data is null or undefined');
        return null;
    }
    
    // Only process event host notifications
    if (notification.type !== 'event_host_notification') {
        return null;
    }
    
    try {
        let targetUserIDs = [];
        
        // Get target users based on recipient type
        switch (notification.recipientType) {
            case 'Event Joinees Only':
                const eventDoc = await admin.firestore()
                    .collection('events')
                    .doc(notification.eventID)
                    .get();
                if (eventDoc.exists) {
                    targetUserIDs = eventDoc.data().interestedUserIDs || [];
                }
                break;
            case 'Everyone':
                const allUsers = await admin.firestore()
                    .collection('users')
                    .get();
                targetUserIDs = allUsers.docs.map(doc => doc.id);
                break;
            case 'Specific Users':
                targetUserIDs = notification.specificUserIDs || [];
                break;
        }
        
        // Remove the host from the target list
        targetUserIDs = targetUserIDs.filter(id => id !== notification.hostID);
        
        if (targetUserIDs.length === 0) {
            console.log('No target users found for notification');
            return { success: true, sentCount: 0 };
        }
        
        // Get push tokens for all target users
        const userDocs = await Promise.all(
            targetUserIDs.map(userID => 
                admin.firestore().collection('users').doc(userID).get()
            )
        );
        
        const allTokens = [];
        userDocs.forEach(doc => {
            if (doc.exists) {
                const tokens = doc.data().pushNotificationTokens || [];
                allTokens.push(...tokens);
            }
        });
        
        if (allTokens.length === 0) {
            console.log('No push tokens found for target users');
            return { success: true, sentCount: 0 };
        }
        
        // Create notification payload
        const payload = {
            notification: {
                title: notification.title,
                body: notification.message
            },
            data: {
                notificationID: notification.notificationID,
                type: 'event_host_notification',
                senderID: notification.hostID,
                eventID: notification.eventID,
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
            }
        };
        
        // Send to all target devices
        const responses = await Promise.all(
            allTokens.map(token => 
                admin.messaging().send({
                    token: token,
                    ...payload
                }).catch(error => {
                    console.log('Failed to send to token:', token, error.message);
                    return null;
                })
            )
        );
        
        const successfulSends = responses.filter(response => response !== null);
        
        console.log('Event host notifications sent:', successfulSends.length);
        return { success: true, sentCount: successfulSends.length };
        
    } catch (error) {
        console.error('Error sending event host notification:', error);
        return { success: false, error: error.message };
    }
});

// Send scheduled notifications
exports.sendScheduledNotifications = onSchedule('every 1 minutes', async (event) => {
    try {
        console.log('🕐 Scheduled notification function triggered at:', new Date().toISOString());
        const now = admin.firestore.Timestamp.now();
        
        // Get scheduled notifications that are due
        let scheduledNotifications;
        try {
            scheduledNotifications = await admin.firestore()
                .collection('scheduledNotifications')
                .where('scheduledFor', '<=', now)
                .where('isSent', '==', false)
                .get();
        } catch (indexError) {
            if (indexError.code === 9 && indexError.message.includes('index')) {
                console.log('⚠️ Index not ready yet, trying alternative query...');
                // Fallback: get all scheduled notifications and filter in memory
                const allScheduled = await admin.firestore()
                    .collection('scheduledNotifications')
                    .get();
                
                scheduledNotifications = {
                    docs: allScheduled.docs.filter(doc => {
                        const data = doc.data();
                        return data.scheduledFor && data.scheduledFor.toDate() <= now.toDate() && !data.isSent;
                    })
                };
            } else {
                throw indexError;
            }
        }
        
        console.log(`📋 Found ${scheduledNotifications.docs.length} scheduled notifications to process`);
        
        let sentCount = 0;
        
        for (const doc of scheduledNotifications.docs) {
            const scheduledNotification = doc.data();
            console.log(`📤 Processing scheduled notification: ${scheduledNotification.title} for ${scheduledNotification.targetAudience}`);
            
            try {
                // Create actual notification
                const notification = {
                    notificationID: admin.firestore().collection('notifications').doc().id,
                    type: scheduledNotification.type || 'event_host_notification',
                    title: scheduledNotification.title,
                    body: scheduledNotification.message || scheduledNotification.body,
                    message: scheduledNotification.message || scheduledNotification.body,
                    senderID: scheduledNotification.hostID,
                    receiverID: '', // Will be set for each target user
                    eventID: scheduledNotification.eventID,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    isRead: false,
                    hostID: scheduledNotification.hostID
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
                    default:
                        // Fallback for old format
                        if (scheduledNotification.recipientType === 'Event Joinees Only') {
                            const eventDoc = await admin.firestore()
                                .collection('events')
                                .doc(scheduledNotification.eventID)
                                .get();
                            if (eventDoc.exists) {
                                targetUserIDs = eventDoc.data().interestedUserIDs || [];
                            }
                        } else if (scheduledNotification.recipientType === 'Specific Users') {
                            targetUserIDs = scheduledNotification.specificUserIDs || [];
                        }
                        break;
                }
                
                console.log(`👥 Found ${targetUserIDs.length} target users for notification`);
                
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
                console.log(`✅ Created ${targetUserIDs.length} notifications in Firestore`);
                
                // Mark scheduled notification as sent
                await doc.ref.update({ isSent: true });
                console.log(`✅ Marked scheduled notification as sent`);
                
                sentCount += targetUserIDs.length;
                
            } catch (error) {
                console.error('Error processing scheduled notification:', error);
            }
        }
        
        console.log(`🎉 Scheduled notification function completed. Sent ${sentCount} notifications`);
        return { success: true, sentCount };
        
    } catch (error) {
        console.error('Error sending scheduled notifications:', error);
        return { success: false, error: error.message };
    }
});

// Test function to verify deployment
exports.testNotification = onRequest((req, res) => {
    res.json({
        message: 'Notification functions deployed successfully!',
        timestamp: new Date().toISOString(),
        functions: [
            'sendPushNotification',
            'sendStoryNotificationToFollowers', 
            'sendEventMilestoneNotification',
            'cleanupInvalidTokens',
            'sendScheduledNotifications'
        ]
    });
});

// Test function to manually trigger scheduled notifications
exports.testScheduledNotifications = onRequest(async (req, res) => {
    try {
        console.log('🧪 Manually triggering scheduled notifications test');
        
        // Call the scheduled notification function logic directly
        const now = admin.firestore.Timestamp.now();
        
        // Get scheduled notifications that are due
        const scheduledNotifications = await admin.firestore()
            .collection('scheduledNotifications')
            .where('scheduledFor', '<=', now)
            .where('isSent', '==', false)
            .get();
        
        console.log(`📋 Found ${scheduledNotifications.docs.length} scheduled notifications to process`);
        
        let sentCount = 0;
        
        for (const doc of scheduledNotifications.docs) {
            const scheduledNotification = doc.data();
            console.log(`📤 Processing scheduled notification: ${scheduledNotification.title} for ${scheduledNotification.targetAudience}`);
            
            try {
                // Create actual notification
                const notification = {
                    notificationID: admin.firestore().collection('notifications').doc().id,
                    type: scheduledNotification.type || 'event_host_notification',
                    title: scheduledNotification.title,
                    body: scheduledNotification.message || scheduledNotification.body,
                    message: scheduledNotification.message || scheduledNotification.body,
                    senderID: scheduledNotification.hostID,
                    receiverID: '', // Will be set for each target user
                    eventID: scheduledNotification.eventID,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    isRead: false,
                    hostID: scheduledNotification.hostID
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
                    default:
                        // Fallback for old format
                        if (scheduledNotification.recipientType === 'Event Joinees Only') {
                            const eventDoc = await admin.firestore()
                                .collection('events')
                                .doc(scheduledNotification.eventID)
                                .get();
                            if (eventDoc.exists) {
                                targetUserIDs = eventDoc.data().interestedUserIDs || [];
                            }
                        } else if (scheduledNotification.recipientType === 'Specific Users') {
                            targetUserIDs = scheduledNotification.specificUserIDs || [];
                        }
                        break;
                }
                
                console.log(`👥 Found ${targetUserIDs.length} target users for notification`);
                
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
                console.log(`✅ Created ${targetUserIDs.length} notifications in Firestore`);
                
                // Mark scheduled notification as sent
                await doc.ref.update({ isSent: true });
                console.log(`✅ Marked scheduled notification as sent`);
                
                sentCount += targetUserIDs.length;
                
            } catch (error) {
                console.error('Error processing scheduled notification:', error);
            }
        }
        
        console.log(`🎉 Test completed. Sent ${sentCount} scheduled notifications`);
        
        res.json({
            success: true,
            message: `Test completed. Sent ${sentCount} scheduled notifications`,
            processedCount: scheduledNotifications.docs.length,
            sentCount: sentCount,
            timestamp: new Date().toISOString()
        });
        
    } catch (error) {
        console.error('Error in test scheduled notifications:', error);
        res.status(500).json({
            success: false,
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

// Send Event Invitation Emails
exports.sendEventInvitationEmails = onCall(async (request) => {
    const { emails, eventData } = request.data;
    
    console.log('📧 Sending event invitations:', {
        emailCount: emails?.length,
        eventID: eventData?.eventID
    });
    
    try {
        // Validate input
        if (!emails || !Array.isArray(emails) || emails.length === 0) {
            throw new Error('No email addresses provided');
        }
        
        if (!eventData) {
            throw new Error('Event data is required');
        }
        
        // Get email credentials from environment config
        const emailUser = gmailUser.value();
        const emailPassword = gmailPassword.value();
        const smtpHostValue = smtpHost.value();
        const smtpPortValue = smtpPort.value();
        const emailServiceValue = emailService.value();
        
        if (!emailUser || !emailPassword) {
            throw new Error('Email credentials not configured. Please set GMAIL_USER and GMAIL_APP_PASSWORD environment variables.');
        }
        
        // Create Nodemailer transporter
        let transportConfig;
        
        if (smtpHostValue && smtpPortValue) {
            // Custom SMTP configuration (for non-Gmail providers)
            transportConfig = {
                host: smtpHostValue,
                port: parseInt(smtpPortValue),
                secure: parseInt(smtpPortValue) === 465, // true for 465, false for other ports
                auth: {
                    user: emailUser,
                    pass: emailPassword
                }
            };
        } else {
            // Gmail or Google Workspace configuration
            transportConfig = {
                service: emailServiceValue,
                auth: {
                    user: emailUser,
                    pass: emailPassword
                }
            };
        }
        
        const transporter = nodemailer.createTransport(transportConfig);
        
        // Get host information
        let hostName = 'KiccBacc Host';
        let hostUsername = '';
        
        if (eventData.hostID) {
            try {
                const hostDoc = await admin.firestore()
                    .collection('users')
                    .doc(eventData.hostID)
                    .get();
                
                if (hostDoc.exists) {
                    const hostData = hostDoc.data();
                    const firstName = hostData.firstName || '';
                    const lastName = hostData.lastName || '';
                    hostName = `${firstName} ${lastName}`.trim() || 'KiccBacc Host';
                    hostUsername = hostData.username || '';
                }
            } catch (error) {
                console.error('Error fetching host data:', error);
            }
        }
        
        // Format event date
        const eventDate = new Date(eventData.fromDate);
        const eventEndDate = new Date(eventData.toDate);
        const dateFormatter = new Intl.DateTimeFormat('en-US', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
        const timeFormatter = new Intl.DateTimeFormat('en-US', {
            hour: 'numeric',
            minute: '2-digit',
            hour12: true
        });
        
        const formattedDate = dateFormatter.format(eventDate);
        const formattedStartTime = timeFormatter.format(eventDate);
        const formattedEndTime = timeFormatter.format(eventEndDate);
        
        // Format ticket price
        let ticketPriceText = 'Free Event';
        if (eventData.ticketTypes && eventData.ticketTypes.length > 0) {
            const prices = eventData.ticketTypes.map(t => parseFloat(t.price)).filter(p => p > 0);
            if (prices.length > 0) {
                const minPrice = Math.min(...prices);
                ticketPriceText = `Starting from $${minPrice.toFixed(2)}`;
            }
        } else if (eventData.ticketPrice && parseFloat(eventData.ticketPrice) > 0) {
            ticketPriceText = `$${parseFloat(eventData.ticketPrice).toFixed(2)}`;
        }
        
        // Generate event link
        const eventLink = `https://kiccbacc.com/event/${eventData.eventID}`;
        
        // Generate HTML email template
        const emailHTML = generateEventInvitationEmailHTML({
            eventName: eventData.name,
            eventDate: formattedDate,
            eventTime: `${formattedStartTime} - ${formattedEndTime}`,
            venueName: eventData.venueName,
            location: `${eventData.city || ''}, ${eventData.state || ''}`.trim(),
            ticketPrice: ticketPriceText,
            hostName: hostName,
            hostUsername: hostUsername,
            eventLink: eventLink,
            eventBannerUrl: eventData.eventBannerUrl
        });
        
        // Send emails in batches to avoid rate limits
        const batchSize = 10;
        const results = {
            successful: 0,
            failed: 0,
            errors: []
        };
        
        for (let i = 0; i < emails.length; i += batchSize) {
            const batch = emails.slice(i, i + batchSize);
            
            const promises = batch.map(async (email) => {
                try {
                    const mailOptions = {
                        from: `"KiccBacc Events" <${emailUser}>`,
                        to: email,
                        subject: `You're Invited: ${eventData.name}`,
                        html: emailHTML
                    };
                    
                    await transporter.sendMail(mailOptions);
                    results.successful++;
                    console.log(`✅ Email sent to: ${email}`);
                } catch (error) {
                    results.failed++;
                    results.errors.push({
                        email: email,
                        error: error.message
                    });
                    console.error(`❌ Failed to send email to ${email}:`, error.message);
                }
            });
            
            await Promise.all(promises);
            
            // Add delay between batches to respect rate limits
            if (i + batchSize < emails.length) {
                await new Promise(resolve => setTimeout(resolve, 2000));
            }
        }
        
        console.log('📊 Email sending complete:', results);
        
        return {
            success: true,
            results: results,
            message: `Successfully sent ${results.successful} emails. ${results.failed} failed.`
        };
        
    } catch (error) {
        console.error('❌ Error sending event invitation emails:', error);
        return {
            success: false,
            error: error.message
        };
    }
});

// Generate professional HTML email template for event invitations
function generateEventInvitationEmailHTML(data) {
    const {
        eventName,
        eventDate,
        eventTime,
        venueName,
        location,
        ticketPrice,
        hostName,
        hostUsername,
        eventLink,
        eventBannerUrl
    } = data;
    
    return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Event Invitation</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            background-color: #f5f5f5;
        }
        .email-container {
            max-width: 600px;
            margin: 0 auto;
            background-color: #ffffff;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header {
            background: linear-gradient(135deg, #F26C92 0%, #E84C79 100%);
            padding: 30px 20px;
            text-align: center;
            color: #ffffff;
        }
        .logo {
            font-size: 28px;
            font-weight: bold;
            letter-spacing: 1px;
        }
        .tagline {
            font-size: 14px;
            opacity: 0.9;
            margin-top: 5px;
        }
        .banner {
            width: 100%;
            height: 250px;
            object-fit: cover;
            display: block;
        }
        .content {
            padding: 40px 30px;
        }
        .invitation-title {
            font-size: 18px;
            color: #666;
            margin-bottom: 10px;
        }
        .event-name {
            font-size: 32px;
            font-weight: bold;
            color: #1a1a1a;
            margin-bottom: 20px;
            line-height: 1.2;
        }
        .event-details {
            background-color: #f9f9f9;
            border-left: 4px solid #F26C92;
            padding: 20px;
            margin: 25px 0;
            border-radius: 8px;
        }
        .detail-row {
            display: flex;
            align-items: flex-start;
            margin-bottom: 15px;
        }
        .detail-row:last-child {
            margin-bottom: 0;
        }
        .detail-icon {
            font-size: 20px;
            margin-right: 12px;
            color: #F26C92;
            min-width: 24px;
        }
        .detail-content {
            flex: 1;
        }
        .detail-label {
            font-size: 12px;
            color: #888;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 3px;
        }
        .detail-value {
            font-size: 16px;
            color: #333;
            font-weight: 500;
        }
        .host-section {
            margin: 30px 0;
            padding: 20px;
            background-color: #f5f9ff;
            border-radius: 8px;
            text-align: center;
        }
        .host-label {
            font-size: 12px;
            color: #888;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 8px;
        }
        .host-name {
            font-size: 20px;
            font-weight: bold;
            color: #1a1a1a;
        }
        .host-username {
            font-size: 14px;
            color: #666;
            margin-top: 3px;
        }
        .cta-button {
            display: inline-block;
            background-color: #F26C92;
            color: #ffffff !important;
            text-decoration: none;
            padding: 16px 40px;
            border-radius: 8px;
            font-size: 18px;
            font-weight: bold;
            text-align: center;
            margin: 30px 0;
        }
        .cta-button:hover {
            background-color: #E84C79;
        }
        /* Yahoo Mail specific table button */
        .button-td {
            background-color: #F26C92;
            border-radius: 8px;
            text-align: center;
        }
        .button-a {
            background-color: #F26C92;
            border: 1px solid #F26C92;
            border-radius: 8px;
            color: #ffffff;
            display: inline-block;
            font-size: 18px;
            font-weight: bold;
            padding: 16px 40px;
            text-align: center;
            text-decoration: none;
            -webkit-text-size-adjust: none;
            mso-hide: all;
        }
        .info-text {
            font-size: 14px;
            color: #666;
            line-height: 1.6;
            margin: 20px 0;
        }
        .footer {
            background-color: #1a1a1a;
            color: #ffffff;
            padding: 30px;
            text-align: center;
        }
        .footer-logo {
            font-size: 24px;
            font-weight: bold;
            margin-bottom: 10px;
        }
        .footer-text {
            font-size: 13px;
            color: #aaa;
            line-height: 1.5;
        }
        .footer-links {
            margin-top: 15px;
        }
        .footer-link {
            color: #F26C92;
            text-decoration: none;
            margin: 0 10px;
            font-size: 13px;
        }
        .divider {
            height: 1px;
            background: linear-gradient(to right, transparent, #ddd, transparent);
            margin: 25px 0;
        }
        @media only screen and (max-width: 600px) {
            .content {
                padding: 30px 20px;
            }
            .event-name {
                font-size: 26px;
            }
            .cta-button {
                display: block;
                padding: 14px 30px;
                font-size: 16px;
            }
        }
    </style>
</head>
<body>
    <div class="email-container">
        <!-- Header -->
        <div class="header">
            <div class="logo">KiccBacc</div>
            <div class="tagline">Create Memories, Share Moments</div>
        </div>
        
        <!-- Banner Image -->
        ${eventBannerUrl ? `<img src="${eventBannerUrl}" alt="${eventName}" class="banner">` : ''}
        
        <!-- Content -->
        <div class="content">
            <div class="invitation-title">✨ You're Invited!</div>
            <h1 class="event-name">${eventName}</h1>
            
            <!-- Event Details -->
            <div class="event-details">
                <div class="detail-row">
                    <div class="detail-icon">📅</div>
                    <div class="detail-content">
                        <div class="detail-label">Date & Time</div>
                        <div class="detail-value">${eventDate}</div>
                        <div class="detail-value">${eventTime}</div>
                    </div>
                </div>
                
                <div class="detail-row">
                    <div class="detail-icon">📍</div>
                    <div class="detail-content">
                        <div class="detail-label">Location</div>
                        <div class="detail-value">${venueName}</div>
                        ${location ? `<div style="font-size: 14px; color: #666; margin-top: 3px;">${location}</div>` : ''}
                    </div>
                </div>
                
                <div class="detail-row">
                    <div class="detail-icon">🎫</div>
                    <div class="detail-content">
                        <div class="detail-label">Ticket Price</div>
                        <div class="detail-value">${ticketPrice}</div>
                    </div>
                </div>
            </div>
            
            <!-- Host Information -->
            <div class="host-section">
                <div class="host-label">Hosted By</div>
                <div class="host-name">${hostName}</div>
                ${hostUsername ? `<div class="host-username">@${hostUsername}</div>` : ''}
            </div>
            
            <!-- Call to Action Button (Yahoo Mail Compatible) -->
            <table border="0" cellpadding="0" cellspacing="0" style="margin: 30px auto;">
                <tr>
                    <td align="center" class="button-td" style="background-color: #F26C92; border-radius: 8px;">
                        <a href="${eventLink}" target="_blank" class="button-a" style="background-color: #F26C92; border: 1px solid #F26C92; border-radius: 8px; color: #ffffff; display: inline-block; font-size: 18px; font-weight: bold; padding: 16px 40px; text-align: center; text-decoration: none;">
                            View Event Details
                        </a>
                    </td>
                </tr>
            </table>
            
            <div class="divider"></div>
            
            <p class="info-text">
                Click the button above to view full event details, get directions, and secure your spot. 
                If you don't have the KiccBacc app, the link will guide you through downloading it.
            </p>
            
            <p class="info-text" style="font-size: 12px; color: #999;">
                This event link works on any device. Open it on your phone to get the full app experience!
            </p>
        </div>
        
        <!-- Footer -->
        <div class="footer">
            <div class="footer-logo">KiccBacc</div>
            <p class="footer-text">
                Making event discovery and sharing easier than ever.<br>
                Connect with friends, discover amazing events, and create unforgettable memories.
            </p>
            <div class="footer-links">
                <a href="https://kiccbacc.com" class="footer-link">Website</a>
                <a href="https://kiccbacc.com/privacy" class="footer-link">Privacy Policy</a>
                <a href="https://kiccbacc.com/terms" class="footer-link">Terms of Service</a>
            </div>
            <p class="footer-text" style="margin-top: 15px; font-size: 11px;">
                © ${new Date().getFullYear()} KiccBacc. All rights reserved.
            </p>
        </div>
    </div>
</body>
</html>
    `.trim();
}
