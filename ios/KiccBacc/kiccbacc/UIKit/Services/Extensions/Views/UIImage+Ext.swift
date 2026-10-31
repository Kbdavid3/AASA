//
//  UIImage+Ext.swift
//  kiccbacc
//
//  Created by Colin Murphy on 12/17/20.
//  Copyright © 2020 APPLE. All rights reserved.
//

import UIKit

extension UIImage {
    
    func resize(to size: CGSize) -> UIImage? {
        let scale: CGFloat = 0.0
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        self.draw(in: CGRect(origin: .zero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
}
