//
//  UIKitViewControllerItem.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//
import Foundation
import UIKit

struct UIKitViewControllerItem: Identifiable {
    
    var id: String {
        UUID().uuidString
    }
    
    var viewController: UIViewController
    var presentationStyle: PresentationStyle
    
    init(_viewController: UIViewController, _presentationStyle: PresentationStyle) {
        self.viewController = _viewController
        self.presentationStyle = _presentationStyle
    }
}
