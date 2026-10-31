import SwiftUI

struct OnboardingStoryUsernameView: View {
    @State private var showContent = false
    @State private var username: String = ""
    @State private var selectedImage: UIImage?
    @State private var isEditingUsername = false
    @State private var isCheckingUsername = false
    @State private var usernameValidationMessage = ""
    @State private var isUsernameValid = true
    @State private var debounceTimer: Timer?
    @State private var hasUserStartedTyping = false
    
    let themeColor = Color(red: 242/255, green: 108/255, blue: 146/255)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Black background
                Color.black
                    .ignoresSafeArea()
                
                // Back Button Overlay - Positioned to match profile picture screen
                Button(action: {
                    NotificationCenter.default.post(name: .onboardingBackTapped, object: nil)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                }
                
                VStack(spacing: 0) {
                    // Header section matching other onboarding screens
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
                        
                        Text("Select a username")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .opacity(showContent ? 1 : 0)
                            .offset(x: showContent ? 0 : -30)
                        
                        // Progress Bar (75% to match story username step)
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 4)
                                .cornerRadius(2)
                            Rectangle()
                                .fill(themeColor)
                                .frame(width: geometry.size.width * 0.75, height: 4)
                                .cornerRadius(2)
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(x: showContent ? 0 : -20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Three story mockups layout - FIXED POSITIONING to prevent overflow
                    HStack(spacing: 0) {
                        // Left story - partially visible, flows off left edge
                        StoryMockupView(
                            imageName: "party",
                            isHighlighted: false,
                            username: username,
                            isCenter: false,
                            selectedImage: selectedImage,
                            geometry: geometry,
                            usernameBinding: .constant("")
                        )
                        .frame(width: geometry.size.width * 0.2, height: geometry.size.height * 0.35)
                        .opacity(0.6)
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 0,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 16,
                                topTrailingRadius: 16
                            )
                        )
                        .offset(x: -geometry.size.width * 0.05)
                        
                        // Center story - MAIN FOCUS - largest and most prominent
                        StoryMockupView(
                            imageName: "username",
                            isHighlighted: true,
                            username: username,
                            isCenter: true,
                            selectedImage: selectedImage,
                            geometry: geometry,
                            usernameBinding: $username
                        )
                        .frame(width: geometry.size.width * 0.6, height: geometry.size.height * 0.45)
                        .zIndex(1)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        
                        // Right story - partially visible, flows off right edge
                        StoryMockupView(
                            imageName: "cinemaDown",
                            isHighlighted: false,
                            username: username,
                            isCenter: false,
                            selectedImage: selectedImage,
                            geometry: geometry,
                            usernameBinding: .constant("")
                        )
                        .frame(width: geometry.size.width * 0.2, height: geometry.size.height * 0.35)
                        .opacity(0.6)
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 16,
                                bottomLeadingRadius: 16,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 0
                            )
                        )
                        .offset(x: geometry.size.width * 0.05)
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.8)
                    .animation(.easeOut(duration: 0.8).delay(0.3), value: showContent)
                    .animation(.none, value: username) // Prevent mockup movement when typing
                        
                    
                    Spacer()
                    
                    // Validation message and explanation
                    VStack(spacing: 8) {
                        // Fixed height container for validation messages to prevent mockup movement
                        VStack(spacing: 8) {
                            // Validation message - only show after user has started typing
                            if hasUserStartedTyping && !usernameValidationMessage.isEmpty {
                                HStack {
                                    Image(systemName: isUsernameValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                        .foregroundColor(isUsernameValid ? .green : .orange)
                                    Text(usernameValidationMessage)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(isUsernameValid ? .green : .orange)
                                }
                                .opacity(showContent ? 1 : 0)
                            }
                            
                            // Loading indicator for username checking - only show after user has started typing
                            if hasUserStartedTyping && isCheckingUsername {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: themeColor))
                                    Text("Checking availability...")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .opacity(showContent ? 1 : 0)
                            }
                        }
                        .frame(height: 40) // Fixed height to prevent mockup movement
                        
                        // Explanation text - made bigger
                        Text("Edit your handle. This is how it\nwill look after posting a story.")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.6), value: showContent)
                    }
                    
                    Spacer()
                    
                    // Continue button matching other onboarding screens
                    Button(action: {
                        // Save username and proceed to next step
                        let finalUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !finalUsername.isEmpty && isUsernameValid {
                            UserDefaults.standard.set(finalUsername, forKey: "onboarding_username")
                            NotificationCenter.default.post(name: .storyUsernameCompleted, object: nil)
                        }
                    }) {
                        Text("Continue")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(height: 60)
                            .frame(maxWidth: .infinity)
                            .background(
                                (username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !isUsernameValid || isCheckingUsername)
                                ? themeColor.opacity(0.5)
                                : themeColor
                            )
                            .cornerRadius(14)
                    }
                    .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !isUsernameValid || isCheckingUsername)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.8), value: showContent)
                }
            }
        }
        .onAppear {
            // Always start with empty username (placeholder will be shown)
            username = ""
            hasUserStartedTyping = false
            
            // Load saved profile image
            if let imageData = UserDefaults.standard.data(forKey: "onboarding_profile_image") {
                selectedImage = UIImage(data: imageData)
            }
            
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
        .ignoresSafeArea(.keyboard) // Prevent keyboard from moving the screen
        .animation(.none, value: username) // Prevent any animations when username changes
        .onChange(of: username) { newValue in
            // Mark that user has started typing when they enter any text
            if !newValue.isEmpty && !hasUserStartedTyping {
                hasUserStartedTyping = true
            }
            
            // Clear previous validation messages when user is typing
            if hasUserStartedTyping && !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                usernameValidationMessage = ""
                isUsernameValid = true
            }
            
            // Only validate if user has started typing
            if hasUserStartedTyping {
                validateUsername(newValue)
            }
        }
    }
    
    // Username validation function
    private func validateUsername(_ username: String) {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Reset state
        usernameValidationMessage = ""
        isUsernameValid = true
        
        // Basic validation - show "Type in a username" only if user has typed something before and now it's empty
        guard !trimmedUsername.isEmpty else {
            if hasUserStartedTyping {
                usernameValidationMessage = "Type in a username"
                isUsernameValid = false
            }
            // Cancel any pending availability check
            debounceTimer?.invalidate()
            return
        }
        
        // Check length
        guard trimmedUsername.count >= 3 else {
            usernameValidationMessage = "Username must be at least 3 characters"
            isUsernameValid = false
            return
        }
        
        guard trimmedUsername.count <= 15 else {
            usernameValidationMessage = "Username must be 15 characters or less"
            isUsernameValid = false
            return
        }
        
        // Check for valid characters (alphanumeric, underscore, and period)
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_."))
        guard trimmedUsername.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            usernameValidationMessage = "Username can only contain letters, numbers, underscores, and periods"
            isUsernameValid = false
            return
        }
        
        // Debounce the availability check to avoid too many Firebase queries
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            checkUsernameAvailability(trimmedUsername)
        }
    }
    
    private func checkUsernameAvailability(_ username: String) {
        isCheckingUsername = true
        
        // Check Firebase for existing users with this exact username (case-insensitive)
        UserManager.shared.getUsers(whereField: "username", isEqualTo: username.lowercased()) { [self] users in
            DispatchQueue.main.async {
                isCheckingUsername = false
                
                // Double-check that we still have the same username being validated
                let currentTrimmed = self.username.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !currentTrimmed.isEmpty && currentTrimmed.lowercased() == username.lowercased() else {
                    // User has changed the username or cleared it, don't show stale results
                    return
                }
                
                if let users = users, !users.isEmpty {
                    // Username is already taken
                    usernameValidationMessage = "Username is already taken"
                    isUsernameValid = false
                } else {
                    // Username is available
                    usernameValidationMessage = "Username is available!"
                    isUsernameValid = true
                }
            }
        }
    }
}

