const admin = require('firebase-admin');

// Initialize Firebase Admin SDK with project ID
admin.initializeApp({
  projectId: 'kiccbacc-b538e'
});

const db = admin.firestore();

async function checkUserEmail() {
  console.log('🔍 Checking for user with email: perez.jenny34@yahoo.com\n');
  
  try {
    // 1. Check if user exists in Firestore by email
    console.log('1. Searching Firestore for user with email...');
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
        console.log(`   - Document exists: ${doc.exists}`);
        console.log('');
      });
    }
    
    // 2. Check Firebase Auth for the email
    console.log('2. Checking Firebase Auth for this email...');
    try {
      const userRecord = await admin.auth().getUserByEmail('perez.jenny34@yahoo.com');
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
      } else {
        console.log(`❌ Error checking Firebase Auth: ${authError.message}`);
      }
    }
    
    // 3. Check for any partial email matches
    console.log('\n3. Checking for partial email matches...');
    const partialSnapshot = await db.collection('users')
      .where('email', '>=', 'perez.jenny34')
      .where('email', '<=', 'perez.jenny34\uf8ff')
      .get();
    
    if (partialSnapshot.empty) {
      console.log('✅ No partial email matches found');
    } else {
      console.log(`⚠️  Found ${partialSnapshot.size} user(s) with similar emails:`);
      partialSnapshot.forEach(doc => {
        const userData = doc.data();
        console.log(`   - User ID: ${doc.id}`);
        console.log(`   - Email: ${userData.email}`);
      });
    }
    
    // 4. Check for any case sensitivity issues
    console.log('\n4. Checking for case sensitivity issues...');
    const caseVariations = [
      'perez.jenny34@yahoo.com',
      'PEREZ.JENNY34@YAHOO.COM',
      'Perez.Jenny34@yahoo.com',
      'perez.jenny34@YAHOO.COM'
    ];
    
    for (const email of caseVariations) {
      const caseSnapshot = await db.collection('users')
        .where('email', '==', email)
        .get();
      
      if (!caseSnapshot.empty) {
        console.log(`❌ Found user with email variation: ${email}`);
        caseSnapshot.forEach(doc => {
          const userData = doc.data();
          console.log(`   - User ID: ${doc.id}`);
          console.log(`   - Original email: ${userData.email}`);
        });
      }
    }
    
    // 5. Check if there are any soft-deleted users or users with different status
    console.log('\n5. Checking for users with different status...');
    const allUsersSnapshot = await db.collection('users')
      .where('email', '==', 'perez.jenny34@yahoo.com')
      .get();
    
    if (!allUsersSnapshot.empty) {
      allUsersSnapshot.forEach(doc => {
        const userData = doc.data();
        console.log(`\nUser document details:`);
        console.log(`   - Document ID: ${doc.id}`);
        console.log(`   - All fields:`, JSON.stringify(userData, null, 2));
        
        // Check for common status fields
        const statusFields = ['isDeleted', 'deleted', 'active', 'status', 'disabled'];
        statusFields.forEach(field => {
          if (userData[field] !== undefined) {
            console.log(`   - ${field}: ${userData[field]}`);
          }
        });
      });
    }
    
    console.log('\n✅ Email check completed');
    
  } catch (error) {
    console.error('❌ Error checking user email:', error);
  }
}

// Run the check
checkUserEmail().then(() => {
  console.log('\n🏁 Script completed');
  process.exit(0);
}).catch(error => {
  console.error('❌ Script failed:', error);
  process.exit(1);
});
