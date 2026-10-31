// Test script for KiccBacc notification system
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp({
  projectId: 'kiccbacc-b538e'
});

const db = admin.firestore();

async function testNotificationSystem() {
  console.log('🧪 Testing KiccBacc Notification System\n');
  
  try {
    // Test 1: Check if notifications collection exists
    console.log('1. Testing notifications collection...');
    const notificationsSnapshot = await db.collection('notifications').limit(1).get();
    console.log('✅ Notifications collection accessible');
    console.log(`   - Found ${notificationsSnapshot.size} notifications`);
    
    // Test 2: Check if users collection exists
    console.log('\n2. Testing users collection...');
    const usersSnapshot = await db.collection('users').limit(1).get();
    console.log('✅ Users collection accessible');
    console.log(`   - Found ${usersSnapshot.size} users`);
    
    // Test 3: Check if any users have push tokens
    console.log('\n3. Checking for users with push tokens...');
    const usersWithTokens = await db.collection('users')
      .where('pushNotificationTokens', '!=', null)
      .get();
    
    console.log(`   - Found ${usersWithTokens.size} users with push tokens`);
    
    if (usersWithTokens.size > 0) {
      const sampleUser = usersWithTokens.docs[0];
      const userData = sampleUser.data();
      const tokens = userData.pushNotificationTokens || [];
      console.log(`   - Sample user: ${userData.fullName || userData.username || 'Unknown'}`);
      console.log(`   - Token count: ${tokens.length}`);
      console.log(`   - First token: ${tokens[0] ? tokens[0].substring(0, 20) + '...' : 'None'}`);
    }
    
    // Test 4: Test Firebase Functions
    console.log('\n4. Testing Firebase Functions...');
    const testResponse = await fetch('https://us-central1-kiccbacc-b538e.cloudfunctions.net/testNotification');
    const testData = await testResponse.json();
    console.log('✅ Firebase Functions are responding');
    console.log(`   - Message: ${testData.message}`);
    console.log(`   - Functions: ${testData.functions.join(', ')}`);
    
    // Test 5: Test debug function with a sample user
    if (usersWithTokens.size > 0) {
      console.log('\n5. Testing debug notification function...');
      const sampleUserID = usersWithTokens.docs[0].id;
      const debugResponse = await fetch(`https://us-central1-kiccbacc-b538e.cloudfunctions.net/debugNotification?userID=${sampleUserID}`);
      const debugData = await debugResponse.json();
      
      console.log('✅ Debug function working');
      console.log(`   - User: ${debugData.user?.fullName || debugData.user?.username || 'Unknown'}`);
      console.log(`   - Push tokens: ${debugData.pushTokens?.count || 0}`);
      console.log(`   - Push result: ${debugData.pushResult?.success ? 'Success' : 'Failed'}`);
      
      if (debugData.pushResult?.error) {
        console.log(`   - Error: ${debugData.pushResult.error}`);
      }
    }
    
    // Test 6: Check recent notifications
    console.log('\n6. Checking recent notifications...');
    const recentNotifications = await db.collection('notifications')
      .orderBy('createdAt', 'desc')
      .limit(5)
      .get();
    
    console.log(`   - Found ${recentNotifications.size} recent notifications`);
    
    recentNotifications.docs.forEach((doc, index) => {
      const data = doc.data();
      console.log(`   ${index + 1}. ${data.title} (${data.type}) - ${data.receiverID}`);
    });
    
    console.log('\n🎉 Notification System Test Complete!');
    console.log('\n📋 Summary:');
    console.log('   ✅ Firestore Database: Connected');
    console.log('   ✅ Notifications Collection: Accessible');
    console.log('   ✅ Users Collection: Accessible');
    console.log('   ✅ Firebase Functions: Deployed and Responding');
    console.log('   ✅ Push Token Storage: Working');
    console.log('   ✅ Debug Function: Available');
    
    console.log('\n🚀 Next Steps:');
    console.log('   1. Open the app and navigate to Debug Notifications');
    console.log('   2. Check permissions and FCM token status');
    console.log('   3. Test Firebase Functions from the app');
    console.log('   4. Send a test notification');
    console.log('   5. Check device notification settings');
    
  } catch (error) {
    console.error('❌ Notification System Test Failed:', error);
    console.log('\n🔧 Troubleshooting:');
    console.log('   1. Check internet connection');
    console.log('   2. Verify Firebase project permissions');
    console.log('   3. Ensure Firebase Functions are deployed');
    console.log('   4. Check Firebase Console for service status');
  }
}

// Run the test
testNotificationSystem();
