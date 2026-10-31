//
//  LocationPickerNavigationViewComponent.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 10/03/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import SwiftUI

struct LocationPickerNavigationViewComponent: View {
    
    @Binding var currentUser: User?
    @Binding var newLocation: String
    
    @StateObject private var viewModel = LocationPickerNavigationViewComponentViewModel()
    
    @State private var viewItem: ViewItem?
    @State private var navigate = false
    
    var body: some View {
        
        NavigationLink("", destination: PreferredLocationPicker(pickedLocation: $viewModel.pickedLocation, newLocation: $newLocation)
            .navigationBarHidden(true), isActive: $navigate)
        
        VStack(alignment: .leading, spacing: 0) {
            
            if let _ = viewModel.currentLocation {
                HStack {
                    
                    Image("locationNew")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12)
                        .foregroundStyle(Color.location)
                    
                    Text(getLocationLabel())
                        .lineLimit(1)
                        .foregroundStyle(Color.labelColor)
                }
                .padding(.vertical, 18)
                .contentShape(Rectangle())
                .onTapGesture {
                    navigate.toggle()
                }
            } else {
                ProgressView()
                    .padding(.vertical, 10)
            }
        }
        .onChange(of: viewModel.pickedLocation) { newCurrentLocation in
            if let prefLoc = newCurrentLocation {
                LocationManager.shared.updatePreferredLocation(preferredLocation: prefLoc)
                viewModel.currentLocation = prefLoc
            }
        }
        .alert(item: $viewModel.alertItem) { alertItem in
            guard let primaryButton = alertItem.primaryButton, let secondaryButton = alertItem.secondaryButton
            else {
                return Alert(title: alertItem.title, message: alertItem.message, dismissButton: alertItem.dismissButton)
            }
            
            return Alert(title: alertItem.title, message: alertItem.message, primaryButton: primaryButton, secondaryButton: secondaryButton)
        }
        .sheet(item: $viewItem) { } content: { viewItem in
            viewItem.viewToPresent
        }
    }
    
    
    private func getLocationLabel() -> String {
        var label = currentUser?.preferredLocation?.getName() ?? ""
        
        if  let _ = currentUser?.preferredLocation,
            let radius = currentUser?.preferredLocation?.selectionRadius {
            label += " - \(Int(radius))mi"
        }
        
        return label
    }
}
