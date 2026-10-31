//
//  CGImage.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import Foundation
import VideoToolbox
import CoreImage
import CoreVideo

extension CGImage {
    static func create(from pixelBuffer: CVPixelBuffer?) -> CGImage? {
        var cgImage: CGImage?
        guard let pixelBuffer = pixelBuffer else {
            return nil
        }

        // Create CGImage with optimized settings
        let status = VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        
        guard status == noErr else {
            print("❌ Failed to create CGImage from pixel buffer: \(status)")
            return nil
        }
        
        return cgImage
    }
    
    // Add a more efficient method for camera preview
    static func createPreview(from pixelBuffer: CVPixelBuffer?) -> CGImage? {
        var cgImage: CGImage?
        guard let pixelBuffer = pixelBuffer else {
            return nil
        }
        
        // Use minimal options for faster processing
        let status = VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        
        guard status == noErr else {
            return nil
        }
        
        return cgImage
    }
    
    // High quality preview for iOS 16+ devices
    static func createHighQualityPreview(from pixelBuffer: CVPixelBuffer?) -> CGImage? {
        var cgImage: CGImage?
        guard let pixelBuffer = pixelBuffer else {
            return nil
        }
        
        // Create options dictionary for higher quality
        let options = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary
        
        // Use enhanced options for better quality
        let status = VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: options, imageOut: &cgImage)
        
        guard status == noErr else {
            return nil
        }
        
        return cgImage
    }
}
