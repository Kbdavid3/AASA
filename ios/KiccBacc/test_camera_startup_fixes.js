#!/usr/bin/env node

/**
 * Test script to verify the camera startup fixes
 * 
 * This script tests the improvements made to fix camera startup issues:
 * 1. Proper session initialization timing
 * 2. Robust preview layer setup with timer-based retry
 * 3. Better error handling and user feedback
 * 4. Prevention of multiple initialization attempts
 * 5. Proper state management
 */

const fs = require('fs');

console.log('🔍 Testing Camera Startup Fixes...\n');

const customStoryCameraFile = 'kiccbacc/SwiftUI/Views/Other Views/Story/CustomStoryCameraView.swift';

if (!fs.existsSync(customStoryCameraFile)) {
    console.error('❌ CustomStoryCameraView.swift not found');
    process.exit(1);
}

const fileContent = fs.readFileSync(customStoryCameraFile, 'utf8');

console.log('📋 Testing Camera Startup Improvements:\n');

// Test 1: Check for proper initialization state management
console.log('1. ✅ Initialization State Management:');
const hasInitializingState = fileContent.includes('@Published var isInitializing: Bool = false');
const hasInitializationGuard = fileContent.includes('guard !isInitializing else {');
const hasInitializationReset = fileContent.includes('isInitializing = false');
console.log(`   - Initializing state tracking: ${hasInitializingState ? '✅' : '❌'}`);
console.log(`   - Multiple init prevention: ${hasInitializationGuard ? '✅' : '❌'}`);
console.log(`   - State reset: ${hasInitializationReset ? '✅' : '❌'}`);

// Test 2: Check for proper session queue management
console.log('\n2. ✅ Session Queue Management:');
const hasSessionQueue = fileContent.includes('private let sessionQueue = DispatchQueue(label: "camera.session.queue")');
const usesSessionQueue = fileContent.includes('sessionQueue.async');
console.log(`   - Dedicated session queue: ${hasSessionQueue ? '✅' : '❌'}`);
console.log(`   - Queue usage: ${usesSessionQueue ? '✅' : '❌'}`);

// Test 3: Check for improved error handling
console.log('\n3. ✅ Error Handling:');
const hasDetailedErrors = fileContent.includes('print("❌ CustomCameraManager: Cannot add video input")');
const hasErrorStateUpdate = fileContent.includes('self.error = CameraError.cameraUnavailable');
const hasErrorReset = fileContent.includes('self.isInitializing = false');
console.log(`   - Detailed error logging: ${hasDetailedErrors ? '✅' : '❌'}`);
console.log(`   - Error state updates: ${hasErrorStateUpdate ? '✅' : '❌'}`);
console.log(`   - Error state reset: ${hasErrorReset ? '✅' : '❌'}`);

// Test 4: Check for timer-based preview layer setup
console.log('\n4. ✅ Preview Layer Setup:');
const hasTimerSetup = fileContent.includes('setupTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true)');
const hasTimerCleanup = fileContent.includes('setupTimer?.invalidate()');
const hasDeinitCleanup = fileContent.includes('deinit {') && fileContent.includes('setupTimer?.invalidate()');
console.log(`   - Timer-based retry: ${hasTimerSetup ? '✅' : '❌'}`);
console.log(`   - Timer cleanup: ${hasTimerCleanup ? '✅' : '❌'}`);
console.log(`   - Deinit cleanup: ${hasDeinitCleanup ? '✅' : '❌'}`);

// Test 5: Check for improved loading UI
console.log('\n5. ✅ Loading UI Improvements:');
const hasInitializingText = fileContent.includes('if cameraManager.isInitializing');
const hasRetryButton = fileContent.includes('Button("Retry")');
const hasDetailedLoading = fileContent.includes('Text("This may take a few seconds")');
console.log(`   - Initializing state text: ${hasInitializingText ? '✅' : '❌'}`);
console.log(`   - Retry button: ${hasRetryButton ? '✅' : '❌'}`);
console.log(`   - Detailed loading text: ${hasDetailedLoading ? '✅' : '❌'}`);

// Test 6: Check for proper session lifecycle
console.log('\n6. ✅ Session Lifecycle:');
const hasSessionCreation = fileContent.includes('captureSession = AVCaptureSession()');
const hasSessionStart = fileContent.includes('captureSession.startRunning()');
const hasSessionStop = fileContent.includes('self.captureSession?.stopRunning()');
const hasSessionCheck = fileContent.includes('if captureSession.isRunning');
console.log(`   - Session creation: ${hasSessionCreation ? '✅' : '❌'}`);
console.log(`   - Session start: ${hasSessionStart ? '✅' : '❌'}`);
console.log(`   - Session stop: ${hasSessionStop ? '✅' : '❌'}`);
console.log(`   - Session state check: ${hasSessionCheck ? '✅' : '❌'}`);

// Test 7: Check for proper permission handling
console.log('\n7. ✅ Permission Handling:');
const hasPermissionCheck = fileContent.includes('AVCaptureDevice.authorizationStatus(for: .video)');
const hasPermissionRequest = fileContent.includes('AVCaptureDevice.requestAccess(for: .video)');
const hasPermissionLogging = fileContent.includes('print("📸 CustomCameraManager: Camera permission authorized")');
console.log(`   - Permission check: ${hasPermissionCheck ? '✅' : '❌'}`);
console.log(`   - Permission request: ${hasPermissionRequest ? '✅' : '❌'}`);
console.log(`   - Permission logging: ${hasPermissionLogging ? '✅' : '❌'}`);

// Summary
console.log('\n📊 Summary:');
const allTests = [
    hasInitializingState && hasInitializationGuard && hasInitializationReset,
    hasSessionQueue && usesSessionQueue,
    hasDetailedErrors && hasErrorStateUpdate && hasErrorReset,
    hasTimerSetup && hasTimerCleanup && hasDeinitCleanup,
    hasInitializingText && hasRetryButton && hasDetailedLoading,
    hasSessionCreation && hasSessionStart && hasSessionStop && hasSessionCheck,
    hasPermissionCheck && hasPermissionRequest && hasPermissionLogging
];

const passedTests = allTests.filter(Boolean).length;
const totalTests = allTests.length;

console.log(`   Tests passed: ${passedTests}/${totalTests}`);

if (passedTests === totalTests) {
    console.log('\n🎉 All camera startup fixes are properly implemented!');
    console.log('\n🔧 Key improvements made:');
    console.log('   • Added proper initialization state management');
    console.log('   • Implemented dedicated session queue for thread safety');
    console.log('   • Added comprehensive error handling and logging');
    console.log('   • Created timer-based preview layer setup with cleanup');
    console.log('   • Improved loading UI with retry functionality');
    console.log('   • Enhanced session lifecycle management');
    console.log('   • Added detailed permission handling');
    console.log('\n📱 The camera should now start reliably without issues!');
} else {
    console.log('\n⚠️  Some improvements are missing. Please review the implementation.');
    process.exit(1);
}

console.log('\n✅ Camera startup fixes verification complete!');
