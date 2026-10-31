//
//  NativeStoryCameraView.swift
//  KiccBacc
//
//  Created by Siddharth Pillai on 21/09/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import UIKit
import AVFoundation
import Photos

// MARK: - CameraFlowState Enum
enum CameraFlowState: Identifiable, Equatable {
    case camera
    case preview(image: UIImage)
    case galleryPicker

    var id: Int {
        switch self {
        case .camera: return 0
        case .preview: return 1
        case .galleryPicker: return 2
        }
    }
    
    static func == (lhs: CameraFlowState, rhs: CameraFlowState) -> Bool {
        switch (lhs, rhs) {
        case (.camera, .camera):
            return true
        case (.preview(let lhsImage), .preview(let rhsImage)):
            return lhsImage == rhsImage
        case (.galleryPicker, .galleryPicker):
            return true
        default:
            return false
        }
    }
}

// MARK: - AVFoundation Camera View
struct AVFoundationCameraView: UIViewRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var isPresented: Bool
    let onGalleryPickerRequested: (() -> Void)?
    
    func makeUIView(context: Context) -> NativeCameraPreviewView {
        let cameraView = NativeCameraPreviewView()
        cameraView.delegate = context.coordinator
        cameraView.startCamera()
        return cameraView
    }
    
    func updateUIView(_ uiView: NativeCameraPreviewView, context: Context) {
        // Updates handled by coordinator
    }
    
    static func dismantleUIView(_ uiView: NativeCameraPreviewView, coordinator: CameraCoordinator) {
        uiView.stopCamera()
    }
    
    func makeCoordinator() -> CameraCoordinator {
        CameraCoordinator(self)
    }
    
    func showGalleryPicker() {
        onGalleryPickerRequested?()
    }
    
    class CameraCoordinator: NSObject, NativeCameraPreviewViewDelegate {
        let parent: AVFoundationCameraView
        
        init(_ parent: AVFoundationCameraView) {
            self.parent = parent
        }
        
        func didCaptureImage(_ image: UIImage) {
            print("📸 NativeCamera: Image captured, size: \(image.size)")
            parent.capturedImage = image
        }
        
        func didRequestClose() {
            print("📸 NativeCamera: Close requested")
            // Set both bindings to ensure proper dismissal
            parent.isPresented = false
            parent.capturedImage = nil
        }
        
        func didRequestGalleryPicker() {
            print("📸 NativeCamera: Gallery picker requested")
            // Trigger gallery picker flow through parent
            parent.showGalleryPicker()
        }
    }
}

protocol NativeCameraPreviewViewDelegate: AnyObject {
    func didCaptureImage(_ image: UIImage)
    func didRequestClose()
    func didRequestGalleryPicker()
}

class NativeCameraPreviewView: UIView, AVCapturePhotoCaptureDelegate {
    weak var delegate: NativeCameraPreviewViewDelegate?
    
    private var captureSession: AVCaptureSession!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!
    private var currentCamera: AVCaptureDevice!
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    private var flashMode: AVCaptureDevice.FlashMode = .auto
    private var zoomScale: CGFloat = 1.0
    
