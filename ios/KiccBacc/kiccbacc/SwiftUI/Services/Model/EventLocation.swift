//
//  EventLocation.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 27/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation
import CoreLocation

struct EventLocation: Identifiable, Codable, Equatable {
    var id = UUID()
    
    var venueName: String
    var latitude: Double
    var longitude: Double
    var streetName: String?
    var streetNumber: String?
    var city: String?
    var neighbourhood: String?
    var state: String?
    var county: String?
    var zipCode: String?
    var selectionRadius: Double?
}

extension EventLocation {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D (
            latitude: self.latitude,
            longitude: self.longitude
        )
    }
    
    var location: CLLocation {
        CLLocation(latitude: self.latitude, longitude: self.longitude)
    }
    
    func convertToPreferredLocation() -> PreferredLocation? {
        guard let currentUserID = UserManager.shared.currentUserID else {
            return nil
        }
        
        return PreferredLocation(userID: currentUserID, latitude: latitude, longitude: longitude, streetName: streetName, streetNumber: streetNumber, city: city, neighbourhood: neighbourhood, state: state, county: county, zipCode: zipCode, selectionRadius: selectionRadius, placeName: venueName)
    }
}

extension EventLocation {
    init() {
        self.init(venueName: "Times Square", latitude: 40.75773, longitude: -73.985708, streetName: nil, streetNumber: nil, city: "Manhattan", neighbourhood: nil, state: "New York", county: "United States", zipCode: "10036")
    }
    
    init(venueName: String, placemark: CLPlacemark) {
        self.init(venueName: venueName, latitude: placemark.location?.coordinate.latitude ?? 0, longitude: placemark.location?.coordinate.longitude ?? 0, streetName: placemark.streetName, streetNumber: placemark.streetNumber, city: placemark.city, neighbourhood: placemark.neighbourhood, state: placemark.state, county: placemark.county, zipCode: placemark.zipCode)
    }
}


