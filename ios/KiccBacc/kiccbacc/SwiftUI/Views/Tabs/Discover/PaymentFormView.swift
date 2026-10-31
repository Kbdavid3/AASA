//
//  PaymentFormView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//
import SwiftUI

struct PaymentFormView: View {
    let eventName: String
    let catalogId: String
    let merchantId: String
    let ticketPrice: Double
    let onPaymentSuccess: () -> Void
    let maxTicketsPerUser: Int?
    let ticketTypeName: String
    let quantity: Int  // Add this parameter to receive the quantity from TicketSelectorView
    let ticketTypeId: String  // Move this property here as a parameter
    
    // Add states for customer contact information
    @State private var customerName: String = ""
    @State private var customerEmail: String = ""
    
    // Remove the numberOfTickets state since we're using the passed quantity
    @State private var showCardPayment = false
    @State private var errorMessage: String? = nil
    @State private var showError = false
    @State private var showTicket = false
    @State private var purchasedTicket: Ticket?
    
    // Form validation
    private var isFormValid: Bool {
        return !customerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               isValidEmail(customerEmail)
    }
    
    // Email validation function
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    var body: some View {
        ZStack {
            Color.bgColor.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header section
                    VStack(spacing: 8) {
                        Text("Purchase Tickets")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.labelColor)
                        
                        Text(eventName)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 8)
                    }
                    .padding(.top, 12)
                    
                    // Ticket information card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ticketTypeName)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.labelColor)
                                
                                Text("$\(String(format: "%.2f", ticketPrice)) per ticket")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            ZStack {
                                Circle()
                                    .fill(Color.buttonBgColor.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                
                                Text("\(quantity)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color.buttonBgColor)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Total")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.2f", Double(quantity) * ticketPrice))")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.labelColor)
                        }
                    }
                    .padding(20)
                    .background(Color.secondaryBgColor)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    
                    // Contact information section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Contact Information")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.labelColor)
                        
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name *")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                TextField("", text: $customerName)
                                    .padding()
                                    .background(Color.secondaryBgColor)
                                    .cornerRadius(12)
                                    .autocapitalization(.words)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email Address *")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                TextField("", text: $customerEmail)
                                    .padding()
                                    .background(Color.secondaryBgColor)
                                    .cornerRadius(12)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            
                            if !customerEmail.isEmpty && !isValidEmail(customerEmail) {
                                Text("Please enter a valid email")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .padding(.leading, 4)
                            }
                            
                            Text("* Required fields")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.top, 12)
                    
                    Spacer()
                    
                    // Payment button
                    Button(action: {
                        if isFormValid {
                            showCardPayment.toggle()
                        } else {
                            if customerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                errorMessage = "Please enter your name"
                            } else if !isValidEmail(customerEmail) {
                                errorMessage = "Please enter a valid email address"
                            } else {
                                errorMessage = "Please fill in all required fields"
                            }
                            showError = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "creditcard")
                                .font(.system(size: 18))
                            Text("Pay Now")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isFormValid ? Color.buttonBgColor : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: isFormValid ? Color.buttonBgColor.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                    }
                    .disabled(!isFormValid)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showCardPayment) {
            CardPaymentView(
                catalogId: catalogId,
                merchantId: merchantId,
                numberOfTickets: quantity,
                ticketPrice: ticketPrice,
                customerName: customerName,
                customerEmail: customerEmail,
                onPaymentSuccess: handlePaymentSuccess,
                ticketTypeName: ticketTypeName,
                ticketTypeId: ticketTypeId
            )
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .fullScreenCover(item: $purchasedTicket) { ticket in
            TicketView(ticket: ticket, showBackButton: true)
        }
    }
    
    func handlePaymentSuccess(ticket: Ticket) {
        purchasedTicket = ticket
        showTicket = true
        
        onPaymentSuccess()
    }
    
    func handlePaymentError(_ error: String) {
        errorMessage = error
        showError = true
    }
}
