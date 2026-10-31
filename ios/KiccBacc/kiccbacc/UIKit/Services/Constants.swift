//
//  Constants.swift
//  kiccbacc
//
//  Created by Colin Murphy on 12/12/20.
//  Copyright © 2020 APPLE. All rights reserved.
//

import UIKit

enum KiccBacc {
    enum Storyboard {
        static let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    }
    
    enum ViewController {
        // FIXED: Safe casting with fallback view controllers
        static var signUp: SignUpViewController {
            guard let vc = Storyboard.mainStoryboard.instantiateViewController(withIdentifier: "SignUpViewController") as? SignUpViewController else {
                print("❌ Failed to instantiate SignUpViewController from storyboard")
                return SignUpViewController()
            }
            return vc
        }
        
        static var signIn: SignInViewController {
            guard let vc = Storyboard.mainStoryboard.instantiateViewController(withIdentifier: "SignInViewController") as? SignInViewController else {
                print("❌ Failed to instantiate SignInViewController from storyboard")
                return SignInViewController()
            }
            return vc
        }
        
        static var onboarding: OnboardingVC {
            guard let vc = Storyboard.mainStoryboard.instantiateViewController(withIdentifier: "OnboardingVC") as? OnboardingVC else {
                print("❌ Failed to instantiate OnboardingVC from storyboard")
                return OnboardingVC()
            }
            return vc
        }
        
        static var resetPassword: ForgotPasswordViewController {
            guard let vc = Storyboard.mainStoryboard.instantiateViewController(withIdentifier: "ForgotPasswordViewController") as? ForgotPasswordViewController else {
                print("❌ Failed to instantiate ForgotPasswordViewController from storyboard")
                return ForgotPasswordViewController()
            }
            return vc
        }
    }
}
