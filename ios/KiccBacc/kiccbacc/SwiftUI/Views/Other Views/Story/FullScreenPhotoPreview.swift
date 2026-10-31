//
//  FullScreenPhotoPreview.swift
//  Instagram-Style Photo Viewer
//
//  Pure SwiftUI implementation with pinch, pan, and rotate gestures
//

import SwiftUI

// MARK: - FullScreenPhotoPreview
struct FullScreenPhotoPreview: View {
    
    let image: UIImage
    let onShare: (UIImage, @escaping (Double, String) -> Void) -> Void
    let onDismiss: () -> Void
    
    // Upload progress state
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0.0
    @State private var uploadStatus: String = "Preparing upload..."
    @State private var uploadCompleted = false
    @State private var showConfetti: Bool = false
    
    // MARK: - State Variables
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var minScale: CGFloat = 1.0
    
    @State private var rotation: Angle = .zero
    @State private var lastRotation: Angle = .zero
    
    @State private var imageSize: CGSize = .zero
    @State private var containerSize: CGSize = .zero
    
    // Animation states
    @State private var isInteracting = false
    @GestureState private var magnifyBy = 1.0
    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var rotateBy: Angle = .zero
    
    // MARK: - Scenes and Overlay State
    @State private var showScenesList = false
    @State private var selectedScene: StoryScene?
    @State private var overlayOffset: CGSize = .zero
    @State private var overlayScale: CGFloat = 1.0
    @State private var overlayRotation: Angle = .zero
    @State private var showOverlayGuide = true
    @State private var hasMovedOverlay = false
    
    // Gesture states for smoother overlay interaction
    @GestureState private var overlayDragOffset: CGSize = .zero
    @GestureState private var overlayMagnifyBy: CGFloat = 1.0
    @GestureState private var overlayRotateBy: Angle = .zero
    
    // Instagram-style snapping constants
    private let snapThreshold: CGFloat = 50.0 // Distance to trigger snapping
    private let snapZones = ["top", "center", "bottom", "left", "right", "topLeft", "topRight", "bottomLeft", "bottomRight"]
    
    // Constants
    private let maxScale: CGFloat = 3.0
    private let imageSnapThreshold: CGFloat = 0.15
    private let animationDuration: Double = 0.3
    
    // Theme color
    private let themeColor = Color(red: 242/255, green: 108/255, blue: 146/255)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                // Photo Container
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .onAppear {
                        print("📸 FullScreenPhotoPreview: Image appeared with size: \(image.size), scale: \(image.scale)")
                    }
                    .scaleEffect(scale * magnifyBy)
                    .rotationEffect(rotation + rotateBy)
                    .offset(x: offset.width + dragOffset.width,
                           y: offset.height + dragOffset.height)
                    .animation(isInteracting ? nil : .spring(response: 0.3, dampingFraction: 0.8),
                              value: offset)
                    .animation(isInteracting ? nil : .spring(response: 0.3, dampingFraction: 0.8),
                              value: scale)
                    .animation(isInteracting ? nil : .spring(response: 0.3, dampingFraction: 0.8),
                              value: rotation)
                    .background(
                        GeometryReader { imageGeometry in
                            Color.clear
                                .onAppear {
                                    imageSize = imageGeometry.size
                                    setupInitialScale()
                                }
                        }
                    )
                    .gesture(createCombinedGesture())
                    .onAppear {
                        containerSize = geometry.size
                    }
                    .onChange(of: geometry.size) { newSize in
                        containerSize = newSize
                        setupInitialScale()
                    }
                
