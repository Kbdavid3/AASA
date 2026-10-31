//
//  ForgotPasswordViewController.swift
//  party
//
//  Created by Hourspent on 5/4/20.
//  Copyright © 2020 Hourspent. All rights reserved.
//

import Hero
import UIKit
import Firebase
import FirebaseAuth

class ForgotPasswordViewController: UIViewController {
    
    let spinnerView = SpinnerView()
    let spinnerLabel = UILabel()
    
    // MARK: - IBOutlets
    @IBOutlet weak var dismissBttn: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var sendBttn: UIButton!
    @IBOutlet private weak var emailTextField: UITextField!
    @IBAction func dismissBttnDidTap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - IBActions
    @IBAction private func forgotPassword(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty
        else {
            return showAlertWhenEmptyField()
        }
        
        resetUserPassword()
    }
    
    // MARK: - View Life Cycles
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Forgot Password"
        
        // Keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        bgImageView.image = imageWithExtraGradientBottom(img: UIImage(named: "cinemaDown"))
        
        cardView.roundCorners([.topLeft,.topRight], radius: 20)
        setUpHeroAnimations()
    }
    
    private func setUpHeroAnimations() {
        self.hero.isEnabled = true
        cardView.hero.id = HeroIDs.cardView
        titleLabel.hero.id = HeroIDs.titleLabel
        descriptionLabel.hero.id = HeroIDs.descriptionLabel
        emailTextField.hero.id = HeroIDs.emailField
        sendBttn.hero.id = HeroIDs.sendBttn
    }
    
    private func resetUserPassword() {
        
        self.startSpinner()
        
        guard let email = emailTextField.text, !email.isEmpty else {
            self.stopSpinner()
            
            let alert = alertWithDefaultAction(AlertTitle: "Email field is empty \nPlease enter your email", Message: "", ActionBttnTitle: "Okay, I got it!")
            self.present(alert, animated: true)
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: email, completion: { (error) in
            
            self.stopSpinner()
            
            if let error = error {
                let alertController = UIAlertController(title: "Error encountered!", message: error.localizedDescription, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "Okay", style: .cancel)
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true, completion: nil)
            } else {
                // reseted password
                let alertController = UIAlertController(title: "We've sent you an email with reset \npassword link. Check you mail", message: "", preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "Okay", style: .cancel)
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true)
            }
        })
    }
    
    // MARK: - Methods
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.view.frame.origin.y = (-keyboardSize.height)
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y = 0
    }
    
    private func showAlertWhenEmptyField() {
        let alert = alertWithDefaultAction(AlertTitle: "Warning", Message: "Please enter your email!", ActionBttnTitle: "Okay, got it!")
        self.present(alert, animated: true)
        self.stopSpinner()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}

// Spinner
extension ForgotPasswordViewController {
    private func startSpinner() {
        // start Spinner
        let Spinner = Spinner.shared
        Spinner.startSpinner(message: "Sending mail...", containerView: cardView, spinner: self.spinnerView, spinnerLabel: self.spinnerLabel, view: self.view)
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
