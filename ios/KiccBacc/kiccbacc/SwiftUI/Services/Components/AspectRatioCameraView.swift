//
//  AspectRatioCameraView.swift
//  kiccbacc
//
//  Created by Assistant on 16/02/2025
//  Copyright © 2025 Assistant. All rights reserved.
//

import SwiftUI
import AVFoundation

struct AspectRatioCameraView: View {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    let aspectRatio: CGFloat
    
    @StateObject private var viewModel = StoryUploadViewViewModel()
    @State private var showFlash = false
    
    var body: some View {
        ZStack {
            // Camera preview
            if let frame = viewModel.frame {
                Image(uiImage: UIImage(cgImage: frame))
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
            }
            
            // Aspect ratio crop guide overlay
            CropGuideOverlay(aspectRatio: aspectRatio)
            
            // Camera controls
            VStack {
                // Top controls
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
                        viewModel.isFlashOn.toggle()
                    }) {
                        Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        viewModel.cameraOrientation.toggle()
                        viewModel.switchCamera(to: viewModel.cameraOrientation)
                    }) {
                        Image(systemName: "camera.rotate")
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
                        viewModel.captureTapped()
                        if let image = viewModel.pickedImage {
                            selectedImage = cropImageToAspectRatio(image, aspectRatio: aspectRatio)
                            isPresented = false
                        }
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 70, height: 70)
                            )
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 50)
            }
            
            // Flash overlay for front camera
            if showFlash {
                Color.white
                    .ignoresSafeArea()
                    .opacity(0.8)
            }
        }
        .onAppear {
            viewModel.setupSubscriptions()
        }
        .onDisappear {
            viewModel.frame = nil
        }
    }
    
    private func cropImageToAspectRatio(_ image: UIImage, aspectRatio: CGFloat) -> UIImage {
        let imageSize = image.size
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
        
        // Perform the crop
        if let cgImage = image.cgImage?.cropping(to: cropRect) {
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        
        return image
    }
}

struct CropGuideOverlay: View {
    let aspectRatio: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let screenSize = geometry.size
            let guideSize = calculateGuideSize(screenSize: screenSize, aspectRatio: aspectRatio)
            
            ZStack {
                // Semi-transparent overlay outside crop area
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .mask(
                        Rectangle()
                            .overlay(
                                Rectangle()
                                    .frame(width: guideSize.width, height: guideSize.height)
                                    .position(x: screenSize.width/2, y: screenSize.height/2)
                                    .blendMode(.destinationOut)
                            )
                    )
                
                // Crop guide border
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: guideSize.width, height: guideSize.height)
                    .position(x: screenSize.width/2, y: screenSize.height/2)
                
                // Corner guides
                ForEach(0..<4) { corner in
                    CropCornerGuide(corner: corner)
                        .frame(width: 30, height: 30)
                        .position(
                            x: getCornerPosition(corner: corner, guideSize: guideSize).x,
                            y: getCornerPosition(corner: corner, guideSize: guideSize).y
                        )
                }
            }
        }
    }
    
    private func calculateGuideSize(screenSize: CGSize, aspectRatio: CGFloat) -> CGSize {
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


