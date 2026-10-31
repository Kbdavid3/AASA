//
//  CLLocationCoordinate2D.swift
//  kiccbacc
//
//  Created by Guillermo Jimenez on 9/21/24.
//  Copyright © 2024 APPLE. All rights reserved.
//

import Foundation
import MapKit

extension  CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude ||
        lhs.longitude == rhs.longitude
    }
}
