//
//  MessageManager.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 08/03/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation

struct MessageManager {
    
    static let shared = MessageManager()
    
    private let repository = MessageDataRepository()
    
    func create(in room: ChatRoom, with message: Message, pushNotification: Any, to user: User) throws {
        do {
            try repository.create(in: room, with: message)
            
            // Send message notification
            EnhancedNotificationManager.shared.sendMessageNotification(
                senderID: message.senderID,
                receiverID: message.receiverID,
                messageContent: message.content
            ) { _ in
                // Notification sent
            }
        } catch {
            throw error
        }
    }
    
    func createWithoutNotification(in room: ChatRoom, with message: Message, to user: User) throws {
        do {
            try repository.create(in: room, with: message)
            // No notification sent - used for story replies
        } catch {
            throw error
        }
    }
    
    func getMessages(for chatroomID: String, completion: @escaping ([Message]?) -> ()) throws {
        Task {
            do {
                let messages = try await repository.getMessages(for: chatroomID)
                completion(messages)
            } catch {
                throw error
            }
        }
    }
}
