//
//  EventDataRepository.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 03/03/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct EventDataRepository {
    
    private let database = Firestore.firestore()
    
    private let collection = "events"
    
    func create(event: Event) throws {
        do {
            // Create a copy of the event to ensure all fields are properly encoded
            var eventData = event
            
            // Ensure ticketTypes are properly set if they exist
            if let ticketTypes = event.ticketTypes, !ticketTypes.isEmpty {
                print("Saving event with \(ticketTypes.count) ticket types")
                // The ticketTypes are already set, but we're logging for debugging
            }
            
            try FirestoreService.createDocumentInCollection(object: eventData, id: eventData.eventID, collectionName: collection)
        } catch {
            print("Error creating event: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getEventsSnapshotListener(whereField: String, isEqualTo: Any?, completion: @escaping ([Event]?) -> ()) {
        guard let isEqualTo = isEqualTo else {
            completion(nil)
            return
        }
        
        FirestoreService.getDocumentsWithSnapshotListener(inCollection: collection, whereField: whereField, isEqualTO: isEqualTo) { events in
            completion(events)
        }
    }
    
    func getEvent(with eventID: String, completion: @escaping (Event?) -> ()) {
        FirestoreService.getDocument(inCollection: collection, withID: eventID) { event in
            completion(event)
        }
    }
    
    func getEvents(whereField: String, isEqualTo: Any, completion: @escaping ([Event]?) -> ()) {
        FirestoreService.getDocuments(inCollection: collection, whereField: whereField, isEqualTo: isEqualTo) { events in
            completion(events)
        }
    }
    
    func getEvents(whereField: String, arrayContains: Any, completion: @escaping ([Event]?) -> ()) {
        FirestoreService.getDocuments(inCollection: collection, whereField: whereField, arrayContains: arrayContains) { events in
            completion(events)
        }
    }
    
    func getEventsForFriends(whereField: String, arrayContains: [Any], completion: @escaping ([Event]?) -> ()) {
        FirestoreService.getDocumentsForArray(inCollection: collection, whereField: whereField, arrayContains: arrayContains) { events in
            completion(events)
        }
    }
    
    func getAllEvents(completion: @escaping ([Event]?) -> ()) {
        FirestoreService.getAllDocuments(inCollection: collection) { events in
            completion(events)
        }
    }
    
    func uploadNewCoverForEvent(data: Data, with eventID: String, completion: @escaping (Result<FirebaseStorageUploadStatus,Error>) -> Void) {
        let fileName = "\(eventID).png"
        
        FirestoreService.uploadImage(with: data, fileName: fileName, withChild: "events/covers/\(eventID)/\(fileName)") { result in
            completion(result)
        }
    }
    
    func isCurrentUserInterested(inEvent: Event, completion: @escaping (Bool)->()) {
        Task {
            guard let currentUserID = UserManager.shared.currentUserID else {
                completion(false)
                return
            }
            
            do {
                let snapshot = try await database
                    .collection(collection)
                    .whereField("eventID", isEqualTo: inEvent.eventID)
                    .whereField("interestedUserIDs", arrayContains: currentUserID)
                    .getDocuments()
                
                let myObjects = snapshot.documents.compactMap { document in
                    try? document.data(as: Event.self)
                }
                
                if myObjects.count > 0 {
                    completion(true)
                } else {
                    completion(false)
                }
            } catch {
                completion(false)
            }
        }
    }
    
    func interestedIn(event: Event, completion: @escaping (Bool)->()) {
        Task {
            // current user is following utf
            // update following of current user
            guard let currentUserID = UserManager.shared.currentUserID else {
                completion(false)
                return
            }
            
            let docRef1 = database
                .collection(collection)
                .document(event.eventID)
            
            do {
                try await docRef1
                    .updateData([
                        "interestedUserIDs" : FieldValue.arrayUnion([currentUserID])
                    ])
                completion(true)
            } catch {
                print(error.localizedDescription)
                completion(false)
            }
        }
    }
    
    func removeUserInterestedIn(userID: String, event: String, completion: @escaping (Bool)->()) {
        Task {
            let docRef = database
                .collection(collection)
                .document(event)
            
            do {
                try await docRef
                    .updateData([
                        "interestedUserIDs" : FieldValue.arrayRemove([userID])
                    ])
                completion(true)
            } catch {
                print(error.localizedDescription)
                completion(false)
            }
        }
    }
    
    func removeInterestedIn(event: Event, completion: @escaping (Bool)->()) {
        Task {
            // current user is following utf
            // update following of current user
            guard let currentUserID = UserManager.shared.currentUserID else {
                completion(false)
                return
            }
            
            let docRef = database
                .collection(collection)
                .document(event.eventID)
            
            do {
                try await docRef
                    .updateData([
                        "interestedUserIDs" : FieldValue.arrayRemove([currentUserID])
                    ])
                completion(true)
            } catch {
                print(error.localizedDescription)
                completion(false)
            }
        }
    }
    
    func getTopFourInterestedPeople(of event: Event, completion: @escaping ([User]?) -> ()) {
        let interestedUsers = event.interestedUserIDs
        
        guard interestedUsers.count > 0 else {
            completion(nil)
            return
        }
        
        Task {
            do {
                let snapshot = try await database
                    .collection("users")
                    .whereField("userID", in: interestedUsers.count > 4 ? Array(interestedUsers.prefix(4)) : interestedUsers)
                    .limit(to: 4)
                    .getDocuments()
                
                let interestedUsers = snapshot.documents.compactMap { document in
                    try? document.data(as: User.self)
                }
                
                completion(interestedUsers)
            } catch {
                completion(nil)
            }
        }
    }
    
    func updateEventWith(eventID: String, with values: [String : Any], completion: @escaping (Bool) -> ()) {
        do {
            try FirestoreService.update(in: collection, documentID: eventID, withValues: values)
            completion(true)
        } catch {
            completion(false)
        }
    }
    
    func search(searchText: String, completion: @escaping ([Event]?) -> ()) {
        FirestoreService.searchDocument(inCollection: collection, field: "name", withSearchText: searchText) { event in
            completion(event)
        }
    }
    
    // delete
    func delete(event: Event, completion: @escaping (Bool) -> ()) {
        
        database
            .collection(collection)
            .document(event.eventID)
            .delete()
        
        completion(true)
    }
}