                // Overlay Image (if scene is selected)
                if let selectedScene = selectedScene {
                    Image(selectedScene.overlayImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(overlayScale * overlayMagnifyBy)
                        .rotationEffect(overlayRotation + overlayRotateBy)
                        .offset(x: overlayOffset.width + overlayDragOffset.width,
                               y: overlayOffset.height + overlayDragOffset.height)
                        .gesture(createOverlayGesture())
                        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: overlayOffset)
                        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: overlayScale)
                        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: overlayRotation)
                }
                
                // Overlay Guide Text
                if showOverlayGuide && selectedScene != nil && !hasMovedOverlay {
                    VStack {
                        Spacer()
                        
                        Text("You can place it anywhere on your story")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.bottom, 120)
                    }
                }
                
                // Snap Zone Indicators (hidden but functionality remains)
                // Note: Visual indicators removed but snapping functionality is preserved
                if selectedScene != nil && overlayDragOffset != .zero {
                    // SnapZoneIndicators() - Hidden for cleaner UI
                }
                
                // UI Overlay
                VStack(spacing: 0) {
                    // Top Bar (hide during upload and after completion)
                    if !isUploading && !uploadCompleted {
                        HStack {
                            Button(action: {
                                hapticFeedback(.light)
                                onDismiss()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            // Scenes Button
                            Button(action: {
                                hapticFeedback(.light)
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    showScenesList.toggle()
                                }
                            }) {
                                Text("Scenes")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                        
                            // Reset button (shows when transformed)
                            if scale != minScale || rotation != .zero {
                                Button(action: resetTransform) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, geometry.safeAreaInsets.top + 50) // Much more padding to be well under notch/dynamic island
                        .animation(.easeInOut(duration: 0.2), value: scale)
                        .animation(.easeInOut(duration: 0.2), value: rotation)
                    }
                    
                    Spacer()
                    
                    // Bottom Upload Button
                    VStack(spacing: 8) {
                        // Guidance text (only show when not uploading)
                        if !isUploading {
                            Text("Pinch to zoom and pan to adjust")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        
                        // Upload Button, Progress, or Success Message
                        if uploadCompleted {
                            // Success Message (auto-dismiss after confetti)
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.green)

                                Text("Story Uploaded Successfully!")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                            .onAppear {
                                // Auto-dismiss after showing confetti for 2.5 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                    print("📸 FullScreenPhotoPreview: Auto-dismissing after confetti")
                                    hapticFeedback(.medium)
                                    onDismiss()
                                }
                            }
                        } else if isUploading {
                            // Progress View
                            VStack(spacing: 12) {
                                // Progress Bar
                                VStack(spacing: 8) {
                                    HStack {
                                        Text(uploadStatus)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("\(Int(uploadProgress * 100))%")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    
                                    ProgressView(value: uploadProgress)
                                        .progressViewStyle(LinearProgressViewStyle(tint: themeColor))
                                        .scaleEffect(y: 2)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                        } else {
                            // Upload Button
                            Button(action: {
                                hapticFeedback(.medium)
                                isUploading = true
                                uploadProgress = 0.0
                                uploadStatus = "Preparing upload..."
                                
                                // Create composite image with overlay before uploading
                                let compositeImage = createCompositeImage()
                                
                                onShare(compositeImage) { progress, status in
                                    DispatchQueue.main.async {
                                        self.uploadProgress = progress
                                        self.uploadStatus = status
                                        
                                        print("📸 FullScreenPhotoPreview: Progress updated to \(Int(progress * 100))%")
                                        
                                        // If upload is complete (progress = 1.0), show success UI and confetti
                                        if progress >= 1.0 {
                                            print("📸 FullScreenPhotoPreview: Upload complete - showing success screen")
                                            print("📸 Setting uploadCompleted = true, isUploading = false, showConfetti = true")
                                            self.uploadCompleted = true
                                            self.isUploading = false
                                            self.showConfetti = true
                                            print("📸 Success screen should now be visible with confetti")
                                        }
                                    }
                                }
                            }) {
                                Text("Upload Story")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(height: 50)
                                    .frame(maxWidth: .infinity)
                                    .background(themeColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                        }
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 40) // Much more padding to prevent overflow
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0),
                                Color.black.opacity(0.3),
                                Color.black.opacity(0.5)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 80) // Further reduced height to prevent overflow
                        .allowsHitTesting(false)
                    )
                }
                
                // Scenes List (slides up from bottom)
                if showScenesList {
                    VStack {
                        Spacer()
                        
                        ScenesListView(
                            selectedScene: $selectedScene,
                            showScenesList: $showScenesList,
                            onSceneSelected: { scene in
                                selectedScene = scene
                                showScenesList = false
                                setupOverlayPosition()
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        // Full width translucent background
                        Color.black.opacity(0.3)
                            .ignoresSafeArea(.all, edges: .bottom)
                    )
                }
            }
        }
        .overlay(
            SharedConfettiAnimationView(isShowing: $showConfetti)
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Overlay Gesture Creation
    private func createOverlayGesture() -> some Gesture {
        let magnification = MagnificationGesture()
            .updating($overlayMagnifyBy) { value, state, _ in
                state = value
            }
            .onEnded { value in
                let newScale = overlayScale * value
                overlayScale = min(max(newScale, 0.15), 3.0) // Much smaller scale (0.15x instead of 0.3x)
                
                // Snap to reasonable scale if too small
                if overlayScale < 0.2 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        overlayScale = 0.2
                    }
                }
            }
        
        let drag = DragGesture(minimumDistance: 0)
            .updating($overlayDragOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let newOffset = CGSize(
                    width: overlayOffset.width + value.translation.width,
                    height: overlayOffset.height + value.translation.height
                )
                
                // Apply Instagram-style snapping
                let snappedOffset = applySnapping(to: newOffset)
                
                // Constrain overlay to screen bounds
                let constrainedOffset = constrainOverlayOffset(snappedOffset)
                overlayOffset = constrainedOffset
                
                // Hide guide text when overlay is moved
                if !hasMovedOverlay {
                    hasMovedOverlay = true
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showOverlayGuide = false
                    }
                }
            }
        
        let rotationGesture = RotationGesture()
            .updating($overlayRotateBy) { value, state, _ in
                state = value
            }
            .onEnded { value in
                let newRotation = overlayRotation + value
                overlayRotation = applyRotationSnapping(to: newRotation)
            }
        
        return SimultaneousGesture(
            SimultaneousGesture(magnification, drag),
            rotationGesture
        )
    }
    
    // MARK: - Instagram-Style Snapping
    private func applySnapping(to offset: CGSize) -> CGSize {
        let screenBounds = UIScreen.main.bounds
        let centerX: CGFloat = 0
        let centerY: CGFloat = 0
        
        // Define snap zones with their target positions
        let snapZones: [(zone: String, position: CGSize, threshold: CGFloat)] = [
            ("center", CGSize(width: 0, height: 0), snapThreshold),
            ("top", CGSize(width: 0, height: -screenBounds.height * 0.3), snapThreshold),
            ("bottom", CGSize(width: 0, height: screenBounds.height * 0.3), snapThreshold),
            ("left", CGSize(width: -screenBounds.width * 0.3, height: 0), snapThreshold),
            ("right", CGSize(width: screenBounds.width * 0.3, height: 0), snapThreshold),
            ("topLeft", CGSize(width: -screenBounds.width * 0.3, height: -screenBounds.height * 0.3), snapThreshold),
            ("topRight", CGSize(width: screenBounds.width * 0.3, height: -screenBounds.height * 0.3), snapThreshold),
            ("bottomLeft", CGSize(width: -screenBounds.width * 0.3, height: screenBounds.height * 0.3), snapThreshold),
            ("bottomRight", CGSize(width: screenBounds.width * 0.3, height: screenBounds.height * 0.3), snapThreshold)
        ]
        
        // Find the closest snap zone
        var closestZone: (zone: String, position: CGSize, distance: CGFloat) = ("none", offset, CGFloat.greatestFiniteMagnitude)
        
        for zone in snapZones {
            let distance = sqrt(
                pow(offset.width - zone.position.width, 2) + 
                pow(offset.height - zone.position.height, 2)
            )
            
            if distance < zone.threshold && distance < closestZone.distance {
                closestZone = (zone.zone, zone.position, distance)
            }
        }
        
        // If we found a snap zone, snap to it with animation
        if closestZone.zone != "none" {
            // Provide haptic feedback for snapping
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                // The offset will be set in the calling function
            }
            return closestZone.position
        }
        
        return offset
    }
    
    // MARK: - Smooth Rotation Snapping
    private func applyRotationSnapping(to rotation: Angle) -> Angle {
        let degrees = rotation.degrees
        let normalizedDegrees = degrees.truncatingRemainder(dividingBy: 360)
        let adjustedDegrees = normalizedDegrees < 0 ? normalizedDegrees + 360 : normalizedDegrees
        
        // Define snap angles (0°, 90°, 180°, 270°)
        let snapAngles: [Double] = [0, 90, 180, 270]
        let snapThreshold: Double = 15.0 // Degrees within which to snap
        
        // Find the closest snap angle
        var closestAngle = adjustedDegrees
        var minDistance = Double.greatestFiniteMagnitude
        
        for snapAngle in snapAngles {
            let distance = min(
                abs(adjustedDegrees - snapAngle),
                abs(adjustedDegrees - snapAngle - 360),
                abs(adjustedDegrees - snapAngle + 360)
            )
            
            if distance < snapThreshold && distance < minDistance {
                minDistance = distance
                closestAngle = snapAngle
            }
        }
        
        // If we found a snap angle, animate to it
        if minDistance < snapThreshold {
            // Provide haptic feedback for rotation snapping
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Use smooth animation for rotation snapping
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                // The rotation will be set by the return value
            }
            
            return Angle(degrees: closestAngle)
        }
        
        return rotation
    }
    
    // MARK: - Overlay Constraint Helper
    private func constrainOverlayOffset(_ offset: CGSize) -> CGSize {
        guard let selectedScene = selectedScene else { return offset }
        
        // Get the overlay image size (approximate)
        let overlayImageSize = CGSize(width: 200, height: 200) // Base size for overlay
        let currentScale = overlayScale * overlayMagnifyBy
        let scaledSize = CGSize(
            width: overlayImageSize.width * currentScale,
            height: overlayImageSize.height * currentScale
        )
        
        // Account for rotation when constraining
        let currentRotation = overlayRotation + overlayRotateBy
        let rotationRadians = currentRotation.radians
        let cos = abs(cos(rotationRadians))
        let sin = abs(sin(rotationRadians))
        
        let rotatedWidth = scaledSize.width * cos + scaledSize.height * sin
        let rotatedHeight = scaledSize.width * sin + scaledSize.height * cos
        
        // Get screen bounds
        let screenBounds = UIScreen.main.bounds
        let maxX = (screenBounds.width - rotatedWidth) / 2
        let maxY = (screenBounds.height - rotatedHeight) / 2
        
        return CGSize(
            width: min(maxX, max(-maxX, offset.width)),
            height: min(maxY, max(-maxY, offset.height))
        )
    }
    
    // MARK: - Overlay Setup
    private func setupOverlayPosition() {
        guard let scene = selectedScene else { return }
        
        // Reset overlay position and scale
        overlayOffset = .zero
        overlayScale = 1.0
        overlayRotation = .zero
        hasMovedOverlay = false
        showOverlayGuide = true
        
        // Position overlay in center initially with snapping
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                // Center the overlay on the image (this will trigger snapping)
                overlayOffset = CGSize(width: 0, height: 0)
            }
        }
    }
    
    // MARK: - Composite Image Creation
    private func createCompositeImage() -> UIImage {
        guard let selectedScene = selectedScene else {
            print("🎭 No scene selected, returning original image")
            return image // Return original image if no scene selected
        }
        
        print("🎭 Creating composite image with scene: \(selectedScene.title)")
        print("🎭 Overlay state - Scale: \(overlayScale), Rotation: \(overlayRotation.degrees), Offset: \(overlayOffset)")
        print("🎭 Trying to load overlay image: '\(selectedScene.overlayImageName)'")
        
        // Test if the image can be loaded
        if let testImage = UIImage(named: selectedScene.overlayImageName) {
            print("🎭 Test load successful: \(selectedScene.overlayImageName), size: \(testImage.size)")
        } else {
            print("❌ Test load failed: \(selectedScene.overlayImageName)")
        }
        
        // Get the current overlay state
        let currentScale = overlayScale * overlayMagnifyBy
        let currentRotation = overlayRotation + overlayRotateBy
        let currentOffset = CGSize(
            width: overlayOffset.width + overlayDragOffset.width,
            height: overlayOffset.height + overlayDragOffset.height
        )
        
        // Create a graphics context with the image size
        let imageSize = image.size
        print("🎭 Creating graphics context with size: \(imageSize), scale: \(image.scale)")
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
        
        // Draw the base image
        image.draw(in: CGRect(origin: .zero, size: imageSize))
        print("🎭 Base image drawn successfully")
        
        // Load and draw the overlay image
        var overlayImage: UIImage? = UIImage(named: selectedScene.overlayImageName)
        
        if overlayImage != nil {
            // FIXED: Safe unwrap of overlayImage
            if let overlayImage = overlayImage {
                print("🎭 Overlay image loaded successfully: \(selectedScene.overlayImageName), size: \(overlayImage.size)")
            }
        } else {
            print("❌ Failed to load overlay image: \(selectedScene.overlayImageName)")
            
            // Try alternative names with better fallback strategy
            let alternativeNames = [
                selectedScene.overlayImageName,
                selectedScene.overlayImageName.replacingOccurrences(of: " ", with: ""),
                selectedScene.overlayImageName.lowercased(),
                selectedScene.overlayImageName.replacingOccurrences(of: " ", with: "_"),
                selectedScene.overlayImageName.uppercased(),
                selectedScene.overlayImageName.replacingOccurrences(of: " ", with: "-")
            ]
            
            print("🔍 Trying alternative names: \(alternativeNames)")
            
            for name in alternativeNames {
                if let altImage = UIImage(named: name) {
                    print("✅ Found overlay image with alternative name: \(name)")
                    overlayImage = altImage
                    break
                } else {
                    print("❌ Alternative name '\(name)' also failed")
                }
            }
            
            // If still no image, try to load from bundle directly
            if overlayImage == nil {
                print("🔍 Trying to load from bundle directly...")
                if let bundlePath = Bundle.main.path(forResource: selectedScene.overlayImageName, ofType: "png") {
                    print("✅ Found bundle path: \(bundlePath)")
                    if let bundleImage = UIImage(contentsOfFile: bundlePath) {
                        print("✅ Loaded from bundle: \(bundleImage.size)")
                        overlayImage = bundleImage
                    } else {
                        print("❌ Failed to load from bundle path")
                    }
                } else {
                    print("❌ No bundle path found for: \(selectedScene.overlayImageName)")
                }
            }
        }
        
        if let overlayImage = overlayImage {
            print("🎭 Drawing overlay image with size: \(overlayImage.size)")
            
            // Calculate overlay position and size
            let overlaySize = overlayImage.size
            let scaledOverlaySize = CGSize(
                width: overlaySize.width * currentScale,
                height: overlaySize.height * currentScale
            )
            
            // Calculate center position
            let centerX = (imageSize.width - scaledOverlaySize.width) / 2
            let centerY = (imageSize.height - scaledOverlaySize.height) / 2
            
            // Apply offset from center
            let overlayX = centerX + currentOffset.width
            let overlayY = centerY + currentOffset.height
            
            // Create the overlay rectangle
            let overlayRect = CGRect(
                x: overlayX,
                y: overlayY,
                width: scaledOverlaySize.width,
                height: scaledOverlaySize.height
            )
            
            print("🎭 Overlay rect: \(overlayRect), scale: \(currentScale), offset: \(currentOffset)")
            
            // Save graphics state for rotation
            let context = UIGraphicsGetCurrentContext()
            context?.saveGState()
            
            // Move to overlay center for rotation
            context?.translateBy(x: overlayRect.midX, y: overlayRect.midY)
            context?.rotate(by: currentRotation.radians)
            context?.translateBy(x: -overlayRect.midX, y: -overlayRect.midY)
            
            // Draw the rotated overlay
            overlayImage.draw(in: overlayRect)
            print("🎭 Overlay image drawn successfully")
            
            // Restore graphics state
            context?.restoreGState()
        } else {
            print("❌ No overlay image available, drawing fallback rectangle")
            
            // Draw a fallback colored rectangle to test the drawing system
            let fallbackRect = CGRect(
                x: imageSize.width * 0.25,
                y: imageSize.height * 0.25,
                width: imageSize.width * 0.5,
                height: imageSize.height * 0.5
            )
            
            UIColor.red.withAlphaComponent(0.5).setFill()
            UIRectFill(fallbackRect)
            print("🎭 Fallback rectangle drawn")
        }
        
        // Get the composite image
        let compositeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let compositeImage = compositeImage {
            print("🎭 Composite image created successfully, size: \(compositeImage.size)")
        } else {
            print("❌ Failed to create composite image, returning original")
        }
        
        return compositeImage ?? image
    }
    
    // MARK: - Gesture Creation
    private func createCombinedGesture() -> some Gesture {
        let magnification = MagnificationGesture()
            .updating($magnifyBy) { value, state, _ in
                state = value
            }
            .onChanged { _ in
                isInteracting = true
            }
            .onEnded { value in
                scale = min(max(scale * value, minScale), maxScale)
                lastScale = scale
                snapBackIfNeeded()
                isInteracting = false
            }
        
        let drag = DragGesture()
            .updating($dragOffset) { value, state, _ in
                if scale > minScale {
                    state = value.translation
                }
            }
            .onChanged { _ in
                isInteracting = true
            }
            .onEnded { value in
                if scale > minScale {
                    var newOffset = CGSize(
                        width: offset.width + value.translation.width,
                        height: offset.height + value.translation.height
                    )
                    newOffset = constrainOffset(newOffset)
                    offset = newOffset
                    lastOffset = offset
                }
                snapBackIfNeeded()
                isInteracting = false
            }
        
        let rotationGesture = RotationGesture()
            .updating($rotateBy) { value, state, _ in
                state = value
            }
            .onChanged { _ in
                isInteracting = true
            }
            .onEnded { value in
                rotation = rotation + value
                lastRotation = rotation
                isInteracting = false
            }
        
        return SimultaneousGesture(
            SimultaneousGesture(magnification, drag),
            rotationGesture
        )
    }
    
    // MARK: - Helper Methods
    private func setupInitialScale() {
        guard imageSize.width > 0, imageSize.height > 0,
              containerSize.width > 0, containerSize.height > 0 else { return }
        
        let widthScale = containerSize.width / imageSize.width
        let heightScale = containerSize.height / imageSize.height
        
        // Use fit mode to show the full cropped image
        minScale = min(widthScale, heightScale)
        scale = minScale
        lastScale = minScale
    }
    
    private func constrainOffset(_ offset: CGSize) -> CGSize {
        guard scale > minScale else { return .zero }
        
        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale
        
        // Account for rotation when constraining
        let rotationRadians = rotation.radians
        let cos = abs(cos(rotationRadians))
        let sin = abs(sin(rotationRadians))
        
        let rotatedWidth = scaledWidth * cos + scaledHeight * sin
        let rotatedHeight = scaledWidth * sin + scaledHeight * cos
        
        let maxX = max(0, (rotatedWidth - containerSize.width) / 2)
        let maxY = max(0, (rotatedHeight - containerSize.height) / 2)
        
        return CGSize(
            width: min(maxX, max(-maxX, offset.width)),
            height: min(maxY, max(-maxY, offset.height))
        )
    }
    
    private func snapBackIfNeeded() {
        // Snap back to center if scale is close to minimum
        if scale <= minScale * (1 + imageSnapThreshold) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                scale = minScale
                offset = .zero
                lastOffset = .zero
            }
        }
        
        // Snap rotation to 0 if close
        if abs(rotation.degrees) < 5 {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                rotation = .zero
                lastRotation = .zero
            }
        }
        
        // Constrain offset for current scale
        if scale > minScale {
            let constrained = constrainOffset(offset)
            if constrained != offset {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    offset = constrained
                    lastOffset = constrained
                }
            }
        }
    }
    
    private func resetTransform() {
        hapticFeedback(.light)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            scale = minScale
            offset = .zero
            rotation = .zero
            lastScale = minScale
            lastOffset = .zero
            lastRotation = .zero
        }
    }
    
    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impact = UIImpactFeedbackGenerator(style: style)
        impact.impactOccurred()
    }
}

