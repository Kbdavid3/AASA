//
//  OnboardingCreateEventView.swift
//  kiccbacc
//
//  Created by Assistant on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import Firebase

struct OnboardingCreateNewEvent: View {
    
    // Add a state variable for free event
    @State private var isFreeEvent: Bool = false
    
    @State private var newName: String = ""
    @State private var newLocation: String = ""
    @State private var newDescription: String = ""
    @State private var newToDate = Date()
    @State private var newFromDate = Date()
    @State private var selectedEventType: EventType = .all
    @State private var pickedAgeGroupInt: Int = 12
    @State private var showImagePicker: Bool = false
    @State private var pickedImage: UIImage?
    @State private var isLoading: Bool = false
    @State private var currentLoadingState: String?
    @State private var pickedLocation: EventLocation?
    @State private var paymentAmount: String = ""
    @State private var customEventType: String = ""
    @State private var password: String = ""
    @State private var isSquareAuthorized: Bool = false
    var otherHosts: String = ""
    var otherHostName: String = ""
    
    @State var alertItem : AlertItem?
    @State private var viewItem: ViewItem?
    @State private var showingSelfProfileView = false
    @State private var showSquareAuthView = false
    
    @State private var totalTickets: String = ""
    @State private var maxTicketsPerUser: String = "2"
    @State private var isUnlimitedTickets: Bool = false
    @State private var ticketTypes: [TicketType] = []
    @State private var showingTicketTypeEditor: Bool = false
    @State private var useMultipleTicketTypes: Bool = false
    @State private var showConfetti: Bool = false
    
    private func calculateSquareFee(_ amount: Double) -> Double {
        let fee = ((amount * 0.029) + 0.30) * 100
        return fee.rounded() / 100
    }

