//
//  EditEventView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
//import SDWebImageSwiftUI

struct EditEventView: View {
    
    @Environment(\.presentationMode) private var presentation
    
    var event: Event
    var host: User
    
    @State private var pickedImage: UIImage?
    @State private var showImagePicker: Bool = false
    @State private var newName: String = ""
    @State private var newDescription: String = ""
    @State private var newLocation: String = ""
    @State private var newToDate = Date()
    @State private var newFromDate = Date()
    @State private var pickedLocation: EventLocation?
    @State private var pickedAgeGroupInt: Int = 12
    @State private var selectedEventType: EventType = .all
    @State private var isLoading: Bool = false
    @State private var currentLoadingState: String?
    @State private var newpaymentAmount: String = ""
    @State private var password: String = ""
    
    @State private var alertItem: AlertItem?
    @State private var viewControllerItem: UIKitViewControllerItem?
    @State private var viewItem: ViewItem?
    
    var body: some View {
        if isLoading {
            ProgressView()
            
            if let currentLoadingState = currentLoadingState {
                Text(currentLoadingState)
            }
        } else {
            
            CustomScrollView(navigationStyle: .dismissBack(title: "Edit event"), scrollViewData: {
                VStack(alignment: .leading, spacing: 0) {
                    if let pickedImage = pickedImage {
                        Image(uiImage: pickedImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 400)
                            .padding(.horizontal)
                            .overlay(
                                VStack {
                                    Spacer()
                                    
                                    Button(action: {
                                        showImagePicker.toggle()
                                    }, label: {
                                        Text("Edit")
                                            .padding(10)
                                            .background(BlurView(style: .systemUltraThinMaterial))
                                            .clipShape(Capsule())
                                            .foregroundColor(.labelColor)
                                            .padding(.bottom)
                                    })
                                }
                            )
                    } else if let url = URL(string: event.eventBannerUrl) {
//                        WebImage(url: url)
//                            .resizable()
//                            .placeholder {
//                                Rectangle()
//                                    .foregroundColor(.gray.opacity(0.2))
//                            }
                        
                            KBImage(url: url)
                        
                            //.scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 400)
                            .padding(.horizontal)
                            .overlay(
                                VStack {
                                    Spacer()
                                    
                                    Button(action: {
                                        showImagePicker.toggle()
                                    }, label: {
                                        Text("Edit")
                                            .padding(10)
                                            .background(BlurView(style: .systemUltraThinMaterial))
                                            .clipShape(Capsule())
                                            .foregroundColor(.labelColor)
                                            .padding(.bottom)
                                    })
                                }
                            )
                    } else {
                        Button {
                            showImagePicker.toggle()
                        } label: {
                            VStack {
                                Text("Upload cover")
                                
                                Image(systemName: "cloud.fill")
                            }
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 200, maxHeight: 300)
                            .background(Color.secondaryBgColor)
                            .cornerRadius(10)
                            .foregroundColor(.gray)
                            .padding()
                        }
                        .buttonStyle(FlatLinkStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 30) {
                        CustomInputField(title: "Title", placeholder: "e.g. Drag race", newValue: $newName)
                        
                        CustomInputField(title: "Description", newValue: $newDescription)
                        
                        // integrate map view for picking up the location
                        if let selectedPlace = pickedLocation {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Location")
                                    .font(.system(size: 14, weight: .regular, design: .default))
                                    .foregroundColor(.gray)
                                
                                Text("\(selectedPlace.streetName ?? ""), \(selectedPlace.city ?? ""), \(selectedPlace.state ?? ""), \(selectedPlace.county ?? ""), \(selectedPlace.zipCode ?? "")")
                                    .padding(8)
                                    .background(Color.secondaryBgColor)
                                    .cornerRadius(10)
                                    .font(.system(size: 14, weight: .regular, design: .default))
                                
                                NavigationLink {
                                    EventLocationPicker(pickedLocation: $pickedLocation, newLocation: $newLocation)
                                        .navigationBarTitle("")
                                        .navigationBarHidden(true)
                                } label: {
                                    Text("Change location")
                                        .font(.system(size: 15, weight: .regular, design: .default))
                                        .padding(7)
                                        .background(Color.buttonBgColor)
                                        .clipShape(Capsule())
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding()
                        } else {
                            NavigationLink {
                                EventLocationPicker(pickedLocation: $pickedLocation, newLocation: $newLocation)
                                    .navigationBarTitle("")
                                    .navigationBarHidden(true)
                            } label: {
                                CustomInputField(title: "Location", newValue: $newLocation)
                                    .buttonStyle(FlatLinkStyle())
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Event time")
                                .font(.system(size: 14, weight: .regular, design: .default))
                                .foregroundColor(.gray)
                                .padding(.leading)
                            
                            DatePicker("From", selection: $newFromDate)
                                .padding(.horizontal)
                                .font(.system(size: 14, weight: .regular, design: .default))
                                .foregroundColor(.labelColor)
                                .onChange(of: newFromDate) { newValue in
                                    newToDate = newValue
                                }
                            
                            DatePicker("To", selection: $newToDate)
                                .padding(.horizontal)
                                .font(.system(size: 14, weight: .regular, design: .default))
                                .foregroundColor(.labelColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Event type")
                                .font(.system(size: 14, weight: .regular, design: .default))
                                .foregroundColor(.gray)
                                .padding(.leading)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(EventType.allCases, id: \.self) { type in
                                        if type == .all {
                                            EmptyView()
                                        } else {
                                            Button {
                                                selectedEventType = type
                                            } label: {
                                                Text(type.title)
                                                    .font(.system(size: 13))
                                                    .padding(10)
                                                    .background(isSelected(type: type) ? Color.labelColor : Color.secondaryBgColor)
                                                    .clipShape(Capsule())
                                                    .foregroundColor(isSelected(type: type) ? .antiLabelColor : .labelColor)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
//                        VStack(alignment: .leading, spacing: 10) {
//                            Text("Age group")
//                                .font(.system(size: 14, weight: .regular, design: .default))
//                                .foregroundColor(.gray)
//                                .padding(.leading)
//
//                            Picker("", selection: $pickedAgeGroupInt) {
//                                ForEach(AgeGroup.allCases, id: \.id) { ageGroup in
//                                    Text(ageGroup.title).tag(ageGroup.rawValue)
//                                }
//                            }
//                            .pickerStyle(.segmented)
//                            .padding(.horizontal)
//                        }
                        
                        CustomInputField(title: "Payment link", newValue: $newpaymentAmount)
                        CustomInputField(title: "Password for private events (Optional)", newValue: $password)
                        
                        let paymentURL = newpaymentAmount
                        if let url = URL(string: paymentURL) {
                            URLPreview(previewURL: url)
                                .aspectRatio(contentMode: .fit)
                                .padding()
                        }
                        
                        Button {
                            HapticGenerator.light.impactOccurred()
                            
                            withAnimation {
                                isLoading = true
                                currentLoadingState = "uploading cover..."
                            }
                            
                            var values = [String : Any]()
                            
                            if let data = pickedImage?.jpeg(.high) {
                                EventManager.shared.uploadNewCoverForEvent(data: data, with: event.eventID) { result in
                                    switch result {
                                    case .success(let uploadStatus):
                                        switch uploadStatus {
                                        case .uploaded(withURL: let uploadURL):
                                            guard let uploadURL = uploadURL else {
                                                withAnimation { 
                                                    isLoading = false
                                                    currentLoadingState = nil
                                                }
                                                alertItem = AlertItem(title: Text("Error encountered."), message: Text("Failed to upload image. Please try again."), dismissButton: .cancel())
                                                return
                                            }
                                            
                                            values.updateValue(uploadURL, forKey: "eventBannerUrl")
                                            
                                            withAnimation { currentLoadingState = "updating event..." }
                                            
                                            // update event here
                                            updateEvent(values: values)
                                        case .failed(withError: let error):
                                            withAnimation { 
                                                isLoading = false
                                                currentLoadingState = nil
                                            }
                                            alertItem = AlertItem(title: Text("Error encountered."), message: Text(error.localizedDescription), dismissButton: .cancel())
                                        }
                                    case .failure(let error):
                                        withAnimation { 
                                            isLoading = false
                                            currentLoadingState = nil
                                        }
                                        alertItem = AlertItem(title: Text("Error encountered."), message: Text(error.localizedDescription), dismissButton: .cancel())
                                    }
                                }
                            } else {
                                updateEvent(values: values)
                            }
                        } label: {
                            Text("Update")
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50, alignment: .center)
                                .padding()
                                .background(Color.buttonBgColor)
                                .cornerRadius(15)
                                .padding(.horizontal)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 15)
                }
            }, alertItem: $alertItem, viewControllerItem: $viewControllerItem, viewItem: $viewItem)
            .onAppear {
                self.newName = event.name
                self.newDescription = event.description
                self.newLocation = "\(event.streetName ?? ""), \(event.city ?? ""), \(event.state ?? ""), \(event.county ?? ""), \(event.zipCode ?? "")"
                self.newToDate = event.to
                self.newFromDate = event.from
                if let selectedEvent = EventType(rawValue: event.type) {
                    self.selectedEventType = selectedEvent
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(isPresented: $showImagePicker, selectedImage: $pickedImage)
                    .ignoresSafeArea()
            }
        }
    }
    
    private func isSelected(type: EventType) -> Bool {
        selectedEventType == type
    }
    
    private func updateEvent(values: [String : Any]) {
        
        var values = values
        
        if !newName.isEmpty, event.name != newName {
            values.updateValue(newName, forKey: "name")
        }
        
        if !newDescription.isEmpty, event.description != newDescription  {
            values.updateValue(newDescription, forKey: "description")
        }
        
        if selectedEventType.rawValue != event.type {
            values.updateValue(selectedEventType.id, forKey: "type")
        }
        
        if newToDate != event.to {
            values.updateValue(newToDate, forKey: "to")
        }
        
        if newFromDate != event.from {
            values.updateValue(newFromDate, forKey: "from")
        }
        
        if let pickedLocation = pickedLocation, pickedLocation != event.location {
            values.updateValue(pickedLocation.venueName, forKey: "venueName")
            values.updateValue(pickedLocation.latitude, forKey: "latitude")
            values.updateValue(pickedLocation.longitude, forKey: "longitude")
            
            if let streetName = pickedLocation.streetName {
                values.updateValue(streetName, forKey: "streetName")
            }
            
            if let streetNumber = pickedLocation.streetNumber {
                values.updateValue(streetNumber, forKey: "streetNumber")
            }
            
            if let city = pickedLocation.city {
                values.updateValue(city, forKey: "city")
            }
            
            if let neighbourhood = pickedLocation.neighbourhood {
                values.updateValue(neighbourhood, forKey: "neighbourhood")
            }
            
            if let state = pickedLocation.state {
                values.updateValue(state, forKey: "state")
            }
            
            if let country = pickedLocation.county {
                values.updateValue(country, forKey: "country")
            }
            
            if let zipCode = pickedLocation.zipCode {
                values.updateValue(zipCode, forKey: "zipCode")
            }
        }
        
        if URL(string: newpaymentAmount) != nil {
            values.updateValue(newpaymentAmount, forKey: "paymentAmount")
        }
        
        if password != "" {
            values.updateValue(password, forKey: "password")
        }
        
        if values.count > 0 {
            EventManager.shared.updateEventWith(eventID: event.eventID, with: values) { isUpdated in
                if isUpdated {
                    // Reset loading state and dismiss
                    withAnimation { 
                        isLoading = false
                        currentLoadingState = nil
                    }
                    presentation.wrappedValue.dismiss()
                    print("updated values", values)
                } else {
                    // failed to update event details, present error
                    withAnimation { 
                        isLoading = false
                        currentLoadingState = nil
                    }
                    alertItem = AlertItem(title: Text("Updation failed"), message: Text("Cannot update the event at the moment please try again later."), dismissButton: .cancel())
                }
            }
        } else {
            withAnimation { 
                isLoading = false
                currentLoadingState = nil
            }
            
            alertItem = AlertItem(title: Text("No changes."), message: Text("Make some changes in the event to update the event."), dismissButton: .cancel())
        }
    }
}

struct EditEventView_Previews: PreviewProvider {
    static var previews: some View {
        EditEventView(event: Event(), host: User())
            .preferredColorScheme(.dark)
    }
}
