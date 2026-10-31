//
//  ViewItemModifier.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI

struct ViewItemModifier: ViewModifier {
    @State private var viewItem: ViewItem?
    
    func body(content: Content) -> some View {
        content
            .fullScreenCover(item: $viewItem) { viewItem in
                viewItem.viewToPresent
            }
    }
}

extension View {
    func viewItemPresentation() -> some View {
        self.modifier(ViewItemModifier())
    }
}
