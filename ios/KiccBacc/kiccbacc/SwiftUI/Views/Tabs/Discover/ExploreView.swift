//
//  ExploreView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import Foundation
//import SDWebImageSwiftUI

struct ExploreView: View {
    
    @State private var searchedValue: String = ""
    @State private var isSearchingForUsers: Bool = false
    @State private var isSearchingForEvents: Bool = false
    @State private var isSearchingForEventsByCode: Bool = false
    @State private var users: [User]?
    @State private var events: [Event]?
    @State private var selectedEvent: Event?
    
    var body: some View {
        VStack {
            HStack {
                Text("Explore")
                    .font(.system(size: 30, weight: .bold, design: .default))

                Spacer()
                
                AccessoryIndicator.down.getImage()
            }
            .padding(.horizontal)
            
            ScrollView(.vertical, showsIndicators: false) {
                TextField("Find people and events", text: $searchedValue)
                    .padding(8)
                    .padding(.leading, 30)
                    .background(Color.secondaryBgColor)
                    .cornerRadius(10)
                    .foregroundColor(.gray)
                    .font(.system(size: 15))
                    .overlay(
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Spacer()
                        }
                            .padding(.leading, 7)
                            .foregroundColor(.gray)
                    )
                    .padding(.horizontal)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .onChange(of: searchedValue) { newValue in
                        withAnimation { isSearchingForUsers = true }
                        withAnimation { isSearchingForEvents = true }
                        if newValue == "" {
                            isSearchingForUsers = false
                            isSearchingForEvents = false
                            return
                        }
                        
                        EventManager.shared.getEvent(with: newValue) { event in
                            guard let event = event else {
                                return
                            }

                            DispatchQueue.main.async {
                                self.events = [event]
                                withAnimation { isSearchingForEventsByCode = false }
                            }
                        }
                        
                        EventManager.shared.getEvents(whereField: "name", isEqualTo: newValue) { event in
                            guard let event = event else {
                                return
                            }
                            
                            DispatchQueue.main.async {
                                self.events = event
                                withAnimation { isSearchingForEvents = false }
                            }
                        }
                        
                        UserManager.shared.getUsers(whereField: "username", isEqualTo: newValue) { users in
                            print("searched users:", users ?? "no users")
                            DispatchQueue.main.async {
                                self.users = users
                                withAnimation { isSearchingForUsers = false }
                            }
                        }
                    }
                
                // searched results
                if isSearchingForUsers && isSearchingForEvents && isSearchingForEventsByCode {
                    Spacer()
                    ProgressView()
                } else if let users = users, users.count > 0 {
                    VStack {
                        ForEach(users, id: \.userID) { user in
                            UserRow(user: user)
                        }
                    }
                    .padding()
                } else if let events = events, events.count > 0 {
                    ForEach(events, id: \.eventID) { event in
                        Button {
                            selectEvent(event)
                        } label: {
                            EventRow(event: event)
                                .padding(.horizontal)
                        }
                    }
                } else {
                    Text("No users or events found")
                }
                
                Group {
                    HStack {
                        Text("People to follow")
                            .font(.system(size: 16, weight: .light, design: .default))
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    //.. people suggestion
                    VStack {
                        
                    }
                    
                    Button {
                        //
                    } label: {
                        Text("See more")
                            .padding(13)
                            .padding(.horizontal, 50)
                            .background(Color.appColor)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    
                    HStack {
                        Text("Event you might be interested in")
                            .font(.system(size: 16, weight: .light, design: .default))
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
                .hidden()
            }
        }
        .padding(.top, 50)
        .background(Color.bgColor.ignoresSafeArea())
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
    }
    
    struct EventRow: View {
        
        var event: Event
        
        var body: some View {
            HStack {
                KBImage(url: URL(string: event.eventBannerUrl)!, resizeMode: .fill)
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                
                VStack(alignment: .leading, spacing: 5) {
                    event.name.text
                        .font(.system(size: 17, weight: .regular, design: .default))
                        .foregroundColor(.labelColor)
                    
                    event.venueName.text
                        .font(.system(size: 13, weight: .light, design: .default))
                        .foregroundColor(.gray)
                }
                .multilineTextAlignment(.leading)
                
                Spacer()
            }
        }
    }
    
    private struct UserRow: View {
        
        var user: User
        
        @State private var isFollowing: Bool = false
        
        var body: some View {
            HStack {
                NavigationLink {
                    UserProfileView(user: user)
                } label: {
                    PfpView(user: user, size: 50, isRound: true)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(user.fullName)
                            .font(.system(size: 17, weight: .bold, design: .default))
                        
                        Text("@\(user.username)")
                            .font(.system(size: 14, weight: .regular, design: .default))
                    }
                    .foregroundColor(.labelColor)
                }
                
                Spacer()
                
                if user.userID != UserManager.shared.currentUserID {
                    Button {
                        if isFollowing {
                            UserManager.shared.unFollow(userToUnFollow: user) { isUnFollowed in
                                withAnimation { self.isFollowing = !isUnFollowed }
                            }
                        } else {
                            UserManager.shared.follow(userToFollow: user) { isFollowed in
                                withAnimation { self.isFollowing = isFollowed }
                            }
                        }
                    } label: {
                        if !isFollowing {
                            Text("Follow")
                                .padding(10)
                                .foregroundColor(.white)
                                .background(Color.buttonBgColor)
                                .cornerRadius(10)
                                .font(.system(size: 14, weight: .regular, design: .default))
                        } else {
                            Text("Following")
                                .padding(10)
                                .foregroundColor(.labelColor)
                                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.appColor, lineWidth: 1))
                                .cornerRadius(10)
                                .font(.system(size: 14, weight: .regular, design: .default))
                        }
                    }
                    .buttonStyle(PlainButtonStyle()) // Prevent gesture interference
                    .contentShape(Rectangle()) // Ensure the entire button area is tappable
                }
            }
            .contentShape(Rectangle())
            .onAppear {
                // check if current user is following this user
                UserManager.shared.isFollowing(user: user) { isFollowing in
                    withAnimation { self.isFollowing = isFollowing }
                }
            }
        }
    }
    
    // Helper function to handle event selection
    private func selectEvent(_ event: Event) {
        guard !event.eventID.isEmpty else {
            print("Error: Event ID is empty")
            return
        }
        
        // TODO: Add password protection once module issues are resolved
        if let password = event.password, !password.isEmpty {
            print("Note: Event requires password: \(event.name) - but password protection temporarily disabled")
        }
        
        selectedEvent = event
        print("selectedEvent set to: \(selectedEvent?.name ?? "nil")")
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
            .preferredColorScheme(.dark)
    }
}
