//
//  PreferredLocation.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 07/03/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation
import CoreLocation

struct PreferredLocation: Codable, Equatable, Identifiable {
    let id = UUID()
    var userID: String
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
    var placeName: String?
    
    enum CodingKeys: String, CodingKey {
        case userID
        case latitude
        case longitude
        case streetName
        case streetNumber
        case city
        case neighbourhood
        case state
        case county
        case zipCode
        case selectionRadius
        case placeName
    }
}

// functions and conversions
extension PreferredLocation {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D (
            latitude: self.latitude,
            longitude: self.longitude
        )
    }
    
    var location: CLLocation {
        CLLocation(latitude: self.latitude, longitude: self.longitude)
    }
    
    func convertToDictionary() -> [String : Any]? {
        do {
            // convert model to json data
            let jsonData = try self.jsonData()
            
            // get dictionary from the data
            let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            let dictionary = json as? [String : Any]
            return dictionary
        } catch {
            return nil
        }
    }
    
    func getName() -> String {
        return placeName ?? neighbourhood ?? city ?? state ?? "---"
    }
}

// init
extension PreferredLocation {
    init() {
        self.init(userID: "fasfn", latitude: 40.75773, longitude: -73.985708, streetName: nil, streetNumber: nil, city: "Manhattan", neighbourhood: nil, state: "New York", county: "United States", zipCode: "10036")
    }
    
    init(userID: String, placemark: CLPlacemark) {
        self.init(userID: userID, latitude: placemark.location?.coordinate.latitude ?? 0, longitude: placemark.location?.coordinate.longitude ?? 0, streetName: placemark.streetName, streetNumber: placemark.streetNumber, city: placemark.city, neighbourhood: placemark.neighbourhood, state: placemark.state, county: placemark.county, zipCode: placemark.zipCode)
    }
}

extension Encodable {
    /// Encode into JSON and return `Data`
    func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
}
