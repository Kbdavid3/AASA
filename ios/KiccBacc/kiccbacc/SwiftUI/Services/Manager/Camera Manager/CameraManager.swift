//
//  CameraManager.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 05/03/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import AVFoundation
import SwiftUI
import CoreImage
import CoreMotion


class CameraManager: ObservableObject {
    
    @Published var error: CameraError?
    
    var session = AVCaptureSession()
    
    private let sessionQueue = DispatchQueue(label: "kiccbacc.Session1", qos: .userInteractive)
    
    private let videoOutput = AVCaptureVideoDataOutput()
    
    private var status = Status.unconfigured
    private var isConfigured = false
    private var currentPosition: CameraPosition = .back
    private var isStartingSession = false
    private var sessionStartTimeout: Timer?
    private var currentDevice: AVCaptureDevice?
    private var frameCheckTimer: Timer?
    private var lastFrameTimestamp = Date()
    private var recoveryAttempts = 0
    private let maxRecoveryAttempts = 3

    enum Status {
        case unconfigured
        case configured
        case unauthorized
        case failed
    }
    
    static let shared = CameraManager()
    
    private init() {
        // Don't automatically configure - let the view model control this
    }
    
    // Add public configure method
    func configure() {
        configure(with: currentPosition)
    }
    
    func switchCamera(to position: CameraPosition) {
        print("🔄 CameraManager: Switching camera to \(position == .front ? "front" : "back")")
        
        // Prevent concurrent switches
        guard !isStartingSession else {
            print("⚠️ CameraManager: Session already starting, skipping switch")
            return
        }
        
        // Don't switch if already on the requested position
        guard position != currentPosition else {
            print("🔄 CameraManager: Already on requested position, skipping switch")
            return
        }
        
        currentPosition = position
        isStartingSession = true
        
        sessionQueue.async {
            // Stop current session if running
            if self.session.isRunning {
                self.session.stopRunning()
                print("🛑 CameraManager: Stopped existing session")
            }
            
            // Cancel any pending timeout
            self.sessionStartTimeout?.invalidate()
            self.sessionStartTimeout = nil
            
            self.status = .unconfigured
            self.isConfigured = false
            
            // Use synchronous sleep during critical session operations
            Thread.sleep(forTimeInterval: 0.1)
            
            // Configure and start session directly
            self.configure(with: position)
        }
    }
    
    func configure(with position: CameraPosition) {
        print("🔧 CameraManager: Starting configuration for \(position == .front ? "front" : "back") camera")
        
        session = AVCaptureSession()
        
        // Set session preset based on iOS version for better performance
        if #available(iOS 16.0, *) {
            // Use medium quality preset for faster initialization on iOS 16+
            session.sessionPreset = .medium
        } else {
            // Use photo preset for older iOS versions
            session.sessionPreset = .photo
        }
        
        // Reset error state before configuration
        DispatchQueue.main.async {
            self.error = nil
        }
        
        checkPermissions()
        
