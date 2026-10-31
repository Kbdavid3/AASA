// Simple Firebase Configuration Verification
const fs = require('fs');
const path = require('path');

console.log('🔍 Verifying Firebase Configuration Files...\n');

// 1. Check GoogleService-Info.plist
console.log('1. Checking GoogleService-Info.plist...');
const googleServicePath = path.join(__dirname, '..', 'kiccbacc', 'GoogleService-Info.plist');

if (fs.existsSync(googleServicePath)) {
  const content = fs.readFileSync(googleServicePath, 'utf8');
  
  // Check for required keys
  const requiredKeys = [
    'CLIENT_ID',
    'REVERSED_CLIENT_ID', 
    'API_KEY',
    'GCM_SENDER_ID',
    'PROJECT_ID',
    'STORAGE_BUCKET',
    'GOOGLE_APP_ID'
  ];
  
  let allKeysPresent = true;
  requiredKeys.forEach(key => {
    if (content.includes(`<key>${key}</key>`)) {
      console.log(`   ✅ ${key}: Present`);
    } else {
      console.log(`   ❌ ${key}: Missing`);
      allKeysPresent = false;
    }
  });
  
  if (allKeysPresent) {
    console.log('   ✅ GoogleService-Info.plist: Valid');
  } else {
    console.log('   ❌ GoogleService-Info.plist: Invalid - missing required keys');
  }
} else {
  console.log('   ❌ GoogleService-Info.plist: Not found');
}

// 2. Check .firebaserc
console.log('\n2. Checking .firebaserc...');
const firebasercPath = path.join(__dirname, '..', '.firebaserc');

if (fs.existsSync(firebasercPath)) {
  const content = fs.readFileSync(firebasercPath, 'utf8');
  if (content.includes('kiccbacc-b538e')) {
    console.log('   ✅ Project ID: kiccbacc-b538e');
  } else {
    console.log('   ❌ Project ID: Mismatch');
  }
} else {
  console.log('   ❌ .firebaserc: Not found');
}

// 3. Check firebase.json
console.log('\n3. Checking firebase.json...');
const firebaseJsonPath = path.join(__dirname, '..', 'firebase.json');

if (fs.existsSync(firebaseJsonPath)) {
  console.log('   ✅ firebase.json: Present');
} else {
  console.log('   ❌ firebase.json: Not found');
}

// 4. Check Xcode project configuration
console.log('\n4. Checking Xcode project configuration...');
const pbxprojPath = path.join(__dirname, '..', 'kiccbacc.xcodeproj', 'project.pbxproj');

if (fs.existsSync(pbxprojPath)) {
  const content = fs.readFileSync(pbxprojPath, 'utf8');
  
  if (content.includes('GoogleService-Info.plist')) {
    console.log('   ✅ GoogleService-Info.plist: Referenced in Xcode project');
  } else {
    console.log('   ❌ GoogleService-Info.plist: Not referenced in Xcode project');
  }
  
  if (content.includes('PRODUCT_BUNDLE_IDENTIFIER = kiccbacc')) {
    console.log('   ✅ Bundle ID: kiccbacc');
  } else {
    console.log('   ❌ Bundle ID: Mismatch');
  }
} else {
  console.log('   ❌ Xcode project: Not found');
}

// 5. Check Info.plist for notification permissions
console.log('\n5. Checking Info.plist for notification configuration...');
const infoPlistPath = path.join(__dirname, '..', 'kiccbacc', 'Info.plist');

if (fs.existsSync(infoPlistPath)) {
  const content = fs.readFileSync(infoPlistPath, 'utf8');
  
  if (content.includes('UIBackgroundModes') && content.includes('remote-notification')) {
    console.log('   ✅ Background modes: Configured for remote notifications');
  } else {
    console.log('   ❌ Background modes: Not configured for remote notifications');
  }
  
  if (content.includes('CFBundleURLSchemes') && content.includes('kiccbacc')) {
    console.log('   ✅ URL schemes: Configured');
  } else {
    console.log('   ❌ URL schemes: Not configured');
  }
} else {
  console.log('   ❌ Info.plist: Not found');
}

// 6. Check Firebase Functions
console.log('\n6. Checking Firebase Functions...');
const functionsIndexPath = path.join(__dirname, 'index.js');

if (fs.existsSync(functionsIndexPath)) {
  const content = fs.readFileSync(functionsIndexPath, 'utf8');
  
  const requiredFunctions = [
    'sendPushNotification',
    'sendStoryNotificationToFollowers',
    'sendEventMilestoneNotification',
    'cleanupInvalidTokens',
    'sendScheduledNotifications'
  ];
  
  let allFunctionsPresent = true;
  requiredFunctions.forEach(func => {
    if (content.includes(`exports.${func}`)) {
      console.log(`   ✅ ${func}: Present`);
    } else {
      console.log(`   ❌ ${func}: Missing`);
      allFunctionsPresent = false;
    }
  });
  
  if (allFunctionsPresent) {
    console.log('   ✅ All required functions: Present');
  } else {
    console.log('   ❌ Some required functions: Missing');
  }
} else {
  console.log('   ❌ Firebase Functions: Not found');
}

// 7. Configuration Summary
console.log('\n📋 Configuration Summary:');
console.log('   Project ID: kiccbacc-b538e');
console.log('   Bundle ID: kiccbacc');
console.log('   GCM Sender ID: 745475106905');
console.log('   API Key: AIzaSyDNuXoreJ4wmaLlER6UeATVaIGMrGW_lbI');
console.log('   Storage Bucket: kiccbacc-b538e.appspot.com');

console.log('\n🎉 Configuration Verification Complete!');
console.log('\n🚀 Next Steps:');
console.log('   1. Build and run the app on a physical device');
console.log('   2. Grant notification permissions when prompted');
console.log('   3. Test notifications using the "Test" button in the app');
console.log('   4. Check console logs for debugging information');
console.log('   5. Verify in Firebase Console that all services are enabled');

console.log('\n🔧 If notifications still don\'t work:');
console.log('   1. Check iOS Settings > Notifications > KiccBacc');
console.log('   2. Ensure "Allow Notifications" is enabled');
console.log('   3. Check "Sounds", "Badges", and "Banners" are enabled');
console.log('   4. Verify the app is not in "Do Not Disturb" mode');
console.log('   5. Check that the device has internet connection');
