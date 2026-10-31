//
//  ViewItem.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import Foundation
import SwiftUI

struct ViewItem: Identifiable {
    
    // ✅ Use stored property with stable UUID instead of computed property
    let id: String = UUID().uuidString
    
    var viewToPresent: AnyView
    var presentationStyle: PresentationStyle
    
    init(_ view: AnyView, _presentationStyle: PresentationStyle) {
        self.viewToPresent = view
        self.presentationStyle = _presentationStyle
    }
}
