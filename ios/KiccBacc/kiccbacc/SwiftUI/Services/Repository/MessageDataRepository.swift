//
//  MessageDataRepository.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 08/03/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct MessageDataRepository {
    
    static let shared = MessageDataRepository()
    
    private let database = Firestore.firestore()
    private let parentCollection = "chatrooms"
    private let collection = "messages"
    
    func create(in room: ChatRoom, with message: Message) throws {
        do {
            try database
                .collection(parentCollection)
                .document(room.roomID)
                .collection(collection)
                .document(message.messageID)
                .setData(from: message)
        } catch {
            throw error
        }
    }
    
    func getMessages(for chatroomID: String) async throws -> [Message]? {
        var messageToReturn: [Message]?

        do {
            let snapshot = try await database
                .collection(parentCollection)
                .document(chatroomID)
                .collection(collection)
                .order(by: "createdAt", descending: false)
                .getDocuments()

            messageToReturn = snapshot.documents.compactMap { document in
                try? document.data(as: Message.self)
            }
        } catch {
            throw error
        }

        return messageToReturn
    }
    
    func updateLastMessage(in room: ChatRoom, lastMessage: String, lastMessageTime: Date) {
        let docRef = database
            .collection(parentCollection)
            .document(room.roomID)
        
        docRef.updateData([
                "lastMessage" : lastMessage,
                "lastMessageTime" : lastMessageTime
            ]) { err in
                if let err = err {
                    // handle error here
                    debugPrint(err.localizedDescription)
                }
            }
    }
}
