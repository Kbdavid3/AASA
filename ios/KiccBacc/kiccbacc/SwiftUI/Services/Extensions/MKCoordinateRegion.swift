//
//  MKCoordinateRegion.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import Foundation
import MapKit

extension  MKCoordinateRegion: Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        lhs.center == rhs.center
    }

    /// Calculates the longitudinal distance between 2 points using the circle radius
    func longBetweenPoints(measure: MapSelectionRadius) -> CLLocationDistance {

        let longitudinalMeasure = measure.rawValue /  69.0
        
        
        let loc1 = CLLocation(latitude: center.latitude - longitudinalMeasure, longitude: center.longitude)
        let loc2 = CLLocation(latitude: center.latitude + longitudinalMeasure, longitude: center.longitude)
        
        // To calculate how many meters are between any 2 points of the circle
        let metersInLatitude = loc1.distance(from: loc2)

        // Converting to kilometers
        let value = Measurement(value: metersInLatitude, unit: UnitLength.meters).converted(to: .miles)
        
        return value.value / 69.0
    }
}
