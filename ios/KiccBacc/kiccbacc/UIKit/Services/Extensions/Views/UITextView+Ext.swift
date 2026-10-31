//
//  UITextView+Ext.swift
//  kiccbacc
//
//  Created by Colin Murphy on 12/11/20.
//  Copyright © 2020 APPLE. All rights reserved.
//

import UIKit

extension UITextView {
    
    func setBorder(width: CGFloat, color: UIColor) -> Void {
        layer.borderColor = color.cgColor
        layer.borderWidth = width
        layer.cornerRadius = 10
    }
    
    func setBorderWithClearBackground(width: CGFloat, color: UIColor) -> Void {
        
        layer.borderColor = color.cgColor
        layer.borderWidth = width
        layer.cornerRadius = 10
        backgroundColor = .clear
    }
}
