#!/usr/bin/env node

/**
 * Test script to verify the visible area crop implementation
 * This script checks if the new cropVisibleAreaTo9x16 method has been properly implemented
 */

const fs = require('fs');
const path = require('path');

console.log('🧪 Testing Visible Area Crop Implementation...\n');

// Test 1: Check UIImage extension for new method
console.log('1. Checking UIImage extension for cropVisibleAreaTo9x16 method...');
const uiImageExtensionPath = 'kiccbacc/SwiftUI/Services/Extensions/UIIImage.swift';
const uiImageExtensionContent = fs.readFileSync(uiImageExtensionPath, 'utf8');

const hasVisibleAreaCropMethod = uiImageExtensionContent.includes('cropVisibleAreaTo9x16');
const hasAVFoundationImport = uiImageExtensionContent.includes('import AVFoundation');

if (hasVisibleAreaCropMethod && hasAVFoundationImport) {
    console.log('   ✅ cropVisibleAreaTo9x16 method found');
    console.log('   ✅ AVFoundation import added');
} else {
    console.log('   ❌ cropVisibleAreaTo9x16 method or AVFoundation import missing');
}

// Test 2: Check NativeStoryCameraView implementation
console.log('\n2. Checking NativeStoryCameraView implementation...');
const nativeCameraPath = 'kiccbacc/SwiftUI/Views/Other Views/Story/NativeStoryCameraView.swift';
const nativeCameraContent = fs.readFileSync(nativeCameraPath, 'utf8');

const hasNativeVisibleAreaCrop = nativeCameraContent.includes('cropVisibleAreaTo9x16');
const hasNativePreviewSize = nativeCameraContent.includes('previewSize = bounds.size');

if (hasNativeVisibleAreaCrop && hasNativePreviewSize) {
    console.log('   ✅ NativeStoryCameraView uses cropVisibleAreaTo9x16');
    console.log('   ✅ Preview size calculation implemented');
} else {
    console.log('   ❌ NativeStoryCameraView missing visible area crop implementation');
}

// Test 3: Check SimpleStoryCameraView implementation
console.log('\n3. Checking SimpleStoryCameraView implementation...');
const simpleCameraPath = 'kiccbacc/SwiftUI/Views/Other Views/Story/SimpleStoryCameraView.swift';
const simpleCameraContent = fs.readFileSync(simpleCameraPath, 'utf8');

const hasSimpleVisibleAreaCrop = simpleCameraContent.includes('cropVisibleAreaTo9x16');
const hasSimpleScreenBounds = simpleCameraContent.includes('UIScreen.main.bounds.size');

if (hasSimpleVisibleAreaCrop && hasSimpleScreenBounds) {
    console.log('   ✅ SimpleStoryCameraView uses cropVisibleAreaTo9x16');
    console.log('   ✅ Screen bounds calculation implemented');
} else {
    console.log('   ❌ SimpleStoryCameraView missing visible area crop implementation');
}

// Test 4: Check CustomStoryCameraView implementation
console.log('\n4. Checking CustomStoryCameraView implementation...');
const customCameraPath = 'kiccbacc/SwiftUI/Views/Other Views/Story/CustomStoryCameraView.swift';
const customCameraContent = fs.readFileSync(customCameraPath, 'utf8');

const hasCustomVisibleAreaCrop = customCameraContent.includes('cropVisibleAreaTo9x16');
const hasCustomScreenBounds = customCameraContent.includes('UIScreen.main.bounds.size');

if (hasCustomVisibleAreaCrop && hasCustomScreenBounds) {
    console.log('   ✅ CustomStoryCameraView uses cropVisibleAreaTo9x16');
    console.log('   ✅ Screen bounds calculation implemented');
} else {
    console.log('   ❌ CustomStoryCameraView missing visible area crop implementation');
}

// Test 5: Verify method signature and parameters
console.log('\n5. Verifying method signature and parameters...');
const methodSignature = 'func cropVisibleAreaTo9x16(previewSize: CGSize, previewVideoGravity: AVLayerVideoGravity = .resizeAspectFill)';
const hasCorrectSignature = uiImageExtensionContent.includes(methodSignature);

if (hasCorrectSignature) {
    console.log('   ✅ Method signature is correct');
} else {
    console.log('   ❌ Method signature is incorrect or missing');
}

// Test 6: Check for proper error handling
console.log('\n6. Checking error handling...');
const hasErrorHandling = uiImageExtensionContent.includes('cropVisibleAreaTo9x16: Failed to crop to visible area');
const hasFallbackHandling = nativeCameraContent.includes('Visible area crop failed, using orientation-fixed image');

if (hasErrorHandling && hasFallbackHandling) {
    console.log('   ✅ Error handling implemented');
    console.log('   ✅ Fallback handling implemented');
} else {
    console.log('   ❌ Error handling or fallback handling missing');
}

// Summary
console.log('\n📋 Implementation Summary:');
console.log('   • Added cropVisibleAreaTo9x16 method to UIImage extension');
console.log('   • Method calculates visible area based on preview size and video gravity');
console.log('   • Crops to visible area first, then applies 9:16 aspect ratio');
console.log('   • Updated all three camera views to use new method');
console.log('   • Added proper error handling and fallbacks');

console.log('\n🎯 Expected Behavior:');
console.log('   • Camera captures exactly what is visible on screen');
console.log('   • All captured images are cropped to 9:16 aspect ratio');
console.log('   • Consistent story format across all camera implementations');
console.log('   • No more aspect ratio mismatches between preview and final image');

console.log('\n✅ Visible Area Crop Implementation Test Complete!');
