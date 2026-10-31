import SwiftUI

struct TicketTypeEditorView: View {
    @Environment(\.presentationMode) private var presentation
    @Binding var ticketTypes: [TicketType]
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var price: String = ""
    @State private var quantity: String = ""
    @State private var maxPerUser: String = ""
    @State private var isUnlimited: Bool = false
    @State private var editingTicket: TicketType?
    @State private var alertItem: AlertItem?
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section {
                        ForEach(ticketTypes) { ticket in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(ticket.name)
                                        .font(.headline)
                                    Text(ticket.description)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text("$\(String(format: "%.2f", ticket.price))")
                                        .font(.subheadline)
                                    if let quantity = ticket.quantity {
                                        Text("Quantity: \(quantity)")
                                            .font(.caption)
                                    } else {
                                        Text("Unlimited")
                                            .font(.caption)
                                    }
                                    Text("Max per user: \(ticket.maxPerUser)")
                                        .font(.caption)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    editingTicket = ticket
                                    name = ticket.name
                                    description = ticket.description
                                    price = String(format: "%.2f", ticket.price)
                                    isUnlimited = ticket.quantity == nil
                                    quantity = ticket.quantity != nil ? "\(ticket.quantity!)" : ""
                                    maxPerUser = "\(ticket.maxPerUser)"
                                }) {
                                    Image(systemName: "pencil")
                                }
                            }
                        }
                        .onDelete(perform: deleteTicket)
                    }
                    
                    Section(header: Text("Add New Ticket Type")) {
                        TextField("Name (e.g. VIP, Early Bird)", text: $name)
                        TextField("Description", text: $description)
                        TextField("Price ($)", text: $price)
                            .keyboardType(.decimalPad)
                        
                        Toggle("Unlimited Quantity", isOn: $isUnlimited)
                        
                        if !isUnlimited {
                            TextField("Quantity", text: $quantity)
                                .keyboardType(.numberPad)
                        }
                        
                        TextField("Max Per User", text: $maxPerUser)
                            .keyboardType(.numberPad)
                        
                        Button(action: addOrUpdateTicket) {
                            Text(editingTicket == nil ? "Add Ticket Type" : "Update Ticket Type")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.buttonBgColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        // Removed the disabled modifier to allow validation alerts to show up
                        // This will let the validation alerts show up
                        //.disabled(name.isEmpty || price.isEmpty || (!isUnlimited && quantity.isEmpty) || maxPerUser.isEmpty)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Ticket Types")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentation.wrappedValue.dismiss()
                }
                .foregroundColor(Color.buttonBgColor),
                trailing: Button("Done") {
                    if ticketTypes.isEmpty {
                        alertItem = AlertItem(
                            title: Text("No Ticket Types"),
                            message: Text("Please add at least one ticket type."),
                            dismissButton: .default(Text("OK"))
                        )
                    } else {
                        presentation.wrappedValue.dismiss()
                    }
                }
                .foregroundColor(Color.buttonBgColor)
            )
            .alert(item: $alertItem) { alertItem in
                Alert(
                    title: alertItem.title,
                    message: alertItem.message,
                    dismissButton: alertItem.dismissButton
                )
            }
        }
    }
    
    private func addOrUpdateTicket() {
        // Validate required fields
        if name.isEmpty {
            alertItem = AlertItem(
                title: Text("Missing Information"),
                message: Text("Please enter a ticket name."),
                dismissButton: .default(Text("OK"))
            )
            return
        }
        
        if price.isEmpty {
            alertItem = AlertItem(
                title: Text("Missing Information"),
                message: Text("Please enter a ticket price."),
                dismissButton: .default(Text("OK"))
            )
            return
        }
        
        if !isUnlimited && quantity.isEmpty {
            alertItem = AlertItem(
                title: Text("Missing Information"),
                message: Text("Please enter a ticket quantity."),
                dismissButton: .default(Text("OK"))
            )
            return
        }
        
        if maxPerUser.isEmpty {
            alertItem = AlertItem(
                title: Text("Missing Information"),
                message: Text("Please enter maximum tickets per user."),
                dismissButton: .default(Text("OK"))
            )
            return
        }
        
        guard let priceValue = Double(price) else { 
            alertItem = AlertItem(
                title: Text("Invalid Price"),
                message: Text("Please enter a valid price."),
                dismissButton: .default(Text("OK"))
            )
            return
        }
        
        let quantityValue = isUnlimited ? nil : Int(quantity)
        
        if !isUnlimited && quantityValue == nil {
            alertItem = AlertItem(
                title: Text("Invalid Quantity"),
                message: Text("Please enter a valid quantity."),
                dismissButton: .default(Text("OK"))
            )
            return
        }
        
        // Validate maxPerUser is between 1 and 8
        guard let maxPerUserValue = Int(maxPerUser), maxPerUserValue >= 1, maxPerUserValue <= 8 else {
            alertItem = AlertItem(
                title: Text("Invalid Max Per User"),
                message: Text("Max tickets per user must be between 1 and 8."),
                dismissButton: .default(Text("OK"))
            )
            return
        }
        
        // Rest of the function remains the same
        if let editingTicket = editingTicket, let index = ticketTypes.firstIndex(where: { $0.id == editingTicket.id }) {
            // Update existing ticket
            ticketTypes[index] = TicketType(
                id: editingTicket.id,
                name: name,
                description: description, // Description is optional
                price: priceValue,
                quantity: quantityValue,
                maxPerUser: maxPerUserValue
            )
            self.editingTicket = nil
        } else {
            // Add new ticket
            let newTicket = TicketType(
                name: name,
                description: description, // Description is optional
                price: priceValue,
                quantity: quantityValue,
                maxPerUser: maxPerUserValue
            )
            ticketTypes.append(newTicket)
        }
        
        // Reset fields
        name = ""
        description = ""
        price = ""
        quantity = ""
        maxPerUser = ""
        isUnlimited = false
    }
    
    private func deleteTicket(at offsets: IndexSet) {
        ticketTypes.remove(atOffsets: offsets)
    }
}

struct TicketTypeEditorView_Previews: PreviewProvider {
    static var previews: some View {
        TicketTypeEditorView(ticketTypes: .constant([
            TicketType(name: "VIP", description: "Front row access", price: 50.0, quantity: 20, maxPerUser: 2),
            TicketType(name: "Regular", description: "General admission", price: 25.0, quantity: 100, maxPerUser: 4)
        ]))
    }
}
