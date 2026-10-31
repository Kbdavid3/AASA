//
//  AlertItem.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI

struct AlertItem: Identifiable {
    var id = UUID()
    var title = Text("Error!")
    var message: Text?
    var dismissButton: Alert.Button?
    var primaryButton: Alert.Button?
    var secondaryButton: Alert.Button?
}

extension AlertItem {
    init(title: Text, message: Text?, primaryButton: Alert.Button?, secondaryButton: Alert.Button?) {
        self.init(title: title, message: message, dismissButton: nil, primaryButton: primaryButton, secondaryButton: secondaryButton)
    }
    
    init(title: Text, message: Text?, dismissButton: Alert.Button?) {
        self.init(title: title, message: message, dismissButton: dismissButton, primaryButton: nil, secondaryButton: nil)
    }
    
    init(error: Error) {
        self.init(title: Text("Error occurred !"), message: Text(error.localizedDescription), dismissButton: .cancel(), primaryButton: nil, secondaryButton: nil)
    }
}