    // UI Elements
    private var captureButton: UIButton!
    private var flipButton: UIButton!
    private var flashButton: UIButton!
    private var closeButton: UIButton!
    private var galleryButton: UIButton!
    private var zoomSlider: UISlider!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
        setupUI()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("❌ Unable to access back camera")
                return 
        }
        
        currentCamera = backCamera
        
        do {
            let input = try AVCaptureDeviceInput(device: currentCamera)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            photoOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer.videoGravity = .resizeAspectFill
            layer.addSublayer(videoPreviewLayer)
            
        } catch {
            print("❌ Error setting up camera: \(error)")
        }
    }
    
    private func setupUI() {
        // Capture Button
        captureButton = UIButton(type: .custom)
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 35
        captureButton.layer.borderWidth = 4
        captureButton.layer.borderColor = UIColor(red: 0.949, green: 0.424, blue: 0.573, alpha: 1.0).cgColor
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        addSubview(captureButton)
        
        // Flip Camera Button
        flipButton = UIButton(type: .system)
        flipButton.setImage(UIImage(systemName: "camera.rotate"), for: .normal)
        flipButton.tintColor = .white
        flipButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        flipButton.layer.cornerRadius = 25
        flipButton.translatesAutoresizingMaskIntoConstraints = false
        flipButton.addTarget(self, action: #selector(flipCamera), for: .touchUpInside)
        addSubview(flipButton)
        
        // Flash Button
        flashButton = UIButton(type: .system)
        updateFlashButtonImage()
        flashButton.tintColor = .white
        flashButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        flashButton.layer.cornerRadius = 25
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        addSubview(flashButton)
        
        // Close Button
        closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 25
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeCamera), for: .touchUpInside)
        addSubview(closeButton)
        
        // Gallery Button
        galleryButton = UIButton(type: .system)
        galleryButton.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
        galleryButton.tintColor = .white
        galleryButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        galleryButton.layer.cornerRadius = 25
        galleryButton.translatesAutoresizingMaskIntoConstraints = false
        galleryButton.addTarget(self, action: #selector(openGalleryPicker), for: .touchUpInside)
        addSubview(galleryButton)
        
        // Zoom Slider
        zoomSlider = UISlider()
        zoomSlider.minimumValue = 1.0
        zoomSlider.maximumValue = Float(min(currentCamera.activeFormat.videoMaxZoomFactor, 10.0))
        zoomSlider.value = 1.0
        zoomSlider.minimumTrackTintColor = .white
        zoomSlider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.3)
        zoomSlider.thumbTintColor = .white
        zoomSlider.translatesAutoresizingMaskIntoConstraints = false
        zoomSlider.addTarget(self, action: #selector(zoomChanged), for: .valueChanged)
        addSubview(zoomSlider)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Capture Button (bottom center)
            captureButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -30),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),
            
            // Flip Button (bottom right)
            flipButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            flipButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            flipButton.widthAnchor.constraint(equalToConstant: 50),
            flipButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Flash Button (top right)
            flashButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            flashButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            flashButton.widthAnchor.constraint(equalToConstant: 50),
            flashButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Close Button (top left)
            closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.widthAnchor.constraint(equalToConstant: 50),
            closeButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Gallery Button (bottom left)
            galleryButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            galleryButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            galleryButton.widthAnchor.constraint(equalToConstant: 50),
            galleryButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Zoom Slider (left side, vertical)
            zoomSlider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -50),
            zoomSlider.centerYAnchor.constraint(equalTo: centerYAnchor),
            zoomSlider.widthAnchor.constraint(equalToConstant: 200),
            zoomSlider.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // Rotate zoom slider to be vertical
        zoomSlider.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer?.frame = bounds
    }
    
    func startCamera() {
        // Start camera session immediately on main thread for faster startup
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInteractive).async {
                self.captureSession.startRunning()
            DispatchQueue.main.async {
                    print("📸 Camera session started")
                }
            }
        }
    }
    
    func stopCamera() {
        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInteractive).async {
                self.captureSession.stopRunning()
            DispatchQueue.main.async {
                    print("📸 Camera session stopped")
                }
            }
        }
    }
    
    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        
        // Add capture animation
        UIView.animate(withDuration: 0.1, animations: {
            self.alpha = 0.8
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.alpha = 1.0
            }
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc private func flipCamera() {
        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else { return }
        
        captureSession.beginConfiguration()
        captureSession.removeInput(currentInput)
        
        let newPosition: AVCaptureDevice.Position = currentCameraPosition == .back ? .front : .back
        
        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
            captureSession.addInput(currentInput)
            captureSession.commitConfiguration()
            return
        }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newCamera)
            captureSession.addInput(newInput)
            currentCamera = newCamera
            currentCameraPosition = newPosition
            
            // Update zoom slider max value
            zoomSlider.maximumValue = Float(min(newCamera.activeFormat.videoMaxZoomFactor, 10.0))
            zoomSlider.value = 1.0
            zoomScale = 1.0
            
        } catch {
            captureSession.addInput(currentInput)
            print("❌ Error switching camera: \(error)")
        }
        
        captureSession.commitConfiguration()
    }
    
    @objc private func toggleFlash() {
        switch flashMode {
        case .auto:
            flashMode = .on
        case .on:
            flashMode = .off
        case .off:
            flashMode = .auto
        @unknown default:
            flashMode = .auto
        }
        updateFlashButtonImage()
    }
    
    private func updateFlashButtonImage() {
        let imageName: String
        switch flashMode {
        case .auto:
            imageName = "bolt.badge.a"
        case .on:
            imageName = "bolt"
        case .off:
            imageName = "bolt.slash"
        @unknown default:
            imageName = "bolt.badge.a"
        }
        flashButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    @objc private func zoomChanged(_ slider: UISlider) {
        let zoomFactor = CGFloat(slider.value)
        
        do {
            try currentCamera.lockForConfiguration()
            currentCamera.videoZoomFactor = zoomFactor
            currentCamera.unlockForConfiguration()
            zoomScale = zoomFactor
        } catch {
            print("❌ Error setting zoom: \(error)")
        }
    }
    
    @objc private func closeCamera() {
        delegate?.didRequestClose()
    }
    
    @objc private func openGalleryPicker() {
        delegate?.didRequestGalleryPicker()
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("❌ Error processing captured image")
            return
        }
        
        // Fix image orientation
        let fixedImage = image.fixedOrientation()
        
        // Crop to match exactly what was visible on camera screen, then to 9:16
        let previewSize = bounds.size
        if let croppedImage = fixedImage.cropVisibleAreaTo9x16(previewSize: previewSize, previewVideoGravity: videoPreviewLayer.videoGravity) {
            print("📸 NativeCamera: Image cropped to visible area + 9:16 successfully")
            delegate?.didCaptureImage(croppedImage)
        } else {
            print("📸 NativeCamera: Visible area crop failed, using orientation-fixed image")
            delegate?.didCaptureImage(fixedImage)
        }
    }
}

