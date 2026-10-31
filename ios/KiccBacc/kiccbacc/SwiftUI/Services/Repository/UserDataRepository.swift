//
//  UserDataRepository.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 25/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import CoreLocation
import Foundation
import MapKit

struct UserDataRepository {
    
    private let database = Firestore.firestore()
    
    private let collection = "users"
    
    static var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    func create(user: User) throws {
        do {
            try FirestoreService.createDocumentInCollection(object: user, id: user.userID, collectionName: collection)
        } catch {
            throw error
        }
    }
    
    func createOrUpdate(user: User, merge: Bool = true) throws {
        do {
            try FirestoreService.createOrUpdateDocumentInCollection(object: user, id: user.userID, collectionName: collection, merge: merge)
        } catch {
            throw error
        }
    }
    
    func getUser(withUserID: String, completion: @escaping (User?) -> ()) {
        FirestoreService.getDocument(inCollection: collection, withID: withUserID) { user in
            completion(user)
        }
    }
    
    func getUsers(whereField: String, isEqualTo: Any, completion: @escaping ([User]?) -> ()) {
        FirestoreService.getDocuments(inCollection: collection, whereField: whereField, isEqualTo: isEqualTo) { users in
            completion(users)
        }
    }
    
    func getUsers(with userIDs: [String]?, completion: @escaping ([User]?) -> ()) {
        guard let userIDs = userIDs else {
            completion(nil)
            return
        }
        
        Task {
            do {
                let snapshot = try await database
                    .collection(collection)
                    .whereField("userID", in: userIDs)
                    .limit(to: 50)
                    .getDocuments()
                
                let followers = snapshot.documents.compactMap { document in
                    try? document.data(as: User.self)
                }
                
                completion(followers)
            } catch {
                completion(nil)
            }
        }
    }
    
    func getUsersNearby(with coordinates: CLLocation, completion: @escaping ((Result<[User], FirebaseError>)) -> Void) {
        UserManager.shared.getCurrentUser { user in
            guard let currentUser = user else { 
                return 
            }
            
            database
                .collection(collection)
                .getDocuments(completion: { documentSnapshot, error in
                    if let error = error {
                        print("Error getting user documents:", error)
                        return
                    }
                    
                    var nearbyUsers = [User]()
                    guard let documents = documentSnapshot?.documents else {
                        completion(.failure(FirebaseError.userNotFound))
                        return
                    }
                    
                    for doc in documents {
                        guard let user = try? doc.data(as: User.self),
                              let lat = user.preferredLocation?.latitude,
                              let lon = user.preferredLocation?.longitude else { 
                            continue 
                        }
                        
                        let distance = coordinates.distance(from: CLLocation(latitude: lat, longitude: lon))
                        let isFriend = (currentUser.followingIDs?.contains(user.userID)) ?? false
                        let isCurrentUser = currentUser.userID == user.userID
                        
                        if distance < 161000 && !isFriend && !isCurrentUser {
                            nearbyUsers.append(user)
                            if nearbyUsers.count > 9 { break }
                        }
                    }
                    
                    completion(.success(nearbyUsers))
                })
        }
    }
    
    func getUserListener(withUserID: String, completion: @escaping ((Result<User, FirebaseError>)) -> Void) {
        database
            .collection(collection)
            .document(withUserID)
            .addSnapshotListener{ documentSnapshot, error in
                guard let document = documentSnapshot else {
                    completion(.failure(.noDocumentsFound))
                    return
                }
                
                do {
                    let user = try document.data(as: User.self)
                    completion(.success(user))
                } catch {
                    completion(.failure(.withError(error: error)))
                }
            }
    }
    
    func uploadNewPfp(data: Data, with userID: String, completion: @escaping (Result<FirebaseStorageUploadStatus,Error>) -> Void) {
        let fileName = "\(userID).png"
        
        FirestoreService.uploadImage(with: data, fileName: fileName, withChild: "users/pfp/\(userID)/\(fileName)") { result in
            completion(result)
        }
    }
    
    func update(userID: String, values: [String : Any]) throws {
        do {
            try FirestoreService.update(in: collection, documentID: userID, withValues: values)
        } catch {
            throw error
        }
    }
    
    func updateAsync(userID: String, values: [String : Any]) async throws {
        try await FirestoreService.updateAsync(in: collection, documentID: userID, withValues: values)
    }
    
