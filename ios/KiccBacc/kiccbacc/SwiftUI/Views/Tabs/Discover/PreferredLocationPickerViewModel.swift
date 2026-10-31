//
//  EventLocationPickerViewModel.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import MapKit
import SwiftUI

//enum MapDetails {
//    static let defaultLocation = CLLocationCoordinate2D(latitude: 37.81800, longitude: -122.47834)
//    static let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
//}
@MainActor
final class PreferredLocationPickerViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var alertItem: AlertItem?
    @Published var region = MKCoordinateRegion(center: MapDetails.defaultLocation, span: MapDetails.defaultSpan)
    @Published var searchTxt: String = ""
    @Published var selectedPlace: Place?
    @Published var selectedEventLocation: PreferredLocation?
    @Published var places: [Place] = []
    @Published var mapSize: GeometryProxy?
    
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
            // current location region
            //            region = MKCoordinateRegion(center: locationManager.location!.coordinate,
            //                                        span: MapDetails.defaultSpan)
            break
            
        @unknown default:
            break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
    func searchQuery() {
        places.removeAll()
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchTxt
        
        MKLocalSearch(request: request).start { response, _ in
            guard let result = response else {return}
            
            self.places = result.mapItems.compactMap({ (item) -> Place? in
                return Place(placemark: item.placemark)
            })
        }
    }
    
    func selectPlace(place: Place, radius: MapSelectionRadius? = nil) {
        selectedPlace = place
        
        searchTxt = place.placemark.name ?? ""
        
        guard let center = place.placemark.location?.coordinate else {return}
        self.region = MKCoordinateRegion(center: center, span: radius?.calculateSpan() ?? MapDetails.defaultSpan)
        
        let eventLocation = EventLocation(venueName: searchTxt, latitude: center.latitude, longitude: center.longitude, streetName: place.placemark.streetName, streetNumber: place.placemark.streetNumber, city: place.placemark.city, neighbourhood: place.placemark.neighbourhood, state: place.placemark.state, county: place.placemark.county, zipCode: place.placemark.zipCode, selectionRadius: radius?.rawValue)
        self.selectedEventLocation = eventLocation.convertToPreferredLocation()
        
        self.places = []
    }
    
    func updateRadius(radius: MapSelectionRadius) {
        selectedEventLocation?.selectionRadius = radius.rawValue
    }
    
    func calculateProportion(with radius: MapSelectionRadius) -> CGFloat? {
        
        guard let frameSize = mapSize else {
            return nil
        }
        
        let milesSize = (frameSize.size.height *
                         region.longBetweenPoints(measure: radius)) / (region.span.latitudeDelta)
        return milesSize
    }
}
