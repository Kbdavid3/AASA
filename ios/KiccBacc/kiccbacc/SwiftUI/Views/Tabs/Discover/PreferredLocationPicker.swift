//
//  EventLocationPicker.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import MapKit

struct PreferredLocationPicker: View {
    
    @Environment(\.presentationMode) private var presentation
    
    @StateObject private var viewModel = PreferredLocationPickerViewModel()
    
    @Binding var pickedLocation: PreferredLocation?
    @Binding var newLocation: String
    
    @State private var selectedLocation: PreferredLocation?
    
    @State var pointsOfInterest: [PreferredLocation] = []
    
    @State var selectedDistance: MapSelectionRadius = .ten
    
    var body: some View {
        VStack {
            GeometryReader { geo in
                ZStack {
                    Map(coordinateRegion: $viewModel.region, interactionModes: [.all], showsUserLocation: false, annotationItems: pointsOfInterest) { item in
                        MapAnnotation(coordinate: item.coordinate) {
                            
                            if let size = viewModel.calculateProportion(with: selectedDistance) {
                                Circle()
                                    .stroke(Color.location, lineWidth: 2)
                                    .background(Circle().foregroundColor(Color.location.opacity(0.4)))
                                    .frame(width: size, height: size)
                            }
                        }
                    }
                    .onAppear {
                        viewModel.mapSize = geo
                    }

                    

                }
            }
            
            Spacer()
            
            VStack {
                if let selectedPlace = viewModel.selectedEventLocation  {
                    
                    let address = [(selectedPlace.streetName),
                                   (selectedPlace.city),
                                   (selectedPlace.state),
                                   (selectedPlace.county),
                                   (selectedPlace.zipCode)]
                    
                    Text("\(address.compactMap { $0 }.joined(separator: ", "))")
                        .lineLimit(1)
                        .frame(maxWidth: .infinity,  alignment: .leading)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    Picker("", selection: $selectedDistance) {
                        Text("10 miles").tag(MapSelectionRadius.ten)
                        Text("50 miles").tag(MapSelectionRadius.fifty)
                        Text("100 miles").tag(MapSelectionRadius.hundred)
                        Text("200 miles").tag(MapSelectionRadius.twoHundred)
                        Text("500 miles").tag(MapSelectionRadius.fiveHundred)
                    }
                    .pickerStyle(.segmented)
                }
                
                Button {
                    pickedLocation = viewModel.selectedEventLocation
                    presentation.wrappedValue.dismiss()
                } label: {
                    Text("Apply")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.buttonBgColor)
                .padding(.bottom)
            }
            .padding()
            .frame(minHeight: 155)
        }
        .onChange(of: selectedDistance) { newValue in
            viewModel.updateRadius(radius: newValue)
        }
        .onChange(of: viewModel.selectedEventLocation) { newValue in
            selectedLocation = newValue
            
            if let newValue = newValue {
                pointsOfInterest = [newValue]
            }
        }
        .ignoresSafeArea()
        .accentColor(Color.appColor)
        .overlay (
            VStack {
                VStack {
                    ZStack(alignment: .center) {
                        TextField("Search location", text: $viewModel.searchTxt)
                            .padding()
                            .padding(.leading, 30)
                        
                        HStack {
                            Button {
                                if viewModel.searchTxt.isEmpty {
                                    presentation.wrappedValue.dismiss()
                                } else {
                                    withAnimation {
                                        viewModel.searchTxt = ""
                                        viewModel.selectedPlace = nil
                                    }
                                }
                            } label: {
                                Assets.UI.arrowLeft
                                    .padding()
                                    .cornerRadius(10)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    if !viewModel.places.isEmpty && !viewModel.searchTxt.isEmpty {
                        Divider()
                            .padding(.horizontal)
                        
                        ScrollView(.vertical, showsIndicators: true) {
                            VStack {
                                ForEach(viewModel.places) { place in
                                    Button {
                                        withAnimation {
                                            viewModel.selectPlace(place: place, radius:selectedDistance)
                                        }
                                    } label: {
                                        if let name = place.placemark.name {
                                            Text(name)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.horizontal)
                                                .padding(.vertical, 5)
                                                .foregroundColor(.labelColor)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(minHeight: 0, maxHeight: 350)
                    }
                }
                .padding(.vertical, 8)
                .background(Color.bgColor)
                .cornerRadius(18)
                .padding(.horizontal)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 0)
                .padding(.top, 30)
                
                Spacer()
            }
        )
        .onAppear {
            viewModel.checkIfLocationServicesIsEnabled()
            if let pickedLocation {
                
                let radius = pickedLocation.selectionRadius
                let selection = MapSelectionRadius(value: radius ?? 10)
                
                viewModel.region = MKCoordinateRegion(center: pickedLocation.coordinate, span: selection?.calculateSpan() ?? MapSelectionRadius.ten.calculateSpan())
                pointsOfInterest = [pickedLocation]
                selectedDistance = selection ?? .ten
                viewModel.selectedEventLocation = pickedLocation
            }
        }
        .onChange(of: viewModel.searchTxt, perform: { newValue in
            withAnimation {
                if newValue != viewModel.selectedPlace?.placemark.name {
                    viewModel.searchQuery()
                }
            }
        })
        .alert(item: $viewModel.alertItem) { alertItem in
            guard let primaryButton = alertItem.primaryButton, let secondaryButton = alertItem.secondaryButton
            else {
                return Alert(title: alertItem.title, message: alertItem.message, dismissButton: alertItem.dismissButton)
            }
            
            return Alert(title: alertItem.title, message: alertItem.message, primaryButton: primaryButton, secondaryButton: secondaryButton)
        }
        .onChange(of: viewModel.region.center) { newCenter in
            // Update selected location when map is moved
            updateLocationFromMapCenter(coordinate: newCenter)
        }
    }
    
    // Function to update location when map is moved
    private func updateLocationFromMapCenter(coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    var newLocation = PreferredLocation(
                        userID: UserManager.shared.currentUserID ?? "",
                        placemark: placemark
                    )
                    newLocation.selectionRadius = selectedDistance.rawValue
                    viewModel.selectedEventLocation = newLocation
                    selectedLocation = newLocation
                    pointsOfInterest = [newLocation]
                }
            }
        }
    }
}