struct StoryMockupView: View {
    let imageName: String
    let isHighlighted: Bool
    let username: String
    let isCenter: Bool
    let selectedImage: UIImage?
    let geometry: GeometryProxy
    @Binding var usernameBinding: String
    
    let themeColor = Color(red: 242/255, green: 108/255, blue: 146/255)
    
    var body: some View {
        ZStack {
            // Story background with gradient overlay matching the design
            ZStack {
                // Background image
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaleEffect(1.05) // Zoom in image by 5%
                    .clipped()
                
                // Gradient overlay to create the warm tone like in the image
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.clear, location: 0.0),
                        .init(color: Color.orange.opacity(0.2), location: 0.3),
                        .init(color: Color.orange.opacity(0.6), location: 0.7),
                        .init(color: Color.orange.opacity(0.8), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isHighlighted ? Color.white.opacity(0.3) : Color.clear, lineWidth: isHighlighted ? 2 : 0)
            )
            
            // Story UI overlay - EXACTLY matching the image layout
            VStack(spacing: 0) {
                // Top section with progress bar
                HStack {
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: isCenter ? 3 : 2)
                            .cornerRadius(isCenter ? 1.5 : 1)
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: isCenter ? 60 : 20, height: isCenter ? 3 : 2)
                            .cornerRadius(isCenter ? 1.5 : 1)
                    }
                    Spacer()
                }
                .padding(.horizontal, isCenter ? 16 : 8)
                .padding(.top, isCenter ? 28 : 14)
                
                // Profile section - EXACTLY matching the image layout
                HStack(spacing: isCenter ? 6 : 3) {
                    // Profile picture - visible and properly sized (smaller to give more space for username)
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: isCenter ? 24 : 12, height: isCenter ? 24 : 12)
                        .overlay(
                            Group {
                                if let selectedImage = selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: isCenter ? 24 : 12, height: isCenter ? 24 : 12)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(themeColor)
                                        .frame(width: isCenter ? 24 : 12, height: isCenter ? 24 : 12)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: isCenter ? 10 : 4))
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                        )
                    
                    // Username section - VISIBLE and editable for center story (wider for longer usernames)
                    HStack(spacing: 3) {
                        if isCenter {
                            // Show actual username or placeholder with edit icon
                            ZStack(alignment: .leading) {
                                if usernameBinding.isEmpty {
                                    Text("Username")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white.opacity(0.6)) // ✅ Bright placeholder
                                        .padding(.leading, 2)    // small offset so it matches textfield cursor
                                }
                                
                                TextField("", text: $usernameBinding)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white) // actual typed text
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .lineLimit(1)
                                    
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .accentColor(.white)
                                    .tint(.white)
                                    .scaleEffect(1.0) // Prevent text from zooming
                                    
                                // Pencil icon positioned after the text
                                HStack {
                                    Spacer()
                                    
                                    Image(systemName: "pencil")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            // Side stories - show username or placeholder
                            Text(username.isEmpty ? "Username" : username)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Top right controls - always visible for center story
                    if isCenter {
                        HStack(spacing: 8) {
                            Button(action: {}) {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(.horizontal, isCenter ? 16 : 8)
                .padding(.top, isCenter ? 10 : 5)
                
                Spacer()
                
                // Bottom stats section - STATIC positioning, always visible for center story
                if isCenter {
                    VStack(alignment: .trailing, spacing: 6) {
                        // Views count with eye icon
                        HStack(spacing: 4) {
                            Spacer()
                            Image(systemName: "eye.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                            Text("22K")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        // Likes count with heart icon
                        HStack(spacing: 4) {
                            Spacer()
                            Image(systemName: "heart.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                            Text("10K")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            

        }
    }
}

struct OnboardingStoryUsernameView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingStoryUsernameView()
    }
}
