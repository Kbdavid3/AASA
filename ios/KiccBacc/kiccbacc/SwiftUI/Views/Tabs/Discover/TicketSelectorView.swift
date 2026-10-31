//
//  TicketSelectorView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 4/28/25.
//  Copyright © 2025 APPLE. All rights reserved.
//

import Foundation
import SwiftUI
import Firebase

struct TicketSelectorView: View {
    let event: Event
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedTickets: [String: Int] = [:]
    @State private var selectedTicketTypeId: String? = nil
    @State private var availableTickets: [String: Int] = [:]
    @State private var isLoading = true
    @State private var isProcessingPayment = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var showPaymentForm = false
    @State private var selectedTicketType: TicketType?
    
    var totalAmount: Double {
        guard let ticketTypes = event.ticketTypes else { return 0 }
        
        return ticketTypes.reduce(0) { total, ticketType in
            let quantity = selectedTickets[ticketType.id] ?? 0
            return total + (ticketType.price * Double(quantity))
        }
    }
    
    var hasSelectedTickets: Bool {
        selectedTickets.values.contains { $0 > 0 }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgColor.edgesIgnoringSafeArea(.all)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else {
                    VStack(spacing: 0) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                                Text("Select Tickets")
                                    .font(.system(size: 28, weight: .bold))
                                    .padding(.horizontal)
                                    .padding(.top, 16)
                                
                                if let ticketTypes = event.ticketTypes, !ticketTypes.isEmpty {
                                    ForEach(ticketTypes) { ticketType in
                                        ModernTicketTypeRow(
                                            ticketType: ticketType,
                                            selectedQuantity: selectedTickets[ticketType.id] ?? 0,
                                            availableQuantity: availableTickets[ticketType.id] ?? 0,
                                            isActive: selectedTicketTypeId == ticketType.id || selectedTicketTypeId == nil,
                                            onIncrement: {
                                                incrementTicket(ticketType)
                                            },
                                            onDecrement: {
                                                decrementTicket(ticketType)
                                            }
                                        )
                                        .padding(.horizontal)
                                    }
                                } else {
                                    Text("No ticket types available")
                                        .foregroundColor(.gray)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                                
                                Spacer(minLength: 100)
                            }
                        }
                        
                        // Fixed bottom payment bar
                        VStack(spacing: 0) {
                            Divider()
                                .background(Color.gray.opacity(0.2))
                            
                            VStack(spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Total")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        Text("$\(String(format: "%.2f", totalAmount))")
                                            .font(.system(size: 24, weight: .bold))
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        processPayment()
                                    }) {
                                        HStack {
                                            if isProcessingPayment {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            } else {
                                                Text("Proceed to Payment")
                                                    .fontWeight(.semibold)
                                            }
                                        }
                                        .frame(width: 180)
                                        .padding(.vertical, 14)
                                        .background(hasSelectedTickets ? Color.buttonBgColor : Color.gray.opacity(0.5))
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                        .shadow(color: hasSelectedTickets ? Color.buttonBgColor.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 2)
                                    }
                                    .disabled(!hasSelectedTickets || isProcessingPayment)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 16)
                            }
                            .background(Color.secondaryBgColor)
                        }
                    }
                }
            }
            .navigationBarTitle("Buy Tickets", displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.labelColor)
            })
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                loadAvailableTickets()
            }
        }
        .sheet(isPresented: $showPaymentForm) {
            if let ticketType = selectedTicketType {
                PaymentFormView(
                    eventName: event.name,
                    catalogId: event.catalog_id ?? "",
                    merchantId: event.hostIDs.first ?? "", // Use the first host ID as the merchant ID
                    ticketPrice: ticketType.price,
                    onPaymentSuccess: {
                        // Refresh available tickets after successful payment
                        loadAvailableTickets()
                        // Clear selection
                        selectedTicketTypeId = nil
                        for key in selectedTickets.keys {
                            selectedTickets[key] = 0
                        }
                    },
                    maxTicketsPerUser: ticketType.maxPerUser,
                    ticketTypeName: ticketType.name,
                    quantity: selectedTickets[ticketType.id] ?? 1,
                    ticketTypeId: ticketType.id
                )
            }
        }
    }
    
    private func loadAvailableTickets() {
        guard let ticketTypes = event.ticketTypes else {
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        let dispatchGroup = DispatchGroup()
        
        for ticketType in ticketTypes {
            dispatchGroup.enter()
            
            // Initialize with default values
            selectedTickets[ticketType.id] = 0
            
            // If quantity is nil, it means unlimited tickets
            if ticketType.quantity == nil {
                availableTickets[ticketType.id] = Int.max
                dispatchGroup.leave()
                continue
            }
            
            // Query to count sold tickets of this type
            db.collection("tickets")
                .whereField("catalogId", isEqualTo: event.catalog_id ?? "")
                .whereField("ticketTypeId", isEqualTo: ticketType.id)
                .getDocuments { snapshot, error in
                    defer { dispatchGroup.leave() }
                    
                    if let error = error {
                        print("Error fetching tickets: \(error)")
                        return
                    }
                    
                    let soldCount = snapshot?.documents.count ?? 0
                    let available = (ticketType.quantity ?? Int.max) - soldCount
                    availableTickets[ticketType.id] = max(0, available)
                }
        }
        
        dispatchGroup.notify(queue: .main) {
            isLoading = false
        }
    }
    
    private func incrementTicket(_ ticketType: TicketType) {
        // If this is a different ticket type than the currently selected one
        // and we already have a selected ticket type with quantity > 0,
        // clear the previous selection
        if let currentSelectedId = selectedTicketTypeId, 
           currentSelectedId != ticketType.id,
           (selectedTickets[currentSelectedId] ?? 0) > 0 {
            // Clear all selections
            for key in selectedTickets.keys {
                selectedTickets[key] = 0
            }
        }
        
        // Set this as the selected ticket type
        selectedTicketTypeId = ticketType.id
        
        guard let available = availableTickets[ticketType.id],
              let current = selectedTickets[ticketType.id] else { return }
        
        // Check if we've reached the available limit
        if current < available {
            // Check if we've reached the max per user limit
            if current < ticketType.maxPerUser {
                selectedTickets[ticketType.id] = current + 1
            } else {
                alertTitle = "Maximum Limit Reached"
                alertMessage = "You can only purchase up to \(ticketType.maxPerUser) tickets of this type per user."
                showAlert = true
            }
        } else {
            alertTitle = "No More Tickets Available"
            alertMessage = "Sorry, there are no more tickets of this type available."
            showAlert = true
        }
    }
    
    private func decrementTicket(_ ticketType: TicketType) {
        guard let current = selectedTickets[ticketType.id], current > 0 else { return }
        selectedTickets[ticketType.id] = current - 1
        
        // If quantity becomes 0, clear the selected ticket type
        if current - 1 == 0 {
            selectedTicketTypeId = nil
        }
    }
    
    private func processPayment() {
        isProcessingPayment = true
        
        // Find the selected ticket type
        if let ticketTypeId = selectedTicketTypeId,
           let ticketTypes = event.ticketTypes,
           let selectedType = ticketTypes.first(where: { $0.id == ticketTypeId }) {
            
            selectedTicketType = selectedType
            
            // Small delay to show the processing state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isProcessingPayment = false
                showPaymentForm = true
            }
        } else {
            isProcessingPayment = false
            alertTitle = "Error"
            alertMessage = "No ticket type selected"
            showAlert = true
        }
    }
}

