//
//  EventLocationPicker.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import MapKit

struct EventLocationPicker: View {
    
    @Environment(\.presentationMode) private var presentation
    
    @StateObject private var viewModel = EventLocationPickerViewModel()
    
    @Binding var pickedLocation: EventLocation?
    @Binding var newLocation: String
    
    @State private var selectedLocation: EventLocation?
    
    @State var pointsOfInterest: [EventLocation] = []
    
    var body: some View {
        Map(coordinateRegion: $viewModel.region, interactionModes: [.all], showsUserLocation: false, annotationItems: pointsOfInterest) { item in
            MapAnnotation(coordinate: item.coordinate) {
                MapAnnotationView(name: item.venueName)
            }
        }
        .onChange(of: viewModel.selectedEventLocation) { newValue in
            self.selectedLocation = newValue
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
                                            viewModel.selectPlace(place: place)
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
                
                if let selectedPlace = viewModel.selectedEventLocation  {
                    HStack {
                        VStack(alignment: .leading) {
                            
                            
                            let address = [(selectedPlace.streetName),
                                           (selectedPlace.city),
                                           (selectedPlace.state),
                                           (selectedPlace.county),
                                           (selectedPlace.zipCode)]
                            
                            Text("\(address.compactMap { $0 }.joined(separator: ", "))")
                                .frame(maxWidth: .infinity,  alignment: .leading)
                            
                            
                            
                            Button {
                                pickedLocation = selectedLocation
                                newLocation = "\(selectedPlace.streetName ?? ""), \(selectedPlace.city ?? ""), \(selectedPlace.state ?? ""), \(selectedPlace.county ?? ""), \(selectedPlace.zipCode ?? "")"
                                presentation.wrappedValue.dismiss()
                            } label: {
                                Text("Confirm location")
                                    .font(.system(size: 15, weight: .regular, design: .default))
                                    .padding(7)
                                    .background(Color.buttonBgColor)
                                    .clipShape(Capsule())
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.bgColor)
                    .cornerRadius(15)
                    .padding()
                }
            }
        )
        .onAppear {
            viewModel.checkIfLocationServicesIsEnabled()
            
            if let location = pointsOfInterest.first {
                viewModel.region = MKCoordinateRegion(center: location.coordinate, span: MapDetails.defaultSpan)
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
    }
}
