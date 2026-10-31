const admin = require('firebase-admin');

// Initialize Firebase Admin SDK with project ID
admin.initializeApp({
  projectId: 'kiccbacc-b538e'
});

const db = admin.firestore();

async function checkAndDeleteUser() {
  console.log('🔍 Checking and potentially deleting user with email: perez.jenny34@yahoo.com\n');
  
  try {
    // 1. Check if user exists in Firebase Auth
    console.log('1. Checking Firebase Auth for this email...');
    let userRecord = null;
    try {
      userRecord = await admin.auth().getUserByEmail('perez.jenny34@yahoo.com');
      console.log(`❌ User found in Firebase Auth:`);
      console.log(`   - UID: ${userRecord.uid}`);
      console.log(`   - Email: ${userRecord.email}`);
      console.log(`   - Email verified: ${userRecord.emailVerified}`);
      console.log(`   - Created: ${new Date(userRecord.metadata.creationTime)}`);
      console.log(`   - Last sign in: ${new Date(userRecord.metadata.lastSignInTime)}`);
      console.log(`   - Disabled: ${userRecord.disabled}`);
    } catch (authError) {
      if (authError.code === 'auth/user-not-found') {
        console.log('✅ No user found in Firebase Auth with this email');
        return;
      } else {
        console.log(`❌ Error checking Firebase Auth: ${authError.message}`);
        return;
      }
    }
    
    // 2. Check if user exists in Firestore
    console.log('\n2. Checking Firestore for user data...');
    const usersSnapshot = await db.collection('users')
      .where('email', '==', 'perez.jenny34@yahoo.com')
      .get();
    
    if (usersSnapshot.empty) {
      console.log('✅ No user found in Firestore with this email');
    } else {
      console.log(`❌ Found ${usersSnapshot.size} user(s) in Firestore with this email:`);
      usersSnapshot.forEach(doc => {
        const userData = doc.data();
        console.log(`   - User ID: ${doc.id}`);
        console.log(`   - Email: ${userData.email}`);
        console.log(`   - Username: ${userData.username || 'N/A'}`);
        console.log(`   - Created: ${userData.createdAt?.toDate() || 'N/A'}`);
      });
    }
    
    // 3. Ask for confirmation to delete
    console.log('\n3. Summary:');
    console.log(`   - Firebase Auth: ${userRecord ? 'User exists' : 'No user'}`);
    console.log(`   - Firestore: ${usersSnapshot.empty ? 'No user data' : `${usersSnapshot.size} user document(s)`}`);
    
    if (userRecord) {
      console.log('\n⚠️  To resolve the "user already exists" issue, you need to:');
      console.log('   1. Delete the user from Firebase Auth');
      console.log('   2. Delete the user document from Firestore (if it exists)');
      
      console.log('\n📝 Instructions:');
      console.log('   - Go to Firebase Console > Authentication > Users');
      console.log('   - Search for: perez.jenny34@yahoo.com');
      console.log('   - Delete the user from there');
      console.log('   - Then go to Firestore > Data > users collection');
      console.log('   - Delete the user document if it exists');
      
      // 4. Option to delete programmatically (commented out for safety)
      console.log('\n🔧 Programmatic deletion (commented out for safety):');
      console.log('   // Uncomment the following lines to delete programmatically:');
      console.log('   // await admin.auth().deleteUser(userRecord.uid);');
      console.log('   // if (!usersSnapshot.empty) {');
      console.log('   //   for (const doc of usersSnapshot.docs) {');
      console.log('   //     await doc.ref.delete();');
      console.log('   //   }');
      console.log('   // }');
    }
    
    console.log('\n✅ Check completed');
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

// Run the check
checkAndDeleteUser().then(() => {
  console.log('\n🏁 Script completed');
  process.exit(0);
}).catch(error => {
  console.error('❌ Script failed:', error);
  process.exit(1);
});
