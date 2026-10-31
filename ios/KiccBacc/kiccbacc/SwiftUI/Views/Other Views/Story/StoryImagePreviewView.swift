//
//  StoryImagePreviewView.swift
//  KiccBacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI

// MARK: - StoryImagePreviewView
struct StoryImagePreviewView: View {
    
    let image: UIImage
    let onBack: () -> Void
    let onUpload: (UIImage) -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isDoubleTapped = false
    @State private var isLoading = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                // Image with Gestures
                ZStack {
                    // Image
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let newScale = lastScale * value
                                    scale = min(max(newScale, 1.0), 3.0)
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    constrainImageToBounds(in: geometry.size)
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newOffset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                    offset = newOffset
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                    constrainImageToBounds(in: geometry.size)
                                }
                        )
                        .gesture(
                            TapGesture(count: 2)
                                .onEnded {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        if isDoubleTapped {
                                            // Reset to fit
                                            scale = 1.0
                                            lastScale = 1.0
                                            offset = .zero
                                            lastOffset = .zero
                                            isDoubleTapped = false
                                        } else {
                                            // Zoom to fill
                                            scale = 2.0
                                            lastScale = 2.0
                                            isDoubleTapped = true
                                        }
                                    }
                                }
                        )
                    
                    // Crop Overlay
                    CropOverlayView()
                }
                
                // UI Overlay
                VStack {
                    // Header
                    HStack {
                        Button {
                            onBack()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Text("Preview")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Placeholder to balance layout
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, geometry.safeAreaInsets.top + 10)
                    
                    Spacer()
                    
                    // Bottom Controls
                    VStack(spacing: 20) {
                        // Instructions
                        Text("Pinch to zoom • Double tap to fit/fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        // Upload Button
                        Button {
                            uploadImage()
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                
                                Text(isLoading ? "Processing..." : "Upload Story")
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
                        .disabled(isLoading)
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private func constrainImageToBounds(in size: CGSize) {
        // Calculate the scaled image size
        let imageSize = image.size
        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale
        
        // Calculate maximum allowed offset
        let maxOffsetX = max(0, (scaledWidth - size.width) / 2)
        let maxOffsetY = max(0, (scaledHeight - size.height) / 2)
        
        // Constrain offset
        offset.width = min(max(offset.width, -maxOffsetX), maxOffsetX)
        offset.height = min(max(offset.height, -maxOffsetY), maxOffsetY)
        
        lastOffset = offset
    }
    
    private func uploadImage() {
        isLoading = true
        
        // Process image with current transform
        DispatchQueue.global(qos: .userInteractive).async {
            let processedImage = self.processImage()
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.onUpload(processedImage)
            }
        }
    }
    
    private func processImage() -> UIImage {
        // Create a new image with the current transform applied
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        return renderer.image { context in
            // Apply the current transform
            context.cgContext.translateBy(x: offset.width / scale, y: offset.height / scale)
            context.cgContext.scaleBy(x: scale, y: scale)
            
            // Draw the image
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}

// MARK: - CropOverlayView
struct CropOverlayView: View {
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark overlay outside crop area
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .mask(
                        Rectangle()
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .frame(
                                        width: geometry.size.width * 0.9,
                                        height: geometry.size.height * 0.7
                                    )
                                    .blendMode(.destinationOut)
                            )
                    )
                
                // Crop area border
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white, lineWidth: 2)
                    .frame(
                        width: geometry.size.width * 0.9,
                        height: geometry.size.height * 0.7
                    )
            }
        }
    }
}

// MARK: - Preview
struct StoryImagePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        StoryImagePreviewView(
            image: UIImage(),
            onBack: {},
            onUpload: { _ in }
        )
    }
}