// MARK: - UIImage Extension for Orientation Fix
extension UIImage {
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? self
    }
}

// MARK: - NativeStoryCameraStateManager (Singleton)
class NativeStoryCameraStateManager: ObservableObject {
    static let shared = NativeStoryCameraStateManager()
    
    @Published var flowState: CameraFlowState? = nil
    @Published var hasAppeared = false
    @Published var isDismissing = false
    @Published var photoTaken = false
    @Published var uploadCompleted = false  // NEW: Track if upload finished successfully
    
    // Debouncing properties
    private var lastCameraCall = Date.distantPast
    private var lastStateChange = Date.distantPast
    private let debounceInterval: TimeInterval = 0.2 // 0.2 second debounce for smooth reopening
    
    private init() {
        print("📸 NativeStoryCameraStateManager: Singleton initialized")
    }
    
    func reset() {
        print("📸 NativeStoryCameraStateManager: Resetting state")
        print("📸 State change: flowState -> nil")
        flowState = nil
        hasAppeared = false
        isDismissing = false
        photoTaken = false
        uploadCompleted = false
        lastCameraCall = Date.distantPast
        lastStateChange = Date.distantPast
    }
    
    func markPhotoTaken() {
        print("📸 NativeStoryCameraStateManager: Marking photo as taken")
        print("📸 State change: photoTaken \(photoTaken) -> true")
        photoTaken = true
        lastStateChange = Date()
    }
    
    func markDismissing() {
        print("📸 NativeStoryCameraStateManager: Marking as dismissing")
        print("📸 State change: isDismissing \(isDismissing) -> true")
        isDismissing = true
        lastStateChange = Date()
    }
    
