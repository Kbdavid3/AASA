//
//  LocationManager.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 19/03/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import MapKit
import CoreLocation

enum LocationError: Error {
    case permissionDenied
    case userNotFound
    case noLocationManager
    case noPlacemark
    case unknownError
}

class LocationManager: NSObject, ObservableObject {
    
    static let shared = LocationManager()
    
    private var locationManager: CLLocationManager?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    /// Initializes the location manager and ensures it is properly set up.
    private func setupLocationManager() {
        guard CLLocationManager.locationServicesEnabled() else {
            print("⚠️ Location services are disabled.")
            return
        }
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        // ✅ Do NOT call `checkLocationAuthorization()` here to avoid UI unresponsiveness.
    }
    
    /// Handles authorization changes and requests permissions if needed.
    private func checkLocationAuthorization() {
        guard let locationManager = locationManager else { return }
        
        DispatchQueue.global(qos: .background).async {  // ✅ Run this in a background thread.
            switch locationManager.authorizationStatus {
            case .notDetermined:
                DispatchQueue.main.async {
                    locationManager.requestWhenInUseAuthorization()
                }
                
            case .restricted, .denied:
                print("🚫 Location access is restricted or denied.")
                
            case .authorizedAlways, .authorizedWhenInUse:
                self.fetchCurrentLocation { _ in }  // ✅ Only fetch location if authorized.
                
            @unknown default:
                print("❓ Unknown authorization status.")
            }
        }
    }
    
    /// Fetches the current user location asynchronously.
    func fetchCurrentLocation(completion: @escaping (Result<PreferredLocation?, LocationError>) -> Void) {
        guard let locationManager = locationManager, let location = locationManager.location else {
            completion(.failure(.noLocationManager))
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            location.placemark { placemark, error in
                if let _ = error {
                    completion(.failure(.noPlacemark))
                    return
                }
                
                guard let placemark = placemark else {
                    completion(.failure(.noPlacemark))
                    return
                }
                
                let preferredLocation = EventLocation(venueName: "", placemark: placemark).convertToPreferredLocation()
                
                DispatchQueue.main.async {
                    completion(.success(preferredLocation))
                }
            }
        }
    }
    
    /// Retrieves the user's location for fetching events.
    func getLocationForFetchingEvents(completion: @escaping (Result<PreferredLocation?, LocationError>) -> Void) {
        guard let currentUserID = UserManager.shared.currentUserID else {
            completion(.failure(.userNotFound))
            return
        }
        
        UserManager.shared.getUser(withUserID: currentUserID) { currentUser in
            if let preferredLocation = currentUser?.preferredLocation {
                completion(.success(preferredLocation))
            } else {
                self.fetchCurrentLocation(completion: completion)
            }
        }
    }
    
    /// Checks if a user’s location is within a given radius.
    func isLocationWithinRadius(userLocation: CLLocation, radius: Double) -> Bool {
        guard let circleCenter = locationManager?.location else { return false }
        return userLocation.distance(from: circleCenter) <= radius
    }
    
    /// Updates the user's preferred location.
    func updatePreferredLocation(preferredLocation: PreferredLocation) {
        do {
            try UserManager.shared.update(preferredLocation: preferredLocation)
        } catch {
            print("⚠️ Failed to update location: \(error.localizedDescription)")
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.global(qos: .background).async {
            self.checkLocationAuthorization()
        }
    }
}