// MARK: - Story Scene Model
struct StoryScene: Identifiable {
    let id = UUID()
    let title: String
    let overlayImageName: String
}

// MARK: - Scenes List View
struct ScenesListView: View {
    @Binding var selectedScene: StoryScene?
    @Binding var showScenesList: Bool
    let onSceneSelected: (StoryScene) -> Void
    
    // Available scenes
    private let availableScenes: [StoryScene] = [
        StoryScene(title: "Scene Overlay 1", overlayImageName: "SceneOverlay1"),
        StoryScene(title: "Scene Overlay 2", overlayImageName: "SceneOverlay2")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.white.opacity(0.6))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            // Title
            Text("Choose a Scene")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.bottom, 20)
            
            // Scenes list
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(availableScenes) { scene in
                    Button(action: {
                        onSceneSelected(scene)
                    }) {
                        VStack(spacing: 12) {
                            Image(scene.overlayImageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 80)
                                .padding(.horizontal, 16)
                            
                            Text(scene.title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .padding(.horizontal, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            
            // Close button
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showScenesList = false
                }
            }) {
                Text("Close")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Snap Zone Indicators
struct SnapZoneIndicators: View {
    var body: some View {
        ZStack {
            // Center snap zone
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                .frame(width: 60, height: 60)
            
            // Top snap zone
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: 40, height: 40)
                .offset(y: -UIScreen.main.bounds.height * 0.3)
            
            // Bottom snap zone
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: 40, height: 40)
                .offset(y: UIScreen.main.bounds.height * 0.3)
            
            // Left snap zone
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: 40, height: 40)
                .offset(x: -UIScreen.main.bounds.width * 0.3)
            
            // Right snap zone
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: 40, height: 40)
                .offset(x: UIScreen.main.bounds.width * 0.3)
            
            // Corner snap zones
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                .frame(width: 30, height: 30)
                .offset(x: -UIScreen.main.bounds.width * 0.3, y: -UIScreen.main.bounds.height * 0.3)
            
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                .frame(width: 30, height: 30)
                .offset(x: UIScreen.main.bounds.width * 0.3, y: -UIScreen.main.bounds.height * 0.3)
            
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                .frame(width: 30, height: 30)
                .offset(x: -UIScreen.main.bounds.width * 0.3, y: UIScreen.main.bounds.height * 0.3)
            
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                .frame(width: 30, height: 30)
                .offset(x: UIScreen.main.bounds.width * 0.3, y: UIScreen.main.bounds.height * 0.3)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Preview Provider
struct FullScreenPhotoPreview_Previews: PreviewProvider {
    static var previews: some View {
        FullScreenPhotoPreview(
            image: UIImage(systemName: "photo.fill")!,
            onShare: { compositeImage, progressCallback in
                print("Share tapped with image size: \(compositeImage.size)")
                progressCallback(0.5, "Uploading...")
            },
            onDismiss: { print("Dismiss tapped") }
        )
        .preferredColorScheme(.dark)
    }
}

// MARK: - Usage Example
struct ContentView: View {
    @State private var showPhotoViewer = false
    
    var body: some View {
        Button("Show Photo") {
            showPhotoViewer = true
        }
        .fullScreenCover(isPresented: $showPhotoViewer) {
            FullScreenPhotoPreview(
                image: UIImage(systemName: "photo.fill")!,
                onShare: { compositeImage, progressCallback in
                    print("Sharing photo with image size: \(compositeImage.size)")
                    // Handle share action with progress
                    progressCallback(0.5, "Uploading...")
                },
                onDismiss: {
                    showPhotoViewer = false
                }
            )
        }
    }
}
