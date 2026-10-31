//
//  FrameManager.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 05/03/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import AVFoundation
import CoreImage
import Accelerate
import os.log

class FrameManager: NSObject, ObservableObject {
  
    static let shared = FrameManager()

    @Published var current: CVPixelBuffer?
    @Published var isProcessing: Bool = false
    @Published var frameProcessingError: Error?

    let videoOutputQueue = DispatchQueue(
        label: "kiccbacc.VideoOutputQ",
        qos: .userInteractive,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
    
    // Logger for debugging
    private let logger = OSLog(subsystem: "com.kiccbacc", category: "FrameManager")
    
    // Enhanced frame rate control
    private var lastFrameTime: CFTimeInterval = 0
    private var targetFrameRate: CFTimeInterval = 1.0 / 60.0 // Default 60 FPS
    private var frameCount: Int = 0
    private var isFrameProcessingEnabled: Bool = true
    private var processingQueue = DispatchQueue(label: "kiccbacc.FrameProcessingQueue", qos: .userInteractive)
    
    // iOS version-specific optimizations
    private let isModernDevice: Bool = {
        if #available(iOS 16.0, *) {
            return true
        } else {
            return false
        }
    }()

    private override init() {
        super.init()
        // Don't automatically switch camera - let the view model control this
    }
    
    func switchCamera(to position: CameraPosition) {
        os_log("Switching camera to %{public}@", log: logger, type: .info, position == .front ? "front" : "back")
        
        // Disable frame processing during switch
        stopFrameProcessing()
        
        // Reset any errors
        frameProcessingError = nil
        
        // Use optimized timing for iOS 16+
        if isModernDevice {
            // Faster delegate setup for iOS 16+
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let cameraManager = CameraManager.shared
                cameraManager.set(self, queue: self.videoOutputQueue)
                
                // Start frame processing after delegate is set with shorter delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.startFrameProcessing()
                    os_log("Camera switched and delegate set (iOS 16+)", log: self.logger, type: .info)
                }
            }
        } else {
            // Legacy timing for older iOS versions
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                let cameraManager = CameraManager.shared
                cameraManager.set(self, queue: self.videoOutputQueue)
                
                // Start frame processing after delegate is set
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.startFrameProcessing()
                    os_log("Camera switched and delegate set", log: self.logger, type: .info)
                }
            }
        }
    }
    
    // Add method to stop frame processing
    func stopFrameProcessing() {
        isFrameProcessingEnabled = false
        DispatchQueue.main.async {
            self.current = nil
            self.isProcessing = false
            self.frameCount = 0
            self.lastFrameTime = 0
            self.frameProcessingError = nil
        }
        os_log("Frame processing stopped", log: logger, type: .info)
    }
    
    // Enhanced method to start frame processing
    func startFrameProcessing() {
        isFrameProcessingEnabled = true
        // Reset frame processing state
        frameCount = 0
        lastFrameTime = 0
        
        // Set optimal frame rate based on device capability
        if isModernDevice {
            // Higher frame rate for iOS 16+ devices
            targetFrameRate = 1.0 / 60.0 // Full 60 FPS
        } else {
            // Lower frame rate for older devices
            targetFrameRate = 1.0 / 30.0 // 30 FPS to reduce processing load
        }
        
        os_log("Frame processing started with target rate: %{public}f FPS", log: logger, type: .info, 1.0/targetFrameRate)
    }
    
    // Handle frame processing errors
    func handleFrameProcessingError(_ error: Error) {
        os_log("Frame processing error: %{public}@", log: logger, type: .error, error.localizedDescription)
        
        DispatchQueue.main.async {
            self.frameProcessingError = error
        }
        
        // Notify CameraManager of the error if it's serious
        DispatchQueue.main.async {
            if self.isProcessing {
                CameraManager.shared.error = .sessionRuntimeError(error.localizedDescription)
            }
        }
    }
}

extension FrameManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Skip if frame processing is disabled
        guard isFrameProcessingEnabled else { return }
        
        // Frame rate control - skip frames if we're processing too fast
        let currentTime = CACurrentMediaTime()
        if currentTime - lastFrameTime < targetFrameRate {
            return
        }
        
        lastFrameTime = currentTime
        
        // Reset any previous errors
        if frameProcessingError != nil {
            DispatchQueue.main.async {
                self.frameProcessingError = nil
            }
        }
        
        // Notify CameraManager that we received a frame
        CameraManager.shared.updateFrameTimestamp()
        
        // Use optimized processing for iOS 16+
        if isModernDevice {
            // Process frames on background queue for iOS 16+
            processingQueue.async {
                if let buffer = sampleBuffer.imageBuffer {
                    // Update on main queue after processing
                    DispatchQueue.main.async {
                        self.current = buffer
                    }
                } else {
                    os_log("Failed to get image buffer", log: self.logger, type: .error)
                }
            }
        } else {
            // Legacy processing for older iOS versions
            if let buffer = sampleBuffer.imageBuffer {
                // Update directly on main queue
                self.current = buffer
            } else {
                os_log("Failed to get image buffer", log: self.logger, type: .error)
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Handle dropped frames silently to avoid delays
        // Don't update any state here to keep it fast
        if frameCount % 100 == 0 {
            // Only log occasionally to reduce console spam
            print("📉 Frame dropped - maintaining performance")
        }
        frameCount += 1
    }
    
    // Add method to check if device supports high performance camera
    private func supportsHighPerformanceCamera() -> Bool {
        if #available(iOS 16.0, *) {
            return true
        } else {
            return ProcessInfo.processInfo.processorCount >= 4
        }
    }

}
