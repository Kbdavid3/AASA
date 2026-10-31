// Test script for event join notifications
// This script tests the notification system to ensure event join notifications are working

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

async function testEventJoinNotification() {
    try {
        console.log('🧪 Testing Event Join Notification System...');
        
        // Test data
        const testEventID = 'test_event_123';
        const testJoinerID = 'test_joiner_456';
        const testHostID = 'test_host_789';
        const eventTitle = 'Test Event';
        
        // Create test event
        console.log('📝 Creating test event...');
        await db.collection('events').doc(testEventID).set({
            eventID: testEventID,
            name: eventTitle,
            hostIDs: [testHostID],
            interestedUserIDs: [],
            createdAt: admin.firestore.Timestamp.now()
        });
        
        // Create test users
        console.log('👥 Creating test users...');
        await db.collection('users').doc(testJoinerID).set({
            userID: testJoinerID,
            fullName: 'Test Joiner',
            pushNotificationTokens: ['test_token_joiner']
        });
        
        await db.collection('users').doc(testHostID).set({
            userID: testHostID,
            fullName: 'Test Host',
            pushNotificationTokens: ['test_token_host']
        });
        
        // Create notification
        console.log('🔔 Creating event join notification...');
        const notificationID = admin.firestore().collection('notifications').doc().id;
        const notification = {
            notificationID: notificationID,
            type: 'event_join',
            title: 'New Event Join',
            body: `Test Joiner joined your event '${eventTitle}'`,
            senderID: testJoinerID,
            receiverID: testHostID,
            eventID: testEventID,
            createdAt: admin.firestore.Timestamp.now(),
            isRead: false
        };
        
        await db.collection('notifications').doc(notificationID).set(notification);
        
        console.log('✅ Test notification created successfully!');
        console.log('📊 Notification details:', {
            id: notificationID,
            type: notification.type,
            title: notification.title,
            body: notification.body,
            sender: notification.senderID,
            receiver: notification.receiverID,
            event: notification.eventID
        });
        
        // Verify notification was created
        const createdNotification = await db.collection('notifications').doc(notificationID).get();
        if (createdNotification.exists) {
            console.log('✅ Notification verified in Firestore');
        } else {
            console.log('❌ Notification not found in Firestore');
        }
        
        // Clean up test data
        console.log('🧹 Cleaning up test data...');
        await db.collection('events').doc(testEventID).delete();
        await db.collection('users').doc(testJoinerID).delete();
        await db.collection('users').doc(testHostID).delete();
        await db.collection('notifications').doc(notificationID).delete();
        
        console.log('✅ Test completed successfully!');
        
    } catch (error) {
        console.error('❌ Test failed:', error);
    }
}

// Run the test
testEventJoinNotification();
