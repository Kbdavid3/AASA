//
//  SignInViewController.swift
//  party
//
//  Created by Hourspent on 5/2/20.
//  Copyright © 2020 Hourspent. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import SwiftUI
import AuthenticationServices
import GoogleSignIn
import CryptoKit

class SignInViewController: UIViewController {
    
    let spinnerView = SpinnerView()
    let spinnerLabel = UILabel()
    
    // Apple Sign-In
    private var currentNonce: String?
    
    // MARK: - IBOutlets
    @IBOutlet weak var dismissBttn: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var usernameTextField: UITextField!
    @IBOutlet public weak var passwordTextField: UITextField!
    @IBOutlet weak var signInBttn: UIButton!
    @IBOutlet weak var privacyPolicyLabel: UITextView!
    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var cardView: UIView!
    
    @IBAction func dissmissBttnDidTap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - View Life Cycles
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up a clean background to avoid grey flash
        view.backgroundColor = .black
        
        // Replace the entire view with SwiftUI content
        setupSwiftUIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide all storyboard elements immediately
        hideAllStoryboardElements()
    }
    
    private func hideAllStoryboardElements() {
        // Hide all storyboard elements to prevent showing lorem ipsum
        dismissBttn?.isHidden = true
        titleLabel?.isHidden = true
        usernameTextField?.isHidden = true
        passwordTextField?.isHidden = true
        signInBttn?.isHidden = true
        privacyPolicyLabel?.isHidden = true
        bgImageView?.isHidden = true
        cardView?.isHidden = true
    }
    
    private func setupSwiftUIView() {
        let signInView = SignInView()
        let hostingController = UIHostingController(rootView: signInView)
        
        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Set up constraints to fill the entire view
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        hostingController.didMove(toParent: self)
    }
    
    // MARK: - IBActions
    @IBAction private func forgotPassword(_ sender: Any) {
        let vc = KiccBacc.ViewController.resetPassword
        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction private func login(_ sender: Any) {
        startSpinner()
        
        guard let email = usernameTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty
        else {
            self.stopSpinner()
            
            let alert = alertWithDefaultAction(AlertTitle: "Warning", Message: "Please enter the username, email and password!", ActionBttnTitle: "Ok")
            self.present(alert, animated: true)
            
            return
        }
        
        let viewModel: SignInViewModel = SignInViewModel(_viewControllerReference: self)
        viewModel.signIn(email: email, password: password)
    }
    
    func didFinishSigningIn(with error: FirebaseError?) {
        
        self.stopSpinner()
        
        if let error = error {
            switch error {
            case .userNotFound:
                let alertController = UIAlertController(title: "Error encountered!", message: "Cannot fetch the user at the moment please try again later.", preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "Okay", style: .cancel)
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true)
            
            case .withError(let error):
                let alertController = UIAlertController(title: "Error encountered!", message: error.localizedDescription, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "Okay", style: .cancel)
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true)
            
            default:
                break
            }
        } else {
            DispatchQueue.main.async {
                // check if initialised data of user is present or not -> if present
                if let userID = Auth.auth().currentUser?.uid {
                    UserManager.shared.getUserListener(withUserID: userID) { result in
                        switch result {
                        case .success(_):
                            // present home screen
                            let vc = UIHostingController(rootView: NewTabBarView())
                            vc.modalPresentationStyle = .fullScreen
                            self.present(vc, animated: true, completion: nil)
                        case .failure(_):
                            // present onboarding for new users
                            let vc = UIHostingController(rootView: OnboardingCoordinatorView())
                            vc.modalPresentationStyle = .fullScreen
                            self.present(vc, animated: true, completion: nil)
                        }
                    }
                } else {
                    let alertController = UIAlertController(title: "Woops", message: "Please create an account to proceed further", preferredStyle: .alert)
                    let primaryAction = UIAlertAction(title: "Sign Up", style: .default) { action in
                        switch action {
                        default:
                            // Use the new SwiftUI SignUpView for new user onboarding
                            let signUpView = SignUpView()
                            let hostingController = UIHostingController(rootView: signUpView)
                            hostingController.modalPresentationStyle = .fullScreen
                            self.present(hostingController, animated: true)
                        }
                    }
                    alertController.addAction(primaryAction)
                    self.present(alertController, animated: true)
                }
            }
        }
    }
    
    // MARK: - Social Sign-In Actions
    
    @objc private func appleSignInTapped() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    @objc private func googleSignInTapped() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            showAlert(title: "Configuration Error", message: "Google Sign-In is not properly configured.")
            return
        }
        
        // Create Google Sign In configuration object
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    let nsError = error as NSError
                    print("Google Sign In Error: \(error.localizedDescription)")
                    
                    // Check if user cancelled - don't show error for cancellation
                    if nsError.code == -2 || nsError.code == -4 || nsError.code == -5 {
                        print("Google Sign In cancelled by user")
                        return
                    }
                    
                    if error.localizedDescription.lowercased().contains("cancel") {
                        print("Google Sign In cancelled based on error message")
                        return
                    }
                    
                    self?.showAlert(title: "Google Sign In Failed", message: error.localizedDescription)
                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    return
                }
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                             accessToken: user.accessToken.tokenString)
                
                // Sign in with Firebase
                Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
                    DispatchQueue.main.async {
                        if let error = error {
                            self?.showAlert(title: "Google Sign In Failed", message: error.localizedDescription)
                        } else if let firebaseUser = authResult?.user {
                            // Check if user exists and navigate accordingly
                            self?.handleSocialSignInSuccess(user: firebaseUser)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    private func configure() {
        let clearAttribute = [NSAttributedString.Key.foregroundColor: UIColor.clear]
        navigationController?.navigationBar.titleTextAttributes = clearAttribute
        navigationController?.navigationBar.tintColor = .white
        navigationItem.title = "Sign In"

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .clear
        
        // Keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        //configure privacy policy label
        privacyPolicyLabel.attributedText = NSMutableAttributedString()
            .termsTextBottom("By registering you confirm that you accept our\n")
            .termsLinkBottom("Privacy policy", url: URL(string: urlManager.privacyPolicyUrl)!)
            .termsTextBottom(" and ")
            .termsLinkBottom("Terms of Use", url: URL(string: urlManager.termsOfUseUrl)!)
            .termsTextBottom(" .")
        privacyPolicyLabel.textAlignment = .center
        
        bgImageView.image = imageWithGradientTop(img: UIImage(named: "cinemaDown"))
        
        cardView.roundCorners([.topLeft,.topRight], radius: 20)
        setUpHeroAnimations()
    }
    
    private func setupSocialSignInButtons() {
        // Create a container view for social buttons
        let socialButtonsContainer = UIView()
        socialButtonsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(socialButtonsContainer)
        
        // Add constraints to position below the sign-in button
        NSLayoutConstraint.activate([
            socialButtonsContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 22),
            socialButtonsContainer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -22),
            socialButtonsContainer.topAnchor.constraint(equalTo: signInBttn.bottomAnchor, constant: 20),
            socialButtonsContainer.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        // Create "or" divider
        let dividerView = UIView()
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        socialButtonsContainer.addSubview(dividerView)
        
        let leftLine = UIView()
        leftLine.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        leftLine.translatesAutoresizingMaskIntoConstraints = false
        dividerView.addSubview(leftLine)
        
        let orLabel = UILabel()
        orLabel.text = "or"
        orLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        orLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        orLabel.textAlignment = .center
        orLabel.translatesAutoresizingMaskIntoConstraints = false
        dividerView.addSubview(orLabel)
        
        let rightLine = UIView()
        rightLine.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        rightLine.translatesAutoresizingMaskIntoConstraints = false
        dividerView.addSubview(rightLine)
        
        NSLayoutConstraint.activate([
            dividerView.topAnchor.constraint(equalTo: socialButtonsContainer.topAnchor),
            dividerView.leadingAnchor.constraint(equalTo: socialButtonsContainer.leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: socialButtonsContainer.trailingAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 20),
            
            leftLine.leadingAnchor.constraint(equalTo: dividerView.leadingAnchor),
            leftLine.trailingAnchor.constraint(equalTo: orLabel.leadingAnchor, constant: -16),
            leftLine.centerYAnchor.constraint(equalTo: dividerView.centerYAnchor),
            leftLine.heightAnchor.constraint(equalToConstant: 1),
            
            orLabel.centerXAnchor.constraint(equalTo: dividerView.centerXAnchor),
            orLabel.centerYAnchor.constraint(equalTo: dividerView.centerYAnchor),
            
            rightLine.leadingAnchor.constraint(equalTo: orLabel.trailingAnchor, constant: 16),
            rightLine.trailingAnchor.constraint(equalTo: dividerView.trailingAnchor),
            rightLine.centerYAnchor.constraint(equalTo: dividerView.centerYAnchor),
            rightLine.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        // Create Apple Sign-In button
        let appleSignInButton = ASAuthorizationAppleIDButton(type: .signIn, style: .white)
        appleSignInButton.translatesAutoresizingMaskIntoConstraints = false
        appleSignInButton.layer.cornerRadius = 16
        appleSignInButton.addTarget(self, action: #selector(appleSignInTapped), for: .touchUpInside)
        socialButtonsContainer.addSubview(appleSignInButton)
        
        // Create Google Sign-In button
        let googleSignInButton = UIButton(type: .system)
        googleSignInButton.translatesAutoresizingMaskIntoConstraints = false
        googleSignInButton.backgroundColor = .white
        googleSignInButton.layer.cornerRadius = 16
        googleSignInButton.layer.shadowColor = UIColor.black.cgColor
        googleSignInButton.layer.shadowOpacity = 0.15
        googleSignInButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        googleSignInButton.layer.shadowRadius = 1
        googleSignInButton.addTarget(self, action: #selector(googleSignInTapped), for: .touchUpInside)
        socialButtonsContainer.addSubview(googleSignInButton)
        
        // Add Google logo and text
        let googleImageView = UIImageView(image: UIImage(named: "Google"))
        googleImageView.translatesAutoresizingMaskIntoConstraints = false
        googleImageView.contentMode = .scaleAspectFit
        googleSignInButton.addSubview(googleImageView)
        
        let googleLabel = UILabel()
        googleLabel.text = "Continue with Google"
        googleLabel.textColor = UIColor.black.withAlphaComponent(0.87)
        googleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        googleLabel.translatesAutoresizingMaskIntoConstraints = false
        googleSignInButton.addSubview(googleLabel)
        
        NSLayoutConstraint.activate([
            appleSignInButton.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: 20),
            appleSignInButton.leadingAnchor.constraint(equalTo: socialButtonsContainer.leadingAnchor),
            appleSignInButton.trailingAnchor.constraint(equalTo: socialButtonsContainer.trailingAnchor),
            appleSignInButton.heightAnchor.constraint(equalToConstant: 56),
            
            googleSignInButton.topAnchor.constraint(equalTo: appleSignInButton.bottomAnchor, constant: 12),
            googleSignInButton.leadingAnchor.constraint(equalTo: socialButtonsContainer.leadingAnchor),
            googleSignInButton.trailingAnchor.constraint(equalTo: socialButtonsContainer.trailingAnchor),
            googleSignInButton.heightAnchor.constraint(equalToConstant: 56),
            
            googleImageView.leadingAnchor.constraint(equalTo: googleSignInButton.leadingAnchor, constant: 16),
            googleImageView.centerYAnchor.constraint(equalTo: googleSignInButton.centerYAnchor),
            googleImageView.widthAnchor.constraint(equalToConstant: 20),
            googleImageView.heightAnchor.constraint(equalToConstant: 20),
            
            googleLabel.leadingAnchor.constraint(equalTo: googleImageView.trailingAnchor, constant: 12),
            googleLabel.centerYAnchor.constraint(equalTo: googleSignInButton.centerYAnchor)
        ])
    }
    
    private func setUpHeroAnimations() {
        self.hero.isEnabled = true
        titleLabel.hero.id = HeroIDs.titleLabel
        cardView.hero.id = HeroIDs.cardView
        cardView.hero.modifiers = [.translate(y:1000)]
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.view.frame.origin.y = (-keyboardSize.height)
            
            titleLabel.isHidden = true
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y = 0
        titleLabel.isHidden = false
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// Spinner
extension SignInViewController {
    private func startSpinner() {
        // start Spinner
        let Spinner = Spinner.shared
        Spinner.startSpinner(message: "Signing you in...", containerView: cardView, spinner: self.spinnerView, spinnerLabel: self.spinnerLabel, view: self.view)
        Spinner.hideALabel(labelToHide: self.titleLabel)
        Spinner.hideAImageView(imageViewToHide: self.bgImageView)
        Spinner.hideAButton(buttonToHide: self.dismissBttn)
    }
    
    private func stopSpinner() {
        DispatchQueue.main.asyncAfter(deadline: .now()+1.5) {
            // stop loader
            let Spinner = Spinner.shared
            Spinner.stopSpinner(containerView: self.cardView, spinner: self.spinnerView, spinnerLabel: self.spinnerLabel)
            Spinner.unHideAImageView(imageViewToUnHide: self.bgImageView)
            Spinner.unHideALabel(labelToUnHide: self.titleLabel)
            Spinner.unHideAButton(buttonToUnHide: self.dismissBttn)
        }
    }
    
    private func handleSocialSignInSuccess(user: FirebaseAuth.User) {
        // For social sign-in, we want to go directly to home screen if user exists
        // or to onboarding if it's a new user
        let userID = user.uid
        UserManager.shared.getUserListener(withUserID: userID) { [weak self] result in
            DispatchQueue.main.async {
                self?.stopSpinner()
                switch result {
                case .success(_):
                    // User exists, go directly to home screen
                    let vc = UIHostingController(rootView: NewTabBarView())
                    vc.modalPresentationStyle = .fullScreen
                    self?.present(vc, animated: true, completion: nil)
                case .failure(_):
                    // User doesn't exist, go to onboarding
                    let vc = UIHostingController(rootView: OnboardingCoordinatorView())
                    vc.modalPresentationStyle = .fullScreen
                    self?.present(vc, animated: true, completion: nil)
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .cancel)
        alertController.addAction(defaultAction)
        present(alertController, animated: true)
    }
    
    // MARK: - Apple Sign-In Helper Methods
    
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
                    // FIXED: Replaced fatalError() with error logging and fallback value
                    print("❌ SignInViewController: Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
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

// MARK: - ASAuthorizationControllerDelegate

extension SignInViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                showAlert(title: "Apple Sign In Error", message: "Invalid state: A login callback was received, but no login request was sent.")
                return
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                showAlert(title: "Apple Sign In Error", message: "Unable to fetch identity token from Apple.")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                showAlert(title: "Apple Sign In Error", message: "Unable to serialize token string from data.")
                return
            }
            
            // Initialize a Firebase credential
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                    idToken: idTokenString,
                                                    rawNonce: nonce)
            
            // Sign in with Firebase
            Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showAlert(title: "Apple Sign In Failed", message: error.localizedDescription)
                    } else if let user = authResult?.user {
                        self?.handleSocialSignInSuccess(user: user)
                    }
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        showAlert(title: "Apple Sign In Failed", message: error.localizedDescription)
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension SignInViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
