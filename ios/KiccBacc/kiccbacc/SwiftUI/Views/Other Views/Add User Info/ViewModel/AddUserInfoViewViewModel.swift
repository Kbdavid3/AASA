//
//  AddUserInfoViewViewModel.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class AddUserInfoViewViewModel : ObservableObject {
    
    private let database = Firestore.firestore()
    private var userWasCreated = false
    
    @Published var isUpdating: Bool = false
    
    func updateUserInfo(user: User, completion: @escaping (FirebaseUpdateStatus) -> Void) {
        do {
            if userWasCreated { return }
            try UserManager.shared.create(user: user)
            userWasCreated = true
            completion(.updated)
        } catch {
            completion(.failed(withError: error))
        }
    }
    
    func getUsersBasicData(completion: @escaping (Result<InitialUser, FirebaseError>) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(.failure(.userNotFound))
            return
        }
        
        database
            .collection("users")
            .document(userID)
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    completion(.failure(.userNotFound))
                    return
                }
                
                do {
                    let user = try document.data(as: InitialUser.self)
                    let initialUser = user
                    completion(.success(initialUser))
                } catch {
                    completion(.failure(.withError(error: error)))
                }
            }
    }
}
