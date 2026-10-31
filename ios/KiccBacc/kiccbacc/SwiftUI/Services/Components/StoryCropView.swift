//
//  StoryCropView.swift
//  kiccbacc
//
//  Created by Assistant on 16/02/2025
//  Copyright © 2025 Assistant. All rights reserved.
//

import SwiftUI

struct StoryCropView: View {
    @Binding var selectedImage: UIImage?
    let onCropComplete: (UIImage) -> Void
    let onCancel: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                // Image with crop overlay
                ZStack {
                    // The image container
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                SimultaneousGesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            let delta = value / lastScale
                                            lastScale = value
                                            
                                            // Limit scale between 1.0 and 5.0
                                            let newScale = scale * delta
                                            scale = min(max(newScale, 1.0), 5.0)
                                        }
                                        .onEnded { _ in
                                            lastScale = 1.0
                                            constrainImageToCropArea(geometry: geometry)
                                        },
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            isDragging = true
                                            let delta = CGSize(
                                                width: value.translation.width - lastOffset.width,
                                                height: value.translation.height - lastOffset.height
                                            )
                                            lastOffset = value.translation
                                            offset = CGSize(
                                                width: offset.width + delta.width,
                                                height: offset.height + delta.height
                                            )
                                        }
                                        .onEnded { _ in
                                            isDragging = false
                                            lastOffset = .zero
                                            constrainImageToCropArea(geometry: geometry)
                                        }
                                )
                            )
                            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: scale)
                            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: offset)
                    }
                    
                    // Crop overlay
                    CropOverlay(aspectRatio: 9.0/16.0)
                }
                
                // Top controls
                VStack {
                    HStack {
                        Button(action: {
                            if let onCancel = onCancel {
                                onCancel()
                            } else {
                                dismiss()
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            resetImage()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Bottom controls
                    VStack(spacing: 20) {
                        // Instructions
                        Text("Pinch to zoom • Drag to move")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                        
                        // Upload button
                        Button(action: {
                            cropAndUpload()
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                Text("Upload Story")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.appColor, Color.appColor.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.appColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            setupInitialImagePosition()
        }
    }
    
    private func setupInitialImagePosition() {
        // Reset to initial position
        scale = 1.0
        offset = .zero
        lastScale = 1.0
        lastOffset = .zero
    }
    
    private func resetImage() {
        withAnimation(.easeInOut(duration: 0.3)) {
            setupInitialImagePosition()
        }
    }
    
    private func constrainImageToCropArea(geometry: GeometryProxy) {
        guard let image = selectedImage else { return }
        
        let screenSize = geometry.size
        let cropSize = calculateCropSize(screenSize: screenSize, aspectRatio: 9.0/16.0)
        
        // Calculate the maximum allowed offset to keep the image within the crop area
        let imageSize = image.size
        let scaledImageSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        
        let maxOffsetX = abs(scaledImageSize.width - cropSize.width) / 2
        let maxOffsetY = abs(scaledImageSize.height - cropSize.height) / 2
        
        // Constrain the offset with animation
        withAnimation(.easeOut(duration: 0.2)) {
            offset = CGSize(
                width: max(-maxOffsetX, min(maxOffsetX, offset.width)),
                height: max(-maxOffsetY, min(maxOffsetY, offset.height))
            )
        }
    }
    
    private func calculateCropSize(screenSize: CGSize, aspectRatio: CGFloat) -> CGSize {
        let screenAspectRatio = screenSize.width / screenSize.height
        
        if screenAspectRatio > aspectRatio {
            // Screen is wider than target aspect ratio
            let height = screenSize.height * 0.8 // Use 80% of screen height
            let width = height * aspectRatio
            return CGSize(width: width, height: height)
        } else {
            // Screen is taller than target aspect ratio
            let width = screenSize.width * 0.8 // Use 80% of screen width
            let height = width / aspectRatio
            return CGSize(width: width, height: height)
        }
    }
    
    private func cropAndUpload() {
        guard let image = selectedImage else { return }
        
        // Create a graphics context with the crop size
        let cropSize = calculateCropSize(screenSize: UIScreen.main.bounds.size, aspectRatio: 9.0/16.0)
        
        UIGraphicsBeginImageContextWithOptions(cropSize, false, 0)
        
        // Calculate the source rectangle in the original image
        let imageSize = image.size
        let scaledImageSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        
        // Calculate the position of the image relative to the crop area
        let cropRect = CGRect(origin: .zero, size: cropSize)
        let imageRect = CGRect(
            x: (cropSize.width - scaledImageSize.width) / 2 - offset.width,
            y: (cropSize.height - scaledImageSize.height) / 2 - offset.height,
            width: scaledImageSize.width,
            height: scaledImageSize.height
        )
        
        // Draw the cropped image
        image.draw(in: imageRect)
        
        // Get the cropped image
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let croppedImage = croppedImage {
            onCropComplete(croppedImage)
        }
    }
}
