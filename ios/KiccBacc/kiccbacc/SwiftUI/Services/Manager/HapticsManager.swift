//
//  HapticsManager.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 20/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import SwiftUI

struct ThemeManager {
    
    @AppStorage("preferredTheme") static var preferredTheme : Int = 2
    //.. 0 -> System, 1 -> Light, 2 -> Dark (now only dark is supported)
    
    static func setAppTheme(with theme: UIUserInterfaceStyle) {
        // Force dark theme regardless of input
        ThemeManager.preferredTheme = 2
        
        // FIXED: Use modern UIWindowScene API instead of deprecated UIApplication.shared.windows
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = .dark
            }
        }
    }
    
    static func initialiseTheme() {
        // FIXED: Use modern UIWindowScene API instead of deprecated UIApplication.shared.windows
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = .dark
            }
        }
    }
    
    static private var currentTheme: UIUserInterfaceStyle {
        // Always return dark theme
        return .dark
    }
}
