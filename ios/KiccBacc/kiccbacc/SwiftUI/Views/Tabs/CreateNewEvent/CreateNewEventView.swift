//
    //  CreateNewEventView.swift
    //  kiccbacc
    //
    //  Created by Siddharth Pillai on 16/02/2025
    //  Copyright © 2025 Siddharth Pillai. All rights reserved.
    //

    import SwiftUI
    import Firebase
    import LinkPresentation

    struct CreateNewEventView: View {
        
        @Environment(\.presentationMode) private var presentation
        
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
                        if otherHostName == "" {
                            Text("Create event")
                                .font(.system(size: 30, weight: .bold, design: .default))
                            
                            Spacer()
                        } else {
                            Text("Create event with \(otherHostName)")
                                .font(.system(size: 30, weight: .bold, design: .default))
                        }
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
                                        }
                                    }
                                
                                // Square Authorization Section for Paid Events
                                if !isFreeEvent && !isSquareAuthorized {
                                    VStack(spacing: 15) {
                                        Text("For paid ticket events, authorize Square")
                                            .font(.system(size: 16, weight: .medium, design: .default))
                                            .foregroundColor(.white)
                                            .padding(.horizontal)
                                            .multilineTextAlignment(.center)
                                        
                                        Button(action: {
                                            showingSelfProfileView = true
                                        }) {
                                            HStack {
                                                Image(systemName: "creditcard.fill")
                                                    .font(.system(size: 16))
                                                Text("Authorize Square")
                                                    .font(.system(size: 16, weight: .medium))
                                            }
                                            .foregroundColor(.white)
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.buttonBgColor)
                                            .cornerRadius(10)
                                        }
                                        .padding(.horizontal)
                                    }
                                    .padding(.vertical, 10)
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
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Refresh Square authorization status when app comes back to foreground
                    // This handles the case when user returns from Square authorization
                    checkSquareAuthorization()
                }
                            
                            CustomInputField(title: "Password for private events (Optional)", newValue: $password)
                            
                            Button {
                                guard let currentUserID = UserManager.shared.currentUserID else {
                                    alertItem = AlertItem(title: Text("Can't find the user."), message: Text("Please check your internet connection and try again."), dismissButton: .cancel())
                                    
                                    // Track error
                                    AnalyticsManager.logCustomEvent(name: "event_creation_error", parameters: [
                                        "error_type": "user_not_found"
                                    ])
                                    return
                                }
                                
                                guard !newName.isEmpty, !newDescription.isEmpty, selectedEventType != .all else {
                                    alertItem = AlertItem(title: Text("Empty fields!"), message: Text("Please make sure you've entered name, description and event type."), dismissButton: .cancel())
                                    
                                    // Track validation error
                                    AnalyticsManager.logCustomEvent(name: "event_creation_error", parameters: [
                                        "error_type": "empty_fields",
                                        "has_name": !newName.isEmpty,
                                        "has_description": !newDescription.isEmpty,
                                        "has_event_type": selectedEventType != .all
                                    ])
                                    return
                                }
                                
                                guard let data = pickedImage?.jpeg(.high) else {
                                    alertItem = AlertItem(title: Text("Please select an image cover for event."), message: nil, dismissButton: .cancel())
                                    
                                    // Track missing image error
                                    AnalyticsManager.logCustomEvent(name: "event_creation_error", parameters: [
                                        "error_type": "missing_image"
                                    ])
                                    return
                                }
                                
                                guard let pickedLocation = pickedLocation else {
                                    alertItem = AlertItem(title: Text("Please select a venue location for event."), message: nil, dismissButton: .cancel())
                                    
                                    // Track missing location error
                                    AnalyticsManager.logCustomEvent(name: "event_creation_error", parameters: [
                                        "error_type": "missing_location"
                                    ])
                                    return
                                }
                                
                                // Track event creation attempt with details
                                AnalyticsManager.logCustomEvent(name: "event_creation_attempt", parameters: [
                                    "event_type": selectedEventType.rawValue,
                                    "is_paid": !paymentAmount.isEmpty,
                                    "has_password": !password.isEmpty,
                                    "has_custom_type": !customEventType.isEmpty,
                                    "unlimited_tickets": isUnlimitedTickets,
                                    "has_co_host": otherHosts != ""
                                ])
                                
                                withAnimation {
                                    isLoading = true
                                    currentLoadingState = "uploading cover"
                                }
                                
                                HapticGenerator.light.impactOccurred()
                                let eventID = UUID().uuidString
                                
                                EventManager.shared.uploadNewCoverForEvent(data: data, with: eventID) { result in
                                    switch result {
                                    case .success(let uploadStatus):
                                        switch uploadStatus {
                                        case .uploaded(withURL: let uploadURL):
                                            guard let uploadURL = uploadURL else {
                                                // Track upload failure
                                                AnalyticsManager.logCustomEvent(name: "event_creation_error", parameters: [
                                                    "error_type": "upload_url_missing"
                                                ])
                                                
                                                // Reset loading state on error
                                                withAnimation {
                                                    isLoading = false
                                                    currentLoadingState = nil
                                                }
                                                
                                                alertItem = AlertItem(title: Text("Error encountered."), message: Text("Failed to upload image. Please try again."), dismissButton: .cancel())
                                                return
                                            }
                                            
                                            withAnimation {
                                                currentLoadingState = "creating event"
                                            }
                                            
                                            // Convert paymentAmount to Double for ticketPrice
                                            let ticketPrice = Double(paymentAmount) ?? 0.0
                                            
                                            // Create the event with ticket types if using multiple ticket types
                                            let event = Event(
                                                eventID: eventID, 
                                                eventBannerUrl: uploadURL, 
                                                name: newName, 
                                                description: newDescription, 
                                                hostIDs: [currentUserID, otherHosts], 
                                                from: newFromDate, 
                                                to: newToDate, 
                                                type: selectedEventType.rawValue, 
                                                customType: customEventType, 
                                                interestedUserIDs: [], 
                                                contactNumber: nil, 
                                                localeIdentifier: Locale.current.languageCode, 
                                                paymentAmount: isFreeEvent ? nil : nil, // Always nil for new approach
                                                password: password, 
                                                createdAt: Date(), 
                                                location: pickedLocation, 
                                                totalTickets: isFreeEvent ? (isUnlimitedTickets ? nil : Int(totalTickets)) : nil, 
                                                maxTicketsPerUser: isFreeEvent ? (Int(maxTicketsPerUser) ?? 2) : nil, 
                                                ticketPrice: isFreeEvent ? nil : nil, // Always nil for new approach
                                                ticketTypes: isFreeEvent ? nil : ticketTypes // Only use ticket types for paid events
                                            )
                                            
                                            do {
                                                try EventManager.shared.create(event: event)
                                                
                                                // Track successful event creation
                                                AnalyticsManager.logCustomEvent(name: "event_created_successfully", parameters: [
                                                    "event_id": eventID,
                                                    "event_type": selectedEventType.rawValue,
                                                    "is_paid": !paymentAmount.isEmpty,
                                                    "ticket_price": Double(paymentAmount) ?? 0.0,
                                                    "has_password": !password.isEmpty
                                                ])
                                                
                                                // Reset loading state
                                                withAnimation {
                                                    isLoading = false
                                                    currentLoadingState = nil
                                                }
                                                
                                                // Trigger confetti animation
                                                showConfetti = true
                                                
                                                // Dismiss after a short delay to show confetti
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                                    presentation.wrappedValue.dismiss()
                                                }
                                            } catch {
                                                // Track event creation error
                                                AnalyticsManager.logCustomEvent(name: "event_creation_error", parameters: [
                                                    "error_type": "firestore_error",
                                                    "error_message": error.localizedDescription
                                                ])
                                                
                                                // Reset loading state on error
                                                withAnimation {
                                                    isLoading = false
                                                    currentLoadingState = nil
                                                }
                                                
                                                alertItem = AlertItem(title: Text("Error encountered."), message: Text(error.localizedDescription), dismissButton: .cancel())
                                            }
                                        case .failed(withError: let error):
                                            // Track upload error
                                            AnalyticsManager.logCustomEvent(name: "event_creation_error", parameters: [
                                                "error_type": "upload_failed",
                                                "error_message": error.localizedDescription
                                            ])
                                            
                                            // Reset loading state on error
                                            withAnimation {
                                                isLoading = false
                                                currentLoadingState = nil
                                            }
                                            
                                            alertItem = AlertItem(title: Text("Error encountered."), message: Text(error.localizedDescription), dismissButton: .cancel())
                                        }
                                    case .failure(let error):
                                        // Track general failure
                                        AnalyticsManager.logCustomEvent(name: "event_creation_error", parameters: [
                                            "error_type": "general_failure",
                                            "error_message": error.localizedDescription
                                        ])
                                        
                                        DispatchQueue.main.async {
                                            // Reset loading state on error
                                            withAnimation {
                                                isLoading = false
                                                currentLoadingState = nil
                                            }
                                            
                                            alertItem = AlertItem(title: Text("Error encountered."), message: Text(error.localizedDescription), dismissButton: .cancel())
                                        }
                                    }
                                }
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
                .background(Color.black.ignoresSafeArea())
                .padding(.bottom, 100) // Add padding to account for tab bar
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
                    AnalyticsManager.logScreenView(screenName: "Create New Event", screenClass: "CreateNewEventView")
                    
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
    }



struct CreateNewEventView_Previews: PreviewProvider {
    static var previews: some View {
        CreateNewEventView()
            .preferredColorScheme(.dark)
    }
}
    // Remove the extraneous closing brace that's causing error #447

    struct URLPreview : UIViewRepresentable {
        
        var previewURL:URL
        
        func makeUIView(context: Context) -> LPLinkView {
            let view = LPLinkView(url: previewURL)
            
            let provider = LPMetadataProvider()
            
            provider.startFetchingMetadata(for: previewURL) { (metadata, error) in
                if let md = metadata {
                    DispatchQueue.main.async {
                        view.metadata = md
                        view.sizeToFit()
                    }
                }
            }
            
            return view
        }
        
        func updateUIView(_ uiView: LPLinkView, context: UIViewRepresentableContext<URLPreview>) {
        }
    }
