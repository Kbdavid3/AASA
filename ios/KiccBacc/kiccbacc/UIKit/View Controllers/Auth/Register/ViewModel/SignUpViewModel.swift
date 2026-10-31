//
//  SignUpViewModel.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 24/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class SignUpViewModel {
    
    private var viewControllerReference: SignUpViewController?
    
    init(_viewControllerReference: SignUpViewController) {
        self.viewControllerReference = _viewControllerReference
    }
    
    private let database = Firestore.firestore()
    
    func signUp(username: String, email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [self] user, error in
            if let error = error {
                // error occurred
                viewControllerReference?.didFinishSignUp(error: .withError(error: error))
            } else {
                // save user to database
                if let userID = Auth.auth().currentUser?.uid {
                    initialiseBasicUserStructure(withUserID: userID, email: email, and: username)
                } else {
                    viewControllerReference?.didFinishSignUp(error: .userNotFound)
                }
            }
        }
    }
    
    private func initialiseBasicUserStructure(withUserID: String, email: String, and username: String) {
        database
            .collection("users")
            .document(withUserID)
            .setData([
                "username": username,
                "userID" : withUserID,
                "email" : email,
                "createdAt" : Date()
            ]) { [self] error in
                if let error = error {
                    viewControllerReference?.didFinishSignUp(error: .withError(error: error))
                } else {
                    viewControllerReference?.didFinishSignUp(error: nil)
                }
            }
    }
}
