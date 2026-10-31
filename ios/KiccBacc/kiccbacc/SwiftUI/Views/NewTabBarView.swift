import SwiftUI

struct NewTabBarView: View {
    @State private var tabSelection: Tab = .home
    @State private var showAddEventView: Bool = false
    @State private var showExploreView: Bool = false
    @State private var newLocation: String = ""
    @State private var fetchedUser: User?
    @State private var logout: Bool = false
    @State private var onboardingProfileImage: UIImage? = nil
    
    @Environment(\.presentationMode) private var presentation
    
    var body: some View {
        ZStack {
            mainContentView
            tabBarOverlay
        }
        .background(Color.clear)
        .ignoresSafeArea(.all, edges: .all)
        .onAppear {
            UIApplication.shared.applicationIconBadgeNumber = 0
            // Load profile image and user data asynchronously to prevent blocking UI
            DispatchQueue.global(qos: .userInitiated).async {
                loadOnboardingProfileImage()
                fetchUser()
            }
        }
        .sheet(isPresented: $showAddEventView) {
            CreateNewEventView()
        }
        .sheet(isPresented: $showExploreView) {
            NavigationView {
                ExploreView()
                    .navigationTitle("")
                    .navigationBarHidden(true)
            }
        }
        .navigationBarHidden(true)
        .navigationTitle("")
        .onChange(of: logout) { logout in
            if logout {
                dismissView()
            }
        }
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        VStack(spacing: 0) {
            headerSection
            contentSection
        }
        .background(Color.clear)
        .ignoresSafeArea(.all, edges: .all)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            if tabSelection != .home {
                HStack {
                    if let navigationTitle = tabSelection.navigationTitle {
                        Text(navigationTitle)
                            .font(.system(size: 30, weight: .bold, design: .default))
                    }
                    
                    Spacer()
                    
                    if tabSelection != .profile {
                        NavigationLink {
                            SelfProfileView()
                        } label: {
                            profileImageView
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 50)
            }
        }
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        ZStack {
            homeTabContent
            chatTabContent
            createEventTabContent
            notificationsTabContent
            profileTabContent
        }
        .animation(.easeInOut(duration: 0.3), value: tabSelection)
        .background(Color.clear)
        .onAppear {
            // Setup window background immediately without delay
            setupWindowBackground()
        }
    }
    
    // MARK: - Tab Content Views
    private var homeTabContent: some View {
        Group {
            if tabSelection == .home {
                NewHomeView(currentUser: $fetchedUser, currentTab: $tabSelection, showExploreView: $showExploreView)
                    .background(Color.clear)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
    }
    
    private var chatTabContent: some View {
        Group {
            if tabSelection == .chat {
                NavigationView {
                    ChatsView()
                        .background(Color.clear)
                        .navigationBarHidden(true)
                }
                .background(Color.clear)
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
    }
    
    private var createEventTabContent: some View {
        Group {
            if tabSelection == .createEvent {
                CreateNewEventView()
                    .background(Color.clear)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
    }
    
    private var notificationsTabContent: some View {
        Group {
            if tabSelection == .notifications {
                SimpleNotificationView()
                    .background(Color.clear)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
    }
    
    private var profileTabContent: some View {
        Group {
            if tabSelection == .profile {
                SettingsView(logout: $logout)
                    .background(Color.clear)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
    }
    
    // MARK: - Tab Bar Overlay
    private var tabBarOverlay: some View {
        VStack {
            Spacer()
            newTabBar
        }
    }
    
    // MARK: - New Frosted Glass Tab Bar
    private var newTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        tabSelection = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        tab.icon
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(isSelected(tab: tab) ? .appColor : .white)
                        
                        Text(tab.title)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(isSelected(tab: tab) ? .appColor : .white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            // Frosted glass effect for the tab bar only
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
        .padding(.bottom, 25)
    }
    
    // MARK: - Helper Methods
    private func setupWindowBackground() {
        // Set window background immediately without async dispatch
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.backgroundColor = UIColor.clear
        }
    }
    
    private func dismissView() {
        presentation.wrappedValue.dismiss()
    }
    
    private func isSelected(tab: Tab) -> Bool {
        tabSelection == tab
    }
    
    private func loadOnboardingProfileImage() {
        // Load onboarding profile image immediately for instant display
        if let imageData = UserDefaults.standard.data(forKey: "onboarding_profile_image") {
            onboardingProfileImage = UIImage(data: imageData)
        }
    }
    
    private func fetchUser() {
        guard let userID = UserManager.shared.currentUserID else {
            return
        }
        
        // First try to get user data immediately (faster)
        UserManager.shared.getUser(withUserID: userID) { user in
            DispatchQueue.main.async {
                if let user = user {
                    self.fetchedUser = user
                    // Clear onboarding image once Firebase user data is loaded
                    self.onboardingProfileImage = nil
                }
            }
        }
        
        // Then set up listener for real-time updates
        UserManager.shared.getUserListener(withUserID: userID) { result in
            switch result {
            case .success(let user):
                DispatchQueue.main.async { [self] in
                    fetchedUser = user
                    // Clear onboarding image once Firebase user data is loaded
                    onboardingProfileImage = nil
                }
            case .failure(_):
                // login again, user fetch failed
                break
            }
        }
    }
    
    // MARK: - Computed Properties
    @ViewBuilder
    private var profileImageView: some View {
        if let fetchedUser = fetchedUser {
            if tabSelection == .home {
                Text(fetchedUser.fullName)
                    .foregroundColor(.labelColor)
            }
        }
    }
}

// MARK: - Tab Extensions
extension Tab {
    var title: String {
        switch self {
        case .home:
            return "Home"
        case .chat:
            return "Chat"
        case .createEvent:
            return "Create"
        case .notifications:
            return "Alerts"
        case .profile:
            return "Profile"
        }
    }
}

#Preview {
    NewTabBarView()
}
