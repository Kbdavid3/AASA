import SwiftUI
import Network
import SDWebImageSwiftUI
import FirebaseFirestore
import CoreLocation

// MARK: - Featured Content Types
enum FeaturedContent: Identifiable {
    case event(Event)
    case story(Story)
    
    var id: String {
        switch self {
        case .event(let event):
            return event.eventID
        case .story(let story):
            return story.storyID
        }
    }
    
    var isEvent: Bool {
        switch self {
        case .event:
            return true
        case .story:
            return false
        }
    }
    
    var event: Event? {
        switch self {
        case .event(let event):
            return event
        case .story:
            return nil
        }
    }
    
    var story: Story? {
        switch self {
        case .story(let story):
            return story
        case .event:
            return nil
        }
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Discover Section Position Preference Key
struct DiscoverSectionPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}



struct NewHomeView: View {
    @Binding var currentUser: User?
    @StateObject private var viewModel = NewHomeViewModel()
    @State private var newLocation: String = ""
    @State private var loaded: Bool = false
    @State private var isLoadingInstagramShare: Bool = false
    @State private var selectedFilter: EventFilter = .events
    
    @State private var selectedStory: Story?
    @State private var currentFeaturedIndex = 0
    @State private var autoChangeTimer: Timer?
    @State private var selectedEventStory: Story?
    @State private var selectedProfileUser: User?
    @State private var showingProfileSheet: Bool = false
    @State private var selectedEvent: Event?
    @State private var showingSelfProfile = false
    @State private var userLocation: String = UserDefaults.standard.string(forKey: "userSelectedLocation") ?? "Set Location"
    @State private var showingLocationPicker = false
    @State private var pickedLocation: PreferredLocation? = UserDefaults.standard.data(forKey: "userPickedLocation").flatMap { try? JSONDecoder().decode(PreferredLocation.self, from: $0) }
    
    // Add parameter to track the current tab selection
    @Binding var currentTab: Tab
    
    // Add binding for showing explore view
    @Binding var showExploreView: Bool
    
    enum EventFilter: String, CaseIterable {
        case events = "Events"
        case friends = "Friends"
        
