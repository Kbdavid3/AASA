//
//  TabBarView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
//import SDWebImageSwiftUI

struct TabBarView: View {
    
    @State private var tabSelection: Tab = .home
    @State private var showAddEventView: Bool = false
    @State private var showExploreView: Bool = false
    @State private var newLocation: String = ""
    @State private var fetchedUser: User?
    @State private var logout: Bool = false
    @State private var onboardingProfileImage: UIImage? = nil
    
    @Environment(\.presentationMode) private var presentation
    
    var body: some View {
        NavigationView {
            ZStack {
                mainContentView
                tabBarOverlay
            }
            .background(Color.clear)
            .onAppear {
                UIApplication.shared.applicationIconBadgeNumber = 0
                loadOnboardingProfileImage()
                fetchUser()
            }
            .ignoresSafeArea(.all, edges: .bottom)
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
        .background(Color.clear)
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        VStack {
            headerSection
            tabViewSection
        }
        .background(Color.clear)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack {
            HStack {
                if let navigationTitle = tabSelection.navigationTitle {
                    Text(navigationTitle)
                        .font(.system(size: 30, weight: .bold, design: .default))
                }
                
                if tabSelection != .home {
                    Spacer()
                }
                
                if tabSelection != .profile {
                    NavigationLink {
                        SelfProfileView()
                    } label: {
                        profileImageView
                    }
                    .buttonStyle(FlatLinkStyle())
                }
                
                if tabSelection == .home {
                    Spacer()
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Profile Image View
    private var profileImageView: some View {
        Group {
            if let user = fetchedUser {
                PfpView(user: user, size: 40, isRound: true, strokeWidth: 1)
            } else {
                Circle()
                    .fill(Color.appColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    )
            }
        }
    }
    
    // MARK: - Tab View Section
    private var tabViewSection: some View {
        TabView(selection: $tabSelection) {
            NewHomeView(currentUser: $fetchedUser, currentTab: $tabSelection, showExploreView: $showExploreView).tag(Tab.home)
            ChatsView().tag(Tab.chat)
            CreateNewEventView().tag(Tab.createEvent)
            SimpleNotificationView().tag(Tab.notifications)
            SettingsView(logout: $logout).tag(Tab.profile)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Tab Bar Overlay
    private var tabBarOverlay: some View {
        VStack {
            Spacer()
            floatingTabBar
        }
    }
    
    // MARK: - Floating Tab Bar
    private var floatingTabBar: some View {
        HStack {
            Spacer()
            
            ForEach(Tab.allCases) { tab in
                tabButton(for: tab)
                Spacer()
            }
        }
        .padding(.vertical, 16)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Tab Button
    private func tabButton(for tab: Tab) -> some View {
        Button {
            if tab == .createEvent {
                showAddEventView.toggle()
            } else {
                self.tabSelection = tab
            }
            
            HapticGenerator.light.impactOccurred()
        } label: {
            if tab == .createEvent {
                createEventButton
            } else {
                tab.icon
                    .resizable()
                    .frame(width: 18, height: 18)
            }
        }
        .foregroundColor(isSelected(tab: tab) ? .appColor : .tabIconTintColor)
    }
    
    // MARK: - Create Event Button
    private var createEventButton: some View {
        ZStack {
            Circle()
                .fill(Color.appColor)
                .frame(width: 30, height: 30)
                .shadow(color: Color.appColor.opacity(0.4), radius: 10, x: 2, y: 2)
            
            Image(systemName: "plus")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
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
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}
