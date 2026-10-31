//
//  SignInValidationView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI

struct SignInValidationView: View {
    
    @State private var showHomeView: Bool = false
    @State private var viewControllerItem: UIKitViewControllerItem?
    @State private var hasValidated: Bool = false
    
    var body: some View {
        VStack {
            if showHomeView {
                NewTabBarView()
            } else {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                    
                    Text("Loading app...")
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Emergency bypass button after 3 seconds
                    Button("Tap to Continue") {
                        print("🚨 SignInValidationView: Emergency bypass triggered")
                        showHomeView = true
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.pink.opacity(0.8))
                    .cornerRadius(8)
                    .padding(.top, 30)
                    .opacity(hasValidated ? 1 : 0) // Only show after validation starts
                }
                .onAppear {
                    // Only validate once to prevent unnecessary redirects
                    if !hasValidated {
                        hasValidated = true
                        validateSignIn()
                    }
                }
            }
        }
        .fullScreenCover(item: $viewControllerItem) { vcItem in
            UIKitVisualisationHelper(viewController: vcItem.viewController)
                .ignoresSafeArea()
        }
    }
    
    private func validateSignIn() {
        if let userID = UserManager.shared.currentUserID {
            print("current userID -> \(userID)")
            
            // For authenticated users, skip onboarding check to prevent logout on app relaunch
            // If user is authenticated, they have already completed onboarding
            print("🔐 SignInValidationView: User is authenticated, proceeding to main app")
            
            // SAFETY TIMEOUT: Force show home view after 2 seconds regardless
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if !showHomeView {
                    print("🚨 SignInValidationView: TIMEOUT - Force showing home view after 2 seconds")
                    showHomeView = true
                }
            }
            
            // check if initialised data of user is present or not -> if present
            UserManager.shared.getUserListener(withUserID: userID) { result in
                print("Validation result -> \(result)")
                switch result {
                case .success(_):
                    // present home screen
                    DispatchQueue.main.async {
                        showHomeView = true
                    }
                case .failure(_):
                    // Skip the old AddUserInfoView and go directly to main app
                    // This handles cases where user data might not be immediately available after onboarding
                    print("User data not found, but user is authenticated - proceeding to main app")
                    DispatchQueue.main.async {
                        showHomeView = true
                    }
                }
            }
        } else {
            print("current userID -> not found")
            let vc = KiccBacc.ViewController.onboarding
            viewControllerItem = UIKitViewControllerItem(_viewController: vc, _presentationStyle: .fullScreen)
        }
    }
    
    private func hasIncompleteOnboarding() -> Bool {
        // Use the static method from OnboardingCoordinatorView
        let isComplete = OnboardingCoordinatorView.isOnboardingComplete()
        print("🔍 SignInValidationView: Onboarding complete check - \(isComplete)")
        return !isComplete
    }
}

struct SignInValidationView_Previews: PreviewProvider {
    static var previews: some View {
        SignInValidationView()
    }
}
