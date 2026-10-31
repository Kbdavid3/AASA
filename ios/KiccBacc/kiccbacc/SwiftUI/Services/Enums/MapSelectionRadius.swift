//
//  MapSelectionRadius.swift
//  kiccbacc
//
//  Created by Guillermo Jimenez on 9/21/24.
//  Copyright © 2024 APPLE. All rights reserved.
//

import Foundation
import MapKit

enum MapSelectionRadius : Double {
    case ten = 10
    case fifty = 50
    case hundred = 100
    case twoHundred = 200
    case fiveHundred = 500
    
    init?(value: Double) {
        switch value {
        case 10: self = .ten
        case 50: self = .fifty
        case 100: self = .hundred
        case 200: self = .twoHundred
        case 500: self = .fiveHundred
        default: return nil
        }
    }
    
    func calculateSpan() -> MKCoordinateSpan {
           // Adjust the span based on the selected radius
           let delta = self.rawValue / 69 
        return MKCoordinateSpan(latitudeDelta: (delta * 4), longitudeDelta: (delta * 4))
       }
}
