//
//  OnboardingCreateEventView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import Firebase

struct OnboardingCreateEventView: View {
    
    // MARK: - State Variables (matching CreateNewEventView exactly)
    @State private var isFreeEvent: Bool = false
    @State private var newName: String = ""
    @State private var newLocation: String = ""
    @State private var newDescription: String = ""
    @State private var newToDate = Date()
    @State private var newFromDate = Date()
    @State private var selectedEventType: EventType = .all
    @State private var showImagePicker: Bool = false
    @State private var pickedImage: UIImage?
    @State private var pickedLocation: EventLocation?
    @State private var paymentAmount: String = ""
    @State private var customEventType: String = ""
    @State private var password: String = ""
    @State private var isSquareAuthorized: Bool = false
    
    @State var alertItem: AlertItem?
    @State private var viewItem: ViewItem?
    
    @State private var totalTickets: String = ""
    @State private var maxTicketsPerUser: String = "2"
    @State private var isUnlimitedTickets: Bool = false
    @State private var ticketTypes: [TicketType] = []
    @State private var showingTicketTypeEditor: Bool = false
    @State private var useMultipleTicketTypes: Bool = false
    @State private var showConfetti: Bool = false
    
    // Onboarding specific
    @State private var showContent = false
    private let themeColor = Color(red: 242/255, green: 108/255, blue: 146/255) // Match other onboarding screens
    
    private func calculateSquareFee(_ amount: Double) -> Double {
        let fee = ((amount * 0.029) + 0.30) * 100
        return fee.rounded() / 100
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 0) {
                // Header with progress
                headerSection(geo: geo)
                
                // Main content - exact copy from CreateNewEventView but constrained
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Image picker section
                        imagePickerSection
                        
                        VStack(alignment: .leading, spacing: 30) {
                            CustomInputField(title: "Title", placeholder: "e.g. Drag race", newValue: $newName)
                            
                            CustomInputField(title: "Description", newValue: $newDescription)
                            
                            locationPickerSection
                            
                            eventTimeSection
                            
                            eventTypeSection
                            
                            if selectedEventType == .custom {
                                CustomInputField(title: "Custom event type", newValue: $customEventType)
                            }
                            
                            ticketManagementSection
                            
                            CustomInputField(title: "Password for private events (Optional)", newValue: $password)
                            
                            actionButtons
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    .padding(.top, 30)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .overlay(
            SharedConfettiAnimationView(isShowing: $showConfetti)
        )
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(isPresented: $showImagePicker, selectedImage: $pickedImage)
        }
        .sheet(item: $viewItem) { viewItem in
            viewItem.viewToPresent
        }
        .sheet(isPresented: $showingTicketTypeEditor) {
            TicketTypeEditorView(ticketTypes: $ticketTypes)
        }
        .alert(item: $alertItem) { alertItem in
            Alert(title: alertItem.title, message: alertItem.message, dismissButton: alertItem.dismissButton)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
            checkSquareAuthorization()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh Square authorization status when app comes back to foreground
            // This handles the case when user returns from Square authorization
            checkSquareAuthorization()
        }
    }
    
    // MARK: - View Components
    
    private var imagePickerSection: some View {
        Group {
            if let pickedImage = pickedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: pickedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    Button(action: {
                        self.pickedImage = nil
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
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                        .foregroundColor(.gray)
                    .padding()
                }
                .buttonStyle(FlatLinkStyle())
            }
        }
    }
    
    private var locationPickerSection: some View {
        Button {
            viewItem = ViewItem(AnyView(EventLocationPicker(pickedLocation: $pickedLocation, newLocation: $newLocation)), _presentationStyle: .modal)
        } label: {
            HStack {
                CustomInputField(title: "Location", newValue: $newLocation)
                    .allowsHitTesting(false)
                    .multilineTextAlignment(.center)
            }
            .contentShape(Rectangle())
            .background(Color.clear)
        }
        .buttonStyle(FlatLinkStyle())
    }
    
    private var eventTimeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Event time")
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundColor(.gray)
                .padding(.leading)
            
            DatePicker("From", selection: $newFromDate)
                .padding(.horizontal)
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundColor(.white)
                .onChange(of: newFromDate) { newValue in
                    // Ensure 'to' date is not before 'from' date
                    if newToDate < newValue {
                        newToDate = newValue
                    }
                }
            
