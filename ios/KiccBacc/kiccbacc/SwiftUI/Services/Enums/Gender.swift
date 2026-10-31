//
//  Gender.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 25/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation

enum Gender: Int, CaseIterable {
    case male = 0
    case female
}

extension Gender: Identifiable {
    var id: String {
        self.notation
    }
    
    var title: String {
        switch self {
        case .male:
            return "Male"
        case .female:
            return "Female"
        }
    }
    
    var notation: String {
        switch self {
        case .male:
            return "M"
        case .female:
            return "F"
        }
    }
}
