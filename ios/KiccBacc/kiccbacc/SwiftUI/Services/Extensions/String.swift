//
//  String.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import Foundation
import SwiftUI

extension String {
    var text: Text {
        Text(self)
    }
}

extension Int {
    var text: Text {
        Text("\(self)")
    }
}

extension Double {
    var text: Text {
        Text("\(self)")
    }
}

extension CGFloat {
    var text: Text {
        Text("\(self)")
    }
}