            DatePicker("To", selection: $newToDate, in: newFromDate...)
                .padding(.horizontal)
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundColor(.white)
        }
    }
    
    private var eventTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Event type")
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundColor(.gray)
                .padding(.leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(EventType.allCases.filter { $0 != .all }, id: \.self) { type in
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
                                .background(isSelected(type: type) ? Color.white : Color.gray.opacity(0.2))
                                .foregroundColor(isSelected(type: type) ? .black : .white)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var ticketManagementSection: some View {
        VStack(spacing: 20) {
            Toggle("Free Event", isOn: $isFreeEvent)
                .padding(.horizontal)
                .padding(.vertical, 5)
                .onChange(of: isFreeEvent) { newValue in
                    if newValue {
                        // If free event is toggled on, clear ticket types
                        ticketTypes = []
                    }
                }
            

            
            if !isFreeEvent && isSquareAuthorized {
                paidEventTicketSection
            }
            
            // Ticket management section - only visible for free events
            if isFreeEvent {
                freeEventTicketSection
            }
        }
    }
    
    private var paidEventTicketSection: some View {
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
                    .background(themeColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
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
                                    .foregroundColor(.white)
                                Text("$\(String(format: "%.2f", ticket.price))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 5)
                            
                            Spacer()
                        }
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 5)
            }
        }
        .padding(.top, 5)
    }
    
    private var freeEventTicketSection: some View {
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
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: saveAndContinue) {
                Text("Save & Continue")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(themeColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            
            Button(action: skipAndContinue) {
                Text("Skip for Now")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Helper Methods
    
    private func headerSection(geo: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Create Your")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(showContent ? 1 : 0)
                    .offset(x: showContent ? 0 : -50)

                Text("First Event")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(themeColor)
                    .opacity(showContent ? 1 : 0)
                    .offset(x: showContent ? 0 : -50)
            }

            Text("Set up your event details or skip for now")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .opacity(showContent ? 1 : 0)
                .offset(x: showContent ? 0 : -30)

            progressBarView(geo: geo)
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
    }
    
    private func progressBarView(geo: GeometryProxy) -> some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 4)
                .cornerRadius(2)
            Rectangle()
                .fill(themeColor)
                .frame(width: geo.size.width * 0.1, height: 4) // 10% progress
                .cornerRadius(2)
        }
        .opacity(showContent ? 1 : 0)
        .offset(x: showContent ? 0 : -20)
    }
    
    private func saveAndContinue() {
        // Validate required fields
        guard !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertItem = AlertItem(title: Text("Missing Information"), message: Text("Please enter an event name."), dismissButton: .cancel())
            return
        }
        
        guard !newDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertItem = AlertItem(title: Text("Missing Information"), message: Text("Please enter an event description."), dismissButton: .cancel())
            return
        }
        
        guard selectedEventType != .all else {
            alertItem = AlertItem(title: Text("Missing Information"), message: Text("Please select an event type."), dismissButton: .cancel())
            return
        }
        
        if selectedEventType == .custom && customEventType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alertItem = AlertItem(title: Text("Missing Information"), message: Text("Please enter a custom event type."), dismissButton: .cancel())
            return
        }
        
        guard pickedImage != nil else {
            alertItem = AlertItem(title: Text("Missing Image"), message: Text("Please select an image cover for the event."), dismissButton: .cancel())
            return
        }
        
        guard pickedLocation != nil else {
            alertItem = AlertItem(title: Text("Missing Location"), message: Text("Please select a venue location for the event."), dismissButton: .cancel())
            return
        }
        
        // Validate ticket settings for free events
        if isFreeEvent && !isUnlimitedTickets {
            guard let totalTicketsInt = Int(totalTickets), totalTicketsInt > 0 else {
                alertItem = AlertItem(title: Text("Invalid Ticket Count"), message: Text("Please enter a valid number of total tickets."), dismissButton: .cancel())
                return
            }
        }
        
        // Validate max tickets per user
        guard let maxTicketsInt = Int(maxTicketsPerUser), maxTicketsInt > 0 else {
            alertItem = AlertItem(title: Text("Invalid Ticket Limit"), message: Text("Please enter a valid number for max tickets per user."), dismissButton: .cancel())
            return
        }
        
        // Validate paid event settings
        if !isFreeEvent && ticketTypes.isEmpty {
            alertItem = AlertItem(title: Text("Missing Ticket Types"), message: Text("Please add at least one ticket type for paid events."), dismissButton: .cancel())
            return
        }
        
        // Validate date range
        guard newFromDate <= newToDate else {
            alertItem = AlertItem(title: Text("Invalid Date Range"), message: Text("Event end time must be after start time."), dismissButton: .cancel())
            return
        }
        
        // Encode ticket types as Data
        let ticketTypesData = try? JSONEncoder().encode(ticketTypes)
        
        let eventData = OnboardingEventData(
            name: newName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: newDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            eventType: selectedEventType.rawValue,
            customEventType: customEventType.trimmingCharacters(in: .whitespacesAndNewlines),
            fromDate: newFromDate,
            toDate: newToDate,
            locationVenueName: pickedLocation?.venueName,
            locationLatitude: pickedLocation?.latitude,
            locationLongitude: pickedLocation?.longitude,
            imageData: pickedImage?.jpeg(.high),
            isFreeEvent: isFreeEvent,
            paymentAmount: paymentAmount,
            totalTickets: totalTickets,
            maxTicketsPerUser: maxTicketsPerUser,
            isUnlimitedTickets: isUnlimitedTickets,
            ticketTypesData: ticketTypesData,
            password: password.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        // Save to UserDefaults
        do {
            let encoded = try JSONEncoder().encode(eventData)
            UserDefaults.standard.set(encoded, forKey: "onboarding_event_data")
            print("Event data saved for onboarding")
            
            // Trigger confetti animation for successful event data save
            showConfetti = true
            
            // Continue to next step after a short delay to show confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                NotificationCenter.default.post(name: .hostEventCompleted, object: nil)
            }
        } catch {
            print("Error encoding event data: \(error)")
            alertItem = AlertItem(title: Text("Save Error"), message: Text("Failed to save event data. Please try again."), dismissButton: .cancel())
        }
    }
    
    private func skipAndContinue() {
        // Clear any saved event data
        UserDefaults.standard.removeObject(forKey: "onboarding_event_data")
        
        // Continue to next step
        NotificationCenter.default.post(name: .hostEventCompleted, object: nil)
    }
    
    private func checkSquareAuthorization() {
        UserManager.shared.getCurrentUser { user in
            DispatchQueue.main.async {
                if let user = user {
                    self.isSquareAuthorized = UserManager.shared.checkSquareAuthorization(user: user)
                } else {
                    self.isSquareAuthorized = false
                }
            }
        }
    }
    
    private func isSelected(type: EventType) -> Bool {
        selectedEventType == type
    }
}

