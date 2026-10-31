//
//  ChatroomManager.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 05/03/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation

struct ChatroomManager {
    
    static let shared = ChatroomManager()
    
    private let repository = ChatroomRepository()
    
    func create(room: ChatRoom) throws {
        do {
            try repository.create(room: room)
        } catch {
            throw error
        }
    }
    
    func getChatRooms(whereField: String, arrayContains: Any, completion: @escaping ([ChatRoom]?) -> ()) {
        repository.getChatRooms(whereField: whereField, arrayContains: arrayContains) { rooms in
            completion(rooms)
        }
    }
    
    func getChatRooms(whereField: String, withValues: [Any], completion: @escaping ([ChatRoom]?) -> ()) {
        repository.getChatRooms(whereField: whereField, values: withValues) { rooms in
            completion(rooms)
        }
    }
}
