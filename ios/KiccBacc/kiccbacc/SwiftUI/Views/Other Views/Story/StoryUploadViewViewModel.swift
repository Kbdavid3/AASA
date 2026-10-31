//
//  StoryUploadViewViewModel.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import AVFoundation
import SwiftUI
import Combine

class StoryUploadViewViewModel: ObservableObject {

    @Published var frame: CGImage?
    @Published var error: Error?
    @Published var pickedImage: UIImage?
    @Published var cameraOrientation: AVCaptureDevice.Position = .back
    @Published var isFlashOn: Bool = false
    @Published var showFrontFlash: Bool = false
    @Published var isCapturing: Bool = false
    @Published var hasCapturedImage: Bool = false
    @Published var isCameraReady: Bool = false
    @Published var debugMessage: String = ""
    
    private var cameraManager = CameraManager.shared
    private var frameManager = FrameManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var processingQueue = DispatchQueue(label: "image.processing", qos: .userInteractive)
    private var cameraStartupAttempts = 0
    private let maxStartupAttempts = 3
    private var isInitialized = false
    
    init() {
        // Only setup subscriptions in init - don't start camera yet
        setupSubscriptions()
    }
    
    func setupSubscriptions() {
        frame = nil
        
        cameraManager.$error
          .receive(on: RunLoop.main)
          .sink { [weak self] error in
              self?.error = error
              if let error = error {
                  self?.debugMessage = "Camera Error: \(error.localizedDescription)"
                  self?.handleCameraError()
              }
          }
          .store(in: &cancellables)
        
        frameManager.$current
          .receive(on: RunLoop.main)
          .compactMap { [weak self] buffer -> CGImage? in
              guard let buffer = buffer else { return nil }
              
              // Use high quality preview method for better image quality
              if #available(iOS 16.0, *) {
                  return CGImage.createHighQualityPreview(from: buffer)
              } else {
                  return CGImage.createPreview(from: buffer)
              }
          }
          .sink { [weak self] image in
              self?.frame = image
              if image != nil && !(self?.isCameraReady ?? false) {
                  self?.isCameraReady = true
                  self?.debugMessage = "Camera is ready and providing frames"
                  print("✅ Camera is now ready and providing frames")
              }
          }
          .store(in: &cancellables)
    }
    
    func startCamera() {
        print("🚀 Starting camera initialization...")
        debugMessage = "Starting camera initialization..."
        
        // Reset state to allow re-initialization
        isInitialized = false
        cameraStartupAttempts = 0
        frame = nil
        isCameraReady = false
        error = nil
        
        // Check camera permissions
        Task {
            let authorizationStatus = await cameraManager.requestCameraPermission()
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                switch authorizationStatus {
                case .authorized:
                    self.debugMessage = "Camera permission authorized, initializing..."
                    // Start camera immediately
                    self.initializeCamera()
                case .notDetermined:
                    self.debugMessage = "Camera permission status still not determined"
                    self.error = CameraError.setupFailed
                case .denied, .restricted:
                    self.debugMessage = "Camera permission denied or restricted"
                    self.error = CameraError.deniedAuthorization
                @unknown default:
                    self.debugMessage = "Unknown camera permission status"
                    self.error = CameraError.unknownAuthorization
                }
            }
        }
    }
    
    private func initializeCamera() {
        cameraStartupAttempts += 1
        print("🔄 Camera initialization attempt \(cameraStartupAttempts)/\(maxStartupAttempts)")
        debugMessage = "Camera initialization attempt \(cameraStartupAttempts)/\(maxStartupAttempts)"
        
        // Convert AVCaptureDevice.Position to CameraPosition
        let cameraPosition: CameraPosition = (cameraOrientation == .front) ? .front : .back
        
        // Reset camera state
        frameManager.stopFrameProcessing() // Stop processing before switching
        
        // Prepare camera manager for faster startup
        cameraManager.prepareForInitialization()
        
        // Use a more efficient approach for iOS 16+
        if #available(iOS 16.0, *) {
            // Faster initialization for modern iOS - use direct configuration
            cameraManager.configure(with: cameraPosition)
            
            // Set delegate immediately with no delay for iOS 16+
            self.debugMessage = "Setting camera delegate (iOS 16+)..."
            self.cameraManager.set(self.frameManager, queue: self.frameManager.videoOutputQueue)
            
            // Start frame processing immediately
            frameManager.startFrameProcessing()
            
            // Check if camera started successfully with shorter timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if self.frame == nil && self.error == nil {
                    self.debugMessage = "Camera timeout - no frames received"
                    print("⏰ Camera timeout - attempting restart")
                    self.handleCameraTimeout()
                }
            }
        } else {
            // Fallback for older iOS versions - use the switchCamera approach
            frameManager.switchCamera(to: cameraPosition)
            
            // Set delegate with reduced timing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.debugMessage = "Setting camera delegate..."
                self.cameraManager.set(self.frameManager, queue: self.frameManager.videoOutputQueue)
                
                // Check if camera started successfully after timeout
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if self.frame == nil && self.error == nil {
                        self.debugMessage = "Camera timeout - no frames received"
                        print("⏰ Camera timeout - attempting restart")
                        self.handleCameraTimeout()
                    }
                }
            }
        }
    }
    
    private func handleCameraTimeout() {
        if cameraStartupAttempts < maxStartupAttempts {
            debugMessage = "Retrying camera startup..."
            print("🔄 Retrying camera startup...")
            
            // Stop current session before retrying
            cameraManager.stopSession()
            frameManager.stopFrameProcessing()
            
            // Reset state
            frame = nil
            isCameraReady = false
            
            // Use shorter wait time for iOS 16+
            let retryDelay: TimeInterval
            if #available(iOS 16.0, *) {
                retryDelay = 0.5
            } else {
                retryDelay = 1.0
            }
            
            // Wait before retrying
            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                self.initializeCamera()
            }
        } else {
            debugMessage = "Camera failed to start after \(maxStartupAttempts) attempts"
            print("❌ Camera failed to start after \(maxStartupAttempts) attempts")
            error = CameraError.cameraUnavailable
        }
    }
    
    private func handleCameraError() {
        let errorDescription = error?.localizedDescription ?? "Unknown error"
        debugMessage = "Camera error: \(errorDescription)"
        print("❌ Camera error occurred: \(errorDescription)")
        
        if cameraStartupAttempts < maxStartupAttempts {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.cameraStartupAttempts = 0
                self.debugMessage = "Retrying after error..."
                self.isInitialized = false // Reset initialization flag
                self.startCamera()
            }
        } else {
            // Reset state after max attempts to allow manual retry
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.isInitialized = false
                self.cameraStartupAttempts = 0
                self.debugMessage = "Camera failed. Tap to retry."
            }
        }
    }
    
    func switchCamera(to position: AVCaptureDevice.Position) {
        cameraOrientation = position
        
        // Convert to CameraPosition
        let cameraPosition: CameraPosition = (position == .front) ? .front : .back
        
        frameManager.switchCamera(to: cameraPosition)
        
        // Set delegate after camera switch
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.cameraManager.set(self.frameManager, queue: self.frameManager.videoOutputQueue)
        }
    }
    
    func clickImage() {
        guard let frame = frame else {
            return
        }
        
        HapticGenerator.light.impactOccurred()
        
        // Process image on background queue for better performance
        processingQueue.async { [weak self] in
            let image = UIImage(cgImage: frame)
            let finalImage: UIImage
            
            // Only flip front camera images to correct mirroring
            if self?.cameraOrientation == .front {
                finalImage = image.withHorizontallyFlippedOrientation()
            } else {
                finalImage = image
            }
            
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self?.pickedImage = finalImage
                    // Set captured image state
                    self?.hasCapturedImage = true
                }
            }
        }
    }
    
    func captureTapped() {
        isCapturing = true
        
        switch cameraOrientation {
        case .back:
            if isFlashOn {
                cameraManager.toggleFlash(on: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [weak self ] in
                    guard let self = self else { return }
                    self.clickImage()
                    self.cameraManager.toggleFlash(on: false)
                    self.isCapturing = false
                })
            } else {
                clickImage()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.isCapturing = false
                }
            }
        case .front:
            if isFlashOn {
                showFrontFlash = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [weak self ] in
                    guard let self = self else { return }
                    self.clickImage()
                    self.showFrontFlash = false
                    self.isCapturing = false
                })
            } else {
                clickImage()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.isCapturing = false
                }
            }
        @unknown default:
            break
        }
    }
    
    func resetToCamera() {
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCapturedImage = false
            pickedImage = nil
        }
    }
    
    func forceRestartCamera() {
        print("🔄 Force restarting camera...")
        cleanup()
        
        // Start immediately for iOS 16+, short delay for older versions
        if #available(iOS 16.0, *) {
            self.startCamera()
        } else {
            // Wait a moment before restarting on older iOS
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.startCamera()
            }
        }
    }
    
    func cleanup() {
        print("🧹 StoryUploadViewViewModel: Cleaning up camera resources")
        
        // Cancel all subscriptions
        cancellables.removeAll()
        
        // Reset all state
        frame = nil
        pickedImage = nil
        hasCapturedImage = false
        isCameraReady = false
        debugMessage = ""
        error = nil
        
        // Reset initialization flags to allow re-initialization
        isInitialized = false
        cameraStartupAttempts = 0
        
        // Stop camera processing
        frameManager.stopFrameProcessing()
        cameraManager.stopSession()
        
        print("✅ StoryUploadViewViewModel: Cleanup completed")
    }
    
    deinit {
        cleanup()
    }
}
