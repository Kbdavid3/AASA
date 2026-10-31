//
//  CustomFont.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 20/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import SwiftUI

enum customFont: String {
    case light = "AirbnbCerealApp-Light"
    case regular = "AirbnbCerealApp-Book"
    case medium = "AirbnbCerealApp-Medium"
    case bold = "AirbnbCerealApp-Bold"
    case black = "AirbnbCerealApp-Black"
    case extraBold = "AirbnbCerealApp-ExtraBold"
}

fileprivate struct AirbnbFontStyle: ViewModifier {
    
    var weight: customFont
    var size: CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(.custom(weight.rawValue, size: size))
    }
}

extension View {
    func customFont(weight: customFont, size: CGFloat) -> some View {
        self.modifier(AirbnbFontStyle(weight: weight, size: size))
    }
}

