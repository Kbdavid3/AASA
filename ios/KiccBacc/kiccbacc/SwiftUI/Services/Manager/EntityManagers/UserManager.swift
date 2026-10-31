//
//  UserManager.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 25/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation
import CoreLocation
import FirebaseFirestore

struct UserManager {
    
    static let shared = UserManager()
    
    private let repository = UserDataRepository()
    
    var currentUserID: String? {
        UserDataRepository.currentUserID
    }
    
    func create(user: User) throws {
        do {
            try repository.create(user: user)
        } catch {
            throw error
        }
    }
    
    func createOrUpdate(user: User, merge: Bool = true) throws {
        do {
            try repository.createOrUpdate(user: user, merge: merge)
        } catch {
            throw error
        }
    }
    
    func getCurrentUser(completion: @escaping (User?) -> ()) {
        guard let currentUserID = currentUserID else {
            completion(nil)
            return
        }

        repository.getUser(withUserID: currentUserID) { user in
            completion(user)
        }
    }
    
    func getUser(withUserID: String, completion: @escaping (User?) -> ()) {
        repository.getUser(withUserID: withUserID) { user in
            completion(user)
        }
    }
    
    func getUsers(with userIDs: [String]?, completion: @escaping ([User]?) -> ()) {
        repository.getUsers(with: userIDs) { users in
            completion(users)
        }
    }
    
    func getUsers(whereField: String, isEqualTo: Any, completion: @escaping ([User]?) -> ()) {
        repository.getUsers(whereField: whereField, isEqualTo: isEqualTo) { users in
            completion(users)
        }
    }
    
    func getUserListener(withUserID: String, completion: @escaping ((Result<User, FirebaseError>)) -> Void) {
        repository.getUserListener(withUserID: withUserID) { result in
            switch result {
            case .success(let user):
                completion(.success(user))
            case .failure(let firebaseError):
                completion(.failure(firebaseError))
            }
        }
    }
    
    func getUsersNearby(with coordinates: CLLocation, completion: @escaping ((Result<[User], FirebaseError>)) -> Void) {
        repository.getUsersNearby(with: coordinates, completion: completion)
    }
    
    func uploadPfp(data: Data, with userID: String, completion: @escaping (Result<FirebaseStorageUploadStatus,Error>) -> Void) {
        repository.uploadNewPfp(data: data, with: userID, completion: completion)
    }
    
    func update(userID: String, values: [String : Any]) throws {
        do {
            try repository.update(userID: userID, values: values)
        } catch {
            throw error
        }
    }
    
    func updateAsync(userID: String, values: [String : Any]) async throws {
        try await repository.updateAsync(userID: userID, values: values)
    }
    
    func update(preferredLocation: PreferredLocation) throws {
        do {
            try repository.update(preferredLocation: preferredLocation)
        } catch {
            throw error
        }
    }
    
    func checkIfCurrentUserExists(completion: @escaping (Bool) -> Void) {
        guard let userID = UserDataRepository.currentUserID else {
            completion(false)
            return
        }
        
        repository.checkIfUserExists(userID: userID) { isExists in
            completion(isExists)
        }
    }
    
    func follow(userToFollow: User, completion: @escaping (Bool)->()) {
        repository.follow(userToFollow: userToFollow) { isFollowed in
            if isFollowed {
                // Send follow notification
                guard let currentUserID = self.currentUserID else {
                    completion(true)
                    return
                }
                
                EnhancedNotificationManager.shared.sendFollowNotification(
                    followerID: currentUserID,
                    followedUserID: userToFollow.userID
                ) { _ in
                    completion(true)
                }
            } else {
                completion(false)
            }
        }
    }
    
    func unFollow(userToUnFollow: User, completion: @escaping (Bool)->()) {
        repository.unFollow(userToUnFollow: userToUnFollow) { isUnFollowed in
            completion(isUnFollowed)
        }
    }
    
