//
//  ShadowedNavigationBar.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import SwiftUIIntrospect

fileprivate struct NavigationBarShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
//            .introspectNavigationController { navigationController in
//                navigationController.navigationBar.setValue(true, forKey: "hidesShadow")
//                navigationController.navigationBar.barTintColor = UIColor(named: "BgColor")
//                navigationController.navigationBar.layer.masksToBounds = false
//                navigationController.navigationBar.layer.shadowColor = UIColor.black.cgColor
//                navigationController.navigationBar.layer.shadowOpacity = 0.1
//                navigationController.navigationBar.layer.shadowOffset = CGSize(width: 0.4, height: 0.4)
//                navigationController.navigationBar.layer.shadowRadius = 10
//            }
    }
}

extension View {
    func shadowedNavigationBar() -> some View {
        self.modifier(NavigationBarShadow())
    }
}


