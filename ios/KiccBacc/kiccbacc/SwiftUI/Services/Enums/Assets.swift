//
//  Assets.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 20/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import SwiftUI

struct Assets {
    struct TabBarIcons {
        static let home = Image("tabicon-1")
        static let chats = Image("tabicon-2")
        static let addNewEvent = Image("tabicon-3")
        static let notifications = Image("tabicon-4")
        static let settings = Image("tabicon-5")
    }
    
    struct UI {
        static let mail = Image("mail-icon")
        static let arrowLeft = Image("backBttn")
        static let sendMessage = Image("send-plane-icon-right")
        static let image = Image("image-icon")
    }
    
    static let appLogo = Image("launchScreenLogo")
    
    struct Sample {
        static let user = Image("person1")
    }
}
