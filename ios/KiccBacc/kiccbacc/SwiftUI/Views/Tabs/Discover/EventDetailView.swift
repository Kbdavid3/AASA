//
//  EventDetailView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI

struct EventDetailView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentation
    
    @State private var currentEvent: Event
    
    init(event: Event) {
        self._currentEvent = State(initialValue: event)
    }
    
    @State private var isFavourite: Bool = false
    @State private var viewItem: ViewItem?
    @State private var modalViewItem: ViewItem?
    @State private var eventHost: User?
    @State private var storiesByUsers: [StoriesByUser]?
    @State private var interestedUsers: [User]?
    @State private var alertTitle: String = "This is a private event"
    @State private var password: String = ""
    @State private var isAlertShown = false
    @State private var isEventLocked = true
    @State private var showPaymentForm = false
    @State private var showCancelConfirmation = false
    @State private var isProcessingCancellation = false
    @State private var isLoadingInstagramShare = false
    @State private var showInstagramNotInstalledAlert = false
    @State private var shouldShowTicketSelector = false
    @State private var showEventPropertiesSheet = false
    
    // Glow effect state for add story button
    @State private var shouldGlowAddStoryButton = false
    @State private var glowAnimation: Bool = false
    
    // Debounce flags to prevent double presentations
    @State private var isStoryViewPresenting = false
    @State private var isStoryUploadPresenting = false
    @State private var isRefreshingStories = false // Add loading state for story refresh
    @State private var storiesListener: ListenerRegistration?
    
    // Welcome overlay state
    @State private var showWelcomeOverlay = false
    @State private var shouldScrollToStories = false
    
    // Tab state for Details and Group Chat
    @State private var selectedTab = 0
    @State private var groupChatRoom: ChatRoom?
    @State private var groupChatMessages: [Message] = []
    @State private var newGroupMessage: String = ""
    @State private var groupChatMembers: [User] = []
    @State private var showInviteSheet = false
    @State private var isHostOnly = true // Initially only host can see chat
    
    func handlePaymentSuccess() {
        print ("payment successful, making API request!")
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
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
    private func overlayQRCodeOnEventBanner(eventBannerData: Data, qrCode: UIImage) -> Data? {
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
    
    var body: some View {
        ZStack {
            // Background color for entire view
            Color.bgColor.ignoresSafeArea()
            
            VStack {
                // navigation
                HStack {
                    Button {
                        presentation.wrappedValue.dismiss()
                    } label: {
                        Assets.UI.arrowLeft
                            .foregroundColor(.labelColor)
                    }
                    
                    Spacer()
                    
                    HStack(alignment: .center, spacing: 20) {
                        if let eventHost = eventHost, isCurrentUserHost() {
                            NavigationLink {
                                EditEventView(event: currentEvent, host: eventHost)
                            } label: {
                                Text("Edit")
                                    .font(.system(size: 15, weight: .regular, design: .default))
                            }
                            
                            NavigationLink {
                                SendNotificationView(event: currentEvent)
                            } label: {
                                Image(systemName: "bell")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            
                            Button {
                                showEventPropertiesSheet = true
                            } label: {
                                Image(systemName: "gear")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .padding([.horizontal, .bottom])
                .padding(.top)
                
                // Tab selector for Details and Group Chat
                HStack(spacing: 0) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = 0
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text("Details")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(selectedTab == 0 ? .appColor : .gray)
                            
                            Rectangle()
                                .fill(selectedTab == 0 ? Color.appColor : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    
                    Spacer()
                    
                    // Show Group Chat tab if user is host or participant in the chat room
                    if isCurrentUserHost() || isCurrentUserInGroupChat() {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab = 1
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text("Group Chat")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(selectedTab == 1 ? .appColor : .gray)
                                
                                Rectangle()
                                    .fill(selectedTab == 1 ? Color.appColor : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                // Tab content
                if selectedTab == 0 {
                    // Details tab content (existing content)
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 25) {
                                let eventBannerUrl = currentEvent.eventBannerUrl
                                if let url = URL(string: eventBannerUrl) {
                                    KBImage(url: url, resizeMode: .fill)
                                        .frame(height: 400)
                                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 400)
                                        .cornerRadius(20)
                                }
                                
                                // event actions
                                HStack(alignment: .center, spacing: 10) {
                                    let eventTypeString = currentEvent.type
                                    if eventTypeString == "Custom" {
                                        Text(currentEvent.customType ?? "")
                                            .padding(10)
                                            .background(BlurView(style: .systemUltraThinMaterial))
                                            .foregroundColor(.labelColor)
                                            .clipShape(Capsule())
                                            .padding(.bottom, 10)
                                    } else {
                                        if let eventType = EventType(rawValue: eventTypeString) {
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
                                    
                                    VStack(spacing: 5) {
                                        if currentEvent.showTicketsSold {
                                            Text("\(currentEvent.soldCount ?? "No") tickets sold")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.gray)
                                        }
                                        
                                        NavigationLink {
                                            ListOfUsersView(userIDs: currentEvent.interestedUserIDs, usersKind: .interestedUsers, isHost: isCurrentUserHost(), eventID: currentEvent.eventID)
                                                .navigationTitle("Joined users")
                                        } label: {
                                            Text("\(currentEvent.interestedUserIDs.count) joined")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    .padding(.trailing, 5)
                                    
                                    let heartIconSize: CGFloat = 17
                                    Button {
                                        HapticGenerator.light.impactOccurred()
                                        
                                        if isFavourite {
                                            EventManager.shared.removeInterestedIn(event: currentEvent) { isNotInterested in
                                                withAnimation { isFavourite = !isNotInterested }
                                            }
                                        } else {
                                            EventManager.shared.interestedIn(event: currentEvent) { isInterested in
                                                withAnimation {
                                                    isFavourite = isInterested
                                                    // Trigger glow effect when user joins event
                                                    if isInterested {
                                                        // Mark event as joined for this install
                                                        markEventAsJoined()
                                                        
                                                        // Always trigger story button glow and autoscroll when joining event
                                                        triggerStoryButtonEffects()
                                                        
                                                        // Check for welcome overlay after joining (once per install)
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                                            checkForWelcomeOverlay()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        Image(systemName: isFavourite ? "heart.fill" : "heart")
                                            .resizable()
                                            .frame(width: heartIconSize, height: heartIconSize)
                                            .foregroundColor(.red)
                                            .frame(width: 40, height: 40)
                                            .background(Color.bgColor)
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(FlatLinkStyle())
                                    
                                    if let user = eventHost, let pfpUrl = user.profileImageUrlString, let url = URL(string: pfpUrl) {
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
                                                        .frame(width: 60, height: 60)
                                                        .position(x: 32, y: 32) // Position at bottom-right corner
                                                }
                                            }
                                            .frame(width: 40, height: 40)
                                        }
                                        .buttonStyle(FlatLinkStyle())
                                    }
                                }
                                
                                // event name
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(alignment: .bottom) {
                                        VStack(alignment: .leading, spacing: 10) {
                                            Text(currentEvent.name)
                                                .font(.system(size: 20, weight: .bold, design: .default))
                                            
                                            HStack {
                                                HStack {
                                                    Image(systemName: "calendar")
                                                        .foregroundColor(.appColor)
                                                    
                                                    Text(getDate())
                                                }
                                            }
                                            .font(.system(size: 13, weight: .regular, design: .default))
                                        }
                                        
                                        Spacer()
                                    }
                                }
                                .foregroundColor(.labelColor)
                                
                                // stories - only show if event allows it
                                if currentEvent.showStories, let stories = storiesByUsers, stories.count > 0 {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Stories")
                                            .font(.system(size: 12, weight: .semibold, design: .default))
                                            .foregroundColor(.gray)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(alignment: .center, spacing: 16) {
                                                // Add story button (only show if user is interested in event)
                                                if isFavourite {
                                                    Button {
                                                        // Prevent double tap and optimize for quick response
                                                        guard !isStoryUploadPresenting else { return }
                                                        
                                                        // Set flag immediately to prevent double-tap
                                                        isStoryUploadPresenting = true
                                                        
                                                        // Reset after a delay to allow re-opening if needed
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                            // Set viewItem to present the NativeStoryCameraView directly with eventID and callback
                                                            viewItem = ViewItem(AnyView(NativeStoryCameraView(
                                                                selectedImage: .constant(nil),
                                                                eventID: currentEvent.eventID,
                                                                onStoryUploaded: {
                                                                    // Refresh stories when a new story is uploaded
                                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                                        loadStories()
                                                                        // Don't set isStoryUploadPresenting here - let onDisappear handle it
                                                                    }
                                                                }
                                                            )
                                                                .onDisappear {
                                                                    // Reset flag when view disappears
                                                                    print("📸 EventDetailView: Camera view disappeared")
                                                                    isStoryUploadPresenting = false
                                                                    // DON'T clear viewItem here - let fullScreenCover handle it
                                                                    // Clearing it can cause premature dismissal
                                                                }), _presentationStyle: .fullScreen)
                                                        }
                                                    } label: {
                                                        // Circle Add Story button - positioned higher
                                                        VStack {
                                                            Circle()
                                                                .fill(Color.secondaryBgColor)
                                                                .frame(width: 80, height: 80)
                                                                .overlay(
                                                                    Image(systemName: "plus")
                                                                        .foregroundColor(.labelColor)
                                                                        .font(.system(size: 24, weight: .medium))
                                                                )
                                                                .background(
                                                                    // Background glow effect
                                                                    Circle()
                                                                        .fill(shouldGlowAddStoryButton ? Color.appColor.opacity(0.3) : Color.clear)
                                                                        .scaleEffect(glowAnimation ? 1.5 : 1.2)
                                                                        .blur(radius: shouldGlowAddStoryButton ? 8 : 0)
                                                                        .animation(
                                                                            shouldGlowAddStoryButton ?
                                                                            Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true) :
                                                                                    .easeOut(duration: 1.0),
                                                                            value: glowAnimation
                                                                        )
                                                                )
                                                                .shadow(
                                                                    color: shouldGlowAddStoryButton ? Color.appColor.opacity(0.6) : Color.clear,
                                                                    radius: shouldGlowAddStoryButton ? 15 : 0,
                                                                    x: 0,
                                                                    y: 0
                                                                )
                                                                .scaleEffect(shouldGlowAddStoryButton ? 1.05 : 1.0)
                                                                .animation(.easeInOut(duration: 0.3), value: shouldGlowAddStoryButton)
                                                            
                                                            Spacer()
                                                                .frame(height: 60) // Reduced from 100 to move circle down
                                                        }
                                                        .frame(height: 180) // Match story height
                                                    }
                                                    .disabled(isStoryUploadPresenting)
                                                }
                                                
                                                // Story cards - stories added first appear first
                                                ForEach(stories, id: \.userID) { storyByUser in
                                                    Button {
                                                        // Prevent double tap
                                                        if !isStoryViewPresenting {
                                                            isStoryViewPresenting = true
                                                            
                                                            // Set viewItem to present the StoriesView with onDisappear callback
                                                            viewItem = ViewItem(AnyView(StoriesView(stories: storyByUser.stories)
                                                                .onDisappear {
                                                                    isStoryViewPresenting = false
                                                                    // Refresh stories to update indicators after viewing
                                                                    // Add a small delay to ensure Firestore has updated
                                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                                        loadStories()
                                                                    }
                                                                }), _presentationStyle: .fullScreen)
                                                        }
                                                    } label: {
                                                        EnhancedStoryView(
                                                            userID: storyByUser.userID,
                                                            stories: storyByUser.stories
                                                        )
                                                    }
                                                    .disabled(isStoryViewPresenting)
                                                }
                                            }
                                            .padding(.horizontal, 0) // Remove left padding
                                            .padding(.vertical, 16) // Increased vertical padding to prevent clipping
                                        }
                                    }
                                    .id("stories-section")
                                } else if currentEvent.showStories && isFavourite {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Stories")
                                            .font(.system(size: 12, weight: .semibold, design: .default))
                                            .foregroundColor(.gray)
                                        
                                        HStack(alignment: .center, spacing: 16) {
                                            Button {
                                                // Prevent double tap and optimize for quick response
                                                guard !isStoryUploadPresenting else { return }
                                                
                                                // Set flag immediately to prevent double-tap
                                                isStoryUploadPresenting = true
                                                
                                                // Reset after a delay to allow re-opening if needed
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                    // Set viewItem to present the NativeStoryCameraView directly with eventID and callback
                                                    viewItem = ViewItem(AnyView(NativeStoryCameraView(
                                                        selectedImage: .constant(nil), // This will be handled internally by NativeStoryCameraView
                                                        eventID: currentEvent.eventID,
                                                        onStoryUploaded: {
                                                            // Refresh stories when a new story is uploaded
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                                loadStories()
                                                                // Don't set isStoryUploadPresenting here - let onDisappear handle it
                                                            }
                                                        }
                                                    )
                                                        .onDisappear {
                                                            // Reset flag when view disappears
                                                            print("📸 EventDetailView: Camera view disappeared (second button)")
                                                            isStoryUploadPresenting = false
                                                            // DON'T clear viewItem here - let fullScreenCover handle it
                                                            // Clearing it can cause premature dismissal
                                                        }), _presentationStyle: .fullScreen)
                                                }
                                            } label: {
                                                // Circle Add Story button - positioned higher
                                                VStack {
                                                    Circle()
                                                        .fill(Color.secondaryBgColor)
                                                        .frame(width: 80, height: 80)
                                                        .overlay(
                                                            Image(systemName: "plus")
                                                                .foregroundColor(.labelColor)
                                                                .font(.system(size: 24, weight: .medium))
                                                        )
                                                        .background(
                                                            // Background glow effect
                                                            Circle()
                                                                .fill(shouldGlowAddStoryButton ? Color.appColor.opacity(0.3) : Color.clear)
                                                                .scaleEffect(glowAnimation ? 1.5 : 1.2)
                                                                .blur(radius: shouldGlowAddStoryButton ? 8 : 0)
                                                                .animation(
                                                                    shouldGlowAddStoryButton ?
                                                                    Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true) :
                                                                            .easeOut(duration: 1.0),
                                                                    value: glowAnimation
                                                                )
                                                        )
                                                        .shadow(
                                                            color: shouldGlowAddStoryButton ? Color.appColor.opacity(0.6) : Color.clear,
                                                            radius: shouldGlowAddStoryButton ? 15 : 0,
                                                            x: 0,
                                                            y: 0
                                                        )
                                                        .scaleEffect(shouldGlowAddStoryButton ? 1.05 : 1.0)
                                                        .animation(.easeInOut(duration: 0.3), value: shouldGlowAddStoryButton)
                                                    
                                                    Spacer()
                                                        .frame(height: 60) // Reduced from 100 to move circle down
                                                }
                                                .frame(height: 180) // Match story height
                                            }
                                            .disabled(isStoryUploadPresenting)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 0) // Remove left padding
                                        .padding(.vertical, 16) // Increased vertical padding to prevent clipping
                                    }
                                    .id("stories-section")
                                }
                                
                                // description
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Description")
                                        .font(.system(size: 12, weight: .semibold, design: .default))
                                        .foregroundColor(.gray)
                                    
                                    Text(currentEvent.description)
                                        .font(.system(size: 13, weight: .regular, design: .default))
                                }
                                if let merchantId = currentEvent.hostIDs.first {
                                    VStack(alignment: .leading, spacing: 15) {
                                        
                                        let availableTicketsForUser: Int = {
                                            if let totalTickets = currentEvent.totalTickets {
                                                let remaining = currentEvent.soldCount.flatMap { soldCount in
                                                    Int(soldCount).map { totalTickets - $0 }
                                                } ?? totalTickets
                                                
                                                return currentEvent.maxTicketsPerUser.map { min(remaining, $0) } ?? remaining
                                            } else if let ticketTypes = currentEvent.ticketTypes, !ticketTypes.isEmpty {
                                                // Find the minimum maxPerUser across all ticket types
                                                let minMaxPerUser = ticketTypes.compactMap { $0.maxPerUser }.min() ?? .max
                                                
                                                // Calculate remaining tickets
                                                let totalFromTicketTypes = ticketTypes.reduce(0) { $0 + (Int($1.quantity ?? 0)) }
                                                let soldCount = currentEvent.soldCount.flatMap { Int($0) } ?? 0
                                                let remaining = max(0, totalFromTicketTypes - soldCount)
                                                
                                                return min(remaining, minMaxPerUser)
                                            } else {
                                                return currentEvent.maxTicketsPerUser ?? .max
                                            }
                                        }()
                                        
                                        Text("Tickets")
                                            .font(.system(size: 12, weight: .semibold, design: .default))
                                            .foregroundColor(.gray)
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            if let totalTickets = currentEvent.totalTickets {
                                                let soldCountInt = currentEvent.soldCount.flatMap { Int($0) } ?? 0
                                                let remaining = totalTickets - soldCountInt
                                                
                                                Text("Total Tickets: \(totalTickets)")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.gray)
                                                
                                                if currentEvent.showTicketsSold {
                                                    Text("Remaining: \(remaining)")
                                                        .font(.system(size: 13))
                                                        .foregroundColor(.gray)
                                                }
                                                
                                                Text("Available Tickets For User: \(availableTicketsForUser)+")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.gray)
                                            } else if let ticketTypes = currentEvent.ticketTypes, !ticketTypes.isEmpty {
                                                // Calculate total tickets from all ticket types
                                                let soldCountInt = currentEvent.soldCount.flatMap { Int($0) } ?? 0
                                                let totalFromTicketTypes = ticketTypes.reduce(0) { $0 + (Int($1.quantity ?? 0)) }
                                                let actualTotalTickets = totalFromTicketTypes + soldCountInt
                                                
                                                Text("Total Tickets: \(actualTotalTickets)")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.gray)
                                                
                                                if currentEvent.showTicketsSold {
                                                    Text("Sold: \(soldCountInt)")
                                                        .font(.system(size: 13))
                                                        .foregroundColor(.gray)
                                                }
                                                
                                                // Calculate remaining tickets
                                                let remaining = totalFromTicketTypes
                                                if currentEvent.showTicketsSold {
                                                    Text("Remaining: \(remaining)")
                                                        .font(.system(size: 13))
                                                        .foregroundColor(.gray)
                                                }
                                                
                                                Text("Available Tickets For User: \(availableTicketsForUser)+")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.gray)
                                            } else {
                                                Text("Total Tickets: Unlimited")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.gray)
                                                Text("Available Tickets For User: \(availableTicketsForUser > 100 ? "Unlimited" : "\(availableTicketsForUser)+")")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        
                                        HStack {
                                            if let ticketTypes = currentEvent.ticketTypes, !ticketTypes.isEmpty {
                                                // Find the lowest price from all ticket types
                                                let lowestPrice = ticketTypes.compactMap { Double($0.price) }.min() ?? 0
                                                Text("Tickets from ")
                                                    .font(.system(size: 24, weight: .regular, design: .default))
                                                    .foregroundColor(.labelColor) +
                                                Text("$\(String(format: "%.2f", lowestPrice))+")
                                                    .font(.system(size: 24, weight: .bold, design: .default))
                                                    .foregroundColor(.labelColor)
                                            } else if currentEvent.catalog_id != nil {
                                                Text("$\(currentEvent.paymentAmount ?? "0.00") per ticket")
                                                    .font(.system(size: 24, weight: .bold, design: .default))
                                                    .foregroundColor(.labelColor)
                                            } else {
                                                Text("Free Event")
                                                    .font(.system(size: 24, weight: .bold, design: .default))
                                                    .foregroundColor(.labelColor)
                                            }
                                            Spacer()
                                            
                                            if availableTicketsForUser > 0 && Date() <= currentEvent.to{
                                                Button {
                                                    if let ticketTypes = currentEvent.ticketTypes, !ticketTypes.isEmpty {
                                                        shouldShowTicketSelector = true
                                                    } else {
                                                        showPaymentForm = true
                                                    }
                                                } label: {
                                                    Text(currentEvent.ticketTypes != nil && !(currentEvent.ticketTypes?.isEmpty ?? true) ?
                                                         "Purchase Tickets" :
                                                            (currentEvent.catalog_id != nil ? "Purchase Tickets" : "Purchase for Free"))
                                                    .font(.system(size: 16, weight: .semibold, design: .default))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 20)
                                                    .padding(.vertical, 10)
                                                    .background(Color.appColor)
                                                    .cornerRadius(10)
                                                }
                                                .sheet(isPresented: $showPaymentForm) {
                                                    if let catalogId = currentEvent.catalog_id, let merchantId = currentEvent.hostIDs.first {
                                                        PaymentFormView(eventName: currentEvent.name, catalogId: catalogId,
                                                                        merchantId: merchantId, ticketPrice: currentEvent.ticketPriceValue ?? 0.00,
                                                                        onPaymentSuccess: handlePaymentSuccess,
                                                                        maxTicketsPerUser: availableTicketsForUser, ticketTypeName: "General Admission", quantity: 2, ticketTypeId: "SiddharthPillai")
                                                    } else {
                                                        FreeEventRegistrationView(eventId: currentEvent.eventID,
                                                                                  merchantId: merchantId,
                                                                                  onRegistrationSuccess: handlePaymentSuccess,
                                                                                  maxTicketsPerUser: availableTicketsForUser)
                                                    }
                                                }
                                            }
                                            if let currentUserId = UserManager.shared.currentUserID,
                                               currentEvent.hostIDs.contains(currentUserId) &&
                                                Date() <= currentEvent.from {
                                                
                                                Button {
                                                    showCancelConfirmation = true
                                                } label: {
                                                    Text("Cancel Event")
                                                        .font(.system(size: 16, weight: .semibold, design: .default))
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 20)
                                                        .padding(.vertical, 10)
                                                        .background(Color.red)
                                                        .cornerRadius(10)
                                                }
                                                .alert(isPresented: $showCancelConfirmation) {
                                                    Alert(
                                                        title: Text("Cancel Event"),
                                                        message: Text("Are you sure you want to cancel this event? All tickets will be refunded."),
                                                        primaryButton: .destructive(Text("Yes, Cancel")) {
                                                            handleEventCancellation(event: currentEvent)
                                                        },
                                                        secondaryButton: .cancel()
                                                    )
                                                }
                                            }
                                            if let currentUserId = UserManager.shared.currentUserID,
                                               currentEvent.hostIDs.contains(currentUserId) {
                                                if Date() > currentEvent.to {
                                                    // Safe URL creation with proper error handling
                                                    if let withdrawURL = URL(string: "https://squareup.com/dashboard/payments") {
                                                        Link(destination: withdrawURL) {
                                                            Text("Withdraw Funds")
                                                                .font(.system(size: 16, weight: .semibold, design: .default))
                                                                .foregroundColor(.white)
                                                                .padding(.horizontal, 20)
                                                                .padding(.vertical, 10)
                                                                .background(Color.green)
                                                                .cornerRadius(10)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 10)
                                }
                                
                                // location
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Location")
                                        .font(.system(size: 12, weight: .semibold, design: .default))
                                        .foregroundColor(.gray)
                                    
                                    Button {
                                        viewItem = ViewItem (
                                            AnyView (
                                                EventLocationView(isPresentedInFullScreen: true, location: currentEvent.location)
                                            ), _presentationStyle: .fullScreen
                                        )
                                    } label: {
                                        EventLocationView(location: currentEvent.location)
                                            .frame(height: 130)
                                            .cornerRadius(15)
                                    }
                                }
                                
                                // copy the unique code to invite the
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Share event")
                                        .font(.system(size: 12, weight: .semibold, design: .default))
                                        .foregroundColor(.gray)
                                    
                                    Text("Share this event with your friends and invite them to attend this event. Share the unique event code with your friends and ask them to search it to get access to the code.")
                                        .font(.system(size: 13, weight: .regular, design: .default))
                                        .foregroundColor(.labelColor)
                                    
                                    HStack {
                                        Text(currentEvent.eventID)
                                        
                                        Spacer()
                                        
                                        Button {
                                            // Create Universal Link
                                            let eventDeepLink = "https://kiccbacc.com/event/\(currentEvent.eventID)"
                                            let kInstagramAppID = "1186790129900556"
                                            
                                            // Instagram Story URL scheme
                                            let urlScheme = "instagram-stories://share?source_application=\(kInstagramAppID)"
                                            
                                            if let urlString = URL(string: urlScheme) {
                                                if UIApplication.shared.canOpenURL(urlString) {
                                                    // Show loading indicator
                                                    isLoadingInstagramShare = true
                                                    
                                                    // Use event banner image instead of default logo
                                                    if let eventBannerUrl = URL(string: currentEvent.eventBannerUrl) {
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
                                                }
                                            }
                                        } label: {
                                            // Label with loading indicator
                                            HStack {
                                                if isLoadingInstagramShare {
                                                    ProgressView()
                                                        .progressViewStyle(CircularProgressViewStyle())
                                                        .scaleEffect(0.8)
                                                } else {
                                                    Image(systemName: "square.and.arrow.up.circle.fill")
                                                }
                                                Text(isLoadingInstagramShare ? "Opening..." : "Share to Instagram")
                                            }
                                            .padding(10)
                                            .background(Color.bgColor)
                                            .cornerRadius(10)
                                            .foregroundColor(.labelColor)
                                        }
                                        .disabled(isLoadingInstagramShare)
                                        .alert(isPresented: $showInstagramNotInstalledAlert) {
                                            Alert(
                                                title: Text("Instagram Not Installed"),
                                                message: Text("Instagram is not installed on your device. Please install Instagram to share this event to Instagram Stories."),
                                                dismissButton: .default(Text("OK"))
                                            )
                                        }
                                        
                                        
                                        Button {
                                            // Create Universal Link
                                            let eventDeepLink = "https://kiccbacc.com/event/\(currentEvent.eventID)"
                                            
                                            // Items to share
                                            let items: [Any] = [
                                                eventDeepLink
                                            ]
                                            
                                            // Create ActivityViewController
                                            let activityVC = UIActivityViewController(
                                                activityItems: items,
                                                applicationActivities: nil
                                            )
                                            
                                            // Get the root view controller more reliably
                                            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                                  let rootViewController = windowScene.windows.first?.rootViewController else {
                                                print("Failed to find root view controller")
                                                return
                                            }
                                            
                                            // Find the currently presented view controller
                                            var currentController = rootViewController
                                            while let presented = currentController.presentedViewController {
                                                currentController = presented
                                            }
                                            
                                            // Present from the current active controller
                                            DispatchQueue.main.async {
                                                currentController.present(activityVC, animated: true)
                                            }
                                        } label: {
                                            HStack {
                                                Image(systemName: "square.and.arrow.up")
                                                Text("Share Elsewhere")
                                            }
                                            .padding(10)
                                            .background(Color.bgColor)
                                            .cornerRadius(10)
                                            .foregroundColor(.labelColor)
                                        }
                                    }
                                    .padding(8)
                                    .background(Color.secondaryBgColor)
                                    .cornerRadius(10)
                                    .font(.system(size: 12, weight: .regular, design: .default))
                                }
                                
                                if isCurrentUserHost() {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Button {
                                            EventManager.shared.delete(event: self.currentEvent) { isDeleted in
                                                if isDeleted {
                                                    presentation.wrappedValue.dismiss()
                                                }
                                            }
                                        } label: {
                                            Text("Delete event")
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding(.bottom, 50)
                                }
                            }
                            .padding(.bottom, 150)
                            .padding(.horizontal)
                        }
                        .padding(.bottom, -150)
                        .onChange(of: shouldScrollToStories) { newValue in
                            if newValue {
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    proxy.scrollTo("stories-section", anchor: UnitPoint.top)
                                }
                                shouldScrollToStories = false
                            }
                        }
                    }
                } else {
                    // Group Chat tab content
                    GroupChatView(
                        event: currentEvent,
                        groupChatRoom: $groupChatRoom,
                        groupChatMessages: $groupChatMessages,
                        newGroupMessage: $newGroupMessage,
                        groupChatMembers: $groupChatMembers,
                        showInviteSheet: $showInviteSheet,
                        isHostOnly: $isHostOnly
                    )
                }
                
                // floating bottom bar - only show if user hasn't joined yet
                if !isFavourite {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Joined")
                            .font(.system(size: 14, weight: .bold, design: .default))
                        
                        Text("By clicking this link you'll be redirected to the event registration link.")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundColor(.gray)
                        
                        HStack {
                            if let interestedUsers = interestedUsers {
                                NavigationLink {
                                    ListOfUsersView(userIDs: currentEvent.interestedUserIDs, usersKind: .interestedUsers, isHost: isCurrentUserHost(), eventID: currentEvent.eventID)
                                        .navigationTitle("Joined users")
                                } label: {
                                    HStack(alignment: .center, spacing: -15) {
                                        ForEach(interestedUsers, id: \.userID) { user in
                                            PfpView(user: user, size: 44, isRound: true, strokeWidth: 0)
                                        }
                                    }
                                }
                            }
                            
                            
                            Text("\(currentEvent.interestedUserIDs.count)")
                                .font(.system(size: 14, weight: .bold, design: .default))
                            
                            Text("joined")
                                .font(.system(size: 12, weight: .regular, design: .default))
                            
                            Spacer()
                            
                            if let paymentURL = currentEvent.paymentAmount, let url = URL(string: paymentURL) {
                                Link(destination: url) {
                                    Text("Register")
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 15)
                                        .background(Color.buttonBgColor)
                                        .clipShape(Capsule())
                                        .foregroundColor(.white)
                                        .font(.system(size: 15, weight: .bold, design: .default))
                                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
                                    
                                }
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [.bgColor.opacity(0.9), .bgColor]), startPoint: .top, endPoint: .bottom)
                    )
                    .background(BlurView(style: .systemUltraThinMaterial))
                    .cornerRadius(20, corners: [.topLeft, .topRight])
                    .shadow(color: .black.opacity(0.15), radius: 25, x: 5, y: 0)
                    .showIf(isFavourite)
                }
            }
            .alert(alertTitle, isPresented: $isAlertShown) {
                SecureField("Enter Password", text: $password)
                Button(action: {
                    dismiss()
                }, label: {
                    Text("Back")
                })
                Button(action: {
                    enterPassword()
                }, label: {
                    Text("Enter")
                })
            }
            .ignoresSafeArea(.all, edges: .bottom)
            .fullScreenCover(item: $viewItem) { viewItem in
                viewItem.viewToPresent
            }
            .sheet(isPresented: $shouldShowTicketSelector) {
                TicketSelectorView(event: currentEvent)
            }
            .sheet(isPresented: $showEventPropertiesSheet) {
                EventPropertiesView(event: currentEvent) { updatedEvent in
                    // Update the current event with new properties
                    currentEvent = updatedEvent
                }
            }
            .onAppear {
                // Safe check for password-protected events
                if let currentUserID = UserManager.shared.currentUserID {
                    if (currentEvent.password != nil && currentEvent.password != "") && !(currentEvent.hostIDs.contains(currentUserID)) {
                        isAlertShown = true
                    } else {
                        isEventLocked = false
                    }
                } else {
                    // User not logged in - treat as locked if password protected
                    if currentEvent.password != nil && currentEvent.password != "" {
                        isAlertShown = true
                    } else {
                        isEventLocked = false
                    }
                }
                
                getHost()
                
                loadStories()
                
                // check if current user is interested in the event or not
                EventManager.shared.isCurrentUserInterested(inEvent: currentEvent) { isInterested in
                    withAnimation { isFavourite = isInterested }
                }
                
                // interested user
                getInterestedPeople()
                
                // Refresh event data to ensure we have the latest properties
                refreshEventData()
                
                // Check if we should show the welcome overlay
                checkForWelcomeOverlay()
                
                // Initialize group chat
                initializeGroupChat()
            }
            .onDisappear {
                // Clean up real-time listener
                storiesListener?.remove()
            }
            .navigationBarHidden(true)
            
            // Welcome to Events overlay
            if showWelcomeOverlay {
                WelcomeToEventsOverlay(isPresented: $showWelcomeOverlay) {
                    handleOverlayDismiss()
                }
                .zIndex(1000)
            }
        }
        Rectangle()
            .frame(width: 2000, height: 2000, alignment: .center)
            .foregroundColor(.black.opacity(0.1))
            .showIf(isEventLocked)
    }
    
    private struct EnhancedStoryView: View {
        
        var userID: String
        var stories: [Story]
        
        @State private var creator: User?
        @State private var hasUnviewedStories: Bool = false
        
        var body: some View {
            ZStack(alignment: .top) {
                // Story card - rectangular with rounded corners
                VStack(spacing: 0) {
                    ZStack {
                        if let firstStory = stories.first {
                            ZStack {
                                WebImage(url: URL(string: firstStory.imageUrlString))
                                    .resizable()
                                    .indicator(.activity)
                                    .transition(.fade(duration: 0.2))
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 105, height: 150) // Reduced from 140x200
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white, lineWidth: 2.5) // Reduced from 3
                                    )
                                
                                // Dark overlay to make stats more visible (only for creator)
                                if isCreator {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.black.opacity(0.3))
                                        .frame(width: 105, height: 150)
                                }
                            }
                            .overlay(
                                // View and like count overlay - only visible to creator
                                StoryStatsOverlay(story: firstStory, userID: userID)
                            )
                        } else {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.secondaryBgColor)
                                .frame(width: 105, height: 150) // Reduced from 140x200
                                .overlay(
                                    ProgressView()
                                        .foregroundColor(.labelColor)
                                )
                        }
                    }
                    
                    // Spacer to push profile picture down
                    Spacer()
                        .frame(height: 30) // Reduced from 40
                }
                
                // Profile picture positioned on top of story card
                VStack(spacing: 0) {
                    // Top half of profile picture overlaps the story card
                    Spacer()
                        .frame(height: 120) // Reduced from 160
                    
                    ZStack {
                        if let creator = creator {
                            // Profile picture with story indicator
                            ZStack {
                                // Story indicator circle (app theme color)
                                Circle()
                                    .fill(Color.appColor)
                                    .frame(width: 66, height: 66) // Reduced from 88
                                    .showIf(hasUnviewedStories)
                                
                                // Profile picture
                                WebImage(url: URL(string: creator.profileImageUrlString ?? ""))
                                    .resizable()
                                    .indicator(.activity)
                                    .transition(.fade(duration: 0.2))
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60) // Reduced from 80
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 3) // Reduced from 4
                                    )
                            }
                        } else {
                            // Loading placeholder
                            Circle()
                                .fill(Color.secondaryBgColor)
                                .frame(width: 60, height: 60) // Reduced from 80
                                .overlay(
                                    ProgressView()
                                        .foregroundColor(.labelColor)
                                )
                        }
                    }
                    
                    // Username below profile picture
                    if let creator = creator {
                        Text("@\(creator.username)")
                            .font(.system(size: 12, weight: .medium)) // Reduced from 20 to 12
                            .foregroundColor(.labelColor)
                            .lineLimit(1)
                            .padding(.top, 6) // Reduced from 8
                    }
                }
            }
            .frame(width: 105, height: 180) // Reduced from 140x240
            .onAppear {
                getHost()
                checkUnviewedStories()
            }
            .onChange(of: stories) { newStories in
                // Refresh unviewed status when stories change
                refreshUnviewedStatus()
                
                // Also check if this is a new story being added
                if let currentUserID = UserManager.shared.currentUserID {
                    // For self-user stories, only show indicator if they haven't watched their own story
                    if userID == currentUserID {
                        let hasUnviewedOwnStory = newStories.contains { story in
                            !story.viewedByUserIDs.contains(currentUserID)
                        }
                        DispatchQueue.main.async {
                            self.hasUnviewedStories = hasUnviewedOwnStory
                        }
                    } else {
                        // For other users, check if any story has not been viewed by current user
                        let hasUnviewed = newStories.contains { story in
                            !story.viewedByUserIDs.contains(currentUserID)
                        }
                        DispatchQueue.main.async {
                            self.hasUnviewedStories = hasUnviewed
                        }
                    }
                }
            }
        }
        
        private func getHost() {
            UserManager.shared.getUserListener(withUserID: userID) { result in
                switch result {
                case .success(let user):
                    self.creator = user
                case .failure(_):
                    break
                }
            }
        }
        
        private func checkUnviewedStories() {
            guard let currentUserID = UserManager.shared.currentUserID else { return }
            
            // For self-user stories, only show indicator if they haven't watched their own story
            if userID == currentUserID {
                let hasUnviewedOwnStory = stories.contains { story in
                    !story.viewedByUserIDs.contains(currentUserID)
                }
                DispatchQueue.main.async {
                    self.hasUnviewedStories = hasUnviewedOwnStory
                }
                
                // Debug logging
                print("🔍 Story indicator check for SELF user \(userID):")
                print("   - Current user ID: \(currentUserID)")
                print("   - Total stories: \(stories.count)")
                print("   - Has unviewed own story (showing indicator): \(hasUnviewedOwnStory)")
                for (index, story) in stories.enumerated() {
                    let isViewed = story.viewedByUserIDs.contains(currentUserID)
                    print("   - Story \(index): \(story.storyID) - Viewed by self: \(isViewed)")
                }
                
                return
            }
            
            // For other users, check if any story has not been viewed by current user
            let hasUnviewed = stories.contains { story in
                !story.viewedByUserIDs.contains(currentUserID)
            }
            
            // Debug logging
            print("🔍 Story indicator check for OTHER user \(userID):")
            print("   - Current user ID: \(currentUserID)")
            print("   - Total stories: \(stories.count)")
            print("   - Has unviewed stories: \(hasUnviewed)")
            for (index, story) in stories.enumerated() {
                let isViewed = story.viewedByUserIDs.contains(currentUserID)
                print("   - Story \(index): \(story.storyID) - Viewed: \(isViewed)")
            }
            
            DispatchQueue.main.async {
                self.hasUnviewedStories = hasUnviewed
            }
        }
        
        // Add a method to refresh unviewed status when stories change
        private func refreshUnviewedStatus() {
            checkUnviewedStories()
        }
        
        private var isCreator: Bool {
            guard let currentUserID = UserManager.shared.currentUserID else { return false }
            return userID == currentUserID
        }
    }
    
    // MARK: - StoryStatsOverlay
    private struct StoryStatsOverlay: View {
        let story: Story
        let userID: String
        
        @State private var currentStory: Story
        @State private var storyListener: FirebaseFirestore.ListenerRegistration?
        
        init(story: Story, userID: String) {
            self.story = story
            self.userID = userID
            self._currentStory = State(initialValue: story)
        }
        
        var body: some View {
            // Only show stats if current user is the creator
            if isCreator {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // View count with eye icon
                        HStack(spacing: 4) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("\(currentStory.viewedByUserIDs.count)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Like count with heart icon - now using real-time updates
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.red)
                            
                            Text("\(currentStory.likeCount)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Spacer()
                }
                .onAppear {
                    setupStoryListener()
                }
                .onDisappear {
                    storyListener?.remove()
                }
            }
        }
        
        private var isCreator: Bool {
            guard let currentUserID = UserManager.shared.currentUserID else { return false }
            return userID == currentUserID
        }
        
        private func setupStoryListener() {
            storyListener = StoryManager.shared.addStoryListener(storyID: story.storyID) { updatedStory in
                if let updatedStory = updatedStory {
                    DispatchQueue.main.async {
                        self.currentStory = updatedStory
                    }
                }
            }
        }
    }
    
    private struct StoryView: View {
        
        var userID: String
        
        @State private var creator: User?
        
        var body: some View {
            if let creator = creator {
                PfpView(user: creator, size: 63, cornerRadius: 0, isRound: true, strokeWidth: 0)
            } else {
                Circle()
                    .fill(Color.secondaryBgColor)
                    .frame(width: 63, height: 63)
                    .overlay(
                        ProgressView()
                    )
                    .foregroundColor(.labelColor)
                    .onAppear {
                        getHost()
                    }
            }
        }
        
        private func getHost() {
            UserManager.shared.getUserListener(withUserID: userID) { result in
                switch result {
                case .success(let user):
                    self.creator = user
                case .failure(_):
                    break
                }
            }
        }
    }
    
    private func getInterestedPeople() {
        EventManager.shared.getTopFourInterestedPeople(of: currentEvent) { users in
            self.interestedUsers = users
        }
    }
    
    private func refreshEventData() {
        EventManager.shared.getEvent(with: currentEvent.eventID) { updatedEvent in
            if let updatedEvent = updatedEvent {
                DispatchQueue.main.async {
                    self.currentEvent = updatedEvent
                }
            }
        }
    }
    
    private func getDate() -> String {
        let calendar = Calendar.current
        
        let fromDateComponent = calendar.dateComponents([.day, .month, .year], from: currentEvent.from)
        let toDateComponent = calendar.dateComponents([.day, .month, .year], from: currentEvent.to)
        
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
    
    private func loadStories() {
        isRefreshingStories = true
        
        // Remove existing listener if any
        storiesListener?.remove()
        
        // Set up real-time listener for stories
        let database = Firestore.firestore()
        storiesListener = database
            .collection("stories")
            .whereField("eventID", isEqualTo: currentEvent.eventID)
            .whereField("visibleTill", isGreaterThan: Date())
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot, error == nil else {
                    DispatchQueue.main.async {
                        self.isRefreshingStories = false
                    }
                    return
                }
                
                let allStories = snapshot.documents.compactMap { document in
                    try? document.data(as: Story.self)
                }
                
                let allUserIDs = allStories.map {
                    $0.creatorID
                }
                
                let uniqueUserIDs = Array(Set(allUserIDs))
                
                var fetchedStoriesByUsers = [StoriesByUser]()
                
                for userID in uniqueUserIDs {
                    let stories = allStories.filter { story in
                        story.creatorID == userID
                    }
                    
                    // Sort stories by creation date (oldest first) so stories added first appear first
                    let sortedStories = stories.sorted {
                        $0.createdAt < $1.createdAt
                    }
                    
                    let storiesByUser = StoriesByUser(userID: userID, stories: sortedStories)
                    fetchedStoriesByUsers.append(storiesByUser)
                }
                
                // Sort StoriesByUser by the creation date of their first story (oldest first)
                let sortedStoriesByUsers = fetchedStoriesByUsers.sorted { first, second in
                    guard let firstStory = first.stories.first,
                          let secondStory = second.stories.first else {
                        return false
                    }
                    return firstStory.createdAt < secondStory.createdAt
                }
                
                DispatchQueue.main.async {
                    self.isRefreshingStories = false
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.storiesByUsers = sortedStoriesByUsers
                    }
                }
            }
    }
    
    private func enterPassword() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if password != currentEvent.password {
                HapticGenerator.rigid.impactOccurred()
                alertTitle = "Incorrect Password \nPlease try again."
                isAlertShown = true
            } else {
                isEventLocked = false
            }
        }
    }
    
    private func getHost() {
        guard let hostID = currentEvent.hostIDs.first else {
            print("Error: currentEvent.hostIDs is empty or nil!")
            return
        }

        UserManager.shared.getUserListener(withUserID: hostID) { result in
            switch result {
            case .success(let user):
                self.eventHost = user
            case .failure(let error):
                print("Error fetching host:", error)
            }
        }
    }
    
    private func isCurrentUserHost() -> Bool {
        guard let eventHostID = eventHost?.userID,
              let currentUserID = UserManager.shared.currentUserID,
              eventHostID == currentUserID else {
            return false
        }
        
        return true
    }
    
    private func isCurrentUserInGroupChat() -> Bool {
        guard let currentUserID = UserManager.shared.currentUserID,
              let room = groupChatRoom else { return false }
        let isParticipant = room.participantsIDs.contains(currentUserID)
        print("🔄 Group chat participation check - Current user: \(currentUserID), Participants: \(room.participantsIDs), Is participant: \(isParticipant)")
        return isParticipant
    }
    
    private func checkForParticipantStatus() {
        guard let currentUserID = UserManager.shared.currentUserID else {
            print("❌ Cannot check participant status: No current user ID")
            return
        }
        
        let eventChatRoomID = "event-\(currentEvent.eventID)"
        print("🔄 Checking if user is participant in room: \(eventChatRoomID)")
        
        let database = Firestore.firestore()
        database.collection("chatrooms").document(eventChatRoomID).getDocument { document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error checking participant status: \(error.localizedDescription)")
                    return
                }
                
                if let document = document, document.exists {
                    do {
                        let room = try document.data(as: ChatRoom.self)
                        if room.participantsIDs.contains(currentUserID) {
                            print("✅ User is participant in existing room")
                            self.groupChatRoom = room
                            self.loadGroupChatMembers()
                            self.loadGroupChatMessages()
                        } else {
                            print("ℹ️ User is not participant in this room")
                        }
                    } catch {
                        print("❌ Error decoding room for participant check: \(error.localizedDescription)")
                    }
                } else {
                    print("ℹ️ Room doesn't exist for participant check")
                }
            }
        }
    }
    
    private func handleEventCancellation(event: Event) {
        isProcessingCancellation = true
        
        // Get all tickets for this event
        let db = Firestore.firestore()
        db.collection("tickets")
            .whereField("catalogId", isEqualTo: currentEvent.catalog_id ?? "")
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error getting tickets: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No tickets found")
                    return
                }
                
                // Process refunds and delete tickets
                for document in documents {
                    let ticket = try? document.data(as: Ticket.self)
                    
                    if let ticket = ticket {
                        if currentEvent.paymentAmount == nil || currentEvent.paymentAmount?.isEmpty == true {
                            // Free event - just delete the ticket
                            db.collection("tickets").document(document.documentID).delete()
                        } else {
                            // Paid event - process refund through Square
                            processSquareRefund(ticket: ticket) { success in
                                if success {
                                    db.collection("tickets").document(document.documentID).delete()
                                }
                            }
                        }
                    }
                }
                
                // Delete the event
                EventManager.shared.delete(event: event) { success in
                    isProcessingCancellation = false
                    if success {
                        // Navigate back or show success message
                        presentation.wrappedValue.dismiss()
                    }
                }
            }
    }
    
//    func ShareToInstagram (image: UIImage){
//        guard let instagramURL = URL(string: "instagram-stories://share") else {return}
//
//        if UIApplication.shared.canOpenURL(instagramURL){
//            let paste = [["com.instagram.sharedSticker.backgroundImage": image as Any]]
//            UIPasteboard.general.setItems(paste)
//            UIApplication.shared.open(instagramURL)
//        }
//    }
    
    private func processSquareRefund(ticket: Ticket, completion: @escaping (Bool) -> Void) {
        UserManager.shared.getCurrentUser { user in
            guard let user = user, let accessToken = user.accessToken else {
                print("Error: Unable to get user or access token")
                return
            }
            let refundBody: [String: Any] = [
                "idempotency_key": UUID().uuidString,
                "payment_id": ticket.paymentId,
                "amount_money": [
                    "amount": Int((Double(ticket.itemPrice) ?? 0)),
                    "currency": "USD"
                ],
                "reason": "Event cancelled by organizer"
            ]
            
            guard let url = URL(string: "https://connect.squareupsandbox.com/v2/refunds") else {
                completion(false)
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("2024-10-17", forHTTPHeaderField: "Square-Version")
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: refundBody)
            } catch {
                completion(false)
                return
            }
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Refund error: \(error)")
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status Code: \(httpResponse.statusCode)")
                    if (200...299).contains(httpResponse.statusCode) {
                        completion(true)
                    } else {
                        print("Request failed with status code: \(httpResponse.statusCode) \(httpResponse)")
                        completion(false)
                    }
                } else {
                    print("Not an HTTP response")
                    completion(false)
                }
            }.resume()
        }
    }
    
    // MARK: - Welcome Overlay Methods
    
    private func checkForWelcomeOverlay() {
        print("🔍 EventDetailView: Checking for welcome overlay...")
        print("🔍 EventDetailView: hasJoinedAnyEvent() = \(hasJoinedAnyEvent())")
        print("🔍 EventDetailView: hasSeenFirstEventOverlay() = \(hasSeenFirstEventOverlay())")
        print("🔍 EventDetailView: shouldShowWelcomeOverlay() = \(shouldShowWelcomeOverlay())")
        
        // Check if user should see the welcome overlay (once per app install)
        if shouldShowWelcomeOverlay() {
            print("✅ EventDetailView: Will show welcome overlay (once per install)!")
            // Small delay to let the view settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showWelcomeOverlay = true
                }
            }
        } else {
            print("❌ EventDetailView: Will NOT show welcome overlay (already seen this install)")
        }
    }
    
    private func handleOverlayDismiss() {
        // Mark overlay as seen
        markFirstEventOverlayAsSeen()
        
        // Start autoscroll and glow effect
        startPostOverlaySequence()
    }
    
    // MARK: - First Event Experience Helper Methods
    
    private func hasSeenFirstEventOverlay() -> Bool {
        let result = UserDefaults.standard.bool(forKey: "has_seen_first_event_overlay")
        print("🔍 EventDetailView: hasSeenFirstEventOverlay() returning \(result)")
        print("🔍 EventDetailView: Raw UserDefaults value = \(UserDefaults.standard.object(forKey: "has_seen_first_event_overlay") ?? "nil")")
        return result
    }
    
    private func markFirstEventOverlayAsSeen() {
        UserDefaults.standard.set(true, forKey: "has_seen_first_event_overlay")
        print("✅ EventDetailView: Marked first event overlay as seen")
    }
    
    
    private func hasJoinedAnyEvent() -> Bool {
        let result = UserDefaults.standard.bool(forKey: "has_joined_any_event_this_install")
        print("🔍 EventDetailView: hasJoinedAnyEvent() returning \(result)")
        return result
    }
    
    private func markEventAsJoined() {
        UserDefaults.standard.set(true, forKey: "has_joined_any_event_this_install")
        print("✅ EventDetailView: Marked event as joined for this install")
        print("✅ EventDetailView: UserDefaults has_joined_any_event_this_install = \(UserDefaults.standard.bool(forKey: "has_joined_any_event_this_install"))")
    }
    
    private func shouldShowWelcomeOverlay() -> Bool {
        return !hasSeenFirstEventOverlay()
    }
    
    private func startPostOverlaySequence() {
        // Small delay before starting the sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            triggerStoryButtonEffects()
        }
    }
    
    private func triggerStoryButtonEffects() {
        // Start glow effect
        shouldGlowAddStoryButton = true
        glowAnimation = true
        
        // Auto-scroll to stories section
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.8)) {
                // Use the ScrollViewReader proxy to scroll to stories section
                // Note: This will be handled by the onChange modifier in the view
                shouldScrollToStories = true
            }
        }
        
        // Stop glow after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 1.0)) {
                shouldGlowAddStoryButton = false
                glowAnimation = false
            }
        }
    }
    
    private func scrollToStoriesSection() {
        shouldScrollToStories = true
    }
    
    private func startAddStoryButtonGlow() {
        shouldGlowAddStoryButton = true
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowAnimation = true
        }
        
        // Stop glowing after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            shouldGlowAddStoryButton = false
            glowAnimation = false
        }
    }
    
    // MARK: - Group Chat Functions
    
    private func initializeGroupChat() {
        // Check if group chat room exists for this event
        let eventChatRoomID = "event-\(currentEvent.eventID)"
        print("🔄 Initializing group chat for event: \(currentEvent.eventID)")
        print("🔄 Looking for chat room: \(eventChatRoomID)")
        
        // First check if room exists by directly querying the roomID
        let database = Firestore.firestore()
        database.collection("chatrooms").document(eventChatRoomID).getDocument { document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error checking for existing chat room: \(error.localizedDescription)")
                    if self.isCurrentUserHost() {
                        self.createGroupChatRoom()
                    }
                    return
                }
                
                if let document = document, document.exists {
                    print("✅ Found existing group chat room")
                    // Room exists, decode it
                    do {
                        let room = try document.data(as: ChatRoom.self)
                        print("✅ Successfully decoded chat room with \(room.participantsIDs.count) participants")
                        self.groupChatRoom = room
                        self.loadGroupChatMembers()
                        self.loadGroupChatMessages()
                    } catch {
                        print("❌ Error decoding chat room: \(error.localizedDescription)")
                        // If we can't decode the existing room, create a new one
                        if self.isCurrentUserHost() {
                            self.createGroupChatRoom()
                        }
                    }
                } else {
                    print("ℹ️ No existing group chat room found")
                    // Room doesn't exist, create new one if user is host
                    if self.isCurrentUserHost() {
                        print("🔄 User is host, creating new group chat room")
                        self.createGroupChatRoom()
                    } else {
                        print("ℹ️ User is not host and no room exists, group chat not available")
                        // For invited users, we need to check if they're participants in any existing room
                        self.checkForParticipantStatus()
                    }
                }
            }
        }
    }
    
    private func createGroupChatRoom() {
        guard let currentUserID = UserManager.shared.currentUserID else { 
            print("❌ Cannot create group chat room: No current user ID")
            return 
        }
        
        let eventChatRoomID = "event-\(currentEvent.eventID)"
        print("🔄 Creating group chat room: \(eventChatRoomID)")
        
        let room = ChatRoom(
            roomID: eventChatRoomID,
            participantsIDs: [currentUserID],
            lastMessage: nil,
            lastMessageTime: nil,
            createdAt: Date()
        )
        
        do {
            try ChatroomManager.shared.create(room: room)
            print("✅ Group chat room created successfully")
            DispatchQueue.main.async {
                self.groupChatRoom = room
                self.loadGroupChatMembers()
                self.loadGroupChatMessages()
            }
        } catch {
            print("❌ Error creating group chat room: \(error.localizedDescription)")
        }
    }
    
    private func loadGroupChatMembers() {
        guard let room = groupChatRoom else { return }
        
        var members: [User] = []
        let group = DispatchGroup()
        
        for participantID in room.participantsIDs {
            group.enter()
            UserManager.shared.getUser(withUserID: participantID) { user in
                if let user = user {
                    members.append(user)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.groupChatMembers = members
        }
    }
    
    private func loadGroupChatMessages() {
        guard let room = groupChatRoom else { return }
        
        do {
            try MessageManager.shared.getMessages(for: room.roomID) { messages in
                DispatchQueue.main.async {
                    self.groupChatMessages = messages ?? []
                }
            }
        } catch {
            print("Error loading group chat messages: \(error.localizedDescription)")
        }
    }
}

@available(iOS 16.0, *)
struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EventDetailView(event: Event())
          // .preferredColorScheme(.dark)
    }
}


struct ActivityView: UIViewControllerRepresentable {

    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityView>) {
        
    }
}
