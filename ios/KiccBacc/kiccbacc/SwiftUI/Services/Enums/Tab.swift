//
//  Tab.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 24/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import SwiftUI

enum Tab: Int, CaseIterable, Identifiable {
    case home = 0
    case chat
    case createEvent
    case notifications
    case profile
}

extension Tab {
    var id: String {
        switch self {
        default:
            return "\(self.rawValue)"
        }
    }
    
    var icon: Image {
        switch self {
        case .home:
            return Assets.TabBarIcons.home
        case .chat:
            return Assets.TabBarIcons.chats
        case .createEvent:
            return Assets.TabBarIcons.addNewEvent
        case .notifications:
            return Assets.TabBarIcons.notifications
        case .profile:
            return Assets.TabBarIcons.settings
        }
    }
    
    var navigationTitle: String? {
        switch self {
        case .home:
            return nil
        case .chat:
            return "Chats"
        case .createEvent:
            return nil
        case .notifications:
            return "Notifications"
        case .profile:
            return "Profile"
        }
    }
}
