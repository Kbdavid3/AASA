import SwiftUI

struct OnboardingProfilePictureView: View {
    @State private var showContent = false
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var userName: String = ""
    
    let themeColor = Color(red: 242/255, green: 108/255, blue: 146/255)
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
            // Header section with title and progress (matching JoinEventView exactly)
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(showContent ? 1 : 0)
                        .offset(x: showContent ? 0 : -50)
                    
                    Text("KiccBacc")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(themeColor)
                        .opacity(showContent ? 1 : 0)
                        .offset(x: showContent ? 0 : -50)
                }
                
                Text("How should people see you?")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .opacity(showContent ? 1 : 0)
                    .offset(x: showContent ? 0 : -30)
                
                // Progress Bar (matching JoinEventView style)
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    Rectangle()
                        .fill(themeColor)
                        .frame(width: UIScreen.main.bounds.width * 0.6, height: 4)
                        .cornerRadius(2)
                }
                .opacity(showContent ? 1 : 0)
                .offset(x: showContent ? 0 : -20)
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            
            Spacer()
            
            // Profile card section
            VStack(spacing: 0) {
                // Pink profile card
                ZStack {
                    // Card background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(themeColor)
                        .frame(width: 280, height: 350)
                    
                    VStack(spacing: 20) {
                        // Profile picture with edit button
                        ZStack {
                            // Profile picture circle - tappable
                            Button(action: {
                                showImagePicker = true
                            }) {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Group {
                                            if let selectedImage = selectedImage {
                                                Image(uiImage: selectedImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 120, height: 120)
                                                    .clipShape(Circle())
                                            } else {
                                                // Placeholder when no image is selected
                                                Circle()
                                                    .fill(Color.white.opacity(0.2))
                                                    .frame(width: 120, height: 120)
                                                    .overlay(
                                                                                                            Image(systemName: "person.fill")
                                                        .font(.system(size: 40))
                                                        .foregroundColor(.white.opacity(0.7))
                                                    )
                                            }
                                        }
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .scaleEffect(selectedImage != nil ? 1.0 : 0.95)
                            .animation(.easeInOut(duration: 0.2), value: selectedImage != nil)
                            
                            // Edit button in top right corner
                            VStack {
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        showImagePicker = true
                                    }) {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Image("editPen")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 16, height: 16)
                                                    .foregroundColor(.black)
                                            )
                                    }
                                }
                                .offset(x: 15, y: -15)
                                Spacer()
                            }
                            .frame(width: 120, height: 120)
                        }
                        
                        // Name
                        Text(userName.isEmpty ? "Name" : userName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Dashes for pseudo information
                        HStack(spacing: 8) {
                            ForEach(0..<3, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.white.opacity(0.6))
                                    .frame(width: 30, height: 2)
                            }
                        }
                        
                        // User pictures and followers section
                        HStack(spacing: 16) {
                            // Clubbed user pictures
                            HStack(spacing: -8) {
                                ForEach(0..<4, id: \.self) { index in
                                    Circle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 1)
                                        )
                                }
                            }
                            
                            // Followers count and text
                            VStack(alignment: .leading, spacing: 2) {
                                Text("11.5K")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Followers")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        // Follow button and message button (static - not clickable)
                        HStack(spacing: 12) {
                            // Follow button - static
                            Text("Follow")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(themeColor)
                                .frame(width: 80, height: 32)
                                .background(Color.white)
                                .cornerRadius(16)
                            
                            // Message button - static
                            Image(systemName: "message.fill")
                                .font(.system(size: 14))
                                .foregroundColor(themeColor)
                                .frame(width: 32, height: 32)
                                .background(Color.white)
                                .cornerRadius(16)
                        }
                    }
                    .padding(.vertical, 20)
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)
                .animation(.easeOut(duration: 0.8).delay(0.3), value: showContent)
            }
            
            Spacer()
            
            // Continue button (matching JoinEventView style)
            Button(action: {
                print("🖼️ OnboardingProfilePictureView: Continue button tapped")
                // Validate that profile picture is selected
                guard let selectedImage = selectedImage else {
                    print("🖼️ OnboardingProfilePictureView: No image selected, not continuing")
                    return // Don't continue if no profile picture is selected
                }
                
                print("🖼️ OnboardingProfilePictureView: Image selected, saving and posting notification")
                // Save the selected image to UserDefaults for use in story username view
                if let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
                    UserDefaults.standard.set(imageData, forKey: "onboarding_profile_image")
                }
                NotificationCenter.default.post(name: .profilePictureCompleted, object: nil)
            }) {
                Text("Continue")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .background(selectedImage == nil ? themeColor.opacity(0.5) : themeColor)
                    .cornerRadius(14)
            }
            .disabled(selectedImage == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(0.6), value: showContent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            
            // Back Button Overlay
            Button(action: {
                NotificationCenter.default.post(name: .onboardingBackTapped, object: nil)
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
            }
        }
        .onAppear {
            // Load the name from UserDefaults
            if let savedName = UserDefaults.standard.string(forKey: "onboarding_name"), !savedName.isEmpty {
                userName = savedName
            } else {
                userName = "Name" // Default placeholder
            }
            
            // Always start with no profile image - user must select one
            selectedImage = nil
            
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
        .fullScreenCover(isPresented: $showImagePicker) {
            ImagePicker(isPresented: $showImagePicker, selectedImage: $selectedImage, allowsEditing: true)
        }
        .onChange(of: showImagePicker) { newValue in
            print("🖼️ OnboardingProfilePictureView: showImagePicker changed to: \(newValue)")
            if !newValue && selectedImage != nil {
                print("🖼️ OnboardingProfilePictureView: Image picker dismissed with image selected")
            }
        }
    }
}



struct OnboardingProfilePictureView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingProfilePictureView()
    }
}




