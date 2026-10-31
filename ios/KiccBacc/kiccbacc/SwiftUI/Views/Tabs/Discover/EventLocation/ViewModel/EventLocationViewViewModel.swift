//
//  EventLocationViewViewModel.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import MapKit
import SwiftUI

enum MapDetails {
    static let defaultLocation = CLLocationCoordinate2D(latitude: 40.75773, longitude: -73.985708)
    static let defaultCLLocation = CLLocation(latitude: 40.75773, longitude: -73.985708)
    static let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
}

@MainActor
final class EventLocationViewViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var alertItem: AlertItem?
    @Published var region = MKCoordinateRegion(center: MapDetails.defaultLocation, span: MapDetails.defaultSpan)
    @Published var places: [Place] = []
    
    var locationManager: CLLocationManager?
    
    func checkIfLocationServicesIsEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager!.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager!.delegate = self
        } else {
            alertItem = AlertItem(title: Text("Permission denied!"), message: Text("Please enable location services in your device settings."), dismissButton: .default(Text("Enable"), action: {
                if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
                    UIApplication.shared.open(appSettings)
                }
            }))
        }
    }
    
    private func checkLocationAuthorization() {
        guard let locationManager = locationManager else { return }
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            
        case .restricted:
            alertItem = AlertItem(title: Text("Permission restricted!"),
                                  message: Text("Your location is restricted likely due to parental controls."), dismissButton: .cancel())
            
        case .denied:
            alertItem = AlertItem(title: Text("Permission restricted!"),
                                  message: Text("You have denied this app location permission. GOt into settings to change it."), dismissButton: .default(Text("Enable"), action: {
                if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
                    UIApplication.shared.open(appSettings)
                }
            }))
            
        case .authorizedAlways, .authorizedWhenInUse:
            break
            
        @unknown default:
            break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}