// MARK: - Data Models

// Data model for storing event data during onboarding
struct OnboardingEventData: Codable {
    let name: String
    let description: String
    let eventType: String // Store as String instead of EventType enum
    let customEventType: String
    let fromDate: Date
    let toDate: Date
    let locationVenueName: String?
    let locationLatitude: Double?
    let locationLongitude: Double?
    let imageData: Data?
    let isFreeEvent: Bool
    let paymentAmount: String
    let totalTickets: String
    let maxTicketsPerUser: String
    let isUnlimitedTickets: Bool
    let ticketTypesData: Data? // Store as encoded Data instead of array
    let password: String
    
    // Helper to convert back to EventLocation
    var eventLocation: EventLocation? {
        guard let venueName = locationVenueName,
              let latitude = locationLatitude,
              let longitude = locationLongitude else {
            return nil
        }
        return EventLocation(
            venueName: venueName,
            latitude: latitude,
            longitude: longitude,
            streetName: nil, streetNumber: nil, city: nil,
            neighbourhood: nil, state: nil, county: nil,
            zipCode: nil, selectionRadius: nil
        )
    }

    // Helper to convert back to TicketTypes
    var ticketTypes: [TicketType] {
        guard let data = ticketTypesData,
              let types = try? JSONDecoder().decode([TicketType].self, from: data) else {
            return []
        }
        return types
    }
}

// MARK: - Extensions
// Note: hostEventCompleted notification is declared in OnboardingCoordinatorView.swift


