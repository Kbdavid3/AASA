const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./kiccbacc/google-services.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function testStoryLikeCreation() {
  console.log('🔍 Testing Story Like Notification Creation...\n');

  try {
    // 1. Check recent notifications
    console.log('1️⃣ Checking recent notifications...');
    const notificationsSnapshot = await db.collection('notifications')
      .orderBy('createdAt', 'desc')
      .limit(10)
      .get();

    console.log(`📋 Found ${notificationsSnapshot.size} recent notifications:`);
    
    notificationsSnapshot.forEach((doc, index) => {
      const data = doc.data();
      console.log(`   ${index + 1}. ${data.type} - ${data.title} (${data.receiverID})`);
    });
    console.log('');

    // 2. Check if any story_like notifications exist
    console.log('2️⃣ Checking for story_like notifications...');
    const storyLikeSnapshot = await db.collection('notifications')
      .where('type', '==', 'story_like')
      .limit(5)
      .get();

    console.log(`📋 Found ${storyLikeSnapshot.size} story_like notifications:`);
    
    storyLikeSnapshot.forEach((doc, index) => {
      const data = doc.data();
      console.log(`   ${index + 1}. ${data.title} - ${data.body} (${data.receiverID})`);
      console.log(`      Created: ${data.createdAt?.toDate?.() || data.createdAt}`);
    });
    console.log('');

    // 3. Check user push tokens
    console.log('3️⃣ Checking user push tokens...');
    const usersSnapshot = await db.collection('users').limit(3).get();
    
    usersSnapshot.forEach((doc, index) => {
      const data = doc.data();
      const tokens = data.pushNotificationTokens || [];
      console.log(`   User ${index + 1}: ${doc.id} - ${tokens.length} push tokens`);
      if (tokens.length > 0) {
        console.log(`      First token: ${tokens[0].substring(0, 30)}...`);
      }
    });
    console.log('');

    // 4. Check Firebase Functions deployment
    console.log('4️⃣ Firebase Functions Status:');
    console.log('📋 To check deployed functions:');
    console.log('   firebase functions:list');
    console.log('');
    console.log('📋 To check function logs:');
    console.log('   firebase functions:log --only sendPushNotification');
    console.log('');

    // 5. Test notification creation
    console.log('5️⃣ Testing notification creation...');
    const testNotification = {
      notificationID: `test-${Date.now()}`,
      type: 'story_like',
      title: 'Test Story Like',
      body: 'This is a test story like notification',
      senderID: 'test-sender',
      receiverID: usersSnapshot.docs[0]?.id || 'test-receiver',
      eventID: '',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false
    };

    console.log('📝 Creating test notification:', testNotification);
    
    await db.collection('notifications').doc(testNotification.notificationID).set(testNotification);
    console.log('✅ Test notification created successfully');
    
    // Wait a moment
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // Check if it was created
    const createdNotification = await db.collection('notifications').doc(testNotification.notificationID).get();
    if (createdNotification.exists) {
      console.log('✅ Test notification exists in Firestore');
    } else {
      console.log('❌ Test notification not found');
    }

    // Cleanup
    await db.collection('notifications').doc(testNotification.notificationID).delete();
    console.log('✅ Test notification cleaned up');

  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

// Run the test
testStoryLikeCreation().then(() => {
  console.log('\n🏁 Test completed');
  process.exit(0);
}).catch(error => {
  console.error('💥 Test failed:', error);
  process.exit(1);
});
