//
//  TicketItemView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//
import SwiftUI
import FirebaseFirestore

struct TicketItemView: View {
    let ticket: Ticket
    @State private var event: Event?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Ticket #\(ticket.bookingId)")
                                    .font(.headline)
                Spacer()
                Text(ticket.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Event Logo
            if let event = event {
                AsyncImage(url: URL(string: event.eventBannerUrl)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                } placeholder: {
                    ProgressView()
                }
                // Event Details
                VStack(alignment: .leading, spacing: 8) {
                    DetailRow(label: "Event", value: event.name)
                    if let ticketTypeName = ticket.ticketTypeName, !ticketTypeName.isEmpty {
                        DetailRow(label: "Ticket Type", value: ticketTypeName)
                    }
                    DetailRow(label: "Number of Tickets", value: ticket.numberOfTickets)
                    DetailRow(label: "Total Price", value: "$\(String(format: "%.2f", (Double(ticket.itemPrice) ?? 0) / 100.0))")
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onAppear {
            loadEvent()
        }
    }
    
    private func loadEvent() {
        if let catalogId = ticket.catalogId, !catalogId.isEmpty {
            EventManager.shared.getEvents(whereField: "catalog_id", isEqualTo: catalogId) { fetchedEvent in
                self.event = fetchedEvent?.first
            }
        } else if let eventId = ticket.eventId {
            EventManager.shared.getEvents(whereField: "eventID", isEqualTo: eventId) { fetchedEvent in
                self.event = fetchedEvent?.first
            }
        }
    }
    
}


// Helper view for consistent detail row formatting
private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}
