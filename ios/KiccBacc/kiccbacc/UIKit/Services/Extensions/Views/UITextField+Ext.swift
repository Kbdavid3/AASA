//
//  UITextField+Ext.swift
//  kiccbacc
//
//  Created by Colin Murphy on 12/11/20.
//  Copyright © 2020 APPLE. All rights reserved.
//

import UIKit

extension UITextField {
    
    func setBorderColor(width: CGFloat, color: UIColor) -> Void {
        
        guard let font = font,
              let placeholder = placeholder else { return }
        layer.borderColor = color.cgColor
        layer.borderWidth = width
        layer.cornerRadius = 10
        
        let attributeString: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: color.withAlphaComponent(0.6),
            NSAttributedString.Key.font: font
        ]
        attributedPlaceholder = NSAttributedString(string: placeholder, attributes: attributeString)
    }
    
    func setBorder(width: CGFloat, color: UIColor) -> Void {
        layer.borderColor = color.cgColor
        layer.borderWidth = width
        layer.cornerRadius = 10
    }

    func placeholderColor(color: UIColor) {
        
        guard let font = font,
              let placeholder = placeholder else { return }
        let attributeString: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: color.withAlphaComponent(0.6),
            NSAttributedString.Key.font: font
        ]
        attributedPlaceholder = NSAttributedString(string: placeholder, attributes: attributeString)
    }
}