    func update(preferredLocation: PreferredLocation) throws {
        guard let currentUserID = UserDataRepository.currentUserID, let preferredLocationDict = preferredLocation.convertToDictionary() else {
            return
        }
        
        let preferredLocationData = [
            "preferredLocation" : preferredLocationDict
        ]

        let docRef = database
            .collection(collection)
            .document(currentUserID)

        docRef.setData(preferredLocationData, merge: true)
        
        // deleted user id
        // v85ircMMQYhtBr6U2QWtl7dl04E2
    }
    
    func checkIfUserExists(userID: String, completion: @escaping (Bool) -> ()) {
        database
            .collection(collection)
            .document(userID)
            .getDocument { (document, error) in
                do {
                    let user =  try document?.data(as: User.self)
                    if let _ = user {
                        completion(true)
                    } else {
                        completion(false)
                    }
                } catch {
                    completion(false)
                }
        }
    }
    
    // follow unfollow
    func follow(userToFollow: User, completion: @escaping (Bool)->()) {
        // current user is following utf
        // update following of current user
        UserManager.shared.getCurrentUser { user in
            guard let currentUser = user else {
                completion(false)
                return
            }
            
            Task {
                let docRef1 = database
                    .collection(collection)
                    .document(currentUser.userID)
                
                do {
                    try await docRef1
                        .updateData([
                            "followingIDs" : FieldValue.arrayUnion([userToFollow.userID]),
                            "followingCounter" : FieldValue.increment(Int64(1))
                        ])
                } catch {
                    print(error.localizedDescription)
                    completion(false)
                }
                
                // and update followers of userToFollow
                let docRef2 = database
                    .collection(collection)
                    .document(userToFollow.userID)
                
                do {
                    try await docRef2
                        .updateData([
                            "followerIDs" : FieldValue.arrayUnion([currentUser.userID]),
                            "followerCounter" : FieldValue.increment(Int64(1))
                        ])
                    
                    // send notification to the user that current user is now following them
                    let title = "[\(userToFollow.fullName) New follower!]"
                    let body = "@\(currentUser.username) started following you."
                    
                    let senderID = currentUser.userID
                    let receiverID = userToFollow.userID
                    
                    // Notification functionality removed as requested
                    // let pushNotification = PushNotification(title: title, body: body, sendToToken: "")
                    // let inAppNotification = InAppNotification(notificationID: UUID().uuidString, title: nil, body: body, imageUrl: currentUser.profileImageUrlString, senderID: senderID, receiverID: receiverID, createdAt: Date())
                    
                    // NotificationManager.shared.sendBothNotifications(notification: inAppNotification, pushNotification: pushNotification, to: userToFollow)
                    
                    completion(true)
                } catch {
                    completion(false)
                }
            }
        }
    }
    
