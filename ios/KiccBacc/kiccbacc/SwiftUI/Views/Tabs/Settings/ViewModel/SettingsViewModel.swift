//
//  SettingsViewModel.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    
    @Published var isLoading: Bool = false
    @Published var fetchedUser: User?
    
    func fetchUser() {
        withAnimation { isLoading = true }
        
        guard let userID = UserManager.shared.currentUserID else {
            withAnimation { isLoading = false }
            return
        }
        
        UserManager.shared.getUserListener(withUserID: userID) { result in
            switch result {
            case .success(let user):
                self.fetchedUser = user
            case .failure(_):
                // login again, user fetch failed
                break
            }
            
            withAnimation { self.isLoading = false }
        }
    }
}
