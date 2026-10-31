//
//  UIViewController+Ext.swift
//  kiccbacc
//
//  Created by Colin Murphy on 12/18/20.
//  Copyright © 2020 APPLE. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func alert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel) { _ in }
        alert.addAction(okAction)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    
    func estimateViewHeight(_ text: String, _ width: CGFloat) -> CGFloat {
        
        let size = CGSize(width: width - 10, height: .infinity)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        let fontAttribute = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)
        ]
        let estimatedFrame = NSString(string: text).boundingRect(with: size,
                                                                 options: options,
                                                                 attributes: fontAttribute,
                                                                 context: nil)
        return estimatedFrame.height
    }
}
