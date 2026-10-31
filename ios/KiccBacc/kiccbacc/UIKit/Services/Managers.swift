//
//  Manager.swift
//  kiccbacc
//
//  Created by ANKIT YADAV on 24/03/21.
//  Copyright © 2021 APPLE. All rights reserved.
//

import Foundation

struct urlManager {
    static let appUrl = "https://apps.apple.com/us/app/kiccbacc/id1534204449"
    static let privacyPolicyUrl = "https://privacypolicy"
    static let termsOfUseUrl = "https://termsofuse"
    static let faqUrl = ""
    static let releaseNotesUrl = ""
}

struct segueManager {
    static let settings = "toSettings"
}

struct fontManager {
    static let regular = "AirbnbCerealApp-Regular"
    static let bold = "AirbnbCerealApp-Bold"
    static let medium = "AirbnbCerealApp-Medium"
}

struct imageNameManager {
    static let noneMark = "noneMark"
    static let checkMark = "checkMark"
    static let check = "check"
}

struct userDefaultsKeyManager {
    static let appIconKey = "appIcon"
}

struct appColorManager {
    static let bgColor = "bgColor"
    static let orangeColor = "orangeColor"
    static let peachColor = "peachColor"
    static let SecondaryBgColor = "SecondaryBgColor"
    static let SubtitleTextColor = "SubtitleTextColor"
    static let whiteTextColor = "whiteTextColor"
    static let grayInterestBgColor = "grayInterestBgColor"
}

struct VCIdentifierManager {
  
    static let signInVC = "SignInViewController"
    static let createAccountVC = "SignUpViewController"
    
}

struct HeroIDs {
    static let titleLabel = "titleAnimate"
    static let cardView = "cardViewAnimate"
    static let descriptionLabel = "descriptionAnimate"
    static let emailField = "emailFieldAnimate"
    static let sendBttn = "sendBttnAnimate"
}


let userDefaults = UserDefaults(suiteName: "group.kiccbacc")
