//
//  UIIImage.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

extension UIImage {
    enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }

    /// Returns the data for the specified image in JPEG format.
    /// If the image object's underlying image data has been purged, calling this function forces that data to be reloaded into memory.
    /// - returns: A data object containing the JPEG data, or nil if there was a problem generating the data. This function may return nil if the image has no data or if the underlying CGImageRef contains data in an unsupported bitmap format.
    func jpeg(_ quality: JPEGQuality) -> Data? {
        self.jpegData(compressionQuality: quality.rawValue)
    }
    
    /// Crops the image to match exactly what was visible on camera screen, then crops to 9:16 aspect ratio
    /// - Parameters:
    ///   - previewSize: The size of the camera preview view
    ///   - previewVideoGravity: The video gravity used for the preview (usually .resizeAspectFill)
    /// - Returns: Cropped UIImage with 9:16 aspect ratio matching visible area, or nil if cropping fails
    func cropVisibleAreaTo9x16(previewSize: CGSize, previewVideoGravity: AVLayerVideoGravity = .resizeAspectFill) -> UIImage? {
        // First, fix the image orientation to prevent rotation issues
        let fixedImage = self.fixOrientation()
        
        // Get the actual image size (accounting for orientation)
        let imageSize = fixedImage.size
        let previewSize = previewSize
        
        // Calculate the visible area based on video gravity
        let visibleRect: CGRect
        
        switch previewVideoGravity {
        case .resizeAspectFill:
            // For aspect fill, the preview shows a cropped portion of the image
            let imageAspectRatio = imageSize.width / imageSize.height
            let previewAspectRatio = previewSize.width / previewSize.height
            
            if imageAspectRatio > previewAspectRatio {
                // Image is wider than preview - crop sides
                let visibleWidth = imageSize.height * previewAspectRatio
                let xOffset = (imageSize.width - visibleWidth) / 2
                visibleRect = CGRect(x: xOffset, y: 0, width: visibleWidth, height: imageSize.height)
            } else {
                // Image is taller than preview - crop top/bottom
                let visibleHeight = imageSize.width / previewAspectRatio
                let yOffset = (imageSize.height - visibleHeight) / 2
                visibleRect = CGRect(x: 0, y: yOffset, width: imageSize.width, height: visibleHeight)
            }
        case .resizeAspect:
            // For aspect fit, the entire image is visible with letterboxing
            visibleRect = CGRect(origin: .zero, size: imageSize)
        case .resize:
            // For resize, the image is stretched to fit
            visibleRect = CGRect(origin: .zero, size: imageSize)
        default:
            visibleRect = CGRect(origin: .zero, size: imageSize)
        }
        
        // Crop to the visible area first
        guard let visibleCGImage = fixedImage.cgImage?.cropping(to: visibleRect) else {
            print("❌ cropVisibleAreaTo9x16: Failed to crop to visible area")
            return nil
        }
        
        let visibleImage = UIImage(cgImage: visibleCGImage, scale: fixedImage.scale, orientation: .up)
        
        // Now crop the visible area to 9:16 aspect ratio
        return visibleImage.cropTo9x16()
    }
    
    /// Crops the image to 9:16 aspect ratio (portrait orientation)
    /// - Returns: Cropped UIImage with 9:16 aspect ratio, or nil if cropping fails
    func cropTo9x16() -> UIImage? {
        // First, fix the image orientation to prevent rotation issues
        let fixedImage = self.fixOrientation()
        
        // Get the actual image size (accounting for orientation)
        let originalSize = fixedImage.size
        let targetAspectRatio: CGFloat = 9.0 / 16.0
        
        // Calculate the crop size to achieve 9:16 aspect ratio
        let cropSize: CGSize
        let cropOrigin: CGPoint
        
        let currentAspectRatio = originalSize.width / originalSize.height
        
        if currentAspectRatio > targetAspectRatio {
            // Image is wider than 9:16, crop width to center
            let targetWidth = originalSize.height * targetAspectRatio
            cropSize = CGSize(width: targetWidth, height: originalSize.height)
            cropOrigin = CGPoint(
                x: (originalSize.width - targetWidth) / 2,
                y: 0
            )
        } else {
            // Image is taller than 9:16, crop height to center
            let targetHeight = originalSize.width / targetAspectRatio
            cropSize = CGSize(width: originalSize.width, height: targetHeight)
            cropOrigin = CGPoint(
                x: 0,
                y: (originalSize.height - targetHeight) / 2
            )
        }
        
        // Create the crop rectangle
        let cropRect = CGRect(origin: cropOrigin, size: cropSize)
        
        // Ensure the crop rectangle is within bounds
        let boundedRect = CGRect(
            x: max(0, min(cropRect.origin.x, originalSize.width - cropRect.width)),
            y: max(0, min(cropRect.origin.y, originalSize.height - cropRect.height)),
            width: min(cropRect.width, originalSize.width),
            height: min(cropRect.height, originalSize.height)
        )
        
        // Convert to points for CGImage cropping
        let scale = fixedImage.scale
        let cgCropRect = CGRect(
            x: boundedRect.origin.x * scale,
            y: boundedRect.origin.y * scale,
            width: boundedRect.width * scale,
            height: boundedRect.height * scale
        )
        
        // Check if we have a valid CGImage
        guard let cgImage = fixedImage.cgImage else {
            print("❌ cropTo9x16: No CGImage available")
            return nil
        }
        
        // Check if the crop rectangle is valid
        guard cgCropRect.width > 0 && cgCropRect.height > 0 else {
            print("❌ cropTo9x16: Invalid crop rectangle dimensions")
            return nil
        }
        
        // Check if the crop rectangle is within the image bounds
        let imageBounds = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        guard imageBounds.contains(cgCropRect) || imageBounds.intersects(cgCropRect) else {
            print("❌ cropTo9x16: Crop rectangle outside image bounds")
            return nil
        }
        
        // Perform the crop
        guard let croppedCGImage = cgImage.cropping(to: cgCropRect) else {
            print("❌ cropTo9x16: Failed to crop CGImage")
            return nil
        }
        
        let result = UIImage(cgImage: croppedCGImage, scale: scale, orientation: .up)
        
        // Validate the result
        if result.size.width > 0 && result.size.height > 0 {
            return result
        } else {
            print("❌ cropTo9x16: Result has invalid dimensions")
            return nil
        }
    }
    
    /// Fixes the image orientation by properly handling EXIF rotation data
    /// - Returns: UIImage with corrected orientation
    func fixOrientation() -> UIImage {
        // If the image is already in the correct orientation, return it
        if self.imageOrientation == .up {
            return self
        }
        
        // Get the CGImage
        guard let cgImage = self.cgImage else {
            return self
        }
        
        // Calculate the proper transform based on orientation
        var transform = CGAffineTransform.identity
        
        switch self.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: self.size.height)
            transform = transform.rotated(by: -.pi / 2)
        default:
            break
        }
        
        // Handle mirrored orientations
        switch self.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: self.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        // Create a new context with the corrected orientation
        guard let colorSpace = cgImage.colorSpace else {
            return self
        }
        
        guard let context = CGContext(
            data: nil,
            width: Int(self.size.width),
            height: Int(self.size.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: cgImage.bitmapInfo.rawValue
        ) else {
            return self
        }
        
        // Apply the transform
        context.concatenate(transform)
        
        // Draw the image
        switch self.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: self.size.height, height: self.size.width))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        }
        
        // Create the corrected image
        guard let correctedCGImage = context.makeImage() else {
            return self
        }
        
        return UIImage(cgImage: correctedCGImage, scale: self.scale, orientation: .up)
    }

}
