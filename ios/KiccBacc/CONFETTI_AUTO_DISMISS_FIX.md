# Confetti Auto-Dismiss Fix

## Issue
After previous fixes:
- ✅ No black screen
- ✅ Confetti shows
- ✅ Success message displays
- ❌ BUT: Preview screen auto-dismisses before user can click "Back to Event"

## Root Cause Investigation

The preview screen with the "Back to Event" button was dismissing automatically without user interaction. Two potential causes identified:

### Cause 1: Confetti Auto-Hide State Change
The confetti animation was setting `isShowing = false` after 3.5 seconds:
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
    isShowing = false  // ❌ This state change might trigger something
}
```

**Problem:** This state change could potentially trigger view updates that interfere with the preview display, though the exact mechanism isn't clear without logs.

### Cause 2: Double onDismiss() Calls
No guard existed to prevent multiple calls to `onDismiss()` if something was triggering it multiple times.

## Solutions Applied

### Fix 1: Disable Confetti Auto-Hide
**File:** `SharedConfettiView.swift`
```swift
.onAppear {
    createParticles()
    startAnimation()
    // ✅ Don't auto-hide confetti - let it stay until view dismisses
    // This prevents state changes that might trigger unwanted behaviors
}
```

**Benefits:**
- No state changes during the success screen display
- Confetti stays visible until user dismisses
- More celebratory UX - confetti keeps going!

### Fix 2: Add Double-Dismissal Guard
**File:** `NativeStoryCameraView.swift`
```swift
onDismiss: {
    print("📸 NativeStoryCameraView: onDismiss from preview")
    print("📸 uploadCompleted: \(uploadCompleted), isDismissing: \(isDismissing)")
    
    // ✅ Guard against double-dismissal
    guard !self.stateManager.isDismissing else {
        print("📸 Already dismissing, ignoring onDismiss call")
        return
    }
    
    if uploadCompleted {
        // ... dismissal logic
    }
}
```

**Benefits:**
- Prevents multiple dismiss attempts
- Adds detailed logging to diagnose issues
- Safer dismissal flow

## Expected Behavior After Fix

```
1. Upload completes (100%)
   ↓
2. Success message appears
   ↓
3. Confetti starts and KEEPS GOING 🎉
   ↓
4. "Back to Event" button shows
   ↓
5. View waits indefinitely for user action
   ↓
6. User clicks "Back to Event" (when ready)
   ↓
7. onDismiss() called (first time only - guard prevents double-call)
   ↓
8. View dismisses smoothly
   ↓
9. Clean return to EventDetailView
```

## Additional Debugging

Added logging to help diagnose any remaining issues:
- Logs when `onDismiss()` is called
- Logs current state (`uploadCompleted`, `isDismissing`)  
- Logs if duplicate dismiss attempt is blocked

## Files Changed

### 1. `SharedConfettiView.swift` (Lines 28-36)
- Commented out auto-hide timer
- Confetti now stays visible until view dismisses

### 2. `NativeStoryCameraView.swift` (Lines 690-720)
- Added guard to prevent double-dismissal
- Added detailed logging
- Print statements show state at time of dismissal

## Testing Instructions

1. Upload a story
2. Watch confetti animation start
3. Verify success message shows with "Back to Event" button
4. **Wait 10+ seconds** - view should NOT auto-dismiss
5. Confetti should continue playing
6. Click "Back to Event" button
7. View should dismiss smoothly
8. Check console for logs - should see only ONE "onDismiss from preview" message

## If Issue Persists

If the view still auto-dismisses, check console logs for:
1. Are there multiple "onDismiss from preview" messages?
2. Is the guard catching duplicate calls?
3. What are the values of `uploadCompleted` and `isDismissing`?
4. Are there any error messages or unexpected state changes?

Share the console logs to help diagnose the exact cause.

## Why These Changes Should Work

1. **Removing confetti auto-hide**: Eliminates a state change that occurs ~3.5 seconds after upload completes
2. **Double-dismiss guard**: Prevents race conditions if something is calling onDismiss multiple times
3. **Enhanced logging**: Helps identify exactly what's triggering dismissal if issue persists

---

**Status:** ✅ Applied - Awaiting Testing  
**Date:** October 10, 2025  
**Priority:** High - Blocking proper story upload UX

