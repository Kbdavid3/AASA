//
//  StoryUploadView.swift
//  KiccBacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import AVFoundation
import Photos
import Combine

// MARK: - StoryUploadView
struct StoryUploadView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentation
    
    let eventID: String
    let onStoryUploaded: (() -> Void)? // Add callback for successful upload
    
    @StateObject private var viewModel = StoryUploadViewModel()
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Error"
    
    init(eventID: String, onStoryUploaded: (() -> Void)? = nil) {
        self.eventID = eventID
        self.onStoryUploaded = onStoryUploaded
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                HStack {
                    Button(action: {
                        presentation.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Add Story")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Invisible spacer to center the title
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding()
                
                Spacer()
                
                // Action buttons - hide after successful upload
                if !viewModel.uploadCompleted {
                    VStack(spacing: 20) {
                        // Take Photo button
                        Button(action: {
                            showCamera = true
                        }) {
                            HStack {
                                Image(systemName: "camera")
                                    .font(.title2)
                                Text("Take Photo")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Upload Photo button
                        Button(action: {
                            showImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title2)
                                Text("Upload Photo")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 40)
                } else {
                    // Show success message after upload
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Story Uploaded Successfully!")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Your story is now live and visible to event attendees.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
            }
        }
        .onAppear {
            viewModel.checkPermissions()
            // Set the upload success callback
            viewModel.onUploadSuccess = onStoryUploaded
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(isPresented: $showImagePicker, selectedImage: $viewModel.selectedImage, aspectRatio: 9.0/16.0)
                .onDisappear {
                    // If image was selected, apply crop and upload it directly
                    if let selectedImage = viewModel.selectedImage?.cropTo9x16() {
                        viewModel.selectedImage = selectedImage
                        uploadStory()
                    }
                }
        }
        .fullScreenCover(isPresented: $showCamera) {
            NativeStoryCameraView(selectedImage: $viewModel.selectedImage, eventID: eventID) {
                // Story uploaded successfully - user clicked "Back to Event" after seeing confetti
                onStoryUploaded?()
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onReceive(viewModel.$errorMessage) { errorMessage in
            if let errorMessage = errorMessage {
                if errorMessage.contains("successfully") {
                    alertTitle = "Success"
                    alertMessage = errorMessage
                } else {
                    alertTitle = "Upload Error"
                    alertMessage = errorMessage
                }
                showAlert = true
                viewModel.clearError()
            }
        }
    }
    
    private func uploadStory() {
        guard let image = viewModel.selectedImage else {
            showError("No image selected")
            return
        }
        
        // Validate image size and format
        guard image.size.width > 0 && image.size.height > 0 else {
            showError("Invalid image format")
            return
        }
        
        // Check if image is too large (prevent memory issues)
        let maxDimension: CGFloat = 8000 // Increased from 4000 to 8000
        if image.size.width > maxDimension || image.size.height > maxDimension {
            // Instead of showing error, let's optimize the image
            let optimizedImage = optimizeImageForUpload(image, maxDimension: maxDimension)
            Task {
                do {
                    await uploadStoryWithRetry(image: optimizedImage, eventID: eventID, retryCount: 0)
                } catch {
                    await MainActor.run {
                        self.showError("Upload failed: \(error.localizedDescription)")
                    }
                }
            }
            return
        }
        
        // Optimize image for file size to ensure it's under 10MB
        let finalImage = optimizeImageForFileSize(image)
        
        // Prevent multiple uploads
        guard !viewModel.isLoading else {
            return
        }
        
        // Add retry mechanism with better error handling
        Task {
            do {
                await uploadStoryWithRetry(image: finalImage, eventID: eventID, retryCount: 0)
            } catch {
                await MainActor.run {
                    self.showError("Upload failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func uploadStoryWithRetry(image: UIImage, eventID: String, retryCount: Int) async {
        do {
            await viewModel.uploadStory(image: image, eventID: eventID)
        } catch {
            if retryCount < 2 && shouldRetry(error: error) {
                // Wait before retrying
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await uploadStoryWithRetry(image: image, eventID: eventID, retryCount: retryCount + 1)
            } else {
                // Show error after max retries
                await MainActor.run {
                    self.showError("Upload failed after \(retryCount + 1) attempts. Please try again later.")
                }
            }
        }
    }
    
    private func shouldRetry(error: Error) -> Bool {
        let errorMessage = error.localizedDescription.lowercased()
        return errorMessage.contains("timeout") || 
               errorMessage.contains("network") || 
               errorMessage.contains("connection")
    }
    
    private func showError(_ message: String) {
        alertTitle = "Error"
        alertMessage = message
        showAlert = true
    }
    
    private func optimizeImageForUpload(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let imageSize = image.size
        let maxSize = max(imageSize.width, imageSize.height)
        
        // If image is already within limits, return as is
        if maxSize <= maxDimension {
            return image
        }
        
        // Calculate scale factor to fit within max dimension
        let scale = maxDimension / maxSize
        let newWidth = imageSize.width * scale
        let newHeight = imageSize.height * scale
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        // Create graphics context and draw resized image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    private func optimizeImageForFileSize(_ image: UIImage) -> UIImage {
        // Start with high quality and reduce if needed
        var compressionQuality: CGFloat = 0.8
        var optimizedImage = image
        
        // Try to get file size under 10MB
        while compressionQuality > 0.1 {
            if let imageData = optimizedImage.jpegData(compressionQuality: compressionQuality) {
                let fileSizeInMB = Double(imageData.count) / (1024 * 1024)
                
                // If file size is under 10MB, we're good
                if fileSizeInMB <= 10.0 {
                    break
                }
                
                // If still too large, reduce quality and try again
                compressionQuality -= 0.1
            } else {
                break
            }
        }
        
        // If still too large after quality reduction, resize the image
        if let imageData = optimizedImage.jpegData(compressionQuality: compressionQuality) {
            let fileSizeInMB = Double(imageData.count) / (1024 * 1024)
            
            if fileSizeInMB > 10.0 {
                // Resize image to reduce file size
                let scale = sqrt(10.0 / fileSizeInMB) // Calculate scale to get under 10MB
                let newWidth = optimizedImage.size.width * scale
                let newHeight = optimizedImage.size.height * scale
                let newSize = CGSize(width: newWidth, height: newHeight)
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                optimizedImage.draw(in: CGRect(origin: .zero, size: newSize))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                optimizedImage = resizedImage ?? optimizedImage
            }
        }
        
        return optimizedImage
    }
}

// MARK: - StoryUploadViewModel
@MainActor
class StoryUploadViewModel: ObservableObject {
    
    @Published var selectedImage: UIImage?
    @Published var isLoading: Bool = false
    @Published var uploadProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var uploadCompleted: Bool = false // Add flag for upload completion
    
    var onUploadSuccess: (() -> Void)? // Add callback for successful upload
    
    // MARK: - Image Selection
    func resetSelection() {
        selectedImage = nil
        uploadProgress = 0.0
        clearError()
    }
    
    // MARK: - Permissions
    func checkPermissions() {
        checkCameraPermission()
        checkPhotoLibraryPermission()
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { _ in }
        case .denied, .restricted:
            showPermissionError("Camera access is required to take photos")
        @unknown default:
            break
        }
    }
    
    private func checkPhotoLibraryPermission() {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            break
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { _ in }
        case .denied, .restricted:
            showPermissionError("Photo library access is required to select images")
        case .limited:
            break
        @unknown default:
            break
        }
    }
    
    private func showPermissionError(_ message: String) {
        errorMessage = message
    }
    
    // MARK: - Upload
    func uploadStory(image: UIImage, eventID: String) async {
        guard let currentUserID = UserManager.shared.currentUserID else {
            showError("User not authenticated")
            return
        }
        
        guard !eventID.isEmpty else {
            showError("Invalid event ID")
            return
        }
        
        // Set loading state immediately
        await MainActor.run {
            isLoading = true
            uploadProgress = 0.0
        }
        
        do {
            // Update progress - Starting upload
            await MainActor.run {
                self.uploadProgress = 0.2
            }
            
            let storyID = UUID().uuidString
            
            // Fix image orientation before upload to prevent rotation issues
            let orientedImage = image.fixOrientation()
            
            // Simple image upload like event banners - no complex processing
            guard let imageData = orientedImage.jpegData(compressionQuality: 0.8) else {
                await MainActor.run {
                    self.isLoading = false
                    self.uploadProgress = 0.0
                    self.showError("Failed to process image")
                }
                return
            }
            
            // Upload image using the same method as event banners
            let uploadResult = try await withTimeout(seconds: 60) {
                try await self.uploadImageSimple(data: imageData, storyID: storyID)
            }
            
            // Update progress - Upload complete, creating story
            await MainActor.run {
                self.uploadProgress = 0.8
            }
            
            // Create story with timeout protection
            let story = Story(
                storyID: storyID,
                creatorID: currentUserID,
                eventID: eventID,
                viewedByUserIDs: [currentUserID],
                imageUrlString: uploadResult,
                visibleTill: Date().addDays(1),
                createdAt: Date(),
                isFeatured: false,
                likedByUserIDs: []
            )
            
            try await withTimeout(seconds: 30) {
                try await StoryManager.shared.create(story: story)
            }
            
            // Success
            await MainActor.run {
                self.isLoading = false
                self.uploadProgress = 1.0
                self.uploadCompleted = true
                self.showSuccess("Story uploaded successfully! Your story is now live and visible to event attendees.")
            }
            
            // Call the success callback
            await MainActor.run {
                self.onUploadSuccess?()
            }
            
            // Dismiss after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // Note: Dismissal is handled by the parent view
                // The view will be dismissed automatically when upload completes
            }
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.uploadProgress = 0.0
                if let timeoutError = error as? TimeoutError {
                    self.showError("Image processing timed out. Please try with a smaller image.")
                } else {
                    self.showError("Upload failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Helper function to add timeout to async operations
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            // Safe unwrap of group.next()
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            group.cancelAll()
            return result
        }
    }
    
    // Custom timeout error
    private struct TimeoutError: Error {
        let localizedDescription = "Operation timed out"
    }
    
    private func uploadImageSimple(data: Data, storyID: String) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            // Use the same approach as event banners
            let fileName = "\(storyID).jpg"
            
            FirestoreService.uploadImage(with: data, fileName: fileName, withChild: "stories/\(storyID)/\(fileName)") { result in
                switch result {
                case .success(let status):
                    switch status {
                    case .uploaded(withURL: let url):
                        if let url = url {
                            continuation.resume(returning: url)
                        } else {
                            continuation.resume(throwing: StoryManagerError.uploadFailed("No URL returned"))
                        }
                    case .failed(withError: let error):
                        continuation.resume(throwing: StoryManagerError.uploadFailed(error.localizedDescription))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Error Handling
    func showError(_ message: String) {
        errorMessage = message
    }
    
    func showSuccess(_ message: String) {
        errorMessage = message
        // Provide haptic feedback for success
        HapticGenerator.medium.impactOccurred()
        // Clear success message after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.clearError()
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Cleanup
    func cleanup() {
        selectedImage = nil
        isLoading = false
        uploadProgress = 0.0
        clearError()
        
        // Force garbage collection to free memory
        autoreleasepool {
            // Clear any cached images
            selectedImage = nil
        }
    }
    
    // Nonisolated cleanup for deinit
    nonisolated func cleanupForDeinit() {
        // No cleanup needed in deinit - resources will be automatically cleaned up
        // when the object is deallocated
    }
    
    deinit {
        cleanupForDeinit()
    }
}

// MARK: - StoryUploadHeaderView
struct StoryUploadHeaderView: View {
    
    let onDismiss: () -> Void
    let onCamera: () -> Void
    let onGallery: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: onCamera) {
                    Image(systemName: "camera")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                
                Button(action: onGallery) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

// MARK: - StoryUploadEmptyView
struct StoryUploadEmptyView: View {
    
    let onCamera: () -> Void
    let onGallery: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "camera.fill")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.6))
            
            VStack(spacing: 16) {
                Text("Share Your Moment")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Take a photo or choose from your gallery to create a story")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 12) {
                Button(action: onCamera) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Take Photo")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                Button(action: onGallery) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Choose from Gallery")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - StoryUploadPreviewView
struct StoryUploadPreviewView: View {
    
    let image: UIImage
    let onRetake: () -> Void
    let onCrop: () -> Void
    let onUpload: () -> Void
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: 400)
                .cornerRadius(12)
                .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                Button(action: onRetake) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Retake")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                }
                .disabled(isLoading)
                
                Button(action: onCrop) {
                    HStack {
                        Image(systemName: "crop")
                        Text("Crop")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                }
                .disabled(isLoading)
                
                Button(action: onUpload) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "paperplane")
                        }
                        Text(isLoading ? "Uploading..." : "Upload Story")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isLoading ? Color.gray : Color.blue)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - StoryUploadLoadingView
struct StoryUploadLoadingView: View {
    
    let progress: Double
    
    var body: some View {
        VStack(spacing: 20) {
            if progress >= 1.0 {
                // Success state
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .scaleEffect(1.2)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: progress)
                
                Text("Upload Complete!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Your story is now live")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
            } else {
                // Loading state
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                    .frame(width: 200)
                
                Text("Uploading Story...")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}



// MARK: - StoryCameraView
struct StoryCameraView: View {
    
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = StoryUploadViewViewModel()
    
    // Crop state
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var isInCropMode = false
    
    var body: some View {
        ZStack {
            if let image = model.frame {
                // Camera preview (only show when not in crop mode)
                if !model.hasCapturedImage {
                    FrameView(image: image, isFrontCamera: model.cameraOrientation == .front)
                }
                
                // Captured image with crop overlay when image is captured
                if model.hasCapturedImage, let capturedImage = model.pickedImage {
                    GeometryReader { geometry in
                        ZStack {
                            // Captured image background with gestures
                            Image(uiImage: capturedImage)
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
                            
                            // Improved crop overlay
                            CropOverlayImproved(aspectRatio: 9.0/16.0, geometry: geometry)
                                .allowsHitTesting(false) // Don't block gestures
                        }
                    }
                }
                
                // Camera controls (only show when not in crop mode, no captured image, and camera is ready)
                if !isInCropMode && !model.hasCapturedImage && model.isCameraReady {
                    VStack {
                        // Top controls
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                CircleIcon(systemName: "xmark")
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                        
                        Spacer()
                        
                        // Bottom controls
                        VStack(spacing: 30) {
                            // Capture button
                            Button {
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    model.captureTapped()
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 80, height: 80)
                                    
                                    Circle()
                                        .stroke(Color.appColor, lineWidth: 4)
                                        .frame(width: 64, height: 64)
                                }
                            }
                            .scaleEffect(model.isCapturing ? 0.9 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: model.isCapturing)
                            
                            // Control buttons
                            HStack(spacing: 40) {
                                Button {
                                    HapticGenerator.light.impactOccurred()
                                    model.isFlashOn.toggle()
                                } label: {
                                    let img = model.isFlashOn ? "bolt.fill" : "bolt.slash"
                                    CircleIcon(systemName: img, color: model.isFlashOn ? .yellow : .white)
                                }
                                
                                Button {
                                    model.cameraOrientation.toggle()
                                } label: {
                                    CircleIcon(systemName: "camera.rotate")
                                }
                                .onChange(of: model.cameraOrientation) { newValue in
                                    model.switchCamera(to: newValue)
                                }
                            }
                        }
                        .padding(.bottom, 50)
                    }
                } else {
                    // Crop mode controls
                    VStack {
                        // Top controls for crop mode
                        HStack {
                            Button {
                                // Reset to camera mode
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isInCropMode = false
                                    model.pickedImage = nil
                                    resetCropState()
                                }
                            } label: {
                                Image(systemName: "arrow.left")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            Button {
                                resetCropState()
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                        
                        Spacer()
                        
                        // Bottom controls for crop mode
                        VStack(spacing: 20) {
                            // Instructions
                            Text("Pinch to zoom • Drag to move")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            
                            // Upload button
                            Button {
                                cropAndUpload()
                            } label: {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 16, weight: .semibold))
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
                
                // Front flash overlay
                GeometryReader { geometry in
                    Rectangle()
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height,
                            alignment: .center)
                        .background(Color.white)
                        .showIf(model.showFrontFlash)
                }
            } else if let error = model.error {
                VStack(spacing: 20) {
                    Text("Camera Error")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(error.localizedDescription)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("Retry Camera") {
                        model.forceRestartCamera()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.appColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            } else {
                // Loading state
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.appColor))
                        .scaleEffect(1.5)
                    
                    Text(model.isCameraReady ? "Camera Ready" : "Starting camera...")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                        .padding(.top, 20)
                    
                    if !model.isCameraReady {
                        Text("This may take a few seconds")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 14, weight: .regular))
                            .padding(.top, 8)
                    }
                    
                    // Debug information
                    if !model.debugMessage.isEmpty {
                        Text(model.debugMessage)
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 12, weight: .regular))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            }
        }
        .onAppear {
            model.startCamera()
            
            // Add timeout to show error if camera doesn't start
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if model.frame == nil && model.error == nil {
                    print("⏰ Camera timeout - no frames received")
                }
            }
        }
        .onDisappear {
            // Cleanup if needed
            model.cleanup()
        }
        .onChange(of: model.pickedImage) { image in
            if let image = image {
                // Instead of dismissing, switch to crop mode
                withAnimation(.easeInOut(duration: 0.3)) {
                    isInCropMode = true
                    setupInitialCropPosition()
                }
            }
        }
    }
    
    @ViewBuilder
    func CircleIcon(systemName: String, color: Color = .white) -> some View {
        Circle()
            .fill(.clear)
            .frame(width: 44, height: 44)
            .background(Color.black.opacity(0.4))
            .clipShape(Circle())
            .overlay(
                Image(systemName: systemName)
                    .foregroundColor(color)
                    .font(.system(size: 18, weight: .medium))
            )
    }
    
    // MARK: - Crop Functions
    private func setupInitialCropPosition() {
        scale = 1.0
        offset = .zero
        lastScale = 1.0
        lastOffset = .zero
    }
    
    private func resetCropState() {
        withAnimation(.easeInOut(duration: 0.3)) {
            setupInitialCropPosition()
        }
    }
    
    private func cropAndUpload() {
        guard let image = model.pickedImage else { return }
        
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
            selectedImage = croppedImage
            dismiss()
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
    
    private func constrainImageToCropArea(geometry: GeometryProxy) {
        guard let image = model.pickedImage else { return }
        
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
}

// MARK: - Improved Crop Overlay
struct CropOverlayImproved: View {
    let aspectRatio: CGFloat
    let geometry: GeometryProxy
    
    var body: some View {
        let screenSize = geometry.size
        let cropSize = calculateCropSize(screenSize: screenSize, aspectRatio: aspectRatio)
        let cropPosition = calculateCropPosition(screenSize: screenSize, cropSize: cropSize)
        
        ZStack {
            // Semi-transparent overlay outside crop area
            Rectangle()
                .fill(Color.black.opacity(0.7))
                .mask(
                    Rectangle()
                        .overlay(
                            Rectangle()
                                .frame(width: cropSize.width, height: cropSize.height)
                                .position(cropPosition)
                                .blendMode(.destinationOut)
                        )
                )
            
            // Crop guide border with improved visibility
            Rectangle()
                .stroke(Color.white, lineWidth: 2.0)
                .frame(width: cropSize.width, height: cropSize.height)
                .position(cropPosition)
            
            // Corner guides (improved)
            ForEach(0..<4) { corner in
                CropCornerGuideImproved(corner: corner)
                    .frame(width: 24, height: 24)
                    .position(
                        x: getCornerPosition(corner: corner, cropSize: cropSize, cropPosition: cropPosition).x,
                        y: getCornerPosition(corner: corner, cropSize: cropSize, cropPosition: cropPosition).y
                    )
            }
            
            // Center guides for better alignment
            VStack {
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 1, height: cropSize.height)
                    .position(x: cropPosition.x, y: cropPosition.y)
            }
            
            HStack {
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: cropSize.width, height: 1)
                    .position(x: cropPosition.x, y: cropPosition.y)
            }
        }
    }
    
    private func calculateCropSize(screenSize: CGSize, aspectRatio: CGFloat) -> CGSize {
        let screenAspectRatio = screenSize.width / screenSize.height
        
        if screenAspectRatio > aspectRatio {
            // Screen is wider than target aspect ratio - use full height
            let height = screenSize.height - 120 // Leave space for top and bottom controls
            let width = height * aspectRatio
            return CGSize(width: width, height: height)
        } else {
            // Screen is taller than target aspect ratio - use full width
            let width = screenSize.width
            let height = width / aspectRatio
            return CGSize(width: width, height: height)
        }
    }
    
    private func calculateCropPosition(screenSize: CGSize, cropSize: CGSize) -> CGPoint {
        let centerX = screenSize.width / 2
        let centerY = screenSize.height / 2
        return CGPoint(x: centerX, y: centerY)
    }
    
    private func getCornerPosition(corner: Int, cropSize: CGSize, cropPosition: CGPoint) -> CGPoint {
        let halfWidth = cropSize.width / 2
        let halfHeight = cropSize.height / 2
        
        switch corner {
        case 0: // Top-left
            return CGPoint(x: cropPosition.x - halfWidth, y: cropPosition.y - halfHeight)
        case 1: // Top-right
            return CGPoint(x: cropPosition.x + halfWidth, y: cropPosition.y - halfHeight)
        case 2: // Bottom-left
            return CGPoint(x: cropPosition.x - halfWidth, y: cropPosition.y + halfHeight)
        case 3: // Bottom-right
            return CGPoint(x: cropPosition.x + halfWidth, y: cropPosition.y + halfHeight)
        default:
            return CGPoint.zero
        }
    }
}

struct CropCornerGuideImproved: View {
    let corner: Int
    
    var body: some View {
        ZStack {
            switch corner {
            case 0: // Top-left
                VStack {
                    HStack {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 16, height: 3)
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 3, height: 16)
                        Spacer()
                    }
                }
            case 1: // Top-right
                VStack {
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 16, height: 3)
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 3, height: 16)
                    }
                }
            case 2: // Bottom-left
                VStack {
                    HStack {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 3, height: 16)
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 16, height: 3)
                        Spacer()
                    }
                }
            case 3: // Bottom-right
                VStack {
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 3, height: 16)
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 16, height: 3)
                    }
                }
            default:
                EmptyView()
            }
        }
    }
}

