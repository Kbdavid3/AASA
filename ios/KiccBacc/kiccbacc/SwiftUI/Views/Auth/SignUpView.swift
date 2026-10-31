import SwiftUI
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import AuthenticationServices
import GoogleSignIn
import CryptoKit

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showContent = false
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var alertItem: AlertItem?
    @State private var viewItem: ViewItem?
    
    // Apple Sign-In
    @State private var currentNonce: String?
    
    let themeColor = Color(red: 242/255, green: 108/255, blue: 146/255) // #F26C92
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Full Screen Background
                Image("party")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea(.all)
                    .overlay(
                        // Dark overlay for text readability
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.3),
                                Color.black.opacity(0.7),
                                Color.black.opacity(0.8)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .onTapGesture {
                        // Dismiss keyboard when tapping background
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Enhanced Header
                        HStack {
                            Button(action: { dismiss() }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                        .blur(radius: 0.5)
                                    
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .frame(maxWidth: geo.size.width)
                        
                        Spacer(minLength: 20)
                        
                        // Main Card
                        VStack(spacing: 0) {
                            // Simple Create Account Header
                            VStack(spacing: 8) {
                                Text("Create Account")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .opacity(showContent ? 1 : 0)
                                    .offset(y: showContent ? 0 : -20)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 32)
                            .padding(.top, 40) // Added top padding to shift down
                            
                            // Enhanced Input Fields
                            VStack(spacing: 20) {
                                // Email Field
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "envelope.fill")
                                            .foregroundColor(themeColor)
                                            .font(.system(size: 14))
                                        
                                        Text("Email Address")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.9))
                                        
                                        Spacer()
                                    }
                                    
                                    TextField("Enter your email", text: $email)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 16)
                                        .background(
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(Color.white.opacity(0.05))
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 16)
                                                            .stroke(
                                                                LinearGradient(
                                                                    gradient: Gradient(colors: [
                                                                        Color.white.opacity(0.2),
                                                                        Color.white.opacity(0.1)
                                                                    ]),
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                ),
                                                                lineWidth: 1
                                                            )
                                                    )
                                            }
                                        )
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                }
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 20)
                                
                                // Password Field
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(themeColor)
                                            .font(.system(size: 14))
                                        
                                        Text("Password")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.9))
                                        
                                        Spacer()
                                    }
                                    
                                    SecureField("Enter your password", text: $password)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 16)
                                        .background(
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(Color.white.opacity(0.05))
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 16)
                                                            .stroke(
                                                                LinearGradient(
                                                                    gradient: Gradient(colors: [
                                                                        Color.white.opacity(0.2),
                                                                        Color.white.opacity(0.1)
                                                                    ]),
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                ),
                                                                lineWidth: 1
                                                            )
                                                    )
                                            }
                                        )
                                }
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 25)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 32)
                            
                            // Enhanced Sign Up Buttons
                            VStack(spacing: 16) {
                                // Email Sign Up Button
                                Button(action: signUpWithEmail) {
                                    HStack(spacing: 12) {
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.9)
                                        } else {
                                            Image(systemName: "envelope.fill")
                                                .font(.system(size: 16, weight: .medium))
                                            
                                            Text("Sign Up with Email")
                                                .font(.system(size: 16, weight: .bold))
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                themeColor,
                                                themeColor.opacity(0.8)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(16)
                                    .shadow(color: themeColor.opacity(0.3), radius: 10, x: 0, y: 5)
                                }
                                .disabled(email.isEmpty || password.isEmpty || isLoading)
                                .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                                .scaleEffect(showContent ? 1 : 0.9)
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 30)
                                
                                // Divider
                                HStack {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(height: 1)
                                    
                                    Text("or")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.horizontal, 16)
                                    
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(height: 1)
                                }
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 32)
                                
                                // Social Buttons (Apple first, then Google)
                                VStack(spacing: 12) {
                                    // Apple Sign Up Button (moved to top)
                                    SignInWithAppleButton(
                                        .signUp,
                                        onRequest: { request in
                                            let nonce = randomNonceString()
                                            currentNonce = nonce
                                            request.requestedScopes = [.fullName, .email]
                                            request.nonce = sha256(nonce)
                                        },
                                        onCompletion: handleAppleSignIn
                                    )
                                    .signInWithAppleButtonStyle(.white)
                                    .frame(height: 56)
                                    .cornerRadius(16)
                                    .opacity(showContent ? 1 : 0)
                                    .offset(y: showContent ? 0 : 35)
                                    
                                    // Google Sign Up Button with official styling
                                    Button(action: signUpWithGoogle) {
                                        HStack(spacing: 12) {
                                            // Official Google logo
                                            Image("Google")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 20, height: 20)
                                            
                                            Text("Continue with Google")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.black.opacity(0.87))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                                                )
                                                .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
                                        )
                                    }
                                    .opacity(showContent ? 1 : 0)
                                    .offset(y: showContent ? 0 : 40)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                            
                            // Enhanced Privacy Policy
                            VStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.shield.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(themeColor)
                                    
                                    Text("Secure & Private")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Text("By creating an account, you agree to our Privacy Policy and Terms of Service")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.6))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .opacity(showContent ? 1 : 0)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 30)
                        }
                        .background(
                            ZStack {
                                // Main background
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.black.opacity(0.7),
                                                Color.black.opacity(0.9)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                // Glassmorphism effect
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.2),
                                                Color.white.opacity(0.05),
                                                Color.clear
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                                
                                // Subtle inner glow
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        RadialGradient(
                                            gradient: Gradient(colors: [
                                                themeColor.opacity(0.05),
                                                Color.clear
                                            ]),
                                            center: .topLeading,
                                            startRadius: 50,
                                            endRadius: 200
                                        )
                                    )
                            }
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                        .padding(.horizontal, 8) // Reduced horizontal padding
                        .padding(.bottom, 20) // Reduced bottom padding
                        .padding(.top, 20) // Added top padding
                        .frame(maxWidth: geo.size.width - 16) // Ensure it doesn't exceed screen width
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geo.size.height)
                }
                .frame(maxWidth: .infinity)
                
                // Confetti Animation Overlay (no text, just confetti)
                if showSuccess {
                    ZStack {
                        // Transparent background to allow confetti to show
                        Color.clear
                            .ignoresSafeArea()
                        
                        // Confetti Animation Only
                        ConfettiView()
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .onAppear {
            // Staggered animations for better visual flow
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
        .alert(item: $alertItem) { alertItem in
            Alert(
                title: alertItem.title,
                message: alertItem.message,
                dismissButton: alertItem.dismissButton
            )
        }
        .fullScreenCover(item: $viewItem) { viewItem in
            viewItem.viewToPresent
        }

    }
    
    // MARK: - Authentication Methods
    
    private func signUpWithEmail() {
        guard !email.isEmpty, !password.isEmpty else {
            alertItem = AlertItem(
                title: Text("Missing Information"),
                message: Text("Please enter both email and password."),
                dismissButton: .default(Text("OK"))
            )
            return
        }
        
        isLoading = true
        
        Auth.auth().createUser(withEmail: email, password: password) { [self] result, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    alertItem = AlertItem(
                        title: Text("Sign Up Failed"),
                        message: Text(error.localizedDescription),
                        dismissButton: .default(Text("OK"))
                    )
                } else if let firebaseUser = result?.user {
                    // Save basic user info to Firestore (without username for now)
                    saveUserToFirestore(firebaseUser: firebaseUser)
                }
            }
        }
    }
    
    private func saveUserToFirestore(firebaseUser: FirebaseAuth.User) {
        let db = Firestore.firestore()
        
        db.collection("users").document(firebaseUser.uid).setData([
            "userID": firebaseUser.uid,
            "email": firebaseUser.email ?? "",
            "createdAt": Date()
        ]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    alertItem = AlertItem(
                        title: Text("Error"),
                        message: Text("Account created but failed to save user data: \(error.localizedDescription)"),
                        dismissButton: .default(Text("OK"))
                    )
                } else {
                    // Show success animation first, then navigate
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showSuccess = true
                    }
                    
                    // Navigate after confetti animation (2.5 seconds)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            viewItem = ViewItem(AnyView(OnboardingCoordinatorView()), _presentationStyle: .fullScreen)
                        }
                    }
                }
            }
        }
    }
    
    private func signUpWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { 
            alertItem = AlertItem(
                title: Text("Configuration Error"),
                message: Text("Google Sign-In is not properly configured."),
                dismissButton: .default(Text("OK"))
            )
            return 
        }
        
        // Create Google Sign In configuration object
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Get the presenting view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let presentingViewController = window.rootViewController else {
            alertItem = AlertItem(
                title: Text("Error"),
                message: Text("Unable to present Google Sign-In."),
                dismissButton: .default(Text("OK"))
            )
            return
        }
        
        // Find the topmost view controller
        var topViewController = presentingViewController
        while let presented = topViewController.presentedViewController {
            topViewController = presented
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: topViewController) { [self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    let nsError = error as NSError
                    print("Google Sign In Error: \(error.localizedDescription)")
                    print("Error Code: \(nsError.code)")
                    print("Error Domain: \(nsError.domain)")
                    
                    // Check if user cancelled - don't show error for cancellation
                    // Google Sign In error codes: -2 = canceled, -4 = no current user, -5 = keychain error
                    if nsError.code == -2 || nsError.code == -4 || nsError.code == -5 {
                        print("Google Sign In cancelled by user, no current user, or keychain error")
                        return
                    }
                    
                    // Also check for specific cancellation messages
                    if error.localizedDescription.lowercased().contains("cancel") || 
                       error.localizedDescription.lowercased().contains("user cancelled") {
                        print("Google Sign In cancelled based on error message")
                        return
                    }
                    
                    alertItem = AlertItem(
                        title: Text("Google Sign In Failed"),
                        message: Text(error.localizedDescription),
                        dismissButton: .default(Text("OK"))
                    )
                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    return
                }
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                             accessToken: user.accessToken.tokenString)
                
                // Sign in with Firebase
                Auth.auth().signIn(with: credential) { [self] (authResult, error) in
                    DispatchQueue.main.async {
                        if let error = error {
                            alertItem = AlertItem(
                                title: Text("Google Sign In Failed"),
                                message: Text(error.localizedDescription),
                                dismissButton: .default(Text("OK"))
                            )
                        } else if let firebaseUser = authResult?.user {
                            // Save user info to Firestore
                            saveGoogleUserToFirestore(firebaseUser: firebaseUser, googleUser: user)
                        }
                    }
                }
            }
        }
    }
    
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    alertItem = AlertItem(
                        title: Text("Apple Sign In Error"),
                        message: Text("Invalid state: A login callback was received, but no login request was sent."),
                        dismissButton: .default(Text("OK"))
                    )
                    return
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    alertItem = AlertItem(
                        title: Text("Apple Sign In Error"),
                        message: Text("Unable to fetch identity token from Apple."),
                        dismissButton: .default(Text("OK"))
                    )
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    alertItem = AlertItem(
                        title: Text("Apple Sign In Error"),
                        message: Text("Unable to serialize token string from data."),
                        dismissButton: .default(Text("OK"))
                    )
                    return
                }
                
                // Initialize a Firebase credential
                let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                        idToken: idTokenString,
                                                        rawNonce: nonce)
                
                // Sign in with Firebase
                Auth.auth().signIn(with: credential) { [self] (authResult, error) in
                    DispatchQueue.main.async {
                        if let error = error {
                            alertItem = AlertItem(
                                title: Text("Apple Sign In Failed"),
                                message: Text(error.localizedDescription),
                                dismissButton: .default(Text("OK"))
                            )
                        } else if let user = authResult?.user {
                            // Save user info to Firestore
                            saveAppleUserToFirestore(user: user, credential: appleIDCredential)
                        }
                    }
                }
            }
        case .failure(let error):
            alertItem = AlertItem(
                title: Text("Apple Sign In Failed"),
                message: Text(error.localizedDescription),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Apple Sign-In Helper Methods
    
    private func saveAppleUserToFirestore(user: FirebaseAuth.User, credential: ASAuthorizationAppleIDCredential) {
        let db = Firestore.firestore()
        
        // Get user info from Apple credential
        let fullName = credential.fullName
        let displayName = [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        db.collection("users").document(user.uid).setData([
            "userID": user.uid,
            "email": user.email ?? "",
            "username": displayName.isEmpty ? "Apple User" : displayName,
            "createdAt": Date(),
            "signInProvider": "apple"
        ]) { [self] error in
            DispatchQueue.main.async {
                if let error = error {
                    alertItem = AlertItem(
                        title: Text("Error"),
                        message: Text("Account created but failed to save user data: \(error.localizedDescription)"),
                        dismissButton: .default(Text("OK"))
                    )
                } else {
                    // Show success animation and navigate
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showSuccess = true
                    }
                    
                    // Navigate after confetti animation (2.5 seconds)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            viewItem = ViewItem(AnyView(OnboardingCoordinatorView()), _presentationStyle: .fullScreen)
                        }
                    }
                }
            }
        }
    }
    
    private func saveGoogleUserToFirestore(firebaseUser: FirebaseAuth.User, googleUser: GIDGoogleUser) {
        let db = Firestore.firestore()
        
        db.collection("users").document(firebaseUser.uid).setData([
            "userID": firebaseUser.uid,
            "email": firebaseUser.email ?? "",
            "username": googleUser.profile?.name ?? "Google User",
            "createdAt": Date(),
            "signInProvider": "google"
        ]) { [self] error in
            DispatchQueue.main.async {
                if let error = error {
                    alertItem = AlertItem(
                        title: Text("Error"),
                        message: Text("Account created but failed to save user data: \(error.localizedDescription)"),
                        dismissButton: .default(Text("OK"))
                    )
                } else {
                    // Show success animation and navigate
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showSuccess = true
                    }
                    
                    // Navigate after confetti animation (2.5 seconds)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            viewItem = ViewItem(AnyView(OnboardingCoordinatorView()), _presentationStyle: .fullScreen)
                        }
                    }
                }
            }
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    print("❌ Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                    // Return 0 as fallback instead of crashing
                    return 0
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