    func canOpenCamera() -> Bool {
        let now = Date()
        let timeSinceLastCall = now.timeIntervalSince(lastCameraCall)
        let timeSinceLastStateChange = now.timeIntervalSince(lastStateChange)
        
        // Prevent camera opening if:
        // 1. Currently dismissing (but allow if photo was taken - user can return from preview)
        // 2. Recent camera call (debouncing)
        // 3. Recent state change (debouncing)
        let canOpen = !isDismissing && 
                     timeSinceLastCall > debounceInterval &&
                     timeSinceLastStateChange > debounceInterval
        
        print("📸 NativeStoryCameraStateManager: canOpenCamera = \(canOpen) (photoTaken: \(photoTaken), isDismissing: \(isDismissing), timeSinceLastCall: \(timeSinceLastCall), timeSinceLastStateChange: \(timeSinceLastStateChange))")
        
        return canOpen
    }
    
    func openCamera() {
        guard canOpenCamera() else {
            print("📸 NativeStoryCameraStateManager: Camera opening blocked by debounce or state")
            return
        }
        
        lastCameraCall = Date()
        print("📸 State change: flowState -> .camera")
        flowState = .camera
        print("📸 NativeStoryCameraStateManager: Opening camera")
    }
    
    func openCameraImmediately() {
        // Bypass all debouncing and checks for immediate opening
        lastCameraCall = Date()
        print("📸 State change: flowState -> .camera (immediate)")
        flowState = .camera
        print("📸 NativeStoryCameraStateManager: Opening camera immediately")
    }
    
    func showPreview(with image: UIImage) {
        print("📸 State change: photoTaken \(photoTaken) -> true (via showPreview)")
        photoTaken = true
        // Don't set isDismissing = true here to allow returning to camera from preview
        lastStateChange = Date()
        print("📸 State change: flowState -> .preview")
        flowState = .preview(image: image)
    }
    
    func openGalleryPicker() {
        print("📸 State change: flowState -> .galleryPicker")
        flowState = .galleryPicker
        print("📸 NativeStoryCameraStateManager: Opening gallery picker")
    }
    
    func closeFlow() {
        print("📸 State change: flowState -> nil")
        isDismissing = true
        lastStateChange = Date()
        flowState = nil
    }
}

// MARK: - NativeStoryCameraView
struct NativeStoryCameraView: View {
    
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    // Add eventID parameter for story upload
    let eventID: String?
    let onStoryUploaded: (() -> Void)?
    
    // Use singleton state manager to persist state across view recreations
    @ObservedObject private var stateManager = NativeStoryCameraStateManager.shared
    
    // Gallery picker state
    @State private var showGalleryPicker = false
    @State private var gallerySelectedImage: UIImage?
    
    // Default initializer for backward compatibility
    init(selectedImage: Binding<UIImage?>) {
        self._selectedImage = selectedImage
        self.eventID = nil
        self.onStoryUploaded = nil
        print("📸 NativeStoryCameraView: Initialized with selectedImage binding")
        
        // Open camera immediately during initialization to prevent black screen
        let stateManager = NativeStoryCameraStateManager.shared
        
        // IMPORTANT: Don't open camera if already dismissing
        if stateManager.isDismissing {
            print("📸 NativeStoryCameraView: Already dismissing, skipping camera initialization")
            return
        }
        
        if stateManager.photoTaken {
            stateManager.reset()
        }
        stateManager.hasAppeared = true
        stateManager.openCameraImmediately()
    }
    
    // New initializer with eventID for story upload
    init(selectedImage: Binding<UIImage?>, eventID: String? = nil, onStoryUploaded: (() -> Void)? = nil) {
        self._selectedImage = selectedImage
        self.eventID = eventID
        self.onStoryUploaded = onStoryUploaded
        print("📸 NativeStoryCameraView: Initialized with eventID: \(eventID ?? "nil")")
        
        // Open camera immediately during initialization to prevent black screen
        let stateManager = NativeStoryCameraStateManager.shared
        
        // IMPORTANT: Don't open camera if already dismissing
        if stateManager.isDismissing {
            print("📸 NativeStoryCameraView: Already dismissing, skipping camera initialization")
            return
        }
        
        if stateManager.photoTaken {
            stateManager.reset()
        }
        stateManager.hasAppeared = true
        stateManager.openCameraImmediately()
    }
    