    var body: some View {
        if isLoading {
            VStack {
                ProgressView()
                
                if let currentLoadingState = currentLoadingState {
                    Text(currentLoadingState)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Create event")
                        .font(.system(size: 30, weight: .bold, design: .default))
                    
                    Spacer()
                    
                    AccessoryIndicator.down.getImage()
                }
                .padding(.horizontal)
                .padding(.top, 30)
                
                ScrollView(.vertical, showsIndicators: false) {
                    if let pickedImage = pickedImage {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: pickedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            Button(action: {
                                self.pickedImage = nil  // Use self to refer to the state variable
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(8)
                        }
                        .padding(.horizontal)
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
                                                  
                        Button {
                            viewItem = ViewItem(AnyView(EventLocationPicker(pickedLocation: $pickedLocation, newLocation: $newLocation)), _presentationStyle: .modal)
                        } label: {
                            HStack {
                                CustomInputField(title: "Location", newValue: $newLocation)
                                    .allowsHitTesting(false)  // Disable interaction with the text field
                                    .multilineTextAlignment(.center)  // Center the text
                            }
                            .contentShape(Rectangle())
                            .background(Color.clear)  // Add clear background to capture taps
                        }
                        .buttonStyle(FlatLinkStyle())
                        
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
                                                
                                                // Track event type selection
                                                AnalyticsManager.logCustomEvent(name: "event_type_selected", parameters: [
                                                    "event_type": type.rawValue
                                                ])
                                            } label: {
                                                Text(type.title)
                                                    .font(.system(size: 13))
                                                    .padding(10)
                                                    .background(isSelected(type: type) ? Color.labelColor : Color.secondaryBgColor)
                                                    .foregroundColor(isSelected(type: type) ? .antiLabelColor : .labelColor)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        CustomInputField(title: "Custom event type", newValue: $customEventType)
                            .showIf(selectedEventType == .custom)
                        
                        VStack(spacing: 20) {
                            Toggle("Free Event", isOn: $isFreeEvent)
                                .padding(.horizontal)
                                .padding(.vertical, 5)
                                .onChange(of: isFreeEvent) { newValue in
                                    if newValue {
                                        // If free event is toggled on, clear ticket types
                                        ticketTypes = []
                                    } else {
                                        // If switching to paid event, check Square authorization
                                        if !isSquareAuthorized {
                                            showSquareAuthView = true
                                        }
                                    }
                                }
                            

                            
                            if !isFreeEvent && isSquareAuthorized {
                                // Always show ticket types UI for paid events
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("Ticket Types")
                                        .font(.system(size: 16, weight: .regular, design: .default))
                                        .foregroundColor(.white)
                                        .padding(.leading)
                                    
                                    Button(action: {
                                        showingTicketTypeEditor = true
                                    }) {
                                        Text("Edit Ticket Types")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.buttonBgColor)
                                            .cornerRadius(10)
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.top, 5)
                                
                                if ticketTypes.isEmpty {
                                    Text("No ticket types added")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal)
                                        .padding(.top, 5)
                                } else {
                                    VStack(spacing: 10) {
                                        ForEach(ticketTypes) { ticket in
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text(ticket.name)
                                                        .font(.headline)
                                                    Text("$\(String(format: "%.2f", ticket.price))")
                                                        .font(.subheadline)
                                                }
                                                .padding(.horizontal)
                                                .padding(.vertical, 5)
                                                
                                                Spacer()
                                            }
                                            .background(Color.secondaryBgColor.opacity(0.5))
                                            .cornerRadius(8)
                                            .padding(.horizontal)
                                        }
                                    }
                                    .padding(.top, 5)
                                }
                            }
                            
                            // Ticket management section - only visible for free events
                            if isFreeEvent {
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("Ticket Management")
                                        .font(.system(size: 16, weight: .regular, design: .default))
                                        .foregroundColor(.white)
                                        .padding(.leading)
                                        
                                    Toggle("Unlimited Tickets", isOn: $isUnlimitedTickets)
                                        .padding(.horizontal)
                                        
                                    if !isUnlimitedTickets {
                                        CustomInputField(title: "Total Available Tickets", newValue: $totalTickets)
                                            .keyboardType(.numberPad)
                                    }
                                        
                                    CustomInputField(title: "Max Tickets Per User", newValue: $maxTicketsPerUser)
                                        .keyboardType(.numberPad)
                                }
                                .padding(.top, 5)
                            }
                        }
                        .sheet(isPresented: $showingTicketTypeEditor) {
                            TicketTypeEditorView(ticketTypes: $ticketTypes)
                        }
                        .sheet(isPresented: $showingSelfProfileView) {
                            SelfProfileView(initialSelectedSection: 2)
                        }
                        .sheet(isPresented: $showSquareAuthView) {
                            OnboardingSquareAuthView(isSquareAuthorized: $isSquareAuthorized)
                        }
                        
                        CustomInputField(title: "Password for private events (Optional)", newValue: $password)
                        
                        Button {
                            validateAndCreateEvent()
                        }
                        label: {
                            Text("Create")
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50, alignment: .center)
                                .padding()
                                .background(Color.buttonBgColor)
                                .cornerRadius(15)
                                .padding(.horizontal)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .background(Color.bgColor.ignoresSafeArea())
            .overlay(
                SharedConfettiAnimationView(isShowing: $showConfetti)
            )
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(isPresented: $showImagePicker, selectedImage: $pickedImage)
            }
            .sheet(item: $viewItem) { viewItem in
                viewItem.viewToPresent
            }
            .alert(item: $alertItem) { alertItem in
                guard let primaryButton = alertItem.primaryButton, let secondaryButton = alertItem.secondaryButton
                else {
                    return Alert(title: alertItem.title, message: alertItem.message, dismissButton: alertItem.dismissButton)
                }
                
                return Alert(title: alertItem.title, message: alertItem.message, primaryButton: primaryButton, secondaryButton: secondaryButton)
            }.onAppear {
                // Track screen view when this view appears
                AnalyticsManager.logScreenView(screenName: "Onboarding Create Event", screenClass: "OnboardingCreateEventView")
                
                checkSquareAuthorization()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Refresh Square authorization status when app comes back to foreground
                // This handles the case when user returns from Square authorization
                checkSquareAuthorization()
            }
        }
    }
    
    private func checkSquareAuthorization() {
        UserManager.shared.getCurrentUser { user in
            if let user = user {
                self.isSquareAuthorized = UserManager.shared.checkSquareAuthorization(user: user)
            } else {
                self.isSquareAuthorized = false
            }
        }
    }
    
    private func isSelected(type: EventType) -> Bool {
        selectedEventType == type
    }
    
    private func validateAndCreateEvent() {
        guard !newName.isEmpty, !newDescription.isEmpty, selectedEventType != .all else {
            alertItem = AlertItem(title: Text("Empty fields!"), message: Text("Please make sure you've entered name, description and event type."), dismissButton: .cancel())
            return
        }
        
        guard let data = pickedImage?.jpeg(.high) else {
            alertItem = AlertItem(title: Text("Please select an image cover for event."), message: nil, dismissButton: .cancel())
            return
        }
        
        guard let pickedLocation = pickedLocation else {
            alertItem = AlertItem(title: Text("Please select a venue location for event."), message: nil, dismissButton: .cancel())
            return
        }
        
        // For paid events, ensure Square is authorized and ticket types are set
        if !isFreeEvent {
            if !isSquareAuthorized {
                alertItem = AlertItem(title: Text("Square Authorization Required"), message: Text("Please authorize Square payment processing for paid events."), dismissButton: .cancel())
                return
            }
            
            if ticketTypes.isEmpty {
                alertItem = AlertItem(title: Text("Ticket Types Required"), message: Text("Please add at least one ticket type for paid events."), dismissButton: .cancel())
                return
            }
        }
        
        // Create event data and store it for later upload
        let eventData = OnboardingEventData(
            name: newName,
            description: newDescription,
            eventType: selectedEventType.rawValue,
            customEventType: customEventType,
            fromDate: newFromDate,
            toDate: newToDate,
            locationVenueName: pickedLocation.venueName,
            locationLatitude: pickedLocation.latitude,
            locationLongitude: pickedLocation.longitude,
            imageData: data,
            isFreeEvent: isFreeEvent,
            paymentAmount: paymentAmount,
            totalTickets: totalTickets,
            maxTicketsPerUser: maxTicketsPerUser,
            isUnlimitedTickets: isUnlimitedTickets,
            ticketTypesData: try? JSONEncoder().encode(ticketTypes),
            password: password
        )
        
        // Store the event data in UserDefaults for later use
        if let encoded = try? JSONEncoder().encode(eventData) {
            UserDefaults.standard.set(encoded, forKey: "onboardingEventData")
            print("✅ OnboardingCreateEventView: Event data saved for later creation")
            
            // Trigger confetti animation for successful event data save
            showConfetti = true
            
            // Notify coordinator that this step is complete after a short delay to show confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                NotificationCenter.default.post(name: .hostEventCompleted, object: nil)
            }
        }
    }
}

// Notification extensions
extension Notification.Name {
    static let hostEventCompleted = Notification.Name("hostEventCompleted")
}



// Preview
struct OnboardingCreateNewEvent_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingCreateNewEvent()
            .preferredColorScheme(.dark)
    }
}

