//
//  ChargeApi.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
// 
import Foundation
import UserNotifications
import Firebase

class ChargeApi {
    static func processPayment(
        _ nonce: String,
        catalogId: String,
        hostId: String,
        numberOfTickets: Int,
        ticketPrice: Double,
        customerName: String,
        customerEmail: String,
        ticketTypeId: String,
        ticketTypeName: String,
        completion: @escaping (Ticket?, String?) -> Void
    ) {
        guard let url = URL(string: "https://chargepayment-7ce4gb3x2q-uc.a.run.app") else {
            completion(nil, "Invalid payment URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        UserManager.shared.getCurrentUser { user in
            guard let user = user else {
                completion(nil, "User not found")
                return
            }
            
            // First fetch the merchant ID from the User collection using the hostId
            let db = Firestore.firestore()
            db.collection("users").document(hostId).getDocument { (document, error) in
                if let error = error {
                    completion(nil, "Error fetching merchant information: \(error.localizedDescription)")
                    sendNotification(title: "Error", body: "Failed to fetch merchant information")
                    return
                }
                
                guard let document = document, document.exists else {
                    completion(nil, "Host user not found")
                    sendNotification(title: "Error", body: "Host user information not found")
                    return
                }
                
                // Extract merchantId from the host's user document
                guard let merchantId = document.data()?["merchantId"] as? String else {
                    completion(nil, "Merchant ID not found for this host")
                    sendNotification(title: "Error", body: "No merchant ID associated with this host")
                    return
                }
                
                // Calculate total amount
                let amount = ticketPrice * Double(numberOfTickets)
                
                print("🔍 Debugging Payment Request")
                print("Nonce: \(nonce)")
                print("Catalog ID: \(catalogId)")
                print("Number of Tickets: \(numberOfTickets)")
                print("Buyer ID: \(user.userID)")
                print("Host ID: \(hostId)")
                print("Merchant ID: \(merchantId)")
                print("Customer Name: \(customerName)")
                print("Customer Email: \(customerEmail)")
                print("Ticket Type ID: \(ticketTypeId)")
                print("Ticket Type Name: \(ticketTypeName)")
                
                // Create payload with the required parameters for the backend
                // Include customer information in payload but NOT in the ticket
                let payload: [String: Any] = [
                    "nonce": nonce,
                    "merchantId": merchantId,
                    "amount": amount,
                    "currency": "USD",
                    
                    // Customer information for Square - critical for fund release
                    "customerName": customerName,
                    "customerEmail": customerEmail,
                    
                    // Additional parameters for your app logic
                    "catalogId": catalogId,
                    "numberOfTickets": numberOfTickets,
                    "buyerId": user.userID,
                    "unitPrice": ticketPrice,
                    "ticketTypeId": ticketTypeId,
                    "ticketTypeName": ticketTypeName
                ]
                
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
                    print("Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "Invalid JSON")")
                } catch {
                    completion(nil, "Failed to encode request: \(error.localizedDescription)")
                    return
                }
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            completion(nil, "Network error: \(error.localizedDescription)")
                            sendNotification(title: "Error", body: "Network error: \(error.localizedDescription)")
                            return
                        }
                        
                        guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                            completion(nil, "Invalid response from server")
                            sendNotification(title: "Error", body: "Invalid response from server")
                            return
                        }
                        
                        print("Raw Response: \(String(data: data, encoding: .utf8) ?? "Empty Response")")
                        
                        do {
                            if httpResponse.statusCode == 200 {
                                // Update PaymentResponse structure to match the backend response
                                let jsonResponse = try JSONDecoder().decode(PaymentResponse.self, from: data)
                                
                                // Create ticket record after successful payment - keeping original format
                                createTicket(
                                    transactionId: jsonResponse.transactionId,
                                    catalogId: catalogId,
                                    merchantId: merchantId,
                                    hostId: hostId,
                                    buyerId: user.userID,
                                    numberOfTickets: numberOfTickets,
                                    ticketPrice: ticketPrice,
                                    ticketTypeId: ticketTypeId,
                                    ticketTypeName: ticketTypeName
                                ) { ticket in
                                    // Store customer information separately to not affect ticket display
                                    storeCustomerInfo(
                                        transactionId: jsonResponse.transactionId,
                                        customerName: customerName,
                                        customerEmail: customerEmail
                                    )
                                    
                                    completion(ticket, nil)
                                    let formattedAmount = String(format: "%.2f", amount)
                                    sendNotification(title: "Success", body: "Payment of $\(formattedAmount) processed successfully!")
                                }
                            } else {
                                let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                                completion(nil, errorResponse.message)
                                sendNotification(title: "Error", body: errorResponse.message)
                            }
                        } catch {
                            print("Decoding error: \(error)")
                            print("Response data: \(String(data: data, encoding: .utf8) ?? "Empty")")
                            completion(nil, "Error decoding response: \(error.localizedDescription)")
                            sendNotification(title: "Error", body: "Unexpected server response")
                        }
                    }
                }.resume()
            }
        }
    }
    
    // Update the createTicket method to include ticket type information
    private static func createTicket(
        transactionId: String,
        catalogId: String,
        merchantId: String,
        hostId: String,
        buyerId: String,
        numberOfTickets: Int,
        ticketPrice: Double,
        ticketTypeId: String,
        ticketTypeName: String,
        completion: @escaping (Ticket?) -> Void
    ) {
        let db = Firestore.firestore()
        let ticketRef = db.collection("tickets").document()
        
        // Generate booking ID
        let currentYear = Calendar.current.component(.year, from: Date())
        let remainingDigits = String(format: "%05d", Int.random(in: 0...99999))
        let bookingId = "\(currentYear)\(remainingDigits)"
        
        // First, look up the event using catalog_id field
        print("Looking up event with catalog_id: \(catalogId)")
        db.collection("events").whereField("catalog_id", isEqualTo: catalogId).getDocuments { snapshot, error in
            if let error = error {
                print("Error finding event: \(error)")
                completion(nil)
                return
            }
            
            // Get eventId from the matching document
            guard let document = snapshot?.documents.first,
                  let eventId = document.data()["eventID"] as? String else {
                print("⚠️ No event found with catalog_id: \(catalogId)")
                completion(nil)
                return
            }
            
            print("✅ Found eventId: \(eventId) for catalog_id: \(catalogId)")
            
            // Create ticket data with the correct eventId and ticket type information
            let ticketData: [String: Any] = [
                "bookingId": bookingId,
                "buyerId": buyerId,
                "catalogId": catalogId,
                "createdAt": Timestamp(),
                "eventId": eventId,
                "itemPrice": String(Int(ticketPrice * 100)), // Store in cents
                "merchantId": merchantId,
                "numberOfTickets": String(numberOfTickets),
                "paymentId": transactionId,
                "ticketTypeId": ticketTypeId,
                "ticketTypeName": ticketTypeName
            ]
            
            ticketRef.setData(ticketData) { error in
                if let error = error {
                    print("Error creating ticket: \(error)")
                    sendNotification(title: "Error", body: "Failed to generate ticket")
                    completion(nil)
                } else {
                    print("Ticket successfully created!")
                    sendNotification(title: "Success", body: "Your ticket has been generated!")
                    
                    // Now update event ticket count using the correct eventId
                    print("Updating count for eventId: \(eventId)")
                    EventManager.shared.getEvents(whereField: "eventID", isEqualTo: eventId) { fetchedEvent in
                        print("Found \(fetchedEvent?.count ?? 0) events matching ID \(eventId)")
                        if let event = fetchedEvent?.first {
                            // Update the specific ticket type's available count if possible
                            if var ticketTypes = event.ticketTypes {
                                if let index = ticketTypes.firstIndex(where: { $0.id == ticketTypeId }) {
                                    if ticketTypes[index].quantity != nil {
                                        // Only update if the ticket type has a quantity limit
                                        print("Updating specific ticket type: \(ticketTypeName)")
                                        
                                        // FETCH THE COMPLETE EVENT DOCUMENT FIRST
                                        let eventRef = db.collection("events").document(event.eventID)
                                        eventRef.getDocument { (document, error) in
                                            guard let document = document, document.exists,
                                                  let eventData = document.data() else {
                                                print("Error fetching complete event data")
                                                return
                                            }
                                            
                                            // Extract the full ticket types array from Firestore
                                            guard let ticketTypesData = eventData["ticketTypes"] as? [[String: Any]] else {
                                                print("No ticket types found in event data")
                                                return
                                            }
                                            
                                            // Create a new array to update
                                            var updatedTicketTypesData = ticketTypesData
                                            
                                            // Find and update only the specific ticket type
                                            for i in 0..<updatedTicketTypesData.count {
                                                if let id = updatedTicketTypesData[i]["id"] as? String,
                                                   id == ticketTypeId,
                                                   let currentQuantity = updatedTicketTypesData[i]["quantity"] as? Int {
                                                    // Only update the quantity field
                                                    updatedTicketTypesData[i]["quantity"] = currentQuantity - numberOfTickets
                                                    break
                                                }
                                            }
                                            
                                            // Update only the ticket types field while preserving all other fields
                                            eventRef.updateData(["ticketTypes": updatedTicketTypesData]) { error in
                                                if let error = error {
                                                    print("Error updating ticket type: \(error)")
                                                } else {
                                                    print("Successfully updated ticket type quantity")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Also update the overall sold count for backward compatibility
                            let totalTickets = Int(event.totalTickets ?? 0)
                            let currentSoldCount = Int(event.soldCount ?? "0") ?? 0
                            let newSoldCount = currentSoldCount + numberOfTickets
                            
                            print("Current sold count: \(currentSoldCount), adding \(numberOfTickets)")
                            
                            if totalTickets == 0 || newSoldCount <= totalTickets {
                                print("Updating event \(event.eventID) with new sold count: \(newSoldCount)")
                                EventManager.shared.updateEventWith(eventID: event.eventID,
                                    with: ["soldCount": String(newSoldCount)]) { isUpdated in
                                    if isUpdated {
                                        print("Successfully updated sold count")
                                    } else {
                                        print("Failed to update sold count")
                                    }
                                }
                            } else {
                                print("Would exceed total tickets available")
                            }
                        } else {
                            print("No event found with ID: \(eventId)")
                        }
                    }
                    
                    // Return the created ticket
                    let ticket = Ticket(
                        id: ticketRef.documentID,
                        buyerId: buyerId,
                        catalogId: catalogId,
                        createdAt: Date(),
                        itemPrice: String(Int(ticketPrice * 100)),
                        merchantId: merchantId,
                        numberOfTickets: String(numberOfTickets),
                        paymentId: transactionId,
                        bookingId: bookingId,
                        eventId: eventId,
                        ticketTypeId: ticketTypeId,
                        ticketTypeName: ticketTypeName
                    )
                    completion(ticket)
                }
            }
        }
    }
    
    // New method to store customer information separately
    private static func storeCustomerInfo(
        transactionId: String,
        customerName: String,
        customerEmail: String
    ) {
        let db = Firestore.firestore()
        
        // Create a separate document to store customer information
        // This won't affect your ticket display but will provide merchant information
        let customerInfoRef = db.collection("customerInfo").document(transactionId)
        
        let customerData: [String: Any] = [
            "transactionId": transactionId,
            "customerName": customerName,
            "customerEmail": customerEmail,
            "createdAt": Timestamp()
        ]
        
        customerInfoRef.setData(customerData) { error in
            if let error = error {
                print("Error storing customer info: \(error)")
            } else {
                print("Customer information stored successfully")
            }
        }
    }
}

func sendNotification(title: String, body: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
}

// Payment response models
struct PaymentResponse: Codable {
    let transactionId: String
    
    enum CodingKeys: String, CodingKey {
        case transactionId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.transactionId = try container.decode(String.self, forKey: .transactionId)
    }
}

struct ErrorResponse: Codable {
    let error: String?
    let errorMessage: String?
    
    var message: String {
        return errorMessage ?? error ?? "Unknown error occurred"
    }
}
