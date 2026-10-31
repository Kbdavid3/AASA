//
//  HapticGenerator.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 26/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation
import UIKit

enum HapticGenerator: Int {
    case light = 0
    case medium
    case heavy
    case soft
    case rigid
}

extension HapticGenerator {
    func impactOccurred() {
        let style = UIImpactFeedbackGenerator.FeedbackStyle.init(rawValue: self.rawValue) ?? .light
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
