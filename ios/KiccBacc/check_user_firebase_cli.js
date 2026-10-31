const { execSync } = require('child_process');

async function checkUserWithFirebaseCLI() {
  console.log('🔍 Checking for user with email: perez.jenny34@yahoo.com using Firebase CLI\n');
  
  try {
    // Check if we're in the right project
    console.log('1. Checking current Firebase project...');
    const projectInfo = execSync('firebase use', { encoding: 'utf8' });
    console.log(projectInfo);
    
    // Try to export users to see if we can access the data
    console.log('\n2. Attempting to export users data...');
    try {
      const usersExport = execSync('firebase firestore:export --collection-ids users --output-format json', { encoding: 'utf8' });
      console.log('✅ Successfully exported users collection');
      console.log(usersExport);
    } catch (exportError) {
      console.log('❌ Could not export users collection:', exportError.message);
    }
    
    // Try to list Firestore indexes to verify access
    console.log('\n3. Checking Firestore indexes...');
    try {
      const indexes = execSync('firebase firestore:indexes', { encoding: 'utf8' });
      console.log('✅ Firestore indexes:');
      console.log(indexes);
    } catch (indexError) {
      console.log('❌ Could not list indexes:', indexError.message);
    }
    
    // Try to use the Firebase emulator to query the data
    console.log('\n4. Starting Firebase emulator to query data...');
    try {
      // Start emulator in background
      const emulatorProcess = execSync('firebase emulators:start --only firestore --export-on-exit=./emulator-data', { 
        encoding: 'utf8',
        timeout: 10000 // 10 second timeout
      });
      console.log('✅ Emulator started');
    } catch (emulatorError) {
      console.log('❌ Could not start emulator:', emulatorError.message);
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

checkUserWithFirebaseCLI().then(() => {
  console.log('\n🏁 Script completed');
  process.exit(0);
}).catch(error => {
  console.error('❌ Script failed:', error);
  process.exit(1);
});
