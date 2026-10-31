//
//  MessagesViewViewModel.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import FirebaseAuth
import FirebaseFirestore
//import FirebaseFirestoreSwift

class MessagesViewViewModel: ObservableObject {
    
    private let database = Firestore.firestore()
    
    @Published var messages: [Message]?
    
    func fetchMessages(in roomID: String) {
        database
            .collection("chatrooms")
            .document(roomID)
            .collection("messages")
            .order(by: "createdAt", descending: false)
            .limit(toLast: 100)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
//                    self.AlertView.present(title: "Error encountered while fetching messages", message: error?.localizedDescription)
                    return
                }
                // Safe message parsing with filtering out nil values
                self.messages = documents.compactMap { (queryDocumentSnapshot) -> Message? in
                    do {
                        return try queryDocumentSnapshot.data(as: Message.self)
                    } catch {
                        print("⚠️ MessagesViewViewModel: Error parsing message: \(error.localizedDescription)")
                        return nil
                    }
                }
        }
    }
}