    var body: some View {
        ZStack {
            // Main content based on flow state
            if let flowState = stateManager.flowState {
                switch flowState {
                case .camera:
                    AVFoundationCameraView(
                        capturedImage: Binding<UIImage?>(
                            get: { 
                                if case .preview(let image) = stateManager.flowState {
                                    return image
                                }
                                return nil
                            },
                            set: { newImage in
                                // When camera captures image, show preview
                                if let img = newImage {
                                    stateManager.showPreview(with: img)
                                }
                            }
                        ),
                        isPresented: Binding<Bool>(
                            get: { 
                                if case .camera = stateManager.flowState {
                                    return true
                                }
                                if case .galleryPicker = stateManager.flowState {
                                    return true
                                }
                                return false
                            },
                            set: { newVal in
                                if !newVal {
                                    // If camera wants to close, dismiss entire view
                                    print("📸 Camera close requested - dismissing entire view")
                                    stateManager.closeFlow()
                                    dismiss()
                                }
                            }
                        ),
                        onGalleryPickerRequested: {
                            stateManager.openGalleryPicker()
                        }
                    )
                .ignoresSafeArea()
                    .transition(.opacity)
                
                case .galleryPicker:
                    ImagePicker(
                        isPresented: $showGalleryPicker,
                        selectedImage: $gallerySelectedImage,
                        aspectRatio: 9.0/16.0, // Story aspect ratio
                        sourceType: .photoLibrary,
                        allowsEditing: false
                    )
                    .ignoresSafeArea()
                    .onAppear {
                        showGalleryPicker = true
                    }
                    .onChange(of: gallerySelectedImage) { newImage in
                        if let image = newImage {
                            // Show preview with selected image
                            stateManager.showPreview(with: image)
                            showGalleryPicker = false
                        }
                    }
                    .onChange(of: showGalleryPicker) { isShowing in
                        if !isShowing && gallerySelectedImage == nil {
                            // User cancelled gallery picker, return to camera
                            stateManager.flowState = .camera
                        }
                    }

                case .preview(let image):
                FullScreenPhotoPreview(
                    image: image,
                    onShare: { compositeImage, progressCallback in
                        handleStoryUpload(image: compositeImage, progressCallback: progressCallback)
                    },
                    onDismiss: {
                        print("📸 NativeStoryCameraView: onDismiss from preview")
                        print("📸 uploadCompleted: \(self.stateManager.uploadCompleted), isDismissing: \(self.stateManager.isDismissing)")
                        
                        // Guard against double-dismissal
                        guard !self.stateManager.isDismissing else {
                            print("📸 Already dismissing, ignoring onDismiss call")
                            return
                        }
                        
                        // Check if upload was completed successfully
                        if self.stateManager.uploadCompleted {
                            print("📸 NativeStoryCameraView: Upload complete - user clicked 'Back to Event'")
                            // Set isDismissing to prevent any re-presentation
                            self.stateManager.markDismissing()
                            
                            // Dismiss immediately
                            self.dismiss()
                            
                            // Call callback AFTER dismissal to avoid UI update race conditions
                            // This prevents the callback from interfering with the dismissal animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.onStoryUploaded?()
                            }
                        } else {
                            print("📸 NativeStoryCameraView: Cancel pressed - returning to camera")
                            // User cancelled without uploading, return to camera
                            self.stateManager.photoTaken = false
                            self.stateManager.flowState = .camera
                        }
                    }
                )
                .ignoresSafeArea()
                    .transition(.opacity)
                }
            } else {
                // Fallback - should not be visible due to immediate camera opening
                Color.clear
            }
        }
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.15), value: stateManager.flowState)
        .onChange(of: stateManager.flowState) { newFlow in
            print("📸 NativeStoryCameraView: flowState changed -> \(String(describing: newFlow))")
            dumpCameraState("flowState change")
        }
        .onAppear {
            print("📸 NativeStoryCameraView: onAppear called - camera already opened in init")
            // Request permissions in case they weren't granted yet
            requestCameraPermissions()
            requestPhotoLibraryPermissions()
        }
        .onDisappear {
            print("📸 NativeStoryCameraView: onDisappear - cleanup")
            dumpCameraState("onDisappear")
            // Don't clear flowState immediately - let the view finish its dismissal animation
            // to avoid showing black screen during transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.stateManager.closeFlow()
                self.stateManager.reset()
                print("📸 NativeStoryCameraView: State reset complete")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            print("📸 NativeStoryCameraView: App will resign active")
            // Don't reset state here - let the camera handle its own session management
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            print("📸 NativeStoryCameraView: App did become active")
            // Only restore camera if we're in camera state and not dismissing
            if case .camera = stateManager.flowState, !stateManager.isDismissing {
                print("📸 NativeStoryCameraView: Restoring camera after background")
                // The camera session should automatically resume
            }
        }
    }
    
    private func requestCameraPermissions() {
        // Pre-request camera permissions for faster access
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if !granted {
                print("⚠️ Camera permission denied")
            }
        }
    }
    
    private func requestPhotoLibraryPermissions() {
        // Pre-request photo library permissions for gallery access
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                print("📸 Photo library permission granted")
            case .denied, .restricted:
                print("⚠️ Photo library permission denied")
            case .notDetermined:
                print("📸 Photo library permission not determined")
            case .limited:
                print("📸 Photo library permission limited")
            @unknown default:
                print("📸 Photo library permission unknown status")
            }
        }
    }
    
    private func handleStoryUpload(image: UIImage, progressCallback: @escaping (Double, String) -> Void) {
        print("📸 NativeStoryCameraView: handleStoryUpload called")
        
        guard let eventID = eventID else {
            print("❌ No eventID provided for story upload")
            progressCallback(0.0, "No event ID")
            return
        }
        
        // Set the selected image for the parent view
        selectedImage = image
        
        // Start upload process with immediate feedback
        progressCallback(0.1, "Preparing upload...")
        
        // Create story upload view model
        let uploadViewModel = StoryUploadViewModel()
        uploadViewModel.selectedImage = image
        
        Task {
            do {
                // Quick progress updates for better UX
                await MainActor.run {
                    progressCallback(0.2, "Optimizing image...")
                }
                
                // Small delay to show progress
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                
                await MainActor.run {
                    progressCallback(0.4, "Uploading story...")
                }
                
                // Upload the story
                await uploadViewModel.uploadStory(image: image, eventID: eventID)
                
                await MainActor.run {
                    progressCallback(0.9, "Finalizing...")
                }
                
                // Small delay for final step
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                
                // Small delay before showing success to ensure UI is stable
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
                await MainActor.run {
                    print("📸 NativeStoryCameraView: Setting progress to 100%")
                    progressCallback(1.0, "Story uploaded successfully!")
                }
                
                // SUCCESS! Set uploadCompleted flag to indicate story was uploaded
                // This allows onDismiss() to distinguish between upload success vs cancel
                await MainActor.run {
                    print("📸 NativeStoryCameraView: Upload successful - setting uploadCompleted = true")
                    print("📸 StateManager uploadCompleted: \(self.stateManager.uploadCompleted) -> true")
                    print("📸 StateManager isDismissing: \(self.stateManager.isDismissing)")
                    self.stateManager.uploadCompleted = true
                }
                
                print("📸 NativeStoryCameraView: Success screen should now be visible")
                print("📸 Waiting for user to click 'Back to Event' button")
                // FullScreenPhotoPreview will show confetti + "Back to Event" button
                // User clicks button → onDismiss() checks uploadCompleted → callback + dismiss
                
            } catch {
                print("❌ Story upload failed: \(error)")
                await MainActor.run {
                    progressCallback(0.0, "Upload failed - \(error.localizedDescription)")
                }
                
                // Don't set isDismissing on error - allow user to retry or cancel
                // If they press cancel/X button, onDismiss will return to camera
            }
        }
    }
    
    // MARK: - Debug Helper
    private func dumpCameraState(_ tag: String = "") {
        print("🔎 CameraState[\(tag)] -> flowState: \(String(describing: stateManager.flowState)), hasAppeared: \(stateManager.hasAppeared), isDismissing: \(stateManager.isDismissing), photoTaken: \(stateManager.photoTaken)")
    }
}