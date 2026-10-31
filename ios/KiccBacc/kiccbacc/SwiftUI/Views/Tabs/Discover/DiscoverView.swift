//
//  DiscoverView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import Network

struct DiscoverView: View {
    
    @Binding var currentUser: User?
    @StateObject private var viewModel = DiscoverViewViewModel()
    @State private var newLocation: String = ""
    @State private var loaded: Bool = false
    @State private var isLoadingInstagramShare: Bool = false
    
    
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            // filter options
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(viewModel.headerText)
                    
                    Spacer()
                    
                    HStack {
                        LocationPickerNavigationViewComponent(currentUser: $currentUser, newLocation: $newLocation)
                    }
                }
                .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { scrollView in
                        HStack {
                            if viewModel.eventTypeSelection != .all {
                                Button {
                                    withAnimation { viewModel.eventTypeSelection = .all }
                                } label: {
                                    Circle()
                                        .fill(Color.gray.opacity(0.5))
                                        .id("selection")
                                        .frame(width: 36, height: 36)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.gray, lineWidth: 0.8)
                                                .padding(.vertical, 1)
                                        )
                                        .overlay(
                                            Image(systemName: "xmark")
                                                .foregroundColor(.white)
                                        )
                                }
                                
                                Text(viewModel.eventTypeSelection.title)
                                    .font(.system(size: 13))
                                    .padding(10)
                                    .background(Color.appColor.opacity(0.5))
                                    .clipShape(Capsule())
                                    .overlay (
                                        Capsule()
                                            .stroke(Color.appColor, lineWidth: 0.8)
                                            .padding(.vertical, 1)
                                    )
                                    .foregroundColor(.white)
                                
                                Divider()
                                    .frame(height: 25)
                            }
                            
                            ForEach(EventType.allCases, id: \.id) { type in
                                Button {
                                    withAnimation { viewModel.eventTypeSelection = type }
                                } label: {
                                    Text(type.title)
                                        .font(.system(size: 13))
                                        .padding(10)
                                        .background(viewModel.isSelected(type: type) ? Color.labelColor : Color.secondaryBgColor)
                                        .clipShape(Capsule())
                                        .foregroundColor(viewModel.isSelected(type: type) ? .antiLabelColor : .labelColor)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .onChange(of: viewModel.eventTypeSelection) { newValue in
                            // Track event filter selection
                            AnalyticsManager.logCustomEvent(name: "filter_events", parameters: [
                                "filter_type": newValue.rawValue
                            ])
                            
                            viewModel.loadEvents()
                        }
                    }
                }
                .padding(.bottom)
                
                if viewModel.isLoadingEvents || viewModel.isLoadingFollowers || viewModel.isLoadingNearYou || viewModel.isLoadingFollowersEvents {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    if let events = viewModel.events, events.count > 0 {
                        
                        VStack {
                            ForEach(events, id: \.eventID) { event in
                                
                                NavigationLink {
                                    EventDetailView(event: event)
                                        .padding(.top)
                                } label: {
                                    DiscoverView.EventCard2(event: event)
                                        .padding(.vertical, 10)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    /// NO EVENTS (Empty state)
                    Divider()
                        .padding()
                        .showIf(viewModel.followers?.count ?? 0 > 0)
                    Text("Host an event with a friend")
                        .padding(.horizontal)
                        .showIf(viewModel.followers?.count ?? 0 > 0)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            if let followers = viewModel.followers {
                                ForEach(followers, id: \.userID) { user in
                                    NavigationLink {
                                        CreateNewEventView(otherHosts: user.userID,
                                                           otherHostName: user.username)
                                    } label: {
                                        VStack {
                                            PfpView(user: user,
                                                    size: 75,
                                                    isRound: true)
                                            Text(user.username)
                                                .font(.system(size: 12))
                                                .foregroundColor(.primary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .padding()
                        .showIf(viewModel.friendEvents?.count ?? 0 > 0)
                    Text("Events friends are attending")
                        .padding(.leading)
                        .showIf(viewModel.friendEvents?.count ?? 0 > 0)
                    ScrollView(.horizontal, showsIndicators: false) {
                        
                        HStack(spacing: 10) {
                            if let friendEvents = viewModel.friendEvents {
                                ForEach(friendEvents, id: \.eventID) { event in
                                    NavigationLink {
                                        EventDetailView(event: event)
                                            .padding(.top)
                                    } label: {
                                        DiscoverView.EventCard2(event: event)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    Divider()
                        .padding()
                        .showIf(viewModel.usersNearby?.count ?? 0 > 0)
                    Text("People using KiccBacc near you")
                        .padding(.leading)
                        .showIf(viewModel.usersNearby?.count ?? 0 > 0)
                    ScrollView(.horizontal, showsIndicators: false) {
                        ScrollViewReader { scrollView in
                            HStack {
                                if let followers = viewModel.usersNearby {
                                    ForEach(followers, id: \.userID) { user in
                                        NavigationLink {
                                            UserProfileView(user: user)
                                        } label: {
                                            VStack {
                                                PfpView(user: user,
                                                        size: 75,
                                                        isRound: true)
                                                Text(user.username)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                        .padding(5)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.top, 5)
        .navigationTitle("")
        .navigationBarHidden(true)
        .onAppear {
            // Track screen view when this view appears
            AnalyticsManager.logScreenView(screenName: "Discover", screenClass: "DiscoverView")
        }
        .onChange(of: currentUser) { newValue in
            if loaded { return }
            
            viewModel.loadEvents()
            viewModel.fetchFollowers(currentUser: newValue)
            viewModel.fetchFriendEvents(currentUser: newValue)
            viewModel.fetchNearbyUsers(currentUser: newValue)

            loaded = true
        }

        .alert(item: $viewModel.alertItem) { alertItem in
            guard let primaryButton = alertItem.primaryButton, let secondaryButton = alertItem.secondaryButton
            else {
                return Alert(title: alertItem.title, message: alertItem.message, dismissButton: alertItem.dismissButton)
            }
            
            return Alert(title: alertItem.title, message: alertItem.message, primaryButton: primaryButton, secondaryButton: secondaryButton)
        }
    }
    
    
    struct EventCard: View {
        
        var event: Event
        
        @State private var user: User?
        @State private var isFavourite: Bool = false
        
        var body: some View {
            ZStack(alignment: .bottom) {
                let pfpUrl = event.eventBannerUrl
                if let url = URL(string: pfpUrl) {
                    KBImage(url: url, resizeMode: .fill)
                        .frame(minWidth: 0, maxWidth: UIScreen.main.bounds.width, minHeight: 0, maxHeight: 500)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal)
                }
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 10) {
                        let eventTypeString = event.type
                        if let eventType = EventType(rawValue: eventTypeString) {
                            if eventType.rawValue == "Custom" {
                                Text(event.customType ?? "")
                                    .padding(10)
                                    .background(BlurView(style: .systemUltraThinMaterial))
                                    .foregroundColor(.labelColor)
                                    .clipShape(Capsule())
                                    .font(.system(size: 12))
                                    .padding(.bottom, 10)
                            } else {
                                Text(eventType.title)
                                    .padding(10)
                                    .background(BlurView(style: .systemUltraThinMaterial))
                                    .foregroundColor(.labelColor)
                                    .clipShape(Capsule())
                                    .font(.system(size: 12))
                                    .padding(.bottom, 10)
                            }
                        }
                        
                        Text(getDate())
                        
                        Text(event.name)
                            .font(.title)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 25) {
                        let heartIconSize: CGFloat = 17
                        if (event.password != nil && event.password != "") {
                            Image(systemName: "lock.circle.fill")
                                .resizable()
                                .frame(width: 37.5, height: 37.5)
                                .foregroundStyle(.gray)
                        }
                        
                        Image(systemName: isFavourite ? "heart.fill" : "heart")
                            .resizable()
                            .frame(width: heartIconSize, height: heartIconSize)
                            .foregroundColor(.red)
                        
                        if let pfpUrl = user?.profileImageUrlString, let url = URL(string: pfpUrl) {
                            ZStack(alignment: .bottomTrailing) {
                                KBImage(url: url, resizeMode: .fill)
                                    .frame(width: 30, height: 30)
                                    .clipShape(Circle())
                                
                                // Add verification badge if user is verified
                                if user?.verified == true {
                                    Image("Verified")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .offset(x: 15, y: 15)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(BlurView(style: .systemThinMaterial))
                .cornerRadius(15)
                .padding([.horizontal, .bottom], 30)
                .foregroundColor(.white)
            }
            .onAppear {
                getUser()
                
                // check if current user is interested in the event or not
                EventManager.shared.isCurrentUserInterested(inEvent: event) { isInterested in
                    withAnimation { isFavourite = isInterested }
                }
            }
        }
        
        private func getUser() {
            // Safe unwrap of first host ID
            guard let firstHostID = event.hostIDs.first else {
                print("⚠️ DiscoverView: No host IDs found for event \(event.eventID)")
                return
            }
            
            UserManager.shared.getUserListener(withUserID: firstHostID) { result in
                switch result {
                case .success(let user):
                    self.user = user
                case .failure(let error):
                    print("⚠️ DiscoverView: Failed to get user: \(error)")
                }
            }
        }
        
        private func getDate() -> String {
            let calendar = Calendar.current
            
            let fromDateComponent = calendar.dateComponents([.day, .month, .year], from: event.from)
            let toDateComponent = calendar.dateComponents([.day, .month, .year], from: event.to)
            
            guard fromDateComponent.month == toDateComponent.month else {
                return "different month"
            }
            
            guard fromDateComponent.year == toDateComponent.year else {
                return "different year"
            }
            
            if let monthCount = fromDateComponent.month, let from = fromDateComponent.day, let to = toDateComponent.day, let year = fromDateComponent.year {
                let month = DateFormatter().monthSymbols[monthCount - 1]
                
                return "\(from) - \(to) \(month), \(year)"
            }
            
            return ""
        }
    }
    
    struct EventCard2: View {
        
        var event: Event
        
        @State private var user: User?
        @State private var isFavourite: Bool = false
        @State private var loaded: Bool = false
        @State private var isLoadingInstagramShare: Bool = false
        @State private var showInstagramNotInstalledAlert: Bool = false
        
        var body: some View {
            VStack {
                let bannerUrl = event.eventBannerUrl
                if let url = URL(string: bannerUrl) {
                    ZStack {
                        KBImage(url: url, resizeMode: .fill)
                            .frame(height: 200)
                            .frame(minWidth: 0, maxWidth: UIScreen.main.bounds.width, minHeight: 0, maxHeight: 200)
                            .cornerRadius(20, corners: [.topLeft, .topRight])
                        
                        VStack {
                            HStack {
                                Spacer()
                                
                                // Regular share button
                                Image(systemName: "square.and.arrow.up")
                                    .resizable()
                                    .frame(width: 17, height: 17)
                                    .foregroundColor(.black)
                                    .frame(width: 40, height: 40)
                                    .background(Color.bgColor)
                                    .clipShape(Circle())
                                    .onTapGesture {
                                        HapticGenerator.light.impactOccurred()
                                        shareEvent()
                                    }
                                    
                                // Instagram share button
                                ZStack {
                                                   Image("instagram")
                                                       .resizable()
                                                       .frame(width: 40, height: 40)
                                                       .foregroundColor(.pink)
                                                       .background(Color.bgColor)
                                                       .clipShape(Circle())
                                                       .opacity(isLoadingInstagramShare ? 0.5 : 1)
                                                       .onTapGesture {
                                                           HapticGenerator.light.impactOccurred()
                                                           shareEventToInstagram()
                                                           
                                                       }
                                                   
                                                   if isLoadingInstagramShare {
                                                       ProgressView()
                                                           .progressViewStyle(CircularProgressViewStyle())
                                                           .scaleEffect(0.8)
                                                   }
                                               }
                                .alert(isPresented: $showInstagramNotInstalledAlert) {
                                    Alert(
                                        title: Text("Instagram Not Installed"),
                                        message: Text("Instagram is not installed on your device. Please install Instagram to share this event to Instagram Stories."),
                                        dismissButton: .default(Text("OK"))
                                    )
                                }
                            }
                            .padding([.top, .horizontal])
                            Spacer()
                            HStack(alignment: .center, spacing: 10) {
                                let eventTypeString = event.type
                                if let eventType = EventType(rawValue: eventTypeString) {
                                    if eventType.rawValue == "Custom" {
                                        Text(event.customType ?? "")
                                            .padding(10)
                                            .background(BlurView(style: .systemUltraThinMaterial))
                                            .foregroundColor(.labelColor)
                                            .clipShape(Capsule())
                                            .font(.system(size: 12))
                                            .padding(.bottom, 10)
                                    } else {
                                        Text(eventType.title)
                                            .padding(10)
                                            .background(BlurView(style: .systemUltraThinMaterial))
                                            .foregroundColor(.labelColor)
                                            .clipShape(Capsule())
                                            .font(.system(size: 12))
                                            .padding(.bottom, 10)
                                    }
                                }
                                
                                Spacer()
                                if (event.password != nil && event.password != "") {
                                    Image(systemName: "lock.circle.fill")
                                        .resizable()
                                        .frame(width: 37.5, height: 37.5)
                                        .foregroundStyle(.gray)
                                }
                                
                                let heartIconSize: CGFloat = 17
                                
                                Image(systemName: isFavourite ? "heart.fill" : "heart")
                                    .resizable()
                                    .frame(width: heartIconSize, height: heartIconSize)
                                    .foregroundColor(.red)
                                    .frame(width: 40, height: 40)
                                    .background(Color.bgColor)
                                    .clipShape(Circle())
                                    .onTapGesture {
                                        
                                        HapticGenerator.light.impactOccurred()
                                        
                                        if isFavourite {
                                            // Track unfavorite event
                                            AnalyticsManager.logCustomEvent(name: "unfavorite_event", parameters: [
                                                "event_id": event.eventID,
                                                "event_name": event.name
                                            ])
                                            
                                            EventManager.shared.removeInterestedIn(event: event) { isNotInterested in
                                                withAnimation { isFavourite = !isNotInterested }
                                            }
                                        } else {
                                            // Track favorite event
                                            AnalyticsManager.logCustomEvent(name: "favorite_event", parameters: [
                                                "event_id": event.eventID,
                                                "event_name": event.name
                                            ])
                                            
                                            EventManager.shared.interestedIn(event: event) { isInterested in
                                                withAnimation { isFavourite = isInterested }
                                            }
                                        }
                                    }
                                
                                if let user = user, let pfpUrl = user.profileImageUrlString, let url = URL(string: pfpUrl) {
                                    NavigationLink {
                                        UserProfileView(user: user)
                                    } label: {
                                        ZStack(alignment: .bottomTrailing) {
                                            KBImage(url: url, resizeMode: .fill)
                                                .frame(width: 40, height: 40)
                                                .clipShape(Circle())
                                            
                                            // Add verification badge if user is verified
                                            if user.verified == true {
                                                Image("Verified")
                                                    .resizable()
                                                    .frame(width: 50, height: 50)
                                                    .offset(x: 15, y: 15)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(getDate())
                            .font(.system(size: 14, weight: .regular, design: .default))
                        
                        Text(event.name)
                            .font(.system(size: 18, weight: .semibold, design: .default))
                    }
                    
                    Spacer()
                    
                    Assets.UI.arrowLeft
                        .rotationEffect(Angle(degrees: 180))
                }
                .padding([.horizontal, .bottom], 25)
                .padding(.top)
            }
            .foregroundColor(.labelColor)
            .contentShape(Rectangle())
            .background(Color.bgColor.cornerRadius(20))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 0)
            .onAppear {
                
                if loaded {
                    return
                }
                
                getUser()
                
                // check if current user is interested in the event or not
                EventManager.shared.isCurrentUserInterested(inEvent: event) { isInterested in
                    withAnimation { isFavourite = isInterested }
                }
                loaded = true
            }
        }
        
        private func getUser() {
            if let hostID = event.hostIDs.first {
                UserManager.shared.getUserListener(withUserID: hostID) { result in
                    switch result {
                    case .success(let user):
                        self.user = user
                    case .failure(_):
                        break
                    }
                }
            }
        }
        
        private func getDate() -> String {
            let calendar = Calendar.current
            
            let fromDateComponent = calendar.dateComponents([.day, .month, .year], from: event.from)
            let toDateComponent = calendar.dateComponents([.day, .month, .year], from: event.to)
            
            guard fromDateComponent.month == toDateComponent.month else {
                return "different month"
            }
            
            guard fromDateComponent.year == toDateComponent.year else {
                return "different year"
            }
            
            if let monthCount = fromDateComponent.month, let from = fromDateComponent.day, let to = toDateComponent.day, let year = fromDateComponent.year {
                let month = DateFormatter().monthSymbols[monthCount - 1]
                
                return "\(from) - \(to) \(month), \(year)"
            }
            
            return ""
        }

        private func shareEventToInstagram() {
            
            func generateQRCode(from string: String) -> UIImage? {
                let data = string.data(using: String.Encoding.ascii)
                
                if let filter = CIFilter(name: "CIQRCodeGenerator") {
                    filter.setValue(data, forKey: "inputMessage")
                    // Smaller scale for QR code that will be in corner
                    let transform = CGAffineTransform(scaleX: 10, y: 10)
                    
                    if let output = filter.outputImage?.transformed(by: transform) {
                        // Create UIImage from CIImage
                        let qrCodeImage = UIImage(ciImage: output)
                        
                        // Get the logo image
                        if let logoImage = UIImage(named: "def_Logo") {
                            // Create a new context with the size of the QR code
                            UIGraphicsBeginImageContextWithOptions(qrCodeImage.size, false, 0)
                            
                            // Draw the QR code
                            qrCodeImage.draw(in: CGRect(origin: .zero, size: qrCodeImage.size))
                            
                            // Calculate logo size (25% of QR code size)
                            let logoSize = qrCodeImage.size.width * 0.25
                            
                            // Calculate position to center the logo
                            let logoX = (qrCodeImage.size.width - logoSize) / 2
                            let logoY = (qrCodeImage.size.height - logoSize) / 2
                            
                            // Create a rounded rect path for the logo (with 20% corner radius)
                            let cornerRadius = logoSize * 0.2
                            let logoRect = CGRect(x: logoX, y: logoY, width: logoSize, height: logoSize)
                            let roundedRectPath = UIBezierPath(roundedRect: logoRect, cornerRadius: cornerRadius)
                            
                            // Create clipping mask for rounded corners
                            roundedRectPath.addClip()
                            
                            // Draw the logo in the center with rounded corners
                            logoImage.draw(in: logoRect)
                            
                            // Get the combined QR code with logo
                            let combinedQRImage = UIGraphicsGetImageFromCurrentImageContext()
                            UIGraphicsEndImageContext()
                            
                            return combinedQRImage
                        }
                        
                        return qrCodeImage
                    }
                }
                
                return nil
            }
            
            // New function to overlay QR code on event banner
            func overlayQRCodeOnEventBanner(eventBannerData: Data, qrCode: UIImage) -> Data? {
                guard let bannerImage = UIImage(data: eventBannerData) else {
                    return nil
                }
                
                // Instagram story dimensions (9:16 aspect ratio)
                let storyWidth: CGFloat = 1080
                let storyHeight: CGFloat = 1920
                
                // Start a new graphics context with Instagram story dimensions
                UIGraphicsBeginImageContextWithOptions(CGSize(width: storyWidth, height: storyHeight), false, 0)
                
                // Fill background with black
                UIColor.black.setFill()
                UIRectFill(CGRect(x: 0, y: 0, width: storyWidth, height: storyHeight))
                
                // Calculate scaling to fit the image within the story dimensions while preserving aspect ratio
                let imageWidth = bannerImage.size.width
                let imageHeight = bannerImage.size.height
                let imageAspect = imageWidth / imageHeight
                let storyAspect = storyWidth / storyHeight
                
                var drawRect: CGRect
                
                if imageAspect > storyAspect {
                    // Image is wider than story - scale to match height
                    let scaledWidth = storyHeight * imageAspect
                    let xOffset = (storyWidth - scaledWidth) / 2
                    drawRect = CGRect(x: xOffset, y: 0, width: scaledWidth, height: storyHeight)
                } else {
                    // Image is taller than story - scale to match width
                    let scaledHeight = storyWidth / imageAspect
                    let yOffset = (storyHeight - scaledHeight) / 2
                    drawRect = CGRect(x: 0, y: yOffset, width: storyWidth, height: scaledHeight)
                }
                
                // Draw the image preserving aspect ratio
                bannerImage.draw(in: drawRect)
                
                // Calculate QR code size (20% of the story width)
                let qrSize = storyWidth * 0.35
                
                // Position in bottom right with padding, ensuring it's fully visible
                let padding: CGFloat = storyWidth * 0.05
                let qrX = storyWidth - qrSize - padding
                let qrY = storyHeight - qrSize - padding
                
                // Draw the QR code in the bottom right
                qrCode.draw(in: CGRect(x: qrX, y: qrY, width: qrSize, height: qrSize))
                
                // Get the combined image
                let combinedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                // Convert to data
                return combinedImage?.pngData()
            }
            // Create Instagram Story URL scheme
            let eventDeepLink = "https://kiccbacc.com/event/\(event.eventID)"
            let kInstagramAppID = "1186790129900556"
            
            // Instagram Story URL scheme
            let urlScheme = "instagram-stories://share?source_application=\(kInstagramAppID)"
            
            if let urlString = URL(string: urlScheme) {
                if UIApplication.shared.canOpenURL(urlString) {
                    // Show loading indicator
                    isLoadingInstagramShare = true
                    
                    // Use event banner image instead of default logo
                    if let eventBannerUrl = URL(string: event.eventBannerUrl) {
                        // Download the image asynchronously
                        URLSession.shared.dataTask(with: eventBannerUrl) { data, response, error in
                            if let error = error {
                                print("Error downloading image: \(error)")
                                DispatchQueue.main.async {
                                    isLoadingInstagramShare = false
                                }
                                return
                            }
                            
                            if let imageData = data {
                                DispatchQueue.main.async {
                                    // Generate QR code for the event deep link
                                    if let qrCodeImage = generateQRCode(from: eventDeepLink) {
                                        // Overlay QR code on the banner image
                                        if let combinedImageData = overlayQRCodeOnEventBanner(eventBannerData: imageData, qrCode: qrCodeImage) {
                                            // Include the combined image as background
                                            let pasteBoardItems: [[String: Any]] = [
                                                [
                                                    "com.instagram.sharedSticker.backgroundImage": combinedImageData,
                                                    "com.instagram.sharedSticker.contentURL":eventDeepLink,
                                                    "com.instagram.sharedSticker.linkURL": eventDeepLink,
                                                    "com.instagram.sharedSticker.linkText":
                                                      "Event Link"
                                                ]
                                            ]
                                            
                                            // Instagram requires items to be formatted as an array of dictionaries
                                            UIPasteboard.general.items = pasteBoardItems
                                            UIApplication.shared.open(urlString)
                                            isLoadingInstagramShare = false
                                        }
                                    }
                                }
                            } else {
                                print("No image data returned")
                                DispatchQueue.main.async {
                                    isLoadingInstagramShare = false
                                }
                            }
                        }.resume()
                    } else {
                        print("Invalid event banner URL")
                        isLoadingInstagramShare = false
                    }
                } else {
                    // Instagram is not installed
                    print("Instagram is not installed")
                    showInstagramNotInstalledAlert = true
                    AnalyticsManager.logCustomEvent(name: "instagram_share_failed", parameters: [
                                       "event_id": event.eventID,
                                       "event_name": event.name,
                                       "reason": "app_not_installed"
                                   ])
                               
                           
                       
                }
            }
        }
        
        private func shareEvent() {
            let eventDeepLink = "https://kiccbacc.com/event/\(event.eventID)"
            
            // Track share event
            AnalyticsManager.logCustomEvent(name: "share_event", parameters: [
                "event_id": event.eventID,
                "event_name": event.name,
                "share_method": "standard"
            ])
                                    
            // Items to share
            let items: [Any] = [
                eventDeepLink
            ]
            let activityVC = UIActivityViewController(
                activityItems: items,
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
    }
    
    struct EventCard3: View {
        
        var event: Event
        
        @State private var user: User?
        @State private var isFavourite: Bool = false
        
        var body: some View {
            VStack(alignment: .center, spacing: 15) {
                let bannerUrl = event.eventBannerUrl
                if let url = URL(string: bannerUrl) {
                    ZStack(alignment: .bottom) {
                        KBImage(url: url, resizeMode: .fill)
                            .frame(width: UIScreen.main.bounds.width - 40, height: 400)
                            .cornerRadius(20)
                            .overlay(
                                LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.6)]), startPoint: .top, endPoint: .bottom)
                                    .cornerRadius(20)
                            )
                            .overlay(
                                LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.4)]), startPoint: .bottom, endPoint: .top)
                                    .cornerRadius(20)
                            )
                        
                        VStack {
                            HStack {
                                VStack(alignment: .center, spacing: 5) {
                                    
                                    Text(getMonth())
                                        .font(.system(size: 14, weight: .regular, design: .default))
                                    
                                    Text(getDay())
                                        .font(.system(size: 16, weight: .bold, design: .default))
                                        .foregroundColor(Color.appColor)
                                }
                                .padding(10)
                                .background(Color.bgColor.cornerRadius(20))
                                
                                Spacer()
                            }
                            .padding(.top)
                            
                            Spacer()
                            
                            if let user = user {
                                VStack(spacing: 20) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 5) {
                                            
                                            Text(event.name)
                                                .font(.system(size: 18, weight: .semibold, design: .default))
                                            
                                            Text("By \(user.fullName)")
                                                .font(.system(size: 12, weight: .regular, design: .default))
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        if let pfpUrl = user.profileImageUrlString, let url = URL(string: pfpUrl) {
                                            ZStack(alignment: .bottomTrailing) {
                                                KBImage(url: url, resizeMode: .fill)
                                                    .frame(width: 40, height: 40)
                                                    .clipShape(Circle())
                                                
                                                // Add verification badge if user is verified
                                                if user.verified == true {
                                                    Image("Verified")
                                                        .resizable()
                                                        .frame(width: 50, height: 50)
                                                        .offset(x: 15, y: 15)
                                                }
                                            }
                                        }
                                    }
                                
                                    
                                    HStack {
                                        
                                        event.city?.text
                                            .font(.system(size: 14, weight: .bold, design: .default))
                                        
                                        Spacer()
                                        
                                        Circle()
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(Color.appColor)
                                            .overlay(Image(systemName: "map.fill").foregroundColor(.white))
                                            .shadow(color: Color.appColor.opacity(0.4), radius: 10, x: 5, y: 5)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 10)
                                    .background(LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.5), Color.appColor.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing).cornerRadius(15))
                                }
                                .padding()
                                .background(Color.bgColor.cornerRadius(20))
                            }
                        }
                        .padding([.horizontal, .bottom])
                    }
                }
            }
            .foregroundColor(.labelColor)
            .contentShape(Rectangle())
            .padding(.horizontal, 20)
            .shadow(color: .black.opacity(0.1), radius: 50, x: 0, y: 0)
            .onAppear {
                getUser()
                
                // check if current user is interested in the event or not
                EventManager.shared.isCurrentUserInterested(inEvent: event) { isInterested in
                    withAnimation { isFavourite = isInterested }
                }
            }
        }
        
        private func getUser() {
            if let hostID = event.hostIDs.first {
                UserManager.shared.getUserListener(withUserID: hostID) { result in
                    switch result {
                    case .success(let user):
                        self.user = user
                    case .failure(_):
                        break
                    }
                }
            }
        }
        
        private func getDay() -> String {
            
            let calendar = Calendar.current
            let fromDateComponent = calendar.dateComponents([.day, .month, .year], from: event.from)
            
            if let from = fromDateComponent.day {
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM"
                
                return "\(from)"
            }
            
            return ""
        }
        
        private func getMonth() -> String {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM"
            
            return "\(dateFormatter.string(from: event.from))"
        }
    }
}
