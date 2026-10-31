//
//  FreeEventRegistrationView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//
import SwiftUI
import FirebaseFirestore

struct FreeEventRegistrationView: View {
    let eventId: String
    let merchantId: String
    var onRegistrationSuccess: () -> Void
    let maxTicketsPerUser: Int?
    
    @State private var numberOfTickets: Int = 1
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Number of Tickets")
                .font(.headline)
            
            HStack {
                Button(action: { if numberOfTickets > 1 { numberOfTickets -= 1 } }) {
                    Image(systemName: "minus.circle.fill")
                }
                
                TextField("Quantity", value: $numberOfTickets, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .frame(width: 80)
                    .multilineTextAlignment(.center)
                    .onChange(of: numberOfTickets) { newValue in
                        if let maxTickets = maxTicketsPerUser {
                            if newValue > maxTickets {
                                numberOfTickets = maxTickets
                            }
                        }
                        if newValue < 1 {
                            numberOfTickets = 1
                        }
                    }
                
                Button(action: {
                    if let maxTickets = maxTicketsPerUser {
                        if numberOfTickets < maxTickets {
                            numberOfTickets += 1
                        }
                    } else {
                        numberOfTickets += 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                }
            }
            .padding()
            
            Button(action: registerTickets) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Register Now")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(Color.blue)
            .cornerRadius(10)
            .disabled(isLoading)
            .padding(.horizontal)
        }
        .padding()
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func registerTickets() {
        isLoading = true
        let db = Firestore.firestore()
        // Generate 9-digit booking ID starting with current year
        let currentYear = Calendar.current.component(.year, from: Date())
        let remainingDigits = String(format: "%05d", Int.random(in: 0...99999))
        let bookingId = "\(currentYear)\(remainingDigits)"
        // Create ticket document data
        let ticketData: [String: Any] = [
            "bookingId": bookingId,
            "merchantId": merchantId,
            "buyerId": UserManager.shared.currentUserID ?? "",
            "numberOfTickets": String(numberOfTickets),
            "catalogId": "",
            "eventId": eventId,
            "paymentId": "",
            "createdAt": Timestamp(),
            "itemPrice": "0"
        ]
        
        // Start a batch write
        let batch = db.batch()
        
        // Add ticket document
        let ticketRef = db.collection("tickets").document()
        batch.setData(ticketData, forDocument: ticketRef)
        
        EventManager.shared.getEvents(whereField: "eventID", isEqualTo: eventId) { fetchedEvent in
            if let event = fetchedEvent?.first {
                // Convert totalTickets to Int if it exists
                let totalTickets = Int(event.totalTickets ?? 0)
                let currentSoldCount = Int(event.soldCount ?? "0") ?? 0
                let newSoldCount = currentSoldCount + numberOfTickets
                
                // Only update if totalTickets is 0 (unlimited) or if new count doesn't exceed total
                if totalTickets == 0 || newSoldCount <= totalTickets {
                    EventManager.shared.updateEventWith(eventID: event.eventID,
                        with: ["soldCount": String(newSoldCount)]) { isUpdated in
                        if isUpdated {
                            // Success handling
                        } else {
                            // Error handling
                        }
                    }
                } else {
                    // Handle the case where soldCount would exceed totalTickets
                    // You might want to show an error message here
                }
            }
        }
        
        
        
        // Commit the batch
        batch.commit { error in
            isLoading = false
            
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
            } else {
                onRegistrationSuccess()
                dismiss()
            }
        }
    }
}