    func isFollowing(user: User, completion: @escaping (Bool)->()) {
        repository.isFollowing(user: user) { isFollowing in
            completion(isFollowing)
        }
    }
    
    func getAllFollowers(with userIDs: [String]?, completion: @escaping ([User]?) -> ()) {
        repository.getAllFollowers(with: userIDs) { users in
            completion(users)
        }
    }
    
    func getFollowers(forUserID userID: String, completion: @escaping ([User]) -> Void) {
        repository.getFollowers(forUserID: userID) { followers in
            completion(followers)
        }
    }
    
    func getAllFollowing(with userIDs: [String]?, completion: @escaping ([User]?) -> ()) {
        repository.getAllFollowing(with: userIDs) { users in
            completion(users)
        }
    }
    
    func getTopFourFollowers(of user: User, completion: @escaping ([User]?) -> ()) {
        repository.getTopFourFollowers(of: user) { users in
            completion(users)
        }
    }
    
    func getFourUsers(withuserIDs: [String], completion: @escaping ([User]?) -> ()) {
        repository.getFourUsers(withuserIDs: withuserIDs) { users in
            completion(users)
        }
    }
    
    func delete(user: User, completion: @escaping (Bool) -> ()) {
        repository.delete(user: user) { isDeleted in
            completion(isDeleted)
        }
    }
    
    func checkSquareAuthorization(user: User) -> Bool {
        if let accessToken = user.accessToken,
           let expiresAtString = user.expiresAt,
           !accessToken.isEmpty {
            let dateFormatter = ISO8601DateFormatter()
            if let expiresAt = dateFormatter.date(from: expiresAtString),
               expiresAt > Date() {
                return true
            }
        }
        return false
    }

    func updateCurrentUserTokens(accessToken: String, expiresAt: String, refreshToken: String, merchantId: String) throws {
        guard let currentUserID = currentUserID else {
            throw NSError(domain: "UserManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No current user found"])
        }

        let values: [String: Any] = [
            "accessToken": accessToken,
            "expiresAt": expiresAt,
            "refreshToken": refreshToken,
            "merchantId": merchantId
        ]

        do {
            try repository.update(userID: currentUserID, values: values)
        } catch {
            throw error
        }
    }
    
    // MARK: - Square Account Unlinking
    
    func unlinkSquareAccount(user: User, completion: @escaping (Bool) -> Void) {
        guard let userId = currentUserID else {
            completion(false)
            return
        }
        
        // Create a batch to handle multiple updates
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        // Update the user document to remove Square authorization data
        let updates: [String: Any] = [
            "accessToken": FieldValue.delete(),
            "refreshToken": FieldValue.delete(),
            "merchantId": FieldValue.delete(),
            "expiresAt": FieldValue.delete()
        ]
        
        userRef.updateData(updates) { error in
            if let error = error {
                print("Error unlinking Square account: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Successfully unlinked Square account")
                
                // Optionally notify your backend about the unlinking
                self.notifyServerAboutSquareUnlink(userId: userId) { success in
                    completion(success)
                }
            }
        }
    }
    
    private func notifyServerAboutSquareUnlink(userId: String, completion: @escaping (Bool) -> Void) {
        // This is optional - if you have a serverless function that manages Square connections
        // Replace the URL with your actual endpoint
        guard let url = URL(string: "https://squareauth-7ce4gb3x2q-uc.a.run.app/revoke") else {
            completion(true) // Continue even if we can't notify the server
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "userId": userId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            
            URLSession.shared.dataTask(with: request) { _, response, error in
                if let error = error {
                    print("Error notifying server about Square unlink: \(error.localizedDescription)")
                    completion(true) // Continue anyway as Firestore was updated
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    completion(true)
                } else {
                    print("Unexpected response from server when unlinking Square")
                    completion(true) // Continue anyway as Firestore was updated
                }
            }.resume()
        } catch {
            print("Error creating request body: \(error.localizedDescription)")
            completion(true) // Continue anyway as Firestore was updated
        }
    }
}
