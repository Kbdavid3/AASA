//
//  User.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 22/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation

struct User: Codable, Equatable {
    var userID: String
    var email: String
    var username: String
    var fullName: String
    var ageGroup: Int
    var bio: String
    var preferredLocation: PreferredLocation?
    var profileImageUrlString: String?
    var followerIDs: [String]?
    var followingIDs: [String]?
    var followerCounter: Int
    var followingCounter: Int
    var pushNotificationTokens: [String]?
    var createdAt: Date
    var accessToken: String?
    var expiresAt: String?
    var refreshToken: String?
    var merchantId: String?
    var verified: Bool?
    var instagramUsername: String?
    var snapchatUsername: String?
    var customURL: String?
    var interests: [String]?
}

extension User {
    var ageGroupModel: AgeGroup? {
        AgeGroup(rawValue: self.ageGroup)
    }
    
    func getInitials() -> String {
        let initial = fullName.first ?? Character(" ")
        return "\(initial)".trimmingCharacters(in: .whitespaces)
    }
}


extension User {
    init() {
        self.init(userID: "", email: "", username: "", fullName: "", ageGroup: 18, bio: "", preferredLocation: nil, profileImageUrlString: nil, followerIDs: nil, followingIDs: nil, followerCounter: 0, followingCounter: 0, pushNotificationTokens: nil, createdAt: Date(), accessToken: nil, expiresAt: nil, refreshToken: nil, merchantId: nil, verified: false, instagramUsername: nil, snapchatUsername: nil, customURL: nil, interests: nil)
    }
}


// user's data model when user has only signed up and not submitted their data
struct InitialUser: Codable {
    var userID: String
    var username: String
    var email: String
    var createdAt: Date
}
