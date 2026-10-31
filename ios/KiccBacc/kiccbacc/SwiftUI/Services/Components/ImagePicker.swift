//
//  ImagePicker.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 24/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import UIKit
import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    let aspectRatio: CGFloat
    let sourceType: UIImagePickerController.SourceType
    let disableAutoCrop: Bool
    let allowsEditing: Bool
    
    // Default initializer for backward compatibility (square 1:1)
    init(isPresented: Binding<Bool>, selectedImage: Binding<UIImage?>, sourceType: UIImagePickerController.SourceType = .photoLibrary, allowsEditing: Bool = false) {
        self._isPresented = isPresented
        self._selectedImage = selectedImage
        self.aspectRatio = 1.0 // Default to square
        self.sourceType = sourceType
        self.allowsEditing = allowsEditing
        self.disableAutoCrop = allowsEditing // If editing is enabled, disable auto-crop
    }
    
    // New initializer with custom aspect ratio
    init(isPresented: Binding<Bool>, selectedImage: Binding<UIImage?>, aspectRatio: CGFloat, sourceType: UIImagePickerController.SourceType = .photoLibrary, allowsEditing: Bool = false) {
        self._isPresented = isPresented
        self._selectedImage = selectedImage
        self.aspectRatio = aspectRatio
        self.sourceType = sourceType
        self.allowsEditing = allowsEditing
        self.disableAutoCrop = allowsEditing // If editing is enabled, disable auto-crop
    }
    
    // New initializer with option to disable auto-cropping
    init(isPresented: Binding<Bool>, selectedImage: Binding<UIImage?>, aspectRatio: CGFloat, sourceType: UIImagePickerController.SourceType = .photoLibrary, disableAutoCrop: Bool = false, allowsEditing: Bool = false) {
        self._isPresented = isPresented
        self._selectedImage = selectedImage
        self.aspectRatio = aspectRatio
        self.sourceType = sourceType
        self.allowsEditing = allowsEditing
        self.disableAutoCrop = disableAutoCrop || allowsEditing // If editing is enabled, disable auto-crop
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> some UIViewController {
        print("📸 ImagePicker: Creating UIImagePickerController with sourceType: \(sourceType.rawValue), allowsEditing: \(allowsEditing)")
        let controller = UIImagePickerController()
        controller.delegate = context.coordinator
        controller.sourceType = sourceType
        controller.allowsEditing = allowsEditing // Enable/disable native editing based on parameter
        
        print("📸 ImagePicker: Controller created successfully")
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ImagePicker.UIViewControllerType, context: UIViewControllerRepresentableContext<ImagePicker>) {
        
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        
        let parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            print("📸 ImagePicker: didFinishPickingMediaWithInfo called")
            
            // Use edited image if editing was enabled and available, otherwise use original
            let selectedImage: UIImage?
            if parent.allowsEditing, let editedImage = info[.editedImage] as? UIImage {
                selectedImage = editedImage
                print("📸 ImagePicker: Edited image selected - size: \(editedImage.size), scale: \(editedImage.scale)")
            } else if let originalImage = info[.originalImage] as? UIImage {
                selectedImage = originalImage
                print("📸 ImagePicker: Original image selected - size: \(originalImage.size), scale: \(originalImage.scale)")
            } else {
                selectedImage = nil
                print("❌ ImagePicker: No image found in info")
            }
            
            if let image = selectedImage {
                if parent.disableAutoCrop {
                    // Don't apply automatic cropping - use the image as is (edited or original)
                    print("📸 ImagePicker: Setting selectedImage (no auto-crop)")
                    print("📸 ImagePicker: Before setting - selectedImage is nil: \(self.parent.selectedImage == nil)")
                    
                    // Use DispatchQueue to ensure the image is set on the main thread
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image
                        print("📸 ImagePicker: After setting - selectedImage is nil: \(self.parent.selectedImage == nil)")
                    }
                } else {
                    // Apply custom aspect ratio cropping
                    print("📸 ImagePicker: Applying auto-crop with aspect ratio: \(parent.aspectRatio)")
                    let finalImage = cropImageToAspectRatio(image, aspectRatio: parent.aspectRatio)
                    
                    DispatchQueue.main.async {
                        self.parent.selectedImage = finalImage
                    }
                }
                
                print("📸 ImagePicker: selectedImage set successfully")
            }
            
            print("📸 ImagePicker: Setting isPresented to false")
            DispatchQueue.main.async {
                self.parent.isPresented = false
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("📸 ImagePicker: User cancelled selection")
            DispatchQueue.main.async {
                self.parent.isPresented = false
            }
        }
        
        // Helper function to crop image to specific aspect ratio
        private func cropImageToAspectRatio(_ image: UIImage, aspectRatio: CGFloat) -> UIImage {
            // First, fix the image orientation to prevent rotation issues
            let fixedImage = fixImageOrientation(image)
            
            let imageSize = fixedImage.size
            let imageAspectRatio = imageSize.width / imageSize.height
            
            var cropRect: CGRect
            
            if imageAspectRatio > aspectRatio {
                // Image is wider than target aspect ratio - crop width
                let newWidth = imageSize.height * aspectRatio
                let xOffset = (imageSize.width - newWidth) / 2
                cropRect = CGRect(x: xOffset, y: 0, width: newWidth, height: imageSize.height)
            } else {
                // Image is taller than target aspect ratio - crop height
                let newHeight = imageSize.width / aspectRatio
                let yOffset = (imageSize.height - newHeight) / 2
                cropRect = CGRect(x: 0, y: yOffset, width: imageSize.width, height: newHeight)
            }
            
            // Convert to points for CGImage cropping
            let scale = fixedImage.scale
            let cgCropRect = CGRect(
                x: cropRect.origin.x * scale,
                y: cropRect.origin.y * scale,
                width: cropRect.width * scale,
                height: cropRect.height * scale
            )
            
            // Perform the crop
            if let cgImage = fixedImage.cgImage?.cropping(to: cgCropRect) {
                return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
            }
            
            return fixedImage
        }
        
        // Helper function to fix image orientation
        private func fixImageOrientation(_ image: UIImage) -> UIImage {
            return image.fixOrientation()
        }
    }
   
}

