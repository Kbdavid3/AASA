//
//  SelfProfileView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import SafariServices
import Foundation
import CryptoKit

class SafariViewControllerDelegate: NSObject, SFSafariViewControllerDelegate {
    func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL) {
        print("Redirected to: \(URL.absoluteString)")
        // Handle the URL change here
        if URL.absoluteString.starts(with: "https://squareauth-7ce4gb3x2q-uc.a.run.app") {
            // This is your redirect URI, handle the callback
            controller.dismiss(animated: true, completion: nil)
            // Process the callback URL (e.g., extract the authorization code)
        }
    }
}
struct EventListView: View {
    let events: [Event]
    let category: String
    
    var body: some View {
        if events.isEmpty {
            Text("No \(category.lowercased()) events.")
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 30) {
                    Spacer(minLength: 16)
                    ForEach(events, id: \.eventID) { event in
                        NavigationLink {
                            if #available(iOS 16.0, *) {
                                EventDetailView(event: event)
                                    .padding(.top)
                            }
                        } label: {
                            DiscoverView.EventCard2(event: event)
                                .frame(minWidth: 0, maxWidth: 280, minHeight: 0, maxHeight: 340)
                        }
                        .buttonStyle(FlatLinkStyle())
                    }
                    Spacer(minLength: 16)
                }
            }
        }
    }
}

struct SelfProfileView: View {
    
    @Environment(\.presentationMode) private var presentation
    
    @State private var fetchedUser: User?
    @State private var events: [Event]?
    @State private var followers: [User]?
    @State private var selectedTab = 0
    @State private var selectedSection = 0
    
    @State private var navTitle: String = ""
    @State private var alertItem: AlertItem?
    @State private var viewItem: ViewItem?
    @State private var viewControllerItem: UIKitViewControllerItem?
    
    @State private var isAuthorizedWithSquare: Bool = false
    @State private var isProcessingSquareAction: Bool = false
    
    @State private var tickets: [Ticket] = []
    @State private var totalTickets: Int = 0
    @State private var totalRevenue: Double = 0.0
    @State private var isRefreshing: Bool = false

    init(initialSelectedSection: Int = 0) {
        _selectedSection = State(initialValue: initialSelectedSection)
    }
    func generateState() -> String {
        let randomData = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        return randomData.map { String(format: "%02hhx", $0) }.joined()
    }

    func authorizeWithSquare() {
        // Track Square authorization attempt
        AnalyticsManager.logCustomEvent(name: "square_authorization_attempt", parameters: nil)
        
        let clientId = "sq0idp-q9b1Mr_a45A7zUnLVYCfaQ"
        
        let scope = "ITEMS_READ+ITEMS_WRITE+MERCHANT_PROFILE_READ+PAYMENTS_WRITE_ADDITIONAL_RECIPIENTS+PAYMENTS_WRITE+PAYMENTS_READ" // Add or modify scopes as needed
        let state = generateState()
        
        let urlString = "https://connect.squareup.com/oauth2/authorize?client_id=\(clientId)&scope=\(scope)&state=\(state)&response_type=code"

        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func unlinkSquareAccount() {
        guard let user = fetchedUser else { return }
        
        // Track Square unlink attempt
        AnalyticsManager.logCustomEvent(name: "square_unlink_attempt", parameters: nil)
        
        isProcessingSquareAction = true
        
        // Display confirmation alert
        alertItem = AlertItem(
            title: Text("Unlink Square Account"),
            message: Text("Are you sure you want to unlink your Square account? You won't be able to process payments until you reconnect."),
            primaryButton: .destructive(Text("Unlink")) {
                // Perform the unlinking operation
                UserManager.shared.unlinkSquareAccount(user: user) { success in
                    DispatchQueue.main.async {
                        isProcessingSquareAction = false
                        if success {
                            isAuthorizedWithSquare = false
                            
                            // Track successful unlink
                            AnalyticsManager.logCustomEvent(name: "square_unlink_success", parameters: nil)
                            
                            alertItem = AlertItem(
                                title: Text("Success"),
                                message: Text("Your Square account has been unlinked successfully."),
                                dismissButton: .default(Text("OK"))
                            )
                        } else {
                            // Track unlink failure
                            AnalyticsManager.logCustomEvent(name: "square_unlink_failure", parameters: nil)
                            
                            alertItem = AlertItem(
                                title: Text("Error"),
                                message: Text("Failed to unlink your Square account. Please try again later."),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                    }
                }
            },
            secondaryButton: .cancel {
                isProcessingSquareAction = false
            }
        )
    }
    
    var body: some View {
        CustomScrollView(navigationStyle: .dismissBack(title: navTitle), scrollViewData: {
            VStack(alignment: .center, spacing: 30) {
                if let fetchedUser = fetchedUser {
                    // Add verification badge to profile picture
                    Button {
                        viewItem = ViewItem(AnyView(EditProfileView(user: fetchedUser)), _presentationStyle: .modal)
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            PfpView(user: fetchedUser, size: 185, isRound: true, strokeWidth: 6)
                            
                            // Add verification badge if user is verified
                            if fetchedUser.verified == true {
                                Image("Verified")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .offset(x: 25, y: 25)
                            }
                        }
                    }
                    .buttonStyle(FlatLinkStyle())
                    
                    VStack(alignment: .center, spacing: 4) {
                        // Add small "verified" text next to user's name
                        HStack(alignment: .center, spacing: 5) {
                            Text("\(fetchedUser.fullName)")
                                .font(.system(size: 30, weight: .bold, design: .default))
                            
                            if fetchedUser.verified == true {
                                Text("verified")
                                    .font(.system(size: 12, weight: .medium, design: .default))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Text("\(fetchedUser.bio)")
                            .font(.system(size: 14, weight: .regular, design: .default))
                        
                        // Social Media Links
                        SocialMediaLinksView(user: fetchedUser)
                            .padding(.bottom, 24)
                        
                        // Interests Tags
                        InterestsTagsView(user: fetchedUser, isCurrentUser: true)
                    }
                    
                    HStack(alignment: .center, spacing: -15) {
                        if let followers = followers {
                            HStack(alignment: .center, spacing: -15) {
                                ForEach(followers, id: \.userID) { follower in
                                    PfpView(user: follower, size: 40, isRound: true)
                                        .overlay (
                                            Circle()
                                                .stroke(Color.bgColor, lineWidth: 4)
                                        )
                                }
                            }
                            .padding(.trailing, 25)
                        }
                        
                        HStack(alignment: .center, spacing: 15) {
                            NavigationLink {
                                ListOfUsersView(userIDs: fetchedUser.followerIDs, usersKind: .followers, isHost: false, eventID: "")
                                    .navigationTitle("Followers")
                            } label: {
                                VStack {
                                    Text("\(fetchedUser.followerCounter)")
                                        .font(.system(size: 20, weight: .bold, design: .default))
                                    
                                    Text("Followers")
                                        .font(.system(size: 10, weight: .medium, design: .default))
                                }
                            }
                            
                            Divider()
                            
                            NavigationLink {
                                ListOfUsersView(userIDs: fetchedUser.followingIDs, usersKind: .following, isHost: false, eventID: "")
                                    .navigationTitle("Following")
                            } label: {
                                VStack {
                                    Text("\(fetchedUser.followingCounter)")
                                        .font(.system(size: 20, weight: .bold, design: .default))
                                    
                                    Text("Following")
                                        .font(.system(size: 10, weight: .medium, design: .default))
                                }
                            }
                        }
                        .foregroundColor(.labelColor)
                    }
                    
                    HStack(spacing: 30) {
                        VStack {
                            Text("\(totalTickets)")
                                .font(.system(size: 20, weight: .bold))
                            Text("Tickets Sold")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                            .frame(height: 30)
                        
                        VStack {
                            Text("$\(String(format: "%.2f", totalRevenue))")
                                .font(.system(size: 20, weight: .bold))
                            Text("Revenue")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: fetchMetrics) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 20))
                                .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                                .animation(isRefreshing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                        }
                        .disabled(isRefreshing)
                    }
                    .padding(.horizontal)
                    .onAppear {
                        fetchMetrics()
                    }
                    
                    Button {
                        viewItem = ViewItem(AnyView(EditProfileView(user: fetchedUser)), _presentationStyle: .modal)
                    } label: {
                        Text("Edit Profile")
                            .foregroundColor(.white)
                            .padding()
                            .padding(.horizontal, 50)
                            .background(Color.buttonBgColor)
                            .cornerRadius(15)
                    }
                    VStack {
                        Picker("Profile Sections", selection: $selectedSection) {
                            Text("Your events").tag(0)
                            Text("Your tickets").tag(1)
                            Text("Your payment").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .onChange(of: selectedSection) { newValue in
                            // Track section changes
                            let sectionName = newValue == 0 ? "Events" : (newValue == 1 ? "Tickets" : "Payment")
                            AnalyticsManager.logCustomEvent(name: "profile_section_changed", parameters: [
                                "section": sectionName
                            ])
                        }
                        
                        TabView(selection: $selectedSection) {
                            // Your events tab
                            VStack {
                                if let events = events, events.count > 0 {
                                    VStack {
                                        Picker("Event Category", selection: $selectedTab) {
                                            Text("Completed").tag(0)
                                            Text("Ongoing").tag(1)
                                            Text("Upcoming").tag(2)
                                        }
                                        .pickerStyle(SegmentedPickerStyle())
                                        .padding(.horizontal)
                                        .onChange(of: selectedTab) { newValue in
                                            // Track event category changes
                                            let categoryName = newValue == 0 ? "Completed" : (newValue == 1 ? "Ongoing" : "Upcoming")
                                            AnalyticsManager.logCustomEvent(name: "event_category_changed", parameters: [
                                                "category": categoryName
                                            ])
                                        }
                                        TabView(selection: $selectedTab) {
                                            EventListView(events: events.filter { $0.to < Date() }, category: "Completed")
                                                .tag(0)
                                            
                                            EventListView(events: events.filter { $0.from <= Date() && $0.to >= Date() }, category: "Ongoing")
                                                .tag(1)
                                            
                                            EventListView(events: events.filter { $0.from > Date() }, category: "Upcoming")
                                                .tag(2)
                                        }
                                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                                        .frame(height: 400)
                                    }
                                } else if events?.count == 0 || events == nil {
                                    Text("No events.")
                                } else {
                                    ProgressView()
                                }
                            }
                            .tag(0)
              
                            // Your tickets tab
                            VStack {
                                ScrollView {
                                    LazyVStack(spacing: 16) {
                                        ForEach(tickets) { ticket in
                                            NavigationLink {
                                                TicketView(ticket: ticket, showBackButton: false)  // Explicitly set to false
                                            } label: {
                                                TicketItemView(ticket: ticket)
                                                    .padding(.horizontal)
                                            }
                                            .onTapGesture {
                                                // Track ticket view
                                                AnalyticsManager.logCustomEvent(name: "view_ticket_from_profile", parameters: [
                                                    "ticket_id": ticket.id,
                                                    "event_id": ticket.eventId
                                                ])
                                            }
                                        }
                                    }
                                }
                            }
                            .tag(1)
                            .onAppear {
                                fetchUserTickets()
                            }
                            
                            // Your payment tab
                            VStack {
                                if isAuthorizedWithSquare {
                                    Text("Authorized with Square")
                                        .font(.headline)
                                    Text("Your account is connected to Square.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.bottom, 8)
                                    
                                    Button(action: unlinkSquareAccount) {
                                        HStack {
                                            Image(systemName: "link.badge.minus")
                                            Text("Unlink Square Account")
                                        }
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: 250)
                                        .background(Color.red)
                                        .cornerRadius(8)
                                    }
                                    .disabled(isProcessingSquareAction)
                                    .opacity(isProcessingSquareAction ? 0.6 : 1.0)
                                    .overlay(
                                        Group {
                                            if isProcessingSquareAction {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            }
                                        }
                                    )
                                } else {
                                    Text("Not authorized with Square")
                                        .font(.headline)
                                    Text("Connect your account to Square to process payments.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.bottom, 8)
                                    
                                    Button(action: authorizeWithSquare) {
                                        HStack {
                                            Image(systemName: "link.badge.plus")
                                            Text("Authorize with Square")
                                        }
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: 250)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                    }
                                    .disabled(isProcessingSquareAction)
                                    .opacity(isProcessingSquareAction ? 0.6 : 1.0)
                                }
                            }
                            .padding()
                            .tag(2)
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .frame(height: 460)
                    }
                } else {
                    ProgressView()
                }
            }
            .padding(.top)
        }, alertItem: $alertItem, viewControllerItem: $viewControllerItem, viewItem: $viewItem)
            .onAppear {
                // Track screen view when this view appears
                AnalyticsManager.logScreenView(screenName: "Self Profile", screenClass: "SelfProfileView")
                
                fetchUser()
                fetchEvents()
            }
    }
    
    private func fetchUser() {
        guard let userID = UserManager.shared.currentUserID else {
            return
        }
        
        UserManager.shared.getUserListener(withUserID: userID) { result in
            switch result {
            case .success(let user):
                self.fetchedUser = user
                self.navTitle = "@\(user.username)"
                // fetch followers
                UserManager.shared.getTopFourFollowers(of: user) { users in
                    self.followers = users
                }
                self.isAuthorizedWithSquare = UserManager.shared.checkSquareAuthorization(user: user)
            case .failure(_):
                // login again, user fetch failed
                break
            }
        }
    }
    
    private func fetchEvents() {
        guard let userID = UserManager.shared.currentUserID else {
            return
        }
        
        EventManager.shared.getEvents(whereField: "hostIDs", arrayContains: userID) { events in
            self.events = events
        }
    }
    
    private func fetchUserTickets() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("tickets")
            .whereField("buyerId", isEqualTo: userId)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching tickets: \(error?.localizedDescription ?? "")")
                    return
                }
                print(documents.map { $0.data()["itemPrice"] ?? "No price" })
                
                self.tickets = documents.compactMap { document -> Ticket? in
                    try? document.data(as: Ticket.self)
                }
            }
    }
    
    private func fetchMetrics() {
        guard let userID = fetchedUser?.userID else { return }
        
        // Track metrics refresh
        AnalyticsManager.logCustomEvent(name: "profile_metrics_refresh", parameters: nil)
        
        isRefreshing = true
        
        EventManager.shared.getEventMetrics(forUserID: userID) { tickets, revenue in
            DispatchQueue.main.async {
                totalTickets = tickets
                totalRevenue = revenue
                isRefreshing = false
                
                // Track metrics loaded
                AnalyticsManager.logCustomEvent(name: "profile_metrics_loaded", parameters: [
                    "total_tickets": tickets,
                    "total_revenue": revenue
                ])
            }
        }
    }
}
