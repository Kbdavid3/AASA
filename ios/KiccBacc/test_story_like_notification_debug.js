const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./kiccbacc/google-services.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function testStoryLikeNotification() {
  console.log('🔍 Testing Story Like Notification Flow...\n');

  try {
    // 1. Check if we can access Firestore
    console.log('1️⃣ Testing Firestore access...');
    const testDoc = await db.collection('test').doc('test').get();
    console.log('✅ Firestore access successful\n');

    // 2. Get a test user to check push tokens
    console.log('2️⃣ Checking user push tokens...');
    const usersSnapshot = await db.collection('users').limit(1).get();
    
    if (usersSnapshot.empty) {
      console.log('❌ No users found in database');
      return;
    }

    const testUser = usersSnapshot.docs[0];
    const userData = testUser.data();
    const pushTokens = userData.pushNotificationTokens || [];
    
    console.log(`📱 User: ${testUser.id}`);
    console.log(`📱 Push tokens: ${pushTokens.length} tokens`);
    if (pushTokens.length > 0) {
      console.log(`📱 First token: ${pushTokens[0].substring(0, 20)}...`);
    } else {
      console.log('❌ No push tokens found for user');
    }
    console.log('');

    // 3. Create a test story like notification
    console.log('3️⃣ Creating test story like notification...');
    const testNotification = {
      notificationID: `test-story-like-${Date.now()}`,
      type: 'story_like',
      title: 'Story Like',
      body: 'Test User liked your story',
      senderID: 'test-sender-id',
      receiverID: testUser.id,
      eventID: '',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false
    };

    console.log('📝 Notification data:', testNotification);

    // Save to Firestore
    await db.collection('notifications').doc(testNotification.notificationID).set(testNotification);
    console.log('✅ Test notification saved to Firestore\n');

    // 4. Wait a moment for Firebase Functions to process
    console.log('4️⃣ Waiting for Firebase Functions to process...');
    await new Promise(resolve => setTimeout(resolve, 5000));

    // 5. Check if notification was processed
    console.log('5️⃣ Checking if notification was processed...');
    const savedNotification = await db.collection('notifications').doc(testNotification.notificationID).get();
    
    if (savedNotification.exists) {
      console.log('✅ Notification exists in Firestore');
      console.log('📊 Notification data:', savedNotification.data());
    } else {
      console.log('❌ Notification not found in Firestore');
    }

    // 6. Check Firebase Functions logs (if possible)
    console.log('\n6️⃣ Firebase Functions Status:');
    console.log('📋 To check if sendPushNotification function is deployed, run:');
    console.log('   firebase functions:list');
    console.log('');
    console.log('📋 To check Firebase Functions logs, run:');
    console.log('   firebase functions:log --only sendPushNotification');
    console.log('');

    // 7. Test manual push notification
    console.log('7️⃣ Testing manual push notification...');
    if (pushTokens.length > 0) {
      try {
        const message = {
          notification: {
            title: 'Test Story Like',
            body: 'This is a test notification for story likes'
          },
          data: {
            test: 'true',
            type: 'story_like'
          },
          token: pushTokens[0]
        };

        const response = await admin.messaging().send(message);
        console.log('✅ Manual push notification sent successfully');
        console.log('📊 Response:', response);
      } catch (error) {
        console.log('❌ Manual push notification failed:', error.message);
      }
    } else {
      console.log('⚠️ Skipping manual push test - no tokens available');
    }

    // 8. Cleanup test notification
    console.log('\n8️⃣ Cleaning up test notification...');
    await db.collection('notifications').doc(testNotification.notificationID).delete();
    console.log('✅ Test notification cleaned up');

  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

// Run the test
testStoryLikeNotification().then(() => {
  console.log('\n🏁 Test completed');
  process.exit(0);
}).catch(error => {
  console.error('💥 Test failed:', error);
  process.exit(1);
});
