//
//  EventType.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 24/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation

enum EventType: String, CaseIterable, Identifiable, Hashable, Codable {
    case all = "All"
    case food = "Food & Drink"
    case party = "Party"
    case festivals = "Festivals"
    case sports = "Sports"
    case entertainment = "Entertainment"
    case gaming = "Gaming"
    case concert = "Concert"
    case custom = "Custom"
}

extension EventType {
    private var emoji: String {
        switch self {
        case .all:
            return ""
        case .food:
            return "🍣"
        case .party:
            return "💃🏽"
        case .festivals:
            return "🎏"
        case .sports:
            return "🏀"
        case .entertainment:
            return "🎡"
        case .gaming:
            return "🎮"
        case .concert:
            return "🎤"
        case .custom:
            return ""
        }
    }
    
    var id: String {
        self.rawValue
    }
    
    var title: String {
        if self == .all {
            return "\(self.rawValue)"
        }
        
        return "\(self.emoji) \(self.rawValue)"
    }
    
    var displayName: String {
        return self.title
    }
}
