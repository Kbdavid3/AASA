//
//  Ticket.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import FirebaseFirestore

struct Ticket: Identifiable, Codable {
    @DocumentID var id: String?
    var buyerId: String
    var catalogId: String?
    var createdAt: Date
    var itemPrice: String
    var merchantId: String
    var numberOfTickets: String
    var paymentId: String
    var bookingId: String
    var eventId: String?
    var ticketTypeId: String?
    var ticketTypeName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case buyerId
        case catalogId
        case createdAt
        case itemPrice
        case merchantId
        case numberOfTickets
        case paymentId
        case bookingId
        case eventId
        case ticketTypeId
        case ticketTypeName
    }
}
