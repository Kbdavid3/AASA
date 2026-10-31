//
//  OnboardingVC.swift
//  kiccbacc
//
//  Created by ANKIT YADAV on 07/04/21.
//  Copyright © 2021 APPLE. All rights reserved.
//

import Hero
import UIKit
import SwiftUI

class OnboardingVC: UIViewController {

    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var privacyPolicyLabel: UITextView!
    @IBOutlet private weak var titleLabel: UILabel!
    
    @IBAction func signInBttnDidTap(_ sender: Any) {
        // Present the old UIKit SignIn screen
        let vc = KiccBacc.ViewController.signIn
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func createAccountBttnDidTap(_ sender: Any) {
        // Present the new SwiftUI SignUp screen
        let signUpView = SignUpView()
        let hostingController = UIHostingController(rootView: signUpView)
        hostingController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(hostingController, animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
    }
    
    // MARK: - Methods
    private func configure() {
        let img1 = imageWithGradientBottom(img: UIImage(named: "yoga"))
        let img2 = imageWithGradientBottom(img: UIImage(named: "cinema"))
        let img3 = imageWithGradientBottom(img: UIImage(named: "football"))
        let img4 = imageWithGradientBottom(img: UIImage(named: "gym"))
        let img5 = imageWithGradientBottom(img: UIImage(named: "party"))

        let array = [img1,img2,img3,img4,img5]
        repeatAnimateImagesChanges(images: array as NSArray, imageView: self.bgImageView)
        
        //configure privacy policy label
        privacyPolicyLabel.attributedText = NSMutableAttributedString()
            .termsTextBottom("By registering you confirm that you accept our\n")
            .termsLinkBottom("Privacy policy", url: URL(string: urlManager.privacyPolicyUrl)!)
            .termsTextBottom(" and ")
            .termsLinkBottom("Terms of Use", url: URL(string: urlManager.termsOfUseUrl)!)
            .termsTextBottom(" .")
        privacyPolicyLabel.textAlignment = .center
        
        titleLabel.hero.id = HeroIDs.titleLabel
    }
    
    
    
    func repeatAnimateImagesChanges(images:NSArray, imageView:UIImageView) {

        if (images.count == 0) {
            return
        }

        var newImage = images.firstObject as! UIImage

        if (imageView.image != nil) {
            for i in 0..<images.count {
                newImage = images.object(at: i) as! UIImage
                if(imageView.image?.isEqual(newImage))! {
                    newImage = i == images.count - 1 ? images.firstObject as! UIImage : images.object(at: i + 1) as! UIImage
                }
            }
        }

        bgImageView.imageWithFade = newImage

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.repeatAnimateImagesChanges(images: images, imageView: imageView)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    

    
}

extension UIImageView{
    var imageWithFade:UIImage?{
        get {
            return self.image
        }
        
        set {
            UIView.transition(with: self,
                              duration: 0.5, options: .transitionCrossDissolve, animations: {
                                self.image = newValue
            }, completion: nil)
        }
    }
}


