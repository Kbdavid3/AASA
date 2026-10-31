//
//  DiscoverViewViewModel.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import MapKit
import SwiftUI
import CoreLocation
import FirebaseAuth

@MainActor
class DiscoverViewViewModel: ObservableObject {
    
    @Published var headerText = "Events near you"
    @Published var events: [Event]? //= [Event().displayEvent]
    @Published var friendEvents: [Event]?
    @Published var followers: [User]?
    @Published var usersNearby: [User]?
    @Published var preferredLocation: PreferredLocation?
    @Published var isLoadingEvents: Bool = false
    @Published var isLoadingFollowers: Bool = true
    @Published var isLoadingFollowersEvents: Bool = true
    @Published var isLoadingNearYou: Bool = true
    @Published var eventTypeSelection: EventType = .all
    @Published var alertItem: AlertItem?
    
    func isSelected(type: EventType) -> Bool {
        eventTypeSelection == type
    }
    
    func loadEvents() {
        withAnimation { isLoadingEvents = true }
        // get live location first
        Task {
            LocationManager.shared.getLocationForFetchingEvents { result in
                switch result {
                case .success(let preferredLocation):
                    guard let preferredLocation else {
                        withAnimation { self.isLoadingEvents = false }
                        return
                    }
                    
                    self.preferredLocation = preferredLocation
                    
                    if let radius = preferredLocation.selectionRadius {
                        
                        EventManager.shared.getAllEvents { events in
                            
                            guard let events else {
                                return
                            }
                            
                            let latitude = preferredLocation.latitude
                            let longitude = preferredLocation.longitude
                            let latitudinalRadius = radius / 69.0
                            
                            // determine if a point is inside a circle
                            let filteredEvent = events.filter({
                                pow(($0.latitude - latitude), 2) + pow(($0.longitude - longitude), 2) < pow(latitudinalRadius, 2) && $0.to > Date()
                            })
                            
                            DispatchQueue.main.async {
                                
                                self.validateFilter(with: filteredEvent)
                                withAnimation { self.isLoadingEvents = false }
                            }
                        }
                    } else {
                        EventManager.shared.getAllEvents { events in
                            
                            guard let events else {
                                return
                            }
                            
                            let filteredEvent = events.filter({ event in
                                event.to > Date()
                            })
                            
                            DispatchQueue.main.async {
                                self.validateFilter(with: filteredEvent)
                                withAnimation { self.isLoadingEvents = false }
                            }
                        }
                    }
                
                case .failure(let error):
                    print(error)
                    withAnimation { self.isLoadingEvents = false }
                }
            }
        }
    }
    
    func fetchFollowers(currentUser: User?) {
        withAnimation { isLoadingFollowers = true }
        guard let currentUser = currentUser else {
            isLoadingFollowers = false
            return
        }
        
        Task {
            UserManager.shared.getAllFollowers(with: currentUser.followerIDs) { users in
                DispatchQueue.main.async { [self] in
                    guard let users = users else { return }
                    followers = users
                    isLoadingFollowers = false
                }
            }
        }
    }
    
    func fetchFriendEvents(currentUser: User?) {
        withAnimation { isLoadingFollowersEvents = true }
        guard let currentUser = currentUser else {
            isLoadingFollowersEvents = false
            return
        }
        
        Task {
            UserManager.shared.getAllFollowers(with: currentUser.followerIDs) { [self] users in
                DispatchQueue.main.async {
                    self.isLoadingFollowers = false
                }
                guard let users = users else {
                    isLoadingFollowersEvents = false
                    return
                }
                var followersIDs = [String]()
                users.forEach { follower in
                    followersIDs.append(follower.userID)
                }
                
                EventManager.shared.getEventsForFriends(whereField: "interestedUserIDs", arrayContains: followersIDs) { events in
                    DispatchQueue.main.async { [self] in
                        if events != nil {
                            let filteredEvents = events!.filter { $0.from >= Date() }
                            if filteredEvents.count > 10 {
                                friendEvents = [Event]()
                                friendEvents!.append(contentsOf: filteredEvents.prefix(upTo: 9))
                            } else {
                                friendEvents = filteredEvents
                            }
                            isLoadingFollowersEvents = false
                        }
                    }
                }
            }
        }
    }
    
    func fetchNearbyUsers(currentUser: User?) {
        isLoadingNearYou = true
        guard let currentUser = currentUser else { return }
        guard let location = currentUser.preferredLocation else { return }
        let lat = location.latitude
        let lon = location.longitude
        
        UserManager.shared.getUsersNearby(with: CLLocation(latitude: lat, longitude: lon)) { result in
            switch result {
            case .success(let users):
                DispatchQueue.main.async {
                    self.isLoadingNearYou = false
                    self.usersNearby = users
                }
            case .failure(let firebaseError):
                print("there was an error getting nearby users:", firebaseError)
            }
        }
    }
    
    private func validateFilter(with filteredEvent: [Event]) {
        if self.eventTypeSelection == .all {
            events = filteredEvent
        } else {
            self.events = filteredEvent.filter({ event in
                event.type == eventTypeSelection.id
            })
        }
        
        if filteredEvent.isEmpty {
            headerText = "No events near you"
        }
    }
}
