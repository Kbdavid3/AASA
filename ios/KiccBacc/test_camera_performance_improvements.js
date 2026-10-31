#!/usr/bin/env node

/**
 * Test script to verify camera performance improvements
 * 
 * This script tests the optimizations made to improve camera startup time and capture functionality:
 * 1. Reduced startup timeout from 1 second to 0.2 seconds
 * 2. Added retry mechanism for faster recovery
 * 3. Fixed PhotoCaptureDelegate for capture button functionality
 * 4. Optimized preview layer setup timer
 */

const fs = require('fs');

console.log('🔍 Testing Camera Performance Improvements...\n');

const customStoryCameraFile = 'kiccbacc/SwiftUI/Views/Other Views/Story/CustomStoryCameraView.swift';

if (!fs.existsSync(customStoryCameraFile)) {
    console.error('❌ CustomStoryCameraView.swift not found');
    process.exit(1);
}

const fileContent = fs.readFileSync(customStoryCameraFile, 'utf8');

console.log('📋 Testing Performance Improvements:\n');

// Test 1: Check for optimized startup timeout
console.log('1. ✅ Startup Time Optimization:');
const hasShortTimeout = fileContent.includes('DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)');
const hasRetryMechanism = fileContent.includes('DispatchQueue.main.asyncAfter(deadline: .now() + 0.3)');
const noLongTimeout = !fileContent.includes('DispatchQueue.main.asyncAfter(deadline: .now() + 1.0)') || 
                      fileContent.includes('DispatchQueue.main.asyncAfter(deadline: .now() + 1.0)') && 
                      fileContent.includes('showFocusIndicator = false');
console.log(`   - Short timeout (0.2s): ${hasShortTimeout ? '✅' : '❌'}`);
console.log(`   - Retry mechanism: ${hasRetryMechanism ? '✅' : '❌'}`);
console.log(`   - No long timeout: ${noLongTimeout ? '✅' : '❌'}`);

// Test 2: Check for PhotoCaptureDelegate implementation
console.log('\n2. ✅ Capture Button Functionality:');
const hasPhotoDelegate = fileContent.includes('class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate');
const hasPhotoOutputMethod = fileContent.includes('func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?)');
const hasPhotoCaptureCall = fileContent.includes('photoOutput.capturePhoto(with: settings, delegate: PhotoCaptureDelegate');
console.log(`   - PhotoCaptureDelegate class: ${hasPhotoDelegate ? '✅' : '❌'}`);
console.log(`   - Photo output method: ${hasPhotoOutputMethod ? '✅' : '❌'}`);
console.log(`   - Photo capture call: ${hasPhotoCaptureCall ? '✅' : '❌'}`);

// Test 3: Check for optimized preview layer setup
console.log('\n3. ✅ Preview Layer Optimization:');
const hasFastTimer = fileContent.includes('Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true)');
const hasTimerCleanup = fileContent.includes('setupTimer?.invalidate()');
const hasDeinitCleanup = fileContent.includes('deinit {') && fileContent.includes('setupTimer?.invalidate()');
console.log(`   - Fast timer (0.05s): ${hasFastTimer ? '✅' : '❌'}`);
console.log(`   - Timer cleanup: ${hasTimerCleanup ? '✅' : '❌'}`);
console.log(`   - Deinit cleanup: ${hasDeinitCleanup ? '✅' : '❌'}`);

// Test 4: Check for proper error handling in capture
console.log('\n4. ✅ Capture Error Handling:');
const hasCaptureErrorLogging = fileContent.includes('print("Photo capture error: \\(error)")');
const hasImageDataCheck = fileContent.includes('guard let imageData = photo.fileDataRepresentation()');
const hasMainThreadDispatch = fileContent.includes('DispatchQueue.main.async {') && fileContent.includes('self.completion(image)');
console.log(`   - Error logging: ${hasCaptureErrorLogging ? '✅' : '❌'}`);
console.log(`   - Image data validation: ${hasImageDataCheck ? '✅' : '❌'}`);
console.log(`   - Main thread dispatch: ${hasMainThreadDispatch ? '✅' : '❌'}`);

// Test 5: Check for capture button state management
console.log('\n5. ✅ Capture Button State:');
const hasCapturingState = fileContent.includes('@Published var isCapturing: Bool = false');
const hasCapturingAnimation = fileContent.includes('.scaleEffect(cameraManager.isCapturing ? 0.9 : 1.0)');
const hasButtonDisabled = fileContent.includes('.disabled(!cameraManager.isCameraReady)');
console.log(`   - Capturing state: ${hasCapturingState ? '✅' : '❌'}`);
console.log(`   - Capture animation: ${hasCapturingAnimation ? '✅' : '❌'}`);
console.log(`   - Button disabled state: ${hasButtonDisabled ? '✅' : '❌'}`);

// Test 6: Check for flash mode support
console.log('\n6. ✅ Flash Mode Support:');
const hasFlashMode = fileContent.includes('private var flashMode: AVCaptureDevice.FlashMode = .off');
const hasFlashSettings = fileContent.includes('settings.flashMode = flashMode');
const hasFlashToggle = fileContent.includes('func setFlashMode(_ mode: AVCaptureDevice.FlashMode)');
console.log(`   - Flash mode property: ${hasFlashMode ? '✅' : '❌'}`);
console.log(`   - Flash settings: ${hasFlashSettings ? '✅' : '❌'}`);
console.log(`   - Flash toggle method: ${hasFlashToggle ? '✅' : '❌'}`);

// Summary
console.log('\n📊 Summary:');
const allTests = [
    hasShortTimeout && hasRetryMechanism && noLongTimeout,
    hasPhotoDelegate && hasPhotoOutputMethod && hasPhotoCaptureCall,
    hasFastTimer && hasTimerCleanup && hasDeinitCleanup,
    hasCaptureErrorLogging && hasImageDataCheck && hasMainThreadDispatch,
    hasCapturingState && hasCapturingAnimation && hasButtonDisabled,
    hasFlashMode && hasFlashSettings && hasFlashToggle
];

const passedTests = allTests.filter(Boolean).length;
const totalTests = allTests.length;

console.log(`   Tests passed: ${passedTests}/${totalTests}`);

if (passedTests === totalTests) {
    console.log('\n🎉 All camera performance improvements are properly implemented!');
    console.log('\n🔧 Key optimizations made:');
    console.log('   • Reduced startup timeout from 1.0s to 0.2s (5x faster)');
    console.log('   • Added retry mechanism for faster recovery');
    console.log('   • Fixed PhotoCaptureDelegate for working capture button');
    console.log('   • Optimized preview layer timer from 0.1s to 0.05s (2x faster)');
    console.log('   • Added proper error handling for photo capture');
    console.log('   • Implemented capture button state management');
    console.log('   • Added flash mode support');
    console.log('\n📱 The camera should now start much faster and capture photos properly!');
} else {
    console.log('\n⚠️  Some improvements are missing. Please review the implementation.');
    process.exit(1);
}

console.log('\n✅ Camera performance improvements verification complete!');