    func isFollowing(user: User, completion: @escaping (Bool)->()) {
        // check for passed user's id in currentUser database
        guard let currentUserID = UserManager.shared.currentUserID else {
            completion(false)
            return
        }
        
        database
            .collection(collection)
            .whereField("followingIDs", arrayContains: user.userID)
            .whereField("userID", isEqualTo: currentUserID)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot, error == nil else {
                    completion(false)
                    return
                }
                
                let myData = snapshot.documents.compactMap { document in
                    try? document.data(as: User.self)
                }
                
                guard myData.count > 0 else {
                    completion(false)
                    return
                }

                completion(true)
            }
    }
    
    func unFollow(userToUnFollow: User, completion: @escaping (Bool)->()) {
        Task {
            // current user is following utf
            // update following of current user
            guard let currentUserID = UserManager.shared.currentUserID else {
                completion(false)
                return
            }
            
            let docRef1 = database
                .collection(collection)
                .document(currentUserID)
            
            do {
                try await docRef1
                    .updateData([
                        "followingIDs" : FieldValue.arrayRemove([userToUnFollow.userID]),
                        "followingCounter" : FieldValue.increment(Int64(-1))
                    ])
            } catch {
                completion(false)
            }
            
            // and update followers of userToFollow
            let docRef2 = database
                .collection(collection)
                .document(userToUnFollow.userID)
            
            do {
                try await docRef2
                    .updateData([
                        "followerIDs" : FieldValue.arrayRemove([currentUserID]),
                        "followerCounter" : FieldValue.increment(Int64(-1))
                    ])
                
                completion(true)
            } catch {
                completion(false)
            }
        }
    }
    
    func getAllFollowers(with userIDs: [String]?, completion: @escaping ([User]?) -> ()) {
       
        guard let followers = userIDs, followers.count > 0 else {
            completion(nil)
            return
        }
        
        Task {
            do {
                let snapshot = try await database
                    .collection(collection)
                    .whereField("userID", in: followers)
                    .limit(to: 10)
                    .getDocuments()
                
                let followers = snapshot.documents.compactMap { document in
                    try? document.data(as: User.self)
                }
                
                completion(followers)
            } catch {
                completion(nil)
            }
        }
    }
    
    func getAllFollowing(with userIDs: [String]?, completion: @escaping ([User]?) -> ()) {
       
        guard let following = userIDs, following.count > 0 else {
            completion(nil)
            return
        }
        
        Task {
            do {
                let snapshot = try await database
                    .collection(collection)
                    .whereField("userID", in: following)
                    .limit(to: 10)
                    .getDocuments()
                
                let followers = snapshot.documents.compactMap { document in
                    try? document.data(as: User.self)
                }
                
                DispatchQueue.main.async {
                    completion(followers)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    func getFollowers(forUserID userID: String, completion: @escaping ([User]) -> Void) {
        Task {
            do {
                let snapshot = try await database
                    .collection(collection)
                    .document(userID)
                    .collection("followers")
                    .getDocuments()
                
                let followerIDs = snapshot.documents.map { $0.documentID }
                
                if followerIDs.isEmpty {
                    completion([])
                    return
                }
                
                let usersSnapshot = try await database
                    .collection(collection)
                    .whereField("userID", in: followerIDs)
                    .getDocuments()
                
                let followers = usersSnapshot.documents.compactMap { document in
                    try? document.data(as: User.self)
                }
                
                completion(followers)
            } catch {
                print("Error getting followers: \(error)")
                completion([])
            }
        }
    }
    
    func getTopFourFollowers(of user: User, completion: @escaping ([User]?) -> ()) {
        
        guard let followers = user.followerIDs, followers.count > 0 else {
            completion(nil)
            return
        }
        
        Task {
            do {
                let snapshot = try await database
                    .collection(collection)
                    .whereField("userID", in: followers.count > 4 ? Array(followers.prefix(4)) : followers)
                    .limit(to: 4)
                    .getDocuments()
                
                let followers = snapshot.documents.compactMap { document in
                    try? document.data(as: User.self)
                }
                
                completion(followers)
            } catch {
                completion(nil)
            }
        }
    }
    
    func getFourUsers(withuserIDs: [String], completion: @escaping ([User]?) -> ()) {
        guard withuserIDs.count > 0 else {
            completion(nil)
            return
        }
        
        Task {
            do {
                var withuserIDs = withuserIDs
                var followers = [User]()
                var IDsArray = [[String]]()
                var slicing = true
                var processed = 0

                while slicing {
                    var newIDs = [String]()
                    if withuserIDs.count < 10 {
                        newIDs = withuserIDs
                    } else {
                        newIDs = Array(withuserIDs.prefix(upTo: 10))
                    }
                    
                    IDsArray.append(newIDs)
                    withuserIDs.removeSubrange(0..<IDsArray[processed].count)
                    if withuserIDs.isEmpty { slicing.toggle() }
                    processed += 1
                }
                
                for IDs in IDsArray {
                    let snapshot = try await database
                        .collection(collection)
                        .whereField("userID", in: IDs)
                        .limit(to: 4)
                        .getDocuments()
                    
                    let followersToAdd = snapshot.documents.compactMap { document in
                        try? document.data(as: User.self)
                    }
                    followers.append(contentsOf: followersToAdd)
                }
                
                completion(followers)
            } catch {
                completion(nil)
            }
        }
    }
    
    // delete
    func delete(user currentUser: User, completion: @escaping (Bool) -> ()) {
        
        let user = Auth.auth().currentUser

        user?.delete { error in
          if let error = error {
            
              completion(false)
          } else {
              
              // delete account model
              database
                  .collection(collection)
                  .document(currentUser.userID)
                  .delete()
              
              completion(true)
          }
        }
    }
}
