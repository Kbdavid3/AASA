//
//  UIView+Ext.swift
//  kiccbacc
//
//  Created by Colin Murphy on 12/17/20.
//  Copyright © 2020 APPLE. All rights reserved.
//

import UIKit

extension UIView {
    
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        
        let path = UIBezierPath(roundedRect: bounds,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
    
    func addShadow() {
        
        layer.masksToBounds = false
        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset  = .zero
        layer.shadowRadius  = 10
    }
}
