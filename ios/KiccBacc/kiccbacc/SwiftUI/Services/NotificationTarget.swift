//
//  NotificationTarget.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import Foundation

enum NotificationTarget: String, Codable, CaseIterable {
    case joinees = "joinees"
    case everyone = "everyone"
    case specificUsers = "specific_users"
    
    var displayName: String {
        switch self {
        case .joinees: return "Event Joinees"
        case .everyone: return "Everyone"
        case .specificUsers: return "Specific Users"
        }
    }
}
