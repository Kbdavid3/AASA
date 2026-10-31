import SwiftUI
import SquareInAppPaymentsSDK

struct CardPaymentView: View {
    let catalogId: String
    let merchantId: String
    let numberOfTickets: Int
    let ticketPrice: Double
    let customerName: String
    let customerEmail: String
    let onPaymentSuccess: (Ticket) -> Void
    
    // Add ticket type information
    let ticketTypeName: String
    let ticketTypeId: String
    
    @State private var showCardEntry = false
    @State private var isProcessing = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.bgColor.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Complete Your Purchase")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.labelColor)
                    
                    Text("Secure payment via Square")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                // Order summary card
                VStack(spacing: 16) {
                    HStack {
                        Text("Order Summary")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.labelColor)
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    // Ticket details
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ticketTypeName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.labelColor)
                            
                            Text("$\(String(format: "%.2f", ticketPrice)) per ticket")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text("x\(numberOfTickets)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.labelColor)
                    }
                    
                    Divider()
                    
                    // Total
                    HStack {
                        Text("Total")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.labelColor)
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.2f", Double(numberOfTickets) * ticketPrice))")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.buttonBgColor)
                    }
                }
                .padding(20)
                .background(Color.secondaryBgColor)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                
                // Customer info summary
                VStack(spacing: 16) {
                    HStack {
                        Text("Customer Information")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.labelColor)
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Name:")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(customerName)
                            .font(.system(size: 16))
                            .foregroundColor(.labelColor)
                    }
                    
                    HStack {
                        Text("Email:")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(customerEmail)
                            .font(.system(size: 16))
                            .foregroundColor(.labelColor)
                    }
                }
                .padding(20)
                .background(Color.secondaryBgColor)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                
                Spacer()
                
                // Payment button
                Button(action: {
                    isProcessing = true
                    showCardEntry = true
                }) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 8)
                        } else {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 18))
                                .padding(.trailing, 8)
                        }
                        
                        Text("Pay $\(String(format: "%.2f", Double(numberOfTickets) * ticketPrice))")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.buttonBgColor)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color.buttonBgColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isProcessing)
                .padding(.bottom, 20)
                
                // Cancel button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showCardEntry) {
            isProcessing = false
        } content: {
            CardEntryView(
                catalogId: catalogId,
                merchantId: merchantId,
                numberOfTickets: numberOfTickets,
                ticketPrice: ticketPrice,
                customerName: customerName,
                customerEmail: customerEmail,
                ticketTypeName: ticketTypeName,
                ticketTypeId: ticketTypeId,
                onPaymentSuccess: onPaymentSuccess
            )
        }
    }
}

struct CardEntryView: UIViewControllerRepresentable {
    let catalogId: String
    let merchantId: String
    let numberOfTickets: Int
    let ticketPrice: Double
    let customerName: String
    let customerEmail: String
    let ticketTypeName: String
    let ticketTypeId: String
    let onPaymentSuccess: (Ticket) -> Void
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let cardEntryVC = makeCardEntryViewController()
        cardEntryVC.delegate = context.coordinator
        return UINavigationController(rootViewController: cardEntryVC)
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            catalogId: catalogId,
            merchantId: merchantId,
            numberOfTickets: numberOfTickets,
            ticketPrice: ticketPrice,
            customerName: customerName,
            customerEmail: customerEmail,
            ticketTypeName: ticketTypeName,
            ticketTypeId: ticketTypeId,
            onPaymentSuccess: onPaymentSuccess
        )
    }
    
    private func makeCardEntryViewController() -> SQIPCardEntryViewController {
        let theme = SQIPTheme()
        theme.saveButtonTitle = "Pay $\(String(format: "%.2f", Double(numberOfTickets) * ticketPrice))"
        theme.saveButtonFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        theme.tintColor = UIColor(Color.buttonBgColor)
        theme.keyboardAppearance = .light
        theme.messageColor = UIColor.systemGray
        
        let cardEntry = SQIPCardEntryViewController(theme: theme)
        cardEntry.collectPostalCode = true
        return cardEntry
    }
    
    class Coordinator: NSObject, SQIPCardEntryViewControllerDelegate {
        let catalogId: String
        let merchantId: String
        let numberOfTickets: Int
        let ticketPrice: Double
        let customerName: String
        let customerEmail: String
        let ticketTypeName: String
        let ticketTypeId: String
        let onPaymentSuccess: (Ticket) -> Void
        
        init(
            catalogId: String,
            merchantId: String,
            numberOfTickets: Int,
            ticketPrice: Double,
            customerName: String,
            customerEmail: String,
            ticketTypeName: String,
            ticketTypeId: String,
            onPaymentSuccess: @escaping (Ticket) -> Void
        ) {
            self.catalogId = catalogId
            self.merchantId = merchantId
            self.numberOfTickets = numberOfTickets
            self.ticketPrice = ticketPrice
            self.customerName = customerName
            self.customerEmail = customerEmail
            self.ticketTypeName = ticketTypeName
            self.ticketTypeId = ticketTypeId
            self.onPaymentSuccess = onPaymentSuccess
        }
        
        func cardEntryViewController(_ cardEntryViewController: SQIPCardEntryViewController, didCompleteWith status: SQIPCardEntryCompletionStatus) {
            switch status {
            case .canceled:
                print("Card entry canceled")
            case .success:
                print("Card entry completed successfully")
            }
            
            cardEntryViewController.dismiss(animated: true, completion: nil)
        }
        
        func cardEntryViewController(_ cardEntryViewController: SQIPCardEntryViewController, didObtain cardDetails: SQIPCardDetails, completionHandler: @escaping (Error?) -> Void) {
            // Process payment with cardDetails, catalogId, and numberOfTickets
            ChargeApi.processPayment(
                cardDetails.nonce,
                catalogId: catalogId,
                hostId: merchantId,
                numberOfTickets: numberOfTickets,
                ticketPrice: ticketPrice,
                customerName: customerName,
                customerEmail: customerEmail,
                ticketTypeId: ticketTypeId,
                ticketTypeName: ticketTypeName,
                completion: { [weak self] (ticket, errorDescription) in
                    guard let self = self else { return }
                    if let errorDescription = errorDescription {
                        // Payment failed
                        let error = NSError(domain: "com.kiccbacc.app", code: 0, userInfo: [NSLocalizedDescriptionKey: errorDescription])
                        completionHandler(error)
                    } else if let ticket = ticket {
                        // Payment successful
                        completionHandler(nil)
                        self.onPaymentSuccess(ticket)
                    }
                }
            )
        }
    }
}
