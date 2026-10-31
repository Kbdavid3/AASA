//
//  AgeGroup.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 24/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation

enum AgeGroup : Int, CaseIterable{
    case twelvePlus = 12
    case eighteenPlus = 18
    case twentyOnePlus = 21
    case twentyFivePlus = 25
}

extension AgeGroup: Identifiable {
    var id: String {
        "\(self.rawValue)"
    }
    
    var title: String {
        "\(self.rawValue) +"
    }
}
