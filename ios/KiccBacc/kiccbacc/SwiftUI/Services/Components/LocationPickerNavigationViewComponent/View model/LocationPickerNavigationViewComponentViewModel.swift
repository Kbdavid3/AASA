//
//  LocationPickerNavigationViewComponentViewModel.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 10/03/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import MapKit
import SwiftUI
import CoreLocation

@MainActor
class LocationPickerNavigationViewComponentViewModel: ObservableObject {
    
    @Published var alertItem: AlertItem?
    @Published var currentLocation: PreferredLocation?
    @Published var pickedLocation: PreferredLocation?
    @Published var hasLocationError: Bool = false
    
    init() {
        self.fetchLocation()
    }
    
    func fetchLocation() {
        LocationManager.shared.getLocationForFetchingEvents { result in
            switch result {
            case .success(let location):
                self.currentLocation = location
                self.pickedLocation = location
                break
            case .failure(let locationError):
                switch locationError {
                case .permissionDenied:
                    break
                case .userNotFound:
                    break
                case .noLocationManager:
                    break
                case .noPlacemark:
                    break
                case .unknownError:
                    break
                }
            }
        }
    }
}

