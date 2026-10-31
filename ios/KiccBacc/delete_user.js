const admin = require('firebase-admin');

// Initialize Firebase Admin SDK with project ID
admin.initializeApp({
  projectId: 'kiccbacc-b538e'
});

const db = admin.firestore();

async function deleteUserByEmail() {
  const email = 'perez.jenny34@yahoo.com';
  console.log(`🗑️  Deleting user with email: ${email}\n`);
  
  try {
    // 1. Find user in Firebase Auth
    console.log('1. Finding user in Firebase Auth...');
    let userRecord = null;
    try {
      userRecord = await admin.auth().getUserByEmail(email);
      console.log(`✅ Found user in Firebase Auth:`);
      console.log(`   - UID: ${userRecord.uid}`);
      console.log(`   - Email: ${userRecord.email}`);
    } catch (authError) {
      if (authError.code === 'auth/user-not-found') {
        console.log('✅ No user found in Firebase Auth');
        return;
      } else {
        console.log(`❌ Error finding user: ${authError.message}`);
        return;
      }
    }
    
    // 2. Find user document in Firestore
    console.log('\n2. Finding user document in Firestore...');
    const usersSnapshot = await db.collection('users')
      .where('email', '==', email)
      .get();
    
    let firestoreDoc = null;
    if (!usersSnapshot.empty) {
      firestoreDoc = usersSnapshot.docs[0];
      console.log(`✅ Found user document in Firestore:`);
      console.log(`   - Document ID: ${firestoreDoc.id}`);
      console.log(`   - Email: ${firestoreDoc.data().email}`);
    } else {
      console.log('✅ No user document found in Firestore');
    }
    
    // 3. Delete from Firestore first (if exists)
    if (firestoreDoc) {
      console.log('\n3. Deleting user document from Firestore...');
      await firestoreDoc.ref.delete();
      console.log('✅ User document deleted from Firestore');
    }
    
    // 4. Delete from Firebase Auth
    console.log('\n4. Deleting user from Firebase Auth...');
    await admin.auth().deleteUser(userRecord.uid);
    console.log('✅ User deleted from Firebase Auth');
    
    console.log('\n🎉 User successfully deleted from both Firebase Auth and Firestore!');
    console.log('   The user can now sign up again with the same email.');
    
  } catch (error) {
    console.error('❌ Error deleting user:', error);
  }
}

// Run the deletion
deleteUserByEmail().then(() => {
  console.log('\n🏁 Script completed');
  process.exit(0);
}).catch(error => {
  console.error('❌ Script failed:', error);
  process.exit(1);
});
