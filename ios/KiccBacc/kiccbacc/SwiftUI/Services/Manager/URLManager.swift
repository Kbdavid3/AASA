//
//  URLManager.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 20/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation

struct URLManager {
    // Safe URL creation with fallback to website if somehow invalid
    static let instagram: URL = {
        guard let url = URL(string: "https://www.instagram.com/kiccbaccapp") else {
            print("⚠️ Invalid Instagram URL, using fallback")
            return URL(string: "https://kiccbacc.com")!
        }
        return url
    }()
    
    static let meta: URL = {
        guard let url = URL(string: "https://www.facebook.com/kiccbacc") else {
            print("⚠️ Invalid Facebook URL, using fallback")
            return URL(string: "https://kiccbacc.com")!
        }
        return url
    }()
}
