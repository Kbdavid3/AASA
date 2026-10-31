import SwiftUI

struct EventPasswordView: View {
    let event: Event
    let onPasswordCorrect: () -> Void
    let onDismiss: () -> Void
    
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showContent: Bool = false
    
    private let themeColor = Color(red: 242/255, green: 108/255, blue: 146/255) // #F26C92
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with event banner and dark overlay
                ZStack {
                    // Event banner as background
                    AsyncImage(url: URL(string: event.eventBannerUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.black.opacity(0.8))
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    
                    // Dark overlay for readability
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.8),
                            Color.black.opacity(0.9)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss keyboard when tapping background
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                
                // Main Content
                VStack(spacing: 0) {
                    // Top section with close button
                    HStack {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.3))
                                        .background(
                                            Circle()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Password prompt card
                    VStack(spacing: 24) {
                        // Lock icon and title
                        VStack(spacing: 16) {
                            // Animated lock icon
                            ZStack {
                                Circle()
                                    .fill(themeColor.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                    .background(
                                        Circle()
                                            .stroke(themeColor.opacity(0.3), lineWidth: 2)
                                    )
                                
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(themeColor)
                            }
                            .scaleEffect(showContent ? 1.0 : 0.8)
                            .opacity(showContent ? 1.0 : 0.0)
                            
                            // Title and event name
                            VStack(spacing: 8) {
                                Text("Private Event")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .opacity(showContent ? 1.0 : 0.0)
                                    .offset(y: showContent ? 0 : 20)
                                
                                Text(event.name)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .opacity(showContent ? 1.0 : 0.0)
                                    .offset(y: showContent ? 0 : 25)
                                
                                Text("Enter password to access this event")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .multilineTextAlignment(.center)
                                    .opacity(showContent ? 1.0 : 0.0)
                                    .offset(y: showContent ? 0 : 30)
                            }
                        }
                        
                        // Password input field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "key.fill")
                                    .foregroundColor(themeColor)
                                    .font(.system(size: 14))
                                
                                Text("Password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Spacer()
                            }
                            
                            SecureField("Enter event password", text: $password)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.08))
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(
                                                        showError ? Color.red.opacity(0.6) :
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                Color.white.opacity(0.2),
                                                                Color.white.opacity(0.1)
                                                            ]),
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ),
                                                        lineWidth: showError ? 2 : 1
                                                    )
                                            )
                                    }
                                )
                                .onSubmit {
                                    validatePassword()
                                }
                            
                            // Error message
                            if showError {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.system(size: 12))
                                    
                                    Text(errorMessage)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.red)
                                }
                                .opacity(showError ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 0.3), value: showError)
                            }
                        }
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 35)
                        
                        // Enter button
                        Button(action: validatePassword) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                
                                Text(isLoading ? "Checking..." : "Enter Event")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    themeColor,
                                                    themeColor.opacity(0.8)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                }
                            )
                            .disabled(isLoading || password.isEmpty)
                            .opacity(password.isEmpty ? 0.6 : 1.0)
                            .scaleEffect(isLoading ? 0.95 : 1.0)
                        }
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 40)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 40)
                    .background(
                        ZStack {
                            // Glassmorphism background
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.08))
                                .background(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.2),
                                                    Color.white.opacity(0.05)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                            
                            // Subtle inner glow
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            themeColor.opacity(0.05),
                                            Color.clear
                                        ]),
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 200
                                    )
                                )
                        }
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            // Animate content appearance
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                showContent = true
            }
        }
    }
    
    private func validatePassword() {
        guard !password.isEmpty else { return }
        
        // Reset error state
        showError = false
        isLoading = true
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Simulate network delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            
            if password == event.password {
                // Correct password - add success haptic
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.notificationOccurred(.success)
                
                // Animate success and call completion
                withAnimation(.easeInOut(duration: 0.3)) {
                    onPasswordCorrect()
                }
            } else {
                // Wrong password - add error haptic
                let errorFeedback = UINotificationFeedbackGenerator()
                errorFeedback.notificationOccurred(.error)
                
                // Show error with animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    showError = true
                    errorMessage = "Incorrect password. Please try again."
                }
                
                // Shake animation for password field
                withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
                    // This would need additional state for shake effect
                }
                
                // Clear password after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    password = ""
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showError = false
                    }
                }
            }
        }
    }
}

// Preview
struct EventPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        EventPasswordView(
            event: Event.init().displayEvent,
            onPasswordCorrect: {},
            onDismiss: {}
        )
    }
}
