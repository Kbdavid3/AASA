// Test script for scheduled notifications
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./kiccbacc-b538e-firebase-adminsdk.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function testScheduledNotifications() {
  try {
    console.log('🧪 Testing scheduled notifications...');
    
    const now = admin.firestore.Timestamp.now();
    
    // Get scheduled notifications that are due
    const scheduledNotifications = await admin.firestore()
      .collection('scheduledNotifications')
      .where('scheduledFor', '<=', now)
      .where('isSent', '==', false)
      .get();
    
    console.log(`📋 Found ${scheduledNotifications.docs.length} scheduled notifications to process`);
    
    if (scheduledNotifications.docs.length === 0) {
      console.log('No scheduled notifications found. Creating a test notification...');
      
      // Create a test scheduled notification
      const testNotification = {
        notificationID: 'test-' + Date.now(),
        eventID: 'test-event-id',
        hostID: 'test-host-id',
        title: 'Test Scheduled Notification',
        body: 'This is a test scheduled notification',
        scheduledFor: new Date(Date.now() - 60000), // 1 minute ago
        targetAudience: 'event_joinees',
        targetUserIDs: [],
        isSent: false,
        createdAt: new Date()
      };
      
      await admin.firestore()
        .collection('scheduledNotifications')
        .doc(testNotification.notificationID)
        .set(testNotification);
      
      console.log('✅ Created test scheduled notification');
    }
    
    // Call the test function
    const response = await fetch('https://us-central1-kiccbacc-b538e.cloudfunctions.net/testScheduledNotifications');
    const result = await response.json();
    
    console.log('📊 Test result:', result);
    
  } catch (error) {
    console.error('❌ Error testing scheduled notifications:', error);
  }
}

// Run the test
testScheduledNotifications();
