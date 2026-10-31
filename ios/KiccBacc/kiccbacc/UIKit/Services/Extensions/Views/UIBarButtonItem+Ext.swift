//
//  UIBarButtonItem+Ext.swift
//  kiccbacc
//
//  Created by Colin Murphy on 1/28/21.
//  Copyright © 2021 APPLE. All rights reserved.
//

import UIKit

extension UIBarButtonItem {
    func hide() {
        isEnabled = false
        tintColor = .clear
    }
    
    func show(with tint: UIColor) {
        isEnabled = true
        tintColor = tint
    }
}
