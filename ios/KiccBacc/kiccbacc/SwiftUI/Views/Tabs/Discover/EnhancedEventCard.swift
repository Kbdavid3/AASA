import SwiftUI
import SDWebImageSwiftUI
import UIKit
import Foundation
import FirebaseFirestore

struct EnhancedEventCard: View {
    let event: Event
    let currentUser: User?
    let screenHeight: CGFloat
    let onStoryTap: ((Story) -> Void)?
    let onProfileTap: ((User) -> Void)?
    let onEventTap: (() -> Void)? // New callback for event tap
    
    @State private var currentEvent: Event
    @State private var eventHost: User?
    @State private var storiesByUsers: [StoriesByUser]?
    @State private var interestedUsers: [User]?
    @State private var isInterested: Bool = false
    @State private var isLoadingInstagramShare: Bool = false
    @State private var showInstagramNotInstalledAlert = false
    @State private var eventListener: ListenerRegistration?
    
    init(event: Event, currentUser: User?, screenHeight: CGFloat, onStoryTap: ((Story) -> Void)? = nil, onProfileTap: ((User) -> Void)? = nil, onEventTap: (() -> Void)? = nil) {
        self.event = event
        self.currentUser = currentUser
        self.screenHeight = screenHeight
        self.onStoryTap = onStoryTap
        self.onProfileTap = onProfileTap
        self.onEventTap = onEventTap
        self._currentEvent = State(initialValue: event)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Event Banner Background with gradient overlay
            ZStack {
                WebImage(url: URL(string: currentEvent.eventBannerUrl))
                    .resizable()
                    .indicator(.activity)
                    .transition(.fade(duration: 0.3))
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width - 32, height: screenHeight * 0.6)
                    .clipped()
                
                // LinearGradient overlay for proper fade effect
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: UIScreen.main.bounds.width - 32, height: screenHeight * 0.6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .onTapGesture {
                onEventTap?()
            }
            
            // Centered Lock Icon for Private Events
            if let password = currentEvent.password, !password.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                        Spacer()
                    }
                    Spacer()
                }
                .frame(width: UIScreen.main.bounds.width - 32, height: screenHeight * 0.6)
            }
            
            // Content Overlay with clean two-section layout
            VStack(spacing: 0) {
                // Top Section: HStack with event info (left) + host profile (right)
                HStack(alignment: .top) {
                    // Event Information Section (Left)
                    VStack(alignment: .leading, spacing: 8) {
                        // Event Title - Smaller size as requested
                        Text(currentEvent.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 2)
                        
                        // Date, Time, and Year - Smaller size as requested
                        Text("\(getDateAndMonth()) • \(getTime()), \(getYear())")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                        
                        // Location - Smaller size as requested
                        Text(getLocationText())
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                        
                        // Price - Smaller size as requested
                        Text(getPriceText())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                        
                        // Event Type Tag
                        HStack(spacing: 8) {
                            Text("🥂 \(currentEvent.type)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.25))
                                .cornerRadius(16)
                        }
                        .padding(.leading, -8) // Move tag to the left
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Host Profile Section (Right) - Resized to match joined profile pictures
                    VStack(spacing: 6) {
                        ZStack(alignment: .bottomTrailing) {
                            if let eventHost = eventHost {
                                WebImage(url: URL(string: eventHost.profileImageUrlString ?? ""))
                                    .resizable()
                                    .indicator(.activity)
                                    .transition(.fade(duration: 0.2))
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 36, height: 36) // Resized to match joined profile pictures
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                    .onTapGesture {
                                        onProfileTap?(eventHost)
                                    }
                                    .offset(x: 12, y: 0) // Move profile picture further right
                                
                                // Verification badge - Reduced size and adjusted offset
                                if eventHost.verified == true {
                                    Image("Verified")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                        .offset(x: 18, y: 6) // Adjusted for profile picture offset
                                }
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 36, height: 36) // Resized to match joined profile pictures
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                    .offset(x: 12, y: 0) // Move placeholder circle further right
                            }
                        }
                        
                        if let eventHost = eventHost {
                            Text("@\(eventHost.username)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                                .lineLimit(1)
                                .onTapGesture {
                                    onProfileTap?(eventHost)
                                }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 20) // Moved further right to align with joined people
                }
                
                Spacer()
                
                // Bottom Section: HStack with stories (left) + joined users (right)
                HStack(alignment: .bottom) {
                    // Stories Section (Bottom Left) - only show if event allows it
                    if currentEvent.showStories, let storiesByUsers = storiesByUsers, !storiesByUsers.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Stories")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                            
                            HStack(spacing: 8) {
                                // Story thumbnails - Show 3 most recent stories with blurring logic
                                let topStories = Array(storiesByUsers.prefix(3))
                                let totalStories = topStories.count
                                
                                // Flatten all stories from the top users and take the first 3
                                let allStories = topStories.flatMap { $0.stories }
                                let displayStories = Array(allStories.prefix(3))
                                
                                ForEach(Array(displayStories.enumerated()), id: \.element.storyID) { index, story in
                                    let isBlurred = shouldBlurStory(index: index, totalStories: displayStories.count)
                                    
                                    Button {
                                        if isBlurred {
                                            // Navigate to event detail view for blurred stories
                                            onEventTap?()
                                        } else {
                                            // Navigate to story view for unblurred stories
                                            onStoryTap?(story)
                                        }
                                    } label: {
                                        ZStack {
                                            WebImage(url: URL(string: story.imageUrlString))
                                                .resizable()
                                                .indicator(.activity)
                                                .transition(.fade(duration: 0.2))
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 56, height: 84)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.white, lineWidth: 2)
                                                )
                                            
                                            // Blur overlay for blurred stories
                                            if isBlurred {
                                                Rectangle()
                                                    .fill(Color.black.opacity(0.6))
                                                    .frame(width: 56, height: 84)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                        }
                                    }
                                }
                                
                                // "View More" - EXACTLY like the image
                                if let firstStory = storiesByUsers.first?.stories.first {
                                    Button {
                                        // Navigate to event detail view for "View More"
                                        onEventTap?()
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: "plus")
                                                .foregroundColor(.white)
                                                .font(.system(size: 16, weight: .medium))
                                            
                                            Text("View More")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.white)
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(width: 56)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    
                    Spacer()
                    
                    // Joined Users Section (Bottom Right)
                    if let interestedUsers = interestedUsers, !interestedUsers.isEmpty {
                        VStack(alignment: .trailing, spacing: 8) {
                            // Joined Users Profile Pictures - Overlapping circles with increased overlap
                            HStack(spacing: -12) {
                                ForEach(Array(interestedUsers.prefix(4)), id: \.userID) { user in
                                    WebImage(url: URL(string: user.profileImageUrlString ?? ""))
                                        .resizable()
                                        .indicator(.activity)
                                        .transition(.fade(duration: 0.2))
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 36, height: 36)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                        )
                                }
                            }
                            
                            // Joined Count
                            Text("\(interestedUsers.count) Joined")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .frame(width: UIScreen.main.bounds.width - 32, height: screenHeight * 0.6)
            
            // Right Side Action Buttons - Positioned with screenHeight * 0.2
            VStack(spacing: 12) {
                // Share Button
                Button {
                    shareEvent()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .medium))
                        .frame(width: 36, height: 36) // Match joined profile picture width
                }
                
                // Instagram Button
                Button {
                    shareToInstagram()
                } label: {
                    HStack {
                        if isLoadingInstagramShare {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Image("instagramLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                        }
                    }
                    .frame(width: 36, height: 36)
                }
                .disabled(isLoadingInstagramShare)
                
                // Heart/Interest Button - Disabled for private events
                Button {
                    // Don't allow joining private events
                    if let password = currentEvent.password, !password.isEmpty {
                        return
                    }
                    toggleInterest()
                } label: {
                    Image(systemName: isInterested ? "heart.fill" : "heart")
                        .foregroundColor(
                            // Gray out the heart for private events
                            // FIXED: Safe password check without force unwrap
                            (!currentEvent.password.isNilOrEmpty) ? .gray : 
                            (isInterested ? .red : .white)
                        )
                        .font(.system(size: 20, weight: .medium))
                        .frame(width: 36, height: 36) // Match joined profile picture width
                }
                // FIXED: Safe password check without force unwrap
                .disabled(!currentEvent.password.isNilOrEmpty)
            }
            .padding(.trailing, 16) // Moved a bit to the left
            .padding(.top, screenHeight * 0.2)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(width: UIScreen.main.bounds.width - 32, height: screenHeight * 0.6)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16)
        .onAppear {
            loadEventData()
            setupEventListener()
        }
        .onDisappear {
            eventListener?.remove()
        }
        .alert(isPresented: $showInstagramNotInstalledAlert) {
            Alert(
                title: Text("Instagram Not Installed"),
                message: Text("Instagram is not installed on your device. Please install Instagram to share this event to Instagram Stories."),
                dismissButton: .default(Text("OK"))
            )
        }

    }
    
    // MARK: - Helper Methods
    
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
    
    private func setupEventListener() {
        let db = Firestore.firestore()
        eventListener = db.collection("events")
            .document(currentEvent.eventID)
            .addSnapshotListener { documentSnapshot, error in
                
                if let error = error {
                    print("Error listening to event changes: \(error)")
                    return
                }
                
                guard let document = documentSnapshot,
                      document.exists,
                      let updatedEvent = try? document.data(as: Event.self) else {
                    return
                }
                
                DispatchQueue.main.async {
                    let oldShowStories = self.currentEvent.showStories
                    self.currentEvent = updatedEvent
                    
                    // If showStories changed, reload stories data
                    if oldShowStories != updatedEvent.showStories {
                        self.loadStoriesData()
                    }
                }
            }
    }
    
    private func loadEventData() {
        // Load event host
        if let hostID = currentEvent.hostIDs.first {
            UserManager.shared.getUser(withUserID: hostID) { user in
                DispatchQueue.main.async {
                    self.eventHost = user
                }
            }
        }
        
        // Load stories data
        loadStoriesData()
        
        // Load interested users
        if !currentEvent.interestedUserIDs.isEmpty {
            UserManager.shared.getUsers(with: currentEvent.interestedUserIDs) { users in
                DispatchQueue.main.async {
                    self.interestedUsers = users
                }
            }
        }
        
        // Check if current user is interested
        if let currentUser = currentUser {
            EventManager.shared.isCurrentUserInterested(inEvent: currentEvent) { isInterested in
                DispatchQueue.main.async {
                    self.isInterested = isInterested
                }
            }
        }
    }
    
    private func loadStoriesData() {
        // Load stories - only if event allows it
        if currentEvent.showStories {
            StoryManager.shared.getStories(withEventID: currentEvent.eventID) { stories in
            DispatchQueue.main.async {
                if let stories = stories {
                    // Sort all stories by creation date (newest first) and take the latest 3
                    let sortedStories = stories.sorted { $0.createdAt > $1.createdAt }
                    let latestStories = Array(sortedStories.prefix(3))
                    
                    // Group the latest stories by user for display purposes
                    let allUserIDs = latestStories.map { $0.creatorID }
                    let uniqueUserIDs = Array(Set(allUserIDs))
                    
                    var fetchedStoriesByUsers = [StoriesByUser]()
                    
                    for userID in uniqueUserIDs {
                        let userStories = latestStories.filter { $0.creatorID == userID }
                        let sortedUserStories = userStories.sorted { $0.createdAt < $1.createdAt }
                        let storiesByUser = StoriesByUser(userID: userID, stories: sortedUserStories)
                        fetchedStoriesByUsers.append(storiesByUser)
                    }
                    
                    self.storiesByUsers = fetchedStoriesByUsers
                }
            }
            }
        } else {
            // Clear stories if showStories is false
            DispatchQueue.main.async {
                self.storiesByUsers = nil
            }
        }
    }
    
    private func getDateAndMonth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: currentEvent.from)
    }
    
    private func getTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: currentEvent.from)
    }
    
    private func getYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: currentEvent.from)
    }
    
    private func getLocationText() -> String {
        var locationComponents: [String] = []
        
        if let city = currentEvent.city, !city.isEmpty {
            locationComponents.append(city)
        }
        
        if let state = currentEvent.state, !state.isEmpty {
            locationComponents.append(state)
        }
        
        if locationComponents.isEmpty {
            // Fallback to venue name if no city/state
            return currentEvent.venueName
        }
        
        return locationComponents.joined(separator: ", ")
    }
    
    private func getPriceText() -> String {
        // Check if event has ticket types (paid event)
        if let ticketTypes = currentEvent.ticketTypes, !ticketTypes.isEmpty {
            // Find the lowest price from all ticket types
            let lowestPrice = ticketTypes.compactMap { Double($0.price) }.min() ?? 0
            if lowestPrice > 0 {
                return "$\(String(format: "%.0f", lowestPrice))/Ticket"
            }
        }
        
        // Check legacy payment amount
        if let ticketPrice = currentEvent.ticketPrice, ticketPrice > 0 {
            return "$\(Int(ticketPrice))/Ticket"
        } else if let paymentAmount = currentEvent.paymentAmount, let amount = Double(paymentAmount), amount > 0 {
            return "$\(Int(amount))/Ticket"
        } else {
            return "Free Event"
        }
    }
    
    private func toggleInterest() {
        guard let currentUser = currentUser else { return }
        
        if isInterested {
            EventManager.shared.removeInterestedIn(event: currentEvent) { success in
                if success {
                    DispatchQueue.main.async {
                        self.isInterested = false
                        // Update local interested users
                        if let index = self.interestedUsers?.firstIndex(where: { $0.userID == currentUser.userID }) {
                            self.interestedUsers?.remove(at: index)
                        }
                    }
                }
            }
        } else {
            EventManager.shared.interestedIn(event: currentEvent) { success in
                if success {
                    DispatchQueue.main.async {
                        self.isInterested = true
                        // Add current user to interested users
                        self.interestedUsers?.append(currentUser)
                    }
                }
            }
        }
    }
    
    private func shareEvent() {
        // Create share URL for the event
        let eventURL = "https://kiccbacc.com/event/\(currentEvent.eventID)"
        if let shareURL = URL(string: eventURL) {
            presentShareSheet(with: shareURL)
        }
    }
    
    private func shareToInstagram() {
        isLoadingInstagramShare = true
        
        // Create Instagram story share URL
        let eventURL = "https://kiccbacc.com/event/\(currentEvent.eventID)"
        let kInstagramAppID = "1186790129900556"
        let instagramURL = "instagram-stories://share?source_application=\(kInstagramAppID)"
        
        if let url = URL(string: instagramURL) {
            if UIApplication.shared.canOpenURL(url) {
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
                                if let qrCodeImage = generateQRCode(from: eventURL) {
                                    // Overlay QR code on the banner image
                                    if let combinedImageData = overlayQRCodeOnEventBanner(eventBannerData: imageData, qrCode: qrCodeImage) {
                                        // Include the combined image as background
                                        let pasteBoardItems: [[String: Any]] = [
                                            [
                                                "com.instagram.sharedSticker.backgroundImage": combinedImageData,
                                                "com.instagram.sharedSticker.contentURL": eventURL,
                                                "com.instagram.sharedSticker.linkURL": eventURL,
                                                "com.instagram.sharedSticker.linkText": "Event Link"
                                            ]
                                        ]
                                        
                                        // Instagram requires items to be formatted as an array of dictionaries
                                        UIPasteboard.general.items = pasteBoardItems
                                        UIApplication.shared.open(url)
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
                isLoadingInstagramShare = false
            }
        }
    }
    
    private func presentShareSheet(with url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // Configure the activity view controller
        activityViewController.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks,
            .markupAsPDF
        ]
        
        // For iPad support
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = UIView()
            popover.sourceRect = CGRect(x: 0, y: 0, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Present the activity view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            // Find the topmost presented view controller
            var topViewController = rootViewController
            while let presentedViewController = topViewController.presentedViewController {
                topViewController = presentedViewController
            }
            
            topViewController.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    /// Determines if a story should be blurred based on its position and total count
    /// - Parameters:
    ///   - index: The index of the story (0-based)
    ///   - totalStories: Total number of stories to display
    /// - Returns: true if the story should be blurred, false otherwise
    private func shouldBlurStory(index: Int, totalStories: Int) -> Bool {
        switch totalStories {
        case 1:
            // 1 story: 1 blurred
            return true
        case 2:
            // 2 stories: 1 blurred (the second one)
            return index == 1
        case 3:
            // 3 stories: 2 blurred (the second and third ones)
            return index == 1 || index == 2
        default:
            return false
        }
    }
}



// MARK: - Preview
#Preview {
    EnhancedEventCard(
        event: Event(),
        currentUser: User(),
        screenHeight: 800,
        onStoryTap: nil,
        onProfileTap: nil,
        onEventTap: nil
    )
    .background(Color.black)
}