struct ModernTicketTypeRow: View {
    let ticketType: TicketType
    let selectedQuantity: Int
    let availableQuantity: Int
    let isActive: Bool
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(ticketType.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isActive ? .labelColor : .gray)
                    
                    if !ticketType.description.isEmpty {
                        Text(ticketType.description)
                            .font(.subheadline)
                            .foregroundColor(isActive ? .gray : .gray.opacity(0.6))
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Text("$\(String(format: "%.2f", ticketType.price))")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(isActive ? .labelColor : .gray)
            }
            
            HStack {
                if availableQuantity == 0 {
                    Text("Sold Out")
                        .foregroundColor(.white)
                        .font(.footnote)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.red)
                        .cornerRadius(8)
                } else {
                    Text(availableQuantity == Int.max ? "Unlimited" : "\(availableQuantity) left")
                        .foregroundColor(.gray)
                        .font(.footnote)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: onDecrement) {
                        ZStack {
                            Circle()
                                .fill(selectedQuantity > 0 && isActive ? Color.buttonBgColor.opacity(0.1) : Color.gray.opacity(0.1))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "minus")
                                .foregroundColor(selectedQuantity > 0 && isActive ? Color.buttonBgColor : Color.gray.opacity(0.3))
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .disabled(selectedQuantity <= 0 || !isActive)
                    
                    Text("\(selectedQuantity)")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 30)
                        .multilineTextAlignment(.center)
                        .foregroundColor(isActive ? .labelColor : .gray)
                    
                    Button(action: onIncrement) {
                        ZStack {
                            Circle()
                                .fill(availableQuantity > selectedQuantity && isActive ? Color.buttonBgColor.opacity(0.1) : Color.gray.opacity(0.1))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "plus")
                                .foregroundColor(availableQuantity > selectedQuantity && isActive ? Color.buttonBgColor : Color.gray.opacity(0.3))
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .disabled(availableQuantity <= selectedQuantity || !isActive)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(selectedQuantity > 0 ? Color.buttonBgColor.opacity(0.05) : Color.secondaryBgColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(selectedQuantity > 0 ? Color.buttonBgColor.opacity(0.5) : Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
        .opacity(isActive || selectedQuantity > 0 ? 1.0 : 0.7)
        .animation(.easeInOut(duration: 0.2), value: selectedQuantity)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}
