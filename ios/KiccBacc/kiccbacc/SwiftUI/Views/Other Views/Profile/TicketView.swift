//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//
import SwiftUI
import SDWebImageSwiftUI

struct TicketView: View {
    let ticket: Ticket
    @State private var event: Event?
    let cornerRadius: CGFloat = 22
    let cutoutRadius: CGFloat = 18
    let cutoutYOffset: CGFloat = 250
    
    // Add this parameter
    var showBackButton: Bool = false
    
    // Add this for navigation
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            // Back button at the top
            if showBackButton {
                HStack {
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(Color(red: 0.95, green: 0.42, blue: 0.57))
                        .padding(.horizontal)
                    }
                    Spacer()
                }
                .padding(.top)
            }
        
            HStack(spacing: 0) {
                Text("Booking ID : ")
                    .font(.title2)
                Text(ticket.bookingId)
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 16)
                
            GeometryReader { geometry in
                Path { path in
                    let width = UIScreen.main.bounds.width - 40
                    let height = geometry.size.height
                    
                    let xOffset = 0.0
                    let height_mid = height - cutoutYOffset;
                    
                    path.move(to: CGPoint(x: xOffset + cornerRadius, y: 0))
                    
                    path.addLine(to: CGPoint(x: xOffset + width - cornerRadius, y: 0))
                    
                    path.addArc(center: CGPoint(x: xOffset + width - cornerRadius, y: cornerRadius),
                            radius: cornerRadius,
                            startAngle: Angle(degrees: -90),
                            endAngle: Angle(degrees: 0),
                            clockwise: false)
                    
                    path.addLine(to: CGPoint(x: xOffset + width, y: height_mid - cutoutRadius))
                    path.addArc(center: CGPoint(x: xOffset + width, y: height_mid),
                            radius: cutoutRadius,
                            startAngle: Angle(degrees: -90),
                            endAngle: Angle(degrees: 90),
                            clockwise: true)
                    path.addLine(to: CGPoint(x: xOffset + width, y: height - cornerRadius))
                    
                    path.addArc(center: CGPoint(x: xOffset + width - cornerRadius, y: height - cornerRadius),
                            radius: cornerRadius,
                            startAngle: Angle(degrees: 0),
                            endAngle: Angle(degrees: 90),
                            clockwise: false)
                    
                    path.addLine(to: CGPoint(x: xOffset + cornerRadius, y: height))
                    
                    path.addArc(center: CGPoint(x: xOffset + cornerRadius, y: height - cornerRadius),
                            radius: cornerRadius,
                            startAngle: Angle(degrees: 90),
                            endAngle: Angle(degrees: 180),
                            clockwise: false)
                    
                    path.addLine(to: CGPoint(x: xOffset + 0, y: height_mid + cutoutRadius))
                    path.addArc(center: CGPoint(x: xOffset + 0, y: height_mid),
                            radius: cutoutRadius,
                            startAngle: Angle(degrees: 90),
                            endAngle: Angle(degrees: -90),
                            clockwise: true)
                    path.addLine(to: CGPoint(x: xOffset + 0, y: cornerRadius))
                    
                    path.addArc(center: CGPoint(x: xOffset + cornerRadius, y: cornerRadius),
                            radius: cornerRadius,
                            startAngle: Angle(degrees: 180),
                            endAngle: Angle(degrees: 270),
                            clockwise: false)
                    
                }
                    .fill(Color(UIColor(red: 0.933, green: 0.933, blue: 0.937, alpha: 1.0)))
                    .padding(.horizontal)

                Path { path in
                    let width = UIScreen.main.bounds.width - 40
                    let height = geometry.size.height
                    let height_mid = height - cutoutYOffset

                    // Move to the start of the dashed line
                    path.move(to: CGPoint(x: cutoutRadius, y: height_mid))
                    // Draw the dashed line to the end
                    path.addLine(to: CGPoint(x: width-cutoutRadius, y: height_mid))
                }
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundColor(.gray)
                    .padding(.horizontal, cutoutRadius)

                VStack {
                    if let imageUrl = event?.eventBannerUrl {
                        WebImage(url: URL(string: imageUrl))
                            .resizable()
                            .indicator(.activity) // Shows a loading indicator while fetching the image
                            .scaledToFill()
                            .frame(maxWidth: UIScreen.main.bounds.width - 60)
                            .frame(height: 150)
                            .cornerRadius(cornerRadius)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(event?.name ?? "Loading...")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.vertical, 20)
                        
                        HStack(alignment: .top, spacing: 0) {
                            VStack(alignment: .leading) {
                                Text("Date")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Label {
                                    Text(event?.from.formatted(date: .abbreviated, time: .omitted) ?? "")
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                } icon: {
                                    Image(systemName: "calendar")
                                        .foregroundColor(Color(red: 0.95, green: 0.42, blue: 0.57))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxWidth: .infinity)
                            
                            VStack(alignment: .leading) {
                                Text("Time")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Label {
                                    Text(event?.from.formatted(date: .omitted, time: .shortened) ?? "")
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                } icon: {
                                    Image(systemName: "clock")
                                        .foregroundColor(Color(red: 0.95, green: 0.42, blue: 0.57))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Venue")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Label {
                                Text(event?.venueName ?? "")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.black)
                            } icon: {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(Color(red: 0.95, green: 0.42, blue: 0.57))
                            }
                        }
                        
                        // Combine "For" and "Ticket Type" in a single row with proper spacing
                        HStack(spacing: 0) {
                            VStack(alignment: .leading) {
                                Text("For")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding(.top, 4)
                                
                                Text(ticket.numberOfTickets + " Adults")
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                            }
                            
                            Spacer()
                            
                            if let ticketTypeName = ticket.ticketTypeName, !ticketTypeName.isEmpty {
                                VStack(alignment: .trailing) {
                                    Text("Ticket Type")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .padding(.top, 4)
                                    
                                    Text(ticketTypeName)
                                        .font(.body)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 50)
                    
                    VStack(alignment: .center, spacing: 8) {
                        if let ticketId = ticket.id {
                            Group {
                                if let qrImage = generateQRCode(from: ticketId) {
                                    if let uiImage = (UIImage(data: qrImage)) {
                                        Image(uiImage: uiImage)
                                            .interpolation(.none)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 200, height: 200)
                                    }
                                } else {
                                    Image(systemName: "exclamationmark.triangle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.red)
                                    Text("Failed to generate QR code")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
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
    
    private func generateQRCode(from string: String) -> Data? {
        let context = CIContext()
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }

        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return nil }

        let scale = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: scale)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }

        return UIImage(cgImage: cgImage).pngData()
    }
}
