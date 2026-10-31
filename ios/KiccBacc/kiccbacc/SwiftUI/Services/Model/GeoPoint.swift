//
//  GeoPoint.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 27/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation
import MapKit
import Contacts

struct GeoPoint: Codable {
    private var longitude: Double
    private var latitude: Double
}

extension GeoPoint {
    var center: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
}

struct Place: Identifiable {
    var id = UUID().uuidString
    
    var placemark: CLPlacemark
}

extension CLPlacemark {
    
    // street name, eg. Infinite Loop
    var streetName: String? { thoroughfare }
    
    // // eg. 1
    var streetNumber: String? { subThoroughfare }
    
    // city, eg. Cupertino
    var city: String? { locality }
    
    // neighbourhood, common name, eg. Mission District
    var neighbourhood: String? { subLocality }
    
    // state, eg. CA
    var state: String? { administrativeArea }
    
    // county, eg. Santa Clara
    var county: String? { subAdministrativeArea }
    
    // zip code, eg. 95014
    var zipCode: String? { postalCode }
    
    // postal address formatted
    var postalAddressFormatted: String? {
        guard let postalAddress = postalAddress else { return nil }
        return CNPostalAddressFormatter().string(from: postalAddress)
    }
}

extension CLLocation {
    func placemark(completion: @escaping (_ placemark: CLPlacemark?, _ error: Error?) -> ()) {
        CLGeocoder().reverseGeocodeLocation(self) { completion($0?.first, $1) }
    }
}
