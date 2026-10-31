//
//  AccessoryIndicator.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 20/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import SwiftUI

enum AccessoryIndicator: String {
    case right = "chevron.right"
    case up = "chevron.up"
    case down = "chevron.down"
    case left = "chevron.left"
    
    func getImage() -> Image {
        Image(systemName: self.rawValue)
    }
}
