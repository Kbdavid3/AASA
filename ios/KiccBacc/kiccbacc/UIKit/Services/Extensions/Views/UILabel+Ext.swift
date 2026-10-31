//
//  UILabel+Ext.swift
//  kiccbacc
//
//  Created by Colin Murphy on 12/11/20.
//  Copyright © 2020 APPLE. All rights reserved.
//

import UIKit

extension UILabel {
    
    func getSize(constrainedWidth: CGFloat) -> CGSize {
        
        let size = CGSize(width: constrainedWidth,
                          height: UIView.layoutFittingCompressedSize.height)
        
        return systemLayoutSizeFitting(size,
                                       withHorizontalFittingPriority: .required,
                                       verticalFittingPriority: .fittingSizeLevel)
    }
}
