//
//  EventLocationView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import MapKit

struct EventLocationView: View {
    
    @Environment(\.presentationMode) private var presentation
    
    @StateObject private var viewModel = EventLocationViewViewModel()
    
    var isPresentedInFullScreen: Bool
    var pointsOfInterest: [EventLocation] = []
    
    init(isPresentedInFullScreen: Bool = false, location: EventLocation) {
        self.isPresentedInFullScreen = isPresentedInFullScreen
        self.pointsOfInterest = [location]
    }
    
    var body: some View {
        Map(coordinateRegion: $viewModel.region, interactionModes: isPresentedInFullScreen ? [.all] : [], showsUserLocation: false, annotationItems: pointsOfInterest) { item in
            MapAnnotation(coordinate: item.coordinate) {
                MapAnnotationView(name: item.venueName)
            }
        }
        .ignoresSafeArea()
        .accentColor(Color.appColor)
        .if (isPresentedInFullScreen) { view in
            view
                .overlay (
                    VStack {
                        
                        HStack {
                            
                            Spacer()
                            
                            Button {
                                HapticGenerator.light.impactOccurred()
                                presentation.wrappedValue.dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .padding()
                                    .background(BlurView(style: .systemThinMaterialDark))
                                    .cornerRadius(15)
                                    .padding(.trailing)
                                    .foregroundColor(.white)
                            }
                        }
                        Spacer()
                    }
                )
        }
        .onAppear {
            if isPresentedInFullScreen {
                viewModel.checkIfLocationServicesIsEnabled()
            }
            
            if let location = pointsOfInterest.first {
                viewModel.region = MKCoordinateRegion(center: location.coordinate, span: MapDetails.defaultSpan)
            }
        }
        .alert(item: $viewModel.alertItem) { alertItem in
            guard let primaryButton = alertItem.primaryButton, let secondaryButton = alertItem.secondaryButton
            else {
                return Alert(title: alertItem.title, message: alertItem.message, dismissButton: alertItem.dismissButton)
            }
            
            return Alert(title: alertItem.title, message: alertItem.message, primaryButton: primaryButton, secondaryButton: secondaryButton)
        }
    }
}

struct EventLocationView_Previews: PreviewProvider {
    static var previews: some View {
        EventLocationView(isPresentedInFullScreen: true, location: EventLocation())
            .preferredColorScheme(.dark)
    }
}

