//
//  ShowIfModifier.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI

struct ShowIfModifier: ViewModifier {
    var condition: Bool
    
    func body(content: Content) -> some View {
        if condition {
            content
        }
    }
}

extension View {
    func showIf(_ condition: Bool) -> some View {
        modifier(ShowIfModifier(condition: condition))
    }
}



