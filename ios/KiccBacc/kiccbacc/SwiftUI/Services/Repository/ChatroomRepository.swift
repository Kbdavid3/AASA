//
//  ChatroomRepository.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 05/03/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct ChatroomRepository {
    
    private let database = Firestore.firestore()
    
    private let collection = "chatrooms"
    
    func create(room: ChatRoom) throws {
        do {
            try FirestoreService.createDocumentInCollection(object: room, id: room.roomID, collectionName: collection)
        } catch {
            throw error
        }
    }
    
    func getChatRooms(whereField: String, arrayContains: Any, completion: @escaping ([ChatRoom]?) -> ()) {
        Task {
            do {
                let snapshot = try await database
                    .collection(collection)
                    .whereField(whereField, arrayContains: arrayContains)
                    .getDocuments()
                
                let documents = snapshot.documents
                
                let rooms = documents.compactMap { document in
                    try? document.data(as: ChatRoom.self)
                }
                completion(rooms)
            } catch {
                completion(nil)
            }
        }
    }
    
    func getChatRooms(whereField: String, values: [Any], completion: @escaping ([ChatRoom]?) -> ()) {
        FirestoreService.getDocuments(inCollection: collection, whereField: whereField, values: values) { chatrooms in
            completion(chatrooms)
        }
    }
}
