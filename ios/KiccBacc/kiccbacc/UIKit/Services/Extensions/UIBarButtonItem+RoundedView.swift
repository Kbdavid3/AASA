//
//  UIBarButtonItem+RoundedView.swift
//  kiccbacc
//
//  Created by ANKIT YADAV on 12/04/21.
//  Copyright © 2021 APPLE. All rights reserved.
//

import Foundation
import UIKit

class ImageBarButton : UIView {
    
    var imageView: UIImageView!
    var button: UIButton!

    convenience init(withImage image: UIImage? = nil, frame: CGRect = CGRect(x: 0, y: 0, width: 30, height: 30)) {
        self.init(frame: frame)

        imageView = UIImageView(frame: frame)
        imageView.backgroundColor = .clear
        imageView.layer.cornerRadius = frame.height/2
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)

        button = UIButton(frame: frame)
        button.backgroundColor = .clear
        button.setTitle("", for: .normal)
        addSubview(button)

        self.imageView.image = image
    }

    func load()-> UIBarButtonItem {
        return UIBarButtonItem(customView: self)
    }
}
