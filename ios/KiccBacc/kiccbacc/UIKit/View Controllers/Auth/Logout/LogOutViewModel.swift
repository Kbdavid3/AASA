//
//  LogOutViewModel.swift
//  kiccbacc
//
//  Created by Jonathan Nunez on 8/21/23.
//  Copyright © 2023 APPLE. All rights reserved.
//

import FirebaseAuth

class LogOutViewModel {
        
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
                viewControllerReference?.didFinishSigningIn(with: nil)
            }
        }
    }
}