        sessionQueue.async {
            self.configureCaptureSession(with: position)
            if self.status == .configured {
                // Add notification observers for runtime errors
                self.setupNotificationObservers()
                self.startSessionWithTimeout()
            } else {
                print("❌ CameraManager: Session configuration failed")
                self.isStartingSession = false
            }
        }
    }
    
    // Setup notification observers for camera session events
    private func setupNotificationObservers() {
        // Remove any existing observers
        NotificationCenter.default.removeObserver(self)
        
        // Register for runtime errors
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionRuntimeError),
            name: .AVCaptureSessionRuntimeError,
            object: session
        )
        
        // Register for session interruptions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionWasInterrupted),
            name: .AVCaptureSessionWasInterrupted,
            object: session
        )
        
        // Register for interruption ended
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionInterruptionEnded),
            name: .AVCaptureSessionInterruptionEnded,
            object: session
        )
    }
    
    // Handle session runtime errors
    @objc private func sessionRuntimeError(notification: Notification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        
        print("❌ CameraManager: Runtime error: \(error.localizedDescription)")
        
        // Set error and update status
        set(error: .sessionRuntimeError(error.localizedDescription))
        status = .failed
        
        // Try to recover
        sessionQueue.async {
            // Reset session
            self.session.stopRunning()
            self.isConfigured = false
            self.isStartingSession = false
            
            // Try to restart after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.restartCamera()
            }
        }
    }
    
    // Handle session interruptions
    @objc private func sessionWasInterrupted(notification: Notification) {
        // Get interruption type
        if #available(iOS 16.0, *) {
            if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
               let reasonIntegerValue = userInfoValue.integerValue,
               let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
                print("📸 CameraManager: Session interrupted with reason: \(reason)")
                
                switch reason {
                case .videoDeviceNotAvailableInBackground:
                    // App went to background, normal behavior
                    print("📸 CameraManager: Video device not available in background")
                    
                case .audioDeviceInUseByAnotherClient:
                    print("📸 CameraManager: Audio device in use by another client")
                    
                case .videoDeviceInUseByAnotherClient:
                    print("📸 CameraManager: Video device in use by another client")
                    set(error: .cameraUnavailable)
                    
                case .videoDeviceNotAvailableWithMultipleForegroundApps:
                    print("📸 CameraManager: Video device not available with multiple foreground apps")
                    set(error: .cameraUnavailable)
                    
                case .videoDeviceNotAvailableDueToSystemPressure:
                    print("📸 CameraManager: Video device not available due to system pressure")
                    
                @unknown default:
                    print("📸 CameraManager: Session interrupted with unknown reason")
                }
            }
        } else {
            // Simpler handling for older iOS versions
            print("📸 CameraManager: Session interrupted")
        }
    }
    
    // Handle end of interruption
    @objc private func sessionInterruptionEnded(notification: Notification) {
        print("📸 CameraManager: Session interruption ended")
        
        // Try to restart session if it was running before
        sessionQueue.async {
            if !self.session.isRunning && self.isConfigured {
                self.session.startRunning()
            }
        }
    }
    
    private func startSessionWithTimeout() {
        print("🚀 CameraManager: Starting session...")
        
        // Use optimized session start for iOS 16+
        if #available(iOS 16.0, *) {
            // Use beginConfiguration/commitConfiguration for atomic updates
            session.beginConfiguration()
            
            // Apply optimized settings for iOS 16+
            if let connection = self.videoOutput.connection(with: .video) {
                // Enable automatic configuration for better performance
                if #available(iOS 16.0, *) {
                    // For iOS 16+, try to get the device from the input port
                    if let videoDeviceInput = session.inputs.first as? AVCaptureDeviceInput {
                        let device = videoDeviceInput.device
                        // Use modern frame rate API for iOS 16+
                        if !device.activeFormat.videoSupportedFrameRateRanges.isEmpty {
                            device.activeVideoMinFrameDuration = CMTime.invalid
                            device.activeVideoMaxFrameDuration = CMTime.invalid
                        }
                    }
                } else {
                    // Fallback for older iOS versions - use alternative approach
                    // Set frame rate through session preset instead of deprecated APIs
                    if session.canSetSessionPreset(.high) {
                        session.sessionPreset = .high
                    }
                }
            }
            
            session.commitConfiguration()
            
            // Start session with reduced timeout for iOS 16+
            self.session.startRunning()
            
            // Check if session started successfully with shorter timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if self.session.isRunning {
                    print("✅ CameraManager: Session started successfully (iOS 16+)")
                    self.isStartingSession = false
                    self.startFrameCheckTimer()
                } else {
                    print("❌ CameraManager: Session failed to start, retrying...")
                    self.handleSessionStartFailure()
                }
            }
        } else {
            // Legacy session start for older iOS versions
            self.session.startRunning()
            
            // Check if session started successfully
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.session.isRunning {
                    print("✅ CameraManager: Session started successfully")
                    self.isStartingSession = false
                    self.startFrameCheckTimer()
                } else {
                    print("❌ CameraManager: Session failed to start, retrying...")
                    self.handleSessionStartFailure()
                }
            }
        }
    }
    
    // Start a timer to check if frames are being received
    private func startFrameCheckTimer() {
        // Cancel any existing timer
        frameCheckTimer?.invalidate()
        frameCheckTimer = nil
        
        // Reset frame count
        lastFrameTimestamp = Date()
        
        // Create a new timer to check for frames
        frameCheckTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // If no frames received for 3 seconds and session is running
            let timeSinceLastFrame = Date().timeIntervalSince(self.lastFrameTimestamp)
            if timeSinceLastFrame > 3.0 && self.session.isRunning && self.isConfigured {
                print("⚠️ CameraManager: No frames received for \(timeSinceLastFrame) seconds")
                
                // Set error and try to recover
                DispatchQueue.main.async {
                    self.error = .noFramesReceived
                }
                
                if self.recoveryAttempts < self.maxRecoveryAttempts {
                    self.recoveryAttempts += 1
                    self.restartCamera()
                }
            }
        }
    }
    
    private func handleSessionStartFailure() {
        print("🔄 CameraManager: Attempting to restart session...")
        isStartingSession = false
        
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
            
            // Retry configuration
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.configure(with: self.currentPosition)
            }
        }
    }
    
    private func set(error: CameraError?) {
        DispatchQueue.main.async {
            self.error = error
        }
    }
    
    func set(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue) {
        sessionQueue.async {
            print("🔧 CameraManager: Setting delegate, session running: \(self.session.isRunning)")
            
            // Use optimized delegate setting for iOS 16+
            if #available(iOS 16.0, *) {
                // For iOS 16+, set delegate immediately with shorter timeout
                if self.session.isRunning {
                    self.videoOutput.setSampleBufferDelegate(delegate, queue: queue)
                    print("✅ CameraManager: Delegate set successfully (iOS 16+)")
                } else {
                    // Wait briefly for session to start
                    var attempts = 0
                    let maxAttempts = 30 // 3 seconds timeout (reduced from 10)
                    
                    while !self.session.isRunning && attempts < maxAttempts {
                        Thread.sleep(forTimeInterval: 0.1)
                        attempts += 1
                        if attempts % 10 == 0 {
                            print("⏳ CameraManager: Still waiting for session to start... (attempt \(attempts))")
                        }
                    }
                    
                    if self.session.isRunning {
                        self.videoOutput.setSampleBufferDelegate(delegate, queue: queue)
                        print("✅ CameraManager: Delegate set successfully after waiting")
                    } else {
                        print("⏰ CameraManager: Session failed to start within timeout")
                        // Retry after a shorter delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.set(delegate, queue: queue)
                        }
                    }
                }
            } else {
                // Legacy delegate setting for older iOS versions
                // Wait for session to be running with timeout
                var attempts = 0
                let maxAttempts = 100 // 10 seconds timeout
                
                while !self.session.isRunning && attempts < maxAttempts {
                    Thread.sleep(forTimeInterval: 0.1)
                    attempts += 1
                    if attempts % 50 == 0 {
                        print("⏳ CameraManager: Still waiting for session to start... (attempt \(attempts))")
                    }
                }
                
                if self.session.isRunning {
                    self.videoOutput.setSampleBufferDelegate(delegate, queue: queue)
                    print("✅ CameraManager: Delegate set successfully")
                } else {
                    print("⏰ CameraManager: Session failed to start within timeout")
                    // Retry after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.set(delegate, queue: queue)
                    }
                }
            }
        }
    }

    func toggleFlash(on: Bool) {
        sessionQueue.async {
            guard let device = AVCaptureDevice.default(for: .video) else { return }
            
            if device.hasTorch {
                do {
                    try device.lockForConfiguration()
                    
                    if on == true {
                        device.torchMode = .on
                    } else {
                        device.torchMode = .off
                    }
                    
                    device.unlockForConfiguration()
                } catch {
                    print("Torch could not be used: \(error)")
                }
            } else {
                print("Torch is not available")
            }
        }
    }
    
    // Update frame timestamp when a new frame is received
    func updateFrameTimestamp() {
        lastFrameTimestamp = Date()
        recoveryAttempts = 0 // Reset recovery attempts when frames are flowing
    }
    
    private func checkPermissions() {
        print("🔐 CameraManager: Checking permissions...")
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .notDetermined:
            print("🔐 CameraManager: Permission not determined, requesting...")
            sessionQueue.suspend()
            
            AVCaptureDevice.requestAccess(for: .video) { authorized in
                print("🔐 CameraManager: Permission request result: \(authorized)")
                if !authorized {
                    self.status = .unauthorized
                    self.set(error: .deniedAuthorization)
                }
                
                self.sessionQueue.resume()
            }
            
            case .restricted:
            print("🔐 CameraManager: Permission restricted")
            status = .unauthorized
            set(error: .restrictedAuthorization)
            
            case .denied:
            print("🔐 CameraManager: Permission denied")
            status = .unauthorized
            set(error: .deniedAuthorization)
            
            case .authorized:
            print("🔐 CameraManager: Permission authorized")
            break
            
            @unknown default:
            print("🔐 CameraManager: Unknown permission status")
            status = .unauthorized
            set(error: .unknownAuthorization)
        }
    }
    
    private func configureCaptureSession(with position: CameraPosition) {
        guard status == .unconfigured else {
            print("⚠️ CameraManager: Session already configured, skipping")
            return
        }
        
        print("🔧 CameraManager: Configuring capture session...")
        
        // Check camera availability before configuring
        guard isCameraAvailable(for: position) else {
            print("❌ CameraManager: Camera not available for position: \(position)")
            set(error: .cameraUnavailable)
            status = .failed
            isStartingSession = false
            return
        }
        
        // Ensure session is stopped before reconfiguring
        if self.session.isRunning {
            self.session.stopRunning()
        }
        
        session.beginConfiguration()
        
        defer {
          session.commitConfiguration()
        }
        
        // Remove existing inputs and outputs
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        
        // Get camera device with optimized discovery for iOS 16+
        var camera: AVCaptureDevice?
        
        if #available(iOS 16.0, *) {
            // Use modern device discovery API for iOS 16+
            let deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera]
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: deviceTypes,
                mediaType: .video,
                position: position
            )
            
            // Get first available device of requested position
            camera = discoverySession.devices.first
        } else {
            // Legacy device discovery for older iOS versions
            camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
        }
        
        guard let camera = camera else {
            print("❌ CameraManager: Camera device not available for position: \(position)")
            set(error: .cameraUnavailable)
            status = .failed
            return
        }
        
        // Store current device for zoom and focus operations
        self.currentDevice = camera
        
        print("📷 CameraManager: Found camera device: \(camera.localizedName)")
        
        do {
            // Configure camera device for better performance
            try camera.lockForConfiguration()
            
            // Set camera configuration based on iOS version
            if #available(iOS 16.0, *) {
                // iOS 16+ optimizations
                if camera.isLowLightBoostSupported {
                    camera.automaticallyEnablesLowLightBoostWhenAvailable = true
                }
                
                // Set focus mode for faster initialization
                if camera.isFocusModeSupported(.continuousAutoFocus) {
                    camera.focusMode = .continuousAutoFocus
                }
                
                // Set exposure mode for faster initialization
                if camera.isExposureModeSupported(.continuousAutoExposure) {
                    camera.exposureMode = .continuousAutoExposure
                }
            } else {
                // Legacy camera configuration
                if camera.isFocusModeSupported(.continuousAutoFocus) {
                    camera.focusMode = .continuousAutoFocus
                }
            }
            
            camera.unlockForConfiguration()
            
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            print("📷 CameraManager: Created camera input successfully")

            if session.canAddInput(cameraInput) {
                session.addInput(cameraInput)
                print("📷 CameraManager: Added camera input to session")
            } else {
                print("❌ CameraManager: Cannot add camera input to session")
                set(error: .cannotAddInput)
                status = .failed
                return
            }
        } catch {
            print("❌ CameraManager: Failed to create camera input: \(error)")
            set(error: .createCaptureInput(error))
            status = .failed
            return
        }

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            print("📷 CameraManager: Added video output to session")
            
            // Optimize video settings based on iOS version
            if #available(iOS 16.0, *) {
                // Use more efficient pixel format for iOS 16+
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
                
                // Optimize for real-time processing
                videoOutput.alwaysDiscardsLateVideoFrames = true
            } else {
                // Legacy video settings
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            }
            
            // Set video orientation and mirroring
            let videoConnection = videoOutput.connection(with: .video)
            videoConnection?.videoOrientation = .portrait
            videoConnection?.isVideoMirrored = (position == .front) // Fixed mirroring logic
            
            // Enable video stabilization if available
            if videoConnection?.isVideoStabilizationSupported == true {
                videoConnection?.preferredVideoStabilizationMode = .auto
                print("📷 CameraManager: Enabled video stabilization")
            }
        } else {
            print("❌ CameraManager: Cannot add video output to session")
            set(error: .cannotAddOutput)
            status = .failed
            return
        }

        status = .configured
        isConfigured = true
        print("✅ CameraManager: Session configured successfully")
    }
    
    // Add method to properly stop camera session
    func stopSession() {
        sessionQueue.async {
            // Cancel any pending timeout
            self.sessionStartTimeout?.invalidate()
            self.sessionStartTimeout = nil
            
            if self.session.isRunning {
                self.session.stopRunning()
                print("🛑 CameraManager: Session stopped")
            }
            
            // Reset state to allow re-initialization
            self.isStartingSession = false
            self.status = .unconfigured
            self.isConfigured = false
            self.currentDevice = nil
            
            // Clear error state
            DispatchQueue.main.async {
                self.error = nil
            }
            
            // Optimize for faster restart on iOS 16+
            if #available(iOS 16.0, *) {
                // Keep session object but reset connections
                self.session.beginConfiguration()
                for input in self.session.inputs {
                    self.session.removeInput(input)
                }
                for output in self.session.outputs {
                    self.session.removeOutput(output)
                }
                self.session.commitConfiguration()
            }
            
            print("🔄 CameraManager: State reset for re-initialization")
        }
    }
    
    // Add method to check if camera is available
    func isCameraAvailable() -> Bool {
        return status == .configured && isConfigured
    }
    
    // Modern camera permission request using async/await
    @available(iOS 13.0, *)
    func requestCameraPermission() async -> AVAuthorizationStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        // Return immediately if already determined
        if status != .notDetermined {
            return status
        }
        
        // Request access
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                let newStatus = granted ? AVAuthorizationStatus.authorized : AVAuthorizationStatus.denied
                continuation.resume(returning: newStatus)
            }
        }
    }
    
    // Add method to get current camera position
    func getCurrentPosition() -> CameraPosition {
        return currentPosition
    }
    
    // Add zoom functionality
    func setZoom(_ zoom: CGFloat) {
        sessionQueue.async {
            guard let device = self.currentDevice else { return }
            
            do {
                try device.lockForConfiguration()
                
                let maxZoom = device.activeFormat.videoMaxZoomFactor
                let clampedZoom = min(max(zoom, 1.0), maxZoom)
                
                device.videoZoomFactor = clampedZoom
                device.unlockForConfiguration()
                
                print("📷 CameraManager: Zoom set to \(clampedZoom)x")
            } catch {
                print("❌ CameraManager: Failed to set zoom: \(error)")
            }
        }
    }
    
    // Add focus functionality
    func focus(at point: CGPoint) {
        sessionQueue.async {
            guard let device = self.currentDevice else { return }
            
            do {
                try device.lockForConfiguration()
                
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                }
                
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = point
                    device.exposureMode = .autoExpose
                }
                
                device.unlockForConfiguration()
                
                print("📷 CameraManager: Focus set to point \(point)")
            } catch {
                print("❌ CameraManager: Failed to set focus: \(error)")
            }
        }
    }
    
    // Prepare for fast initialization
    func prepareForInitialization() {
        print("🔄 CameraManager: Preparing for fast initialization")
        sessionQueue.async {
            // Cancel any pending timeout
            self.sessionStartTimeout?.invalidate()
            self.sessionStartTimeout = nil
            
            if self.session.isRunning {
                self.session.stopRunning()
            }
            
            self.status = .unconfigured
            self.isConfigured = false
            self.isStartingSession = false
            
            // Pre-warm AVCaptureSession for faster startup
            if #available(iOS 16.0, *) {
                // Reset session for clean start
                self.session = AVCaptureSession()
                // Set optimal preset for faster startup
                self.session.sessionPreset = .medium
            }
        }
    }
    
    // Add method to force restart camera
    func restartCamera() {
        print("🔄 CameraManager: Force restarting camera")
        sessionQueue.async {
            // Cancel any pending timeout
            self.sessionStartTimeout?.invalidate()
            self.sessionStartTimeout = nil
            
            if self.session.isRunning {
                self.session.stopRunning()
            }
            
            self.status = .unconfigured
            self.isConfigured = false
            self.isStartingSession = false
            
            // Faster reconfiguration for iOS 16+
            let reconfigDelay: TimeInterval
            if #available(iOS 16.0, *) {
                reconfigDelay = 0.3
            } else {
                reconfigDelay = 1.0
            }
            
            // Wait before reconfiguring
            DispatchQueue.main.asyncAfter(deadline: .now() + reconfigDelay) {
                self.configure(with: self.currentPosition)
            }
        }
    }
    
    // Add method to check camera status
    func getCameraStatus() -> String {
        return "Status: \(status), Configured: \(isConfigured), Running: \(session.isRunning)"
    }
    
    // Add device availability check method with modern API support
    private func isCameraAvailable(for position: CameraPosition) -> Bool {
        if #available(iOS 16.0, *) {
            // Use modern discovery API for iOS 16+
            let deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera, .builtInUltraWideCamera]
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: deviceTypes,
                mediaType: .video,
                position: position == .front ? .front : .back
            )
            return !discoverySession.devices.isEmpty
        } else {
            // Fallback for older iOS versions
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position == .front ? .front : .back) != nil
        }
    }
    
    // Add method to enable video stabilization if available
    func enableVideoStabilization() {
        sessionQueue.async {
            guard let connection = self.videoOutput.connection(with: .video) else { return }
            
            if #available(iOS 16.0, *) {
                // Use enhanced stabilization for iOS 16+
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .cinematicExtended
                    print("📹 CameraManager: Enhanced video stabilization enabled")
                }
            } else {
                // Use standard stabilization for older iOS
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .standard
                    print("📹 CameraManager: Standard video stabilization enabled")
                }
            }
        }
    }
    
    // Add method to optimize camera for current conditions
    func optimizeCameraForCurrentConditions() {
        sessionQueue.async {
            guard let device = self.currentDevice else { return }
            
            do {
                try device.lockForConfiguration()
                
                // Enable auto-focus
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                
                // Enable auto-exposure
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                
                // Enable low light boost if available
                if #available(iOS 16.0, *) {
                    if device.isLowLightBoostSupported {
                        device.automaticallyEnablesLowLightBoostWhenAvailable = true
                        print("💡 CameraManager: Low light boost enabled")
                    }
                }
                
                device.unlockForConfiguration()
            } catch {
                print("❌ CameraManager: Failed to optimize camera: \(error)")
            }
        }
    }
    
    deinit {
        sessionStartTimeout?.invalidate()
        frameCheckTimer?.invalidate()
        
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
    }
}
