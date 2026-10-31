//
//  ImageCropView.swift
//  kiccbacc
//
//  Created by Assistant on 16/02/2025
//  Copyright © 2025 Assistant. All rights reserved.
//

import SwiftUI

struct ImageCropView: View {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    let aspectRatio: CGFloat
    let onCropComplete: (UIImage) -> Void
    
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
                    Image(uiImage: selectedImage ?? UIImage())
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
                                        
                                        // Limit scale between 1.0 and 3.0
                                        let newScale = scale * delta
                                        scale = min(max(newScale, 1.0), 3.0)
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    },
                                DragGesture()
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
                                        
                                        // Constrain the image within the crop area
                                        constrainImageToCropArea(geometry: geometry)
                                    }
                            )
                        )
                    
                    // Crop overlay
                    CropOverlay(aspectRatio: aspectRatio)
                }
                
                // Top controls
                VStack {
                    HStack {
                        Button(action: {
                            isPresented = false
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
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            cropAndUpload()
                        }) {
                            Text("Upload")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
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
        let cropSize = calculateCropSize(screenSize: screenSize, aspectRatio: aspectRatio)
        
        // Calculate the maximum allowed offset to keep the image within the crop area
        let imageSize = image.size
        let scaledImageSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        
        let maxOffsetX = abs(scaledImageSize.width - cropSize.width) / 2
        let maxOffsetY = abs(scaledImageSize.height - cropSize.height) / 2
        
        // Constrain the offset
        offset = CGSize(
            width: max(-maxOffsetX, min(maxOffsetX, offset.width)),
            height: max(-maxOffsetY, min(maxOffsetY, offset.height))
        )
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
        let cropSize = calculateCropSize(screenSize: UIScreen.main.bounds.size, aspectRatio: aspectRatio)
        
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
            isPresented = false
        }
    }
}

struct CropOverlay: View {
    let aspectRatio: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let screenSize = geometry.size
            let cropSize = calculateCropSize(screenSize: screenSize, aspectRatio: aspectRatio)
            
            ZStack {
                // Semi-transparent overlay outside crop area
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .mask(
                        Rectangle()
                            .overlay(
                                Rectangle()
                                    .frame(width: cropSize.width, height: cropSize.height)
                                    .position(x: screenSize.width/2, y: screenSize.height/2)
                                    .blendMode(.destinationOut)
                            )
                    )
                
                // Crop guide border
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: cropSize.width, height: cropSize.height)
                    .position(x: screenSize.width/2, y: screenSize.height/2)
                
                // Corner guides
                ForEach(0..<4) { corner in
                    CropCornerGuide(corner: corner)
                        .frame(width: 30, height: 30)
                        .position(
                            x: getCornerPosition(corner: corner, guideSize: cropSize).x,
                            y: getCornerPosition(corner: corner, guideSize: cropSize).y
                        )
                }
            }
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
    
    private func getCornerPosition(corner: Int, guideSize: CGSize) -> CGPoint {
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height / 2
        let halfWidth = guideSize.width / 2
        let halfHeight = guideSize.height / 2
        
        switch corner {
        case 0: // Top-left
            return CGPoint(x: centerX - halfWidth, y: centerY - halfHeight)
        case 1: // Top-right
            return CGPoint(x: centerX + halfWidth, y: centerY - halfHeight)
        case 2: // Bottom-left
            return CGPoint(x: centerX - halfWidth, y: centerY + halfHeight)
        case 3: // Bottom-right
            return CGPoint(x: centerX + halfWidth, y: centerY + halfHeight)
        default:
            return CGPoint.zero
        }
    }
}

struct CropCornerGuide: View {
    let corner: Int
    
    var body: some View {
        ZStack {
            switch corner {
            case 0: // Top-left
                VStack {
                    HStack {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 20, height: 3)
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 3, height: 20)
                        Spacer()
                    }
                }
            case 1: // Top-right
                VStack {
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 20, height: 3)
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 3, height: 20)
                    }
                }
            case 2: // Bottom-left
                VStack {
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 3, height: 20)
                    }
                    Spacer()
                    HStack {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 20, height: 3)
                        Spacer()
                    }
                }
            case 3: // Bottom-right
                VStack {
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 3, height: 20)
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 20, height: 3)
                    }
                }
            default:
                EmptyView()
            }
        }
    }
}


