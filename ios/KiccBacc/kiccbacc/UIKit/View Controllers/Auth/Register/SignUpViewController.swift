//
//  SignUpViewController.swift
//  party
//
//  Created by Hourspent on 5/4/20.
//  Copyright © 2020 Hourspent. All rights reserved.
//

import Hero
import UIKit
import Firebase
//import FirebaseDatabase
import FirebaseAuth
import SwiftUI
//import SCLAlertView

class SignUpViewController: UIViewController {
    
    let spinnerView = SpinnerView()
    let spinnerLabel = UILabel()
    
    // MARK: - IBOutlets
    @IBOutlet weak var dismissBttn: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet weak var privacyPolicyLabel: UITextView!
    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var signUpBttn: UIButton!
    @IBOutlet private weak var usernameTextField: UITextField!
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    
    @IBAction func dismissBttnDidTap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - View Life Cycles

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Sign Up"
        
        // Hide the username field since we'll collect it later in onboarding
        usernameTextField.isHidden = true
        
        // Keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        bgImageView.image = imageWithGradientTop(img: UIImage(named: "cinemaDown"))
        
        //configure privacy policy label
        privacyPolicyLabel.attributedText = NSMutableAttributedString()
            .termsTextBottom("By registering you confirm that you accept our\n")
            .termsLinkBottom("Privacy policy", url: URL(string: urlManager.privacyPolicyUrl)!)
            .termsTextBottom(" and ")
            .termsLinkBottom("Terms of Use", url: URL(string: urlManager.termsOfUseUrl)!)
            .termsTextBottom(" .")
        privacyPolicyLabel.textAlignment = .center
        
        cardView.roundCorners([.topLeft,.topRight], radius: 20)
        setUpHeroAnimations()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - IBActions
    @IBAction private func createAccount(_ sender: Any) {
        
        self.startSpinner()
        
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty
        else {
            self.stopSpinner()
            
            let alert = alertWithDefaultAction(AlertTitle: "Warning", Message: "Please enter the email and password!", ActionBttnTitle: "Ok")
            self.present(alert, animated: true)
            
            return
        }
        
        let viewModel: SignUpViewModel = SignUpViewModel(_viewControllerReference: self)
        
        // Use a temporary username since we'll collect it later in onboarding
        let tempUsername = "user_\(Int.random(in: 1000...9999))"
        viewModel.signUp(username: tempUsername, email: email, password: password)
    }
    
    func didFinishSignUp(error: FirebaseError?) {
        self.stopSpinner()
        
        if let error = error {
            // show error
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
            // display onboarding flow instead of going directly to AddUserInfoView
            let vc = UIHostingController(rootView: OnboardingCoordinatorView())
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        }
    }
    
    // MARK: - Methods
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
    
    private func setUpHeroAnimations() {
        self.hero.isEnabled = true
        titleLabel.hero.id = HeroIDs.titleLabel
        cardView.hero.modifiers = [.translate(y:1000)]
    }
}

// Spinner
extension SignUpViewController {
    private func startSpinner() {
        // start Spinner
        let Spinner = Spinner.shared
        Spinner.startSpinner(message: "Creating your account...", containerView: cardView, spinner: self.spinnerView, spinnerLabel: self.spinnerLabel, view: self.view)
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
}
