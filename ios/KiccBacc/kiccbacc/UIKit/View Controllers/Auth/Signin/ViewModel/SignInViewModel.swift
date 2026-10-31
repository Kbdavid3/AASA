//
//  SignInViewModel.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 24/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import FirebaseAuth

class SignInViewModel {
        
    private var viewControllerReference: SignInViewController?
    
    init(_viewControllerReference: SignInViewController) {
        self.viewControllerReference = _viewControllerReference
    }
    
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [self] user, error in
            if let error = error {
                // error occurred
                viewControllerReference?.didFinishSigningIn(with: .withError(error: error))
            } else {
                // user signed In
                viewControllerReference?.passwordTextField.text = ""
                viewControllerReference?.didFinishSigningIn(with: nil)
            }
        }
    }
}