        var title: String {
            return self.rawValue
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background for entire view
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Only show sticky header when this tab is active
                    if currentTab == .home {
                        stickyHeaderSection
                    } else {
                        // Add top spacing when not on home tab to prevent content overlap
                        Spacer()
                            .frame(height: 50)
                    }
                    
                    // Content that scrolls
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                // Only show content when on home tab
                                if currentTab == .home {
                                    // Featured Section
                                    featuredSection
                                        .id("featured")
                                    
                                    // Scroll Indicator
                                    scrollIndicator
                                    
                                    // Discover Section (scrolls with content initially)
                                    discoverSection
                                        .id("discover")
                                    
                                    // Event Cards
                                    eventCardsSection(geometry: geometry)
                                        .id("events")
                                    
                                    // Bottom spacing to ensure content is visible above tab bar
                                    Spacer(minLength: 100)
                                } else {
                                    // Show placeholder when not on home tab
                                    VStack(spacing: 20) {
                                        Spacer()
                                        Text("Switch to Home tab to view content")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 16, weight: .medium))
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            }
                            .background(
                                GeometryReader { geometry in
                                    Color.clear.preference(
                                        key: ScrollOffsetPreferenceKey.self,
                                        value: geometry.frame(in: .named("scroll")).minY
                                    )
                                }
                            )
                        }
                        .coordinateSpace(name: "scroll")
                    }
                }
            }
            .navigationBarHidden(true)
            .ignoresSafeArea(.all, edges: .top)
            .background(Color.black)
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 0)
            }
            .onAppear {
                // Only load content when on home tab
                if currentTab == .home {
                    // Load content with saved location if available
                    viewModel.loadAllFeaturedContent(withLocation: pickedLocation)
                    viewModel.loadEvents(withLocation: pickedLocation)
                    
                    // Load nearby users if Friends filter is selected
                    if selectedFilter == .friends {
                        viewModel.loadNearbyUsers(withLocation: pickedLocation)
                    }
                }
            }
            .onChange(of: currentTab) { newTab in
                // Load content when switching to home tab
                if newTab == .home {
                    viewModel.loadAllFeaturedContent(withLocation: pickedLocation)
                    viewModel.loadEvents(withLocation: pickedLocation)
                    
                    // Load nearby users if Friends filter is selected
                    if selectedFilter == .friends {
                        viewModel.loadNearbyUsers(withLocation: pickedLocation)
                    }
                    
                    startAutoChangeTimer()
                } else {
                    // Stop timer when leaving home tab
                    stopAutoChangeTimer()
                }
            }
            .onDisappear {
                // Always stop timer when view disappears
                stopAutoChangeTimer()
            }
            .sheet(isPresented: Binding(
                get: { selectedStory != nil },
                set: { if !$0 { selectedStory = nil } }
            )) {
                if let selectedStory = selectedStory {
                    NavigationView {
                        StoriesView(stories: [selectedStory])
                            .navigationBarHidden(true)
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { selectedEventStory != nil },
                set: { if !$0 { selectedEventStory = nil } }
            )) {
                if let selectedEventStory = selectedEventStory {
                    NavigationView {
                        StoriesView(stories: [selectedEventStory])
                            .navigationBarHidden(true)
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { selectedEvent != nil },
                set: { if !$0 { selectedEvent = nil } }
            )) {
                if let selectedEvent = selectedEvent {
                    NavigationView {
                        EventDetailView(event: selectedEvent)
                            .navigationBarHidden(true)
                    }
                }
            }
            .sheet(isPresented: $showingProfileSheet) {
                if let selectedProfileUser = selectedProfileUser {
                    NavigationView {
                        UserProfileView(user: selectedProfileUser)
                            .navigationBarHidden(true)
                    }
                    .interactiveDismissDisabled(true) // Prevent dismissal during follow operations
                }
            }
            .onChange(of: showingProfileSheet) { isShowing in
                if !isShowing {
                    selectedProfileUser = nil
                }
            }
            .sheet(isPresented: $showingSelfProfile) {
                NavigationView {
                    UserProfileView(user: currentUser ?? User())
                        .navigationBarHidden(true)
                }
            }
            .sheet(isPresented: $showingLocationPicker) {
                PreferredLocationPicker(pickedLocation: $pickedLocation, newLocation: $userLocation)
            }
            .onChange(of: pickedLocation) { newLocation in
                if let newLocation = newLocation {
                    // Update the display text with the selected location
                    let address = [newLocation.city, newLocation.state, newLocation.county]
                        .compactMap { $0 }
                        .joined(separator: ", ")
                    userLocation = address.isEmpty ? "Location Set" : address
                    
                    // Save location to UserDefaults
                    UserDefaults.standard.set(userLocation, forKey: "userSelectedLocation")
                    if let locationData = try? JSONEncoder().encode(newLocation) {
                        UserDefaults.standard.set(locationData, forKey: "userPickedLocation")
                    }
                    
                    // Reload events with location filtering
                    viewModel.loadEvents(withLocation: newLocation)
                    viewModel.loadAllFeaturedContent(withLocation: newLocation)
                    
                    // Reload nearby users if Friends filter is selected
                    if selectedFilter == .friends {
                        viewModel.loadNearbyUsers(withLocation: newLocation)
                    }
                }
            }
        }
    }
    
    // MARK: - Auto Change Timer Functions
    private func startAutoChangeTimer() {
        guard viewModel.featuredContent.count > 1 else { return }
        
        stopAutoChangeTimer() // Stop any existing timer
        
        autoChangeTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentFeaturedIndex = (currentFeaturedIndex + 1) % viewModel.featuredContent.count
            }
        }
    }
    
    private func stopAutoChangeTimer() {
        autoChangeTimer?.invalidate()
        autoChangeTimer = nil
    }
    
    // MARK: - Sticky Header Section
    private var stickyHeaderSection: some View {
        VStack(spacing: 16) {
            // Profile and Name Row
            HStack {
                if let currentUser = currentUser {
                    Button {
                        showingSelfProfile = true
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            PfpView(user: currentUser, size: 40, isRound: true, strokeWidth: 1)
                            
                            // Verification badge
                            if currentUser.verified == true {
                                Image("Verified")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .offset(x: 8, y: 8)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentUser.fullName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.labelColor)
                    }
                    
                    Spacer()
                    
                    // Location Picker on the right side
                    VStack(alignment: .trailing, spacing: 2) {
                        Button {
                            showingLocationPicker = true
                        } label: {
                            HStack(spacing: 4) {
                                Text(userLocation)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(userLocation == "Set Location" ? .gray : .labelColor)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .background(Color.clear) // Ensure button is tappable
                    }
                }
            }
            .padding(.horizontal)
            
            // Search Bar
            Button {
                showExploreView = true
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                                    Text("Search people and events")
                    .foregroundColor(.gray)
                    Spacer()
                }
                .padding(12)
                .background(Color.secondaryBgColor)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
        }
        .background(Color.black)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding(.top, 50) // Add proper top padding for safe area
        .padding(.bottom, 12) // Reduced bottom spacing after search bar
    }
        
        // MARK: - Featured Section
        private var featuredSection: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Featured")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.labelColor)
                    Spacer()
                }
                .padding(.horizontal)
                
                if viewModel.isFeaturedContentLoading {
                    // Loading state with skeleton
                    VStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.secondaryBgColor)
                            .frame(height: 280)
                            .overlay(
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                        .foregroundColor(.labelColor)
                                    Text("Loading featured content...")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                            )
                    }
                    .padding(.horizontal)
                } else if !viewModel.featuredContent.isEmpty {
                    TabView(selection: $currentFeaturedIndex) {
                        ForEach(Array(viewModel.featuredContent.enumerated()), id: \.element.id) { index, content in
                            switch content {
                            case .event(let event):
                                Button {
                                    // Navigate to event detail view
                                    print("Featured event tapped: \(event.name)")
                                    print("Featured event ID: \(event.eventID)")
                                    guard !event.eventID.isEmpty else {
                                        print("Error: Event ID is empty")
                                        return
                                    }
                                    selectedEvent = event
                                    print("selectedEvent set to: \(selectedEvent?.name ?? "nil")")
                                } label: {
                                    FeaturedEventCard(event: event, totalContent: viewModel.featuredContent.count, onProfileTap: { user in
                                        guard !user.userID.isEmpty else {
                                            print("Error: User ID is empty")
                                            return
                                        }
                                        selectedProfileUser = user
                                    })
                                }
                                .buttonStyle(PlainButtonStyle())
                                .allowsHitTesting(true)
                                .tag(index)
                            case .story(let story):
                                Button {
                                    // Open story view
                                    print("Featured story tapped: \(story.storyID)")
                                    guard !story.storyID.isEmpty else {
                                        print("Error: Story ID is empty")
                                        return
                                    }
                                    selectedStory = story
                                } label: {
                                    FeaturedStoryCard(story: story, totalContent: viewModel.featuredContent.count)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .allowsHitTesting(true)
                                .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: viewModel.featuredContent.count > 1 ? .automatic : .never))
                    .frame(height: 280)
                    .padding(.horizontal)
                    .onAppear {
                        if currentTab == .home {
                            startAutoChangeTimer()
                        }
                    }
                    .onDisappear {
                        stopAutoChangeTimer()
                    }
                    .onChange(of: currentFeaturedIndex) { newIndex in
                        // Preload next content for smoother transitions
                        let nextIndex = (newIndex + 1) % viewModel.featuredContent.count
                        if nextIndex < viewModel.featuredContent.count {
                            // Trigger preloading of next content
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                // This ensures the next content is ready when user swipes
                            }
                        }
                    }
                } else {
                    Text("No featured content yet")
                        .foregroundColor(.gray)
                        .frame(height: 280)
                        .frame(maxWidth: .infinity)
                        .background(Color.secondaryBgColor)
                        .cornerRadius(16)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
        
        // MARK: - Scroll Indicator
        private var scrollIndicator: some View {
            VStack(spacing: 8) {
                Text("Scroll down for events")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                
                Image(systemName: "chevron.down")
                    .foregroundColor(.gray)
                    .font(.system(size: 16, weight: .medium))
            }
            .padding(.vertical, 20)
            .onTapGesture {
                // Single tap takes user directly to discover area
                // This can be used for future functionality
            }
        }
        
        // MARK: - Discover Section
        private var discoverSection: some View {
            VStack(spacing: 16) {
                // Discover Title
                HStack {
                    Text("Discover")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.labelColor)
                    Spacer()
                }
                .padding(.horizontal)
                
                // Filter Buttons
                HStack(spacing: 16) {
                    ForEach(EventFilter.allCases, id: \.self) { filter in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = filter
                                
                                // Load appropriate content based on filter
                                if filter == .friends {
                                    viewModel.loadNearbyUsers(withLocation: pickedLocation)
                                }
                            }
                        } label: {
                            Text(filter.title)
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedFilter == filter ? Color.appColor : Color.secondaryBgColor)
                                .foregroundColor(selectedFilter == filter ? .white : .labelColor)
                                .clipShape(Capsule())
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 16)
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: DiscoverSectionPreferenceKey.self,
                        value: geometry.frame(in: .named("scroll")).minY
                    )
                }
            )
        }
        
        
        
        // MARK: - Event Cards Section
        private func eventCardsSection(geometry: GeometryProxy) -> some View {
            Group {
                if selectedFilter == .events {
                    // Show events
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.events.enumerated()), id: \.element.eventID) { index, event in
                            VStack(spacing: 0) {
                                // Event Card
                                EnhancedEventCard(
                                    event: event,
                                    currentUser: currentUser,
                                    screenHeight: geometry.size.height,
                                    onStoryTap: { story in
                                        guard !story.storyID.isEmpty else {
                                            print("Error: Story ID is empty")
                                            return
                                        }
                                        selectedEventStory = story
                                    },
                                    onProfileTap: { user in
                                        guard !user.userID.isEmpty else {
                                            print("Error: User ID is empty")
                                            return
                                        }
                                        selectedProfileUser = user
                                        showingProfileSheet = true
                                    },
                                    onEventTap: {
                                        // Navigate to event detail view
                                        print("Event card tapped: \(event.name)")
                                        print("Event card ID: \(event.eventID)")
                                        guard !event.eventID.isEmpty else {
                                            print("Error: Event ID is empty")
                                            return
                                        }
                                        selectedEvent = event
                                        print("selectedEvent set to: \(selectedEvent?.name ?? "nil")")
                                    }
                                )
                                
                                // Navigation Text
                                if index < viewModel.events.count - 1 {
                                    VStack(spacing: 8) {
                                        Text("Swipe for next event")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gray)
                                        
                                        Image(systemName: "chevron.up")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .padding(.vertical, 20)
                                } else {
                                    Text("That's it for now. Stay tuned!")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gray)
                                        .padding(.vertical, 30)
                                }
                            }
                        }
                    }
                } else {
                    // Show nearby users
                    nearbyUsersSection
                }
            }
        }
        
        // MARK: - Nearby Users Section
        private var nearbyUsersSection: some View {
            LazyVStack(spacing: 20) {
                if viewModel.isLoadingNearbyUsers {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .foregroundColor(.appColor)
                        
                        Text("Finding people near you...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .padding(.vertical, 40)
                } else if viewModel.usersNearby.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No people nearby")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.labelColor)
                        
                        Text("Try expanding your location or check back later")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .padding(.vertical, 40)
                } else {
                    ForEach(Array(viewModel.usersNearby.enumerated()), id: \.element.userID) { index, user in
                        NearbyUserCard(user: user) {
                            selectedProfileUser = user
                            showingProfileSheet = true
                        }
                        
                        if index == viewModel.usersNearby.count - 1 {
                            Text("That's everyone nearby for now!")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.vertical, 30)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
}

// MARK: - Featured Story Card
struct FeaturedStoryCard: View {
    let story: Story
    @State private var storyCreator: User?
    @State private var eventName: String?
    @State private var currentStory: Story
    @State private var storyListener: FirebaseFirestore.ListenerRegistration?
    let totalContent: Int
    
    init(story: Story, totalContent: Int) {
        self.story = story
        self.totalContent = totalContent
        self._currentStory = State(initialValue: story)
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Story Image
            WebImage(url: URL(string: currentStory.imageUrlString))
                .resizable()
                .indicator(.activity)
                .transition(.fade(duration: 0.3))
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .clipped()
                .cornerRadius(16)
            
            // Story Info Overlay
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Story")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        if let storyCreator = storyCreator {
                                if let eventName = eventName {
                                Text("@\(storyCreator.username) / \(eventName)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(1)
                            } else {
                                Text("@\(storyCreator.username)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        } else {
                            Text("Loading...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    // Like Button and Count
                    VStack(spacing: 4) {
                        Button {
                            toggleLike()
                        } label: {
                            Image(systemName: currentStory.isLikedByCurrentUser ? "heart.fill" : "heart")
                                .foregroundColor(currentStory.isLikedByCurrentUser ? .red : .white)
                                .font(.system(size: 20, weight: .medium))
                                .padding(8)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        
                        Text("\(currentStory.likeCount)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .cornerRadius(16)
        }
        .onAppear {
            loadStoryCreator()
            loadEventName()
            setupStoryListener()
        }
        .onDisappear {
            storyListener?.remove()
        }
    }
    
    private func toggleLike() {
        if currentStory.isLikedByCurrentUser {
            StoryManager.shared.unlikeStory(currentStory) { error in
                if let error = error {
                    print("Error unliking story: \(error)")
                } else {
                    print("✅ Story unliked successfully")
                    // Refresh current story to get updated data
                    self.setupStoryListener()
                }
            }
        } else {
            StoryManager.shared.likeStory(currentStory) { error in
                if let error = error {
                    print("Error liking story: \(error)")
                } else {
                    print("✅ Story liked successfully")
                    // Refresh current story to get updated data
                    self.setupStoryListener()
                }
            }
        }
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
    
    private func loadStoryCreator() {
        UserManager.shared.getUser(withUserID: story.creatorID) { user in
            DispatchQueue.main.async {
                self.storyCreator = user
            }
        }
    }
    
    private func loadEventName() {
        // Load event name using the story's eventID
        EventDataRepository().getEvent(with: story.eventID) { event in
            DispatchQueue.main.async {
                if let event = event {
                    self.eventName = event.name
                }
            }
        }
    }
}

// MARK: - Featured Event Card
struct FeaturedEventCard: View {
    let event: Event
    @State private var eventHost: User?
    @State private var isInterested: Bool = false
    let totalContent: Int
    let onProfileTap: ((User) -> Void)?
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Use WebImage exactly like FeaturedStoryCard for consistency
            WebImage(url: URL(string: event.eventBannerUrl))
                .resizable()
                .indicator(.activity)
                .transition(.fade(duration: 0.3))
                .aspectRatio(contentMode: .fill)
                .frame(width: UIScreen.main.bounds.width - 32, height: 280) // Fixed width to prevent overflow
                .clipped()
                .cornerRadius(16)
            
            // Event Info Overlay - exact same structure as story card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        // Event details: date, time, venue, price
                        VStack(alignment: .leading, spacing: 2) {
                            // Date and Time
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text(formatEventDate())
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Image(systemName: "clock")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text(formatEventTime())
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            // Venue
                            if !event.venueName.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "location")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text(event.venueName)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                        .lineLimit(1)
                                }
                            }
                            
                            // Price
                            if let ticketTypes = event.ticketTypes, !ticketTypes.isEmpty {
                                // Show starting price for ticket types
                                HStack(spacing: 8) {
                                    Image(systemName: "ticket")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    let startingPrice = ticketTypes.map { $0.price }.min() ?? 0
                                    Text("$\(String(format: "%.0f", startingPrice)) +")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                        .lineLimit(1)
                                }
                            } else if let paymentAmount = event.paymentAmount, !paymentAmount.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "dollarsign.circle")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text(paymentAmount)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                        .lineLimit(1)
                                }
                            }
                        }
                        
                        if let eventHost = eventHost {
                            Text("@\(eventHost.username)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .onTapGesture {
                                    onProfileTap?(eventHost)
                                }
                        } else {
                            Text("Loading...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    // Heart Button and Join Count
                    VStack(spacing: 4) {
                        Button {
                            HapticGenerator.light.impactOccurred()
                            
                            if isInterested {
                                EventManager.shared.removeInterestedIn(event: event) { isNotInterested in
                                    withAnimation { isInterested = !isNotInterested }
                                }
                            } else {
                                EventManager.shared.interestedIn(event: event) { isInterested in
                                    withAnimation { self.isInterested = isInterested }
                                }
                            }
                        } label: {
                            Image(systemName: isInterested ? "heart.fill" : "heart")
                                .foregroundColor(isInterested ? .red : .white)
                                .font(.system(size: 20, weight: .medium))
                                .padding(8)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        
                        Text("\(event.interestedUserIDs.count)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .cornerRadius(16)
        }
        .onAppear { 
            loadEventHost()
            checkIfInterested()
        }
    }
    
    private func loadEventHost() {
        if let hostID = event.hostIDs.first {
            UserManager.shared.getUser(withUserID: hostID) { user in
                DispatchQueue.main.async {
                    self.eventHost = user
                }
            }
        }
    }
    
    private func checkIfInterested() {
        EventManager.shared.isCurrentUserInterested(inEvent: event) { isInterested in
            DispatchQueue.main.async {
                withAnimation {
                    self.isInterested = isInterested
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func formatEventDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: event.from)
    }
    
    private func formatEventTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: event.from)
    }
}

// MARK: - View Model
class NewHomeViewModel: ObservableObject {
    @Published var featuredContent: [FeaturedContent] = []
    @Published var events: [Event] = []
    @Published var usersNearby: [User] = []
    @Published var isLoading = false
    @Published var isFeaturedContentLoading = true
    @Published var isLoadingNearbyUsers = false
        
    func loadAllFeaturedContent(withLocation location: PreferredLocation? = nil) {
        isFeaturedContentLoading = true
        
        // Use DispatchGroup to load both types of content simultaneously
        let group = DispatchGroup()
        var tempEvents: [Event] = []
        var tempStories: [Story] = []
        
        // Load featured events
        group.enter()
        EventDataRepository().getAllEvents { events in
            defer { group.leave() }
            if let events = events {
                // Filter events to only show featured future events
                var featuredFutureEvents = events.filter {
                    $0.to > Date() && $0.isFeatured == true
                }
                
                // Apply location filtering if location is set
                if let location = location {
                    featuredFutureEvents = featuredFutureEvents.filter { event in
                        self.isEventInLocation(event: event, location: location)
                    }
                }
                
                tempEvents = featuredFutureEvents
            }
        }
        
        // Load featured stories
        group.enter()
        Task { @MainActor in
            defer { group.leave() }
            do {
                let stories = try await StoryManager.shared.getFeaturedStories()
                tempStories = stories
            } catch {
                print("Failed to load featured stories: \(error)")
                tempStories = []
            }
        }
        
        // Combine both types of content when both are loaded
        group.notify(queue: .main) {
            var combinedContent: [FeaturedContent] = []
            
            // Add featured events first (prioritize events)
            combinedContent.append(contentsOf: tempEvents.map { FeaturedContent.event($0) })
            
            // Add featured stories
            combinedContent.append(contentsOf: tempStories.map { FeaturedContent.story($0) })
            
            // Update UI with all content at once
            withAnimation(.easeInOut(duration: 0.3)) {
                self.featuredContent = combinedContent
                self.isFeaturedContentLoading = false
            }
        }
    }
    
    func loadEvents(withLocation location: PreferredLocation? = nil) {
        // Load all events for the discover section using existing EventDataRepository
        isLoading = true
        
        EventDataRepository().getAllEvents { events in
            DispatchQueue.main.async {
                self.isLoading = false
                if let events = events {
                    // Filter events to only show future events
                    var futureEvents = events.filter { $0.to > Date() }
                    
                    // Apply location filtering if location is set
                    if let location = location {
                        futureEvents = futureEvents.filter { event in
                            self.isEventInLocation(event: event, location: location)
                        }
                    }
                    
                    self.events = futureEvents
                } else {
                    self.events = []
                }
            }
        }
    }
    
    // Helper function to check if an event is within the selected location radius
    private func isEventInLocation(event: Event, location: PreferredLocation) -> Bool {
        // Check if location has radius
        guard let radius = location.selectionRadius else {
            return false
        }
        
        let eventLocation = CLLocation(latitude: event.latitude, longitude: event.longitude)
        let selectedLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        let distance = eventLocation.distance(from: selectedLocation)
        let radiusInMeters = radius * 1609.34 // Convert miles to meters
        
        return distance <= radiusInMeters
    }
    
    func loadNearbyUsers(withLocation location: PreferredLocation? = nil) {
        isLoadingNearbyUsers = true
        
        // Get current user to access their location
        UserManager.shared.getCurrentUser { [weak self] currentUser in
            guard let self = self,
                  let currentUser = currentUser else {
                DispatchQueue.main.async {
                    self?.isLoadingNearbyUsers = false
                }
                return
            }
            
            // Try to get location from multiple sources
            var locationToUse: PreferredLocation?
            
            // First, try the provided location parameter
            if let providedLocation = location {
                locationToUse = providedLocation
            }
            // Second, try the user's preferred location
            else if let userLocation = currentUser.preferredLocation {
                locationToUse = userLocation
            }
            // Third, try to get location from UserDefaults
            else if let locationData = UserDefaults.standard.data(forKey: "userPickedLocation"),
                      let savedLocation = try? JSONDecoder().decode(PreferredLocation.self, from: locationData) {
                locationToUse = savedLocation
            }
            
            guard let finalLocation = locationToUse else {
                DispatchQueue.main.async {
                    self.isLoadingNearbyUsers = false
                }
                return
            }
            
            let coordinates = CLLocation(latitude: finalLocation.latitude, longitude: finalLocation.longitude)
            
            UserManager.shared.getUsersNearby(with: coordinates) { result in
                DispatchQueue.main.async {
                    self.isLoadingNearbyUsers = false
                    switch result {
                    case .success(let users):
                        self.usersNearby = users
                    case .failure(let error):
                        print("Failed to load nearby users: \(error)")
                        self.usersNearby = []
                    }
                }
            }
        }
    }
}

// MARK: - Nearby User Card
struct NearbyUserCard: View {
    let user: User
    let onTap: () -> Void
    @State private var isFollowing = false
    @State private var isLoadingFollow = false
    
    var body: some View {
        VStack(spacing: 0) {
            // User Card
            VStack(spacing: 16) {
                // Profile Image and Info
                HStack(spacing: 16) {
                    // Profile Image
                    PfpView(user: user, size: 80, isRound: true)
                    
                    // User Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(user.username)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.labelColor)
                        
                        if !user.bio.isEmpty {
                            Text(user.bio)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                                .lineLimit(2)
                        }
                        
                        // Location info if available
                        if let location = user.preferredLocation {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                
                                Text("\(location.city), \(location.state)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                // Follow Button
                Button {
                    handleFollowAction()
                } label: {
                    HStack(spacing: 8) {
                        if isLoadingFollow {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: isFollowing ? "checkmark" : "plus")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        
                        Text(isFollowing ? "Following" : "Follow")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(isFollowing ? Color.gray : Color.appColor)
                    .cornerRadius(22)
                }
                .disabled(isLoadingFollow)
            }
            .padding(20)
            .background(Color.secondaryBgColor)
            .cornerRadius(16)
            .onTapGesture {
                onTap()
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            checkFollowStatus()
        }
    }
    
    private func checkFollowStatus() {
        UserManager.shared.isFollowing(user: user) { isFollowing in
            DispatchQueue.main.async {
                self.isFollowing = isFollowing
            }
        }
    }
    
    private func handleFollowAction() {
        isLoadingFollow = true
        
        if isFollowing {
            // Unfollow
            UserManager.shared.unFollow(userToUnFollow: user) { success in
                DispatchQueue.main.async {
                    self.isLoadingFollow = false
                    if success {
                        self.isFollowing = false
                    }
                }
            }
        } else {
            // Follow
            UserManager.shared.follow(userToFollow: user) { success in
                DispatchQueue.main.async {
                    self.isLoadingFollow = false
                    if success {
                        self.isFollowing = true
                    }
                }
            }
        }
    }
}

#Preview {
    NewHomeView(currentUser: .constant(User()), currentTab: .constant(.home), showExploreView: .constant(false))
}