// MARK: - Frame View
struct FrameView: View {
    
    var image: CGImage?
    var isFrontCamera: Bool = false
    private let label = Text("Camera feed")
    
    var body: some View {
        if let image = image {
            GeometryReader { geometry in
                Image(image, scale: 1.0, orientation: isFrontCamera ? .upMirrored : .up, label: label)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height,
                        alignment: .center)
                    .clipped()
            }
        } else {
            Text("No camera available")
                .foregroundColor(.white)
        }
    }
}





// MARK: - StoryCameraViewController (Legacy - keeping for compatibility)
struct StoryCameraViewController: UIViewControllerRepresentable {
    
    @Binding var selectedImage: UIImage?
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: StoryCameraViewController
        
        init(_ parent: StoryCameraViewController) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            var finalImage: UIImage?
            
            if let editedImage = info[.editedImage] as? UIImage {
                finalImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                finalImage = originalImage
            }
            
            // Apply 9:16 aspect ratio cropping for stories
            if let image = finalImage {
                finalImage = cropImageToAspectRatio(image, aspectRatio: 9.0/16.0)
            }
            
            parent.selectedImage = finalImage
            parent.onDismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onDismiss()
        }
        
        // Helper function to crop image to 9:16 aspect ratio
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
}

// MARK: - DefaultCameraView (Simple iOS Camera)
struct DefaultCameraView: View {
    
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var showImagePicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Take Photo")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Placeholder to balance the layout
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                // Camera icon
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Tap to open camera")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Camera button
                Button {
                    showImagePicker = true
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Open Camera")
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
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(
                isPresented: $showImagePicker,
                selectedImage: $selectedImage,
                sourceType: .camera
            )
            .onDisappear {
                // If image was selected, dismiss this view
                if selectedImage != nil {
                    dismiss()
                }
            }
        }
        .alert("Camera Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

// MARK: - Preview
struct StoryUploadView_Previews: PreviewProvider {
    static var previews: some View {
        StoryUploadView(eventID: "test-event-id")
    }
}
