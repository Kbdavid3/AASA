# Success Screen Auto-Dismiss Debugging

## Current Issue
After upload completes:
- ✅ No black screen
- ✅ Confetti shows
- ✅ Success message appears
- ❌ **Screen shows for only a FRACTION OF A SECOND then auto-dismisses**

## Changes Applied for Diagnosis

### 1. Removed Premature viewItem Clearing
**Files:** `EventDetailView.swift` (Lines 443-449, 552-558)

**Before:** ❌
```swift
.onDisappear {
    isStoryUploadPresenting = false
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        self.viewItem = nil  // Could cause premature dismissal
    }
}
```

**After:** ✅
```swift
.onDisappear {
    isStoryUploadPresenting = false
    // DON'T clear viewItem here - let fullScreenCover handle it
    // Clearing it can cause premature dismissal
}
```

**Reason:** The delayed `viewItem = nil` could fire while the success screen is showing, causing immediate dismissal.

### 2. Added Extensive Logging
**Files:** `NativeStoryCameraView.swift`, `FullScreenPhotoPreview.swift`

**New Logs:**
```
📸 NativeStoryCameraView: Setting progress to 100%
📸 NativeStoryCameraView: Upload successful - setting uploadCompleted = true
📸 StateManager uploadCompleted: false -> true
📸 StateManager isDismissing: false
📸 Success screen should now be visible
📸 Waiting for user to click 'Back to Event' button

📸 FullScreenPhotoPreview: Upload complete - showing success screen
📸 Setting uploadCompleted = true, isUploading = false, showConfetti = true
📸 Success screen should now be visible with confetti

📸 NativeStoryCameraView: onDismiss from preview
📸 uploadCompleted: true, isDismissing: false
(If dismissing) Upload complete - user clicked 'Back to Event'
(Or) 📸 Already dismissing, ignoring onDismiss call
```

**Purpose:** Track exactly when success screen appears and when/why it dismisses.

### 3. Added Small Delay Before Success Screen
**File:** `NativeStoryCameraView.swift` (Line 837-838)
```swift
// Small delay before showing success to ensure UI is stable
try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
```

**Purpose:** Give UI time to stabilize before showing success screen.

## Testing Instructions

1. **Upload a story**
2. **Watch console logs carefully** - Look for:
   - "Success screen should now be visible" messages
   - How long after this before any dismiss messages
   - Whether "onDismiss from preview" appears automatically or only after clicking button
   - Whether "Already dismissing, ignoring" appears (indicates double-dismiss attempt)

3. **Share the console output** - Specifically:
   ```
   Time between "Success screen should now be visible" 
   and 
   "onDismiss from preview"
   ```

## Diagnostic Questions

### If Screen Still Auto-Dismisses:

**Q1: Is onDismiss being called automatically?**
- Check for "onDismiss from preview" in logs
- Should ONLY appear when you click "Back to Event"
- If it appears immediately after "Success screen should now be visible", something is calling it automatically

**Q2: Are there multiple onDismiss calls?**
- Check for "Already dismissing, ignoring" messages
- This would indicate something is calling onDismiss multiple times

**Q3: What are the state values?**
- When "onDismiss from preview" appears, check:
  - `uploadCompleted` value
  - `isDismissing` value
- Both should match expected states

**Q4: Are there any error messages?**
- Any Firebase errors?
- Any SwiftUI warnings?
- Any unexpected state changes?

## Potential Root Causes Still Being Investigated

### Hypothesis 1: ViewItem Presentation Issue
The `ViewItem.id` generates a NEW UUID every time:
```swift
var id: String {
    UUID().uuidString  // NEW UUID EVERY ACCESS!
}
```
This could cause SwiftUI to think the item changed and re-present/dismiss.

**Test:** Check if the camera view's onDisappear fires unexpectedly during success screen display.

### Hypothesis 2: State Change Cascade
When `stateManager.uploadCompleted = true`, something in the view hierarchy might be reacting to this Published property change.

**Test:** Check if any SwiftUI views are observing stateManager and triggering updates.

### Hypothesis 3: FullScreenCover Binding Issue
The `fullScreenCover(item: $viewItem)` might be reacting to state changes in unexpected ways.

**Test:** Try using a boolean `showCamera` instead of ViewItem to present.

### Hypothesis 4: Callback Timing
Even though we moved `onStoryUploaded()` to after dismissal, something in that callback chain might be affecting the view.

**Test:** Comment out `onStoryUploaded()` call entirely and see if success screen stays.

## Next Steps Based on Logs

### If onDismiss is NOT being called:
- Issue is with view presentation/dismissal mechanism
- Check ViewItem.id issue
- Check fullScreenCover behavior

### If onDismiss IS being called automatically:
- Something is triggering the "Back to Event" button action
- Or something is programmatically calling onDismiss
- Check FullScreenPhotoPreview for automatic dismiss logic

### If "Already dismissing" appears:
- Double-dismiss attempt is being blocked
- Need to find what's calling dismiss first time

## Files Changed

### 1. EventDetailView.swift
- Lines 443-449: Removed viewItem = nil clearing (first button)
- Lines 552-558: Removed viewItem = nil clearing (second button)

### 2. NativeStoryCameraView.swift
- Lines 837-857: Added logging and small delay before success
- Lines 690-720: Enhanced onDismiss logging (already had guard)

### 3. FullScreenPhotoPreview.swift
- Lines 290-300: Added progress logging and success state logging

---

**Status:** 🔍 Debugging - Awaiting Test Results  
**Date:** October 10, 2025  
**Priority:** Critical - Need console logs to diagnose

