import Foundation
import FirebaseFirestore

struct EventManager {
    
    static let shared = EventManager()
    
    private let repository = EventDataRepository()
    
    func create(event: Event) throws {
        // Log the event details for debugging
        print("Creating event: \(event.name) with ID: \(event.eventID)")
        if let ticketTypes = event.ticketTypes, !ticketTypes.isEmpty {
            print("Event has \(ticketTypes.count) ticket types")
            for type in ticketTypes {
                print("Ticket type: \(type.name), price: \(type.price)")
            }
        } else if let paymentAmount = event.paymentAmount, !paymentAmount.isEmpty {
            print("Event has payment amount: \(paymentAmount)")
        } else {
            print("Event is free")
        }
        
        // Continue with existing code
        try repository.create(event: event)
        
        // If this is a paid event, create the Square catalog item
        if (event.ticketTypes != nil && !(event.ticketTypes?.isEmpty ?? true)) ||
           (event.paymentAmount != nil && !(event.paymentAmount?.isEmpty ?? true)) {
            createSquareCatalogItem(for: event)
        }
    }
    
    private func createSquareCatalogItem(for event: Event) {
        // Implementation for creating Square catalog item
        print("Creating Square catalog item for event: \(event.name)")
    }
    
    func getEventsSnapshotListener(whereField: String, isEqualTo: Any?, completion: @escaping ([Event]?) -> ()) {
        repository.getEventsSnapshotListener(whereField: whereField, isEqualTo: isEqualTo) { events in
            completion(events)
        }
    }
    
    func getEvent(with eventID: String, completion: @escaping (Event?) -> ()) {
        repository.getEvent(with: eventID) { event in
            completion(event)
        }
    }
    
    func getEvents(whereField: String, isEqualTo: Any, completion: @escaping ([Event]?) -> ()) {
        repository.getEvents(whereField: whereField, isEqualTo: isEqualTo) { events in
            completion(events)
        }
    }
    
    func getEvents(whereField: String, arrayContains: Any, completion: @escaping ([Event]?) -> ()) {
        repository.getEvents(whereField: whereField, arrayContains: arrayContains) { events in
            completion(events)
        }
    }
    
    func getEventsForFriends(whereField: String, arrayContains: [Any], completion: @escaping ([Event]?) -> ()) {
        repository.getEventsForFriends(whereField: whereField, arrayContains: arrayContains) { events in
            completion(events)
        }
    }
    
    func isCurrentUserInterested(inEvent: Event, completion: @escaping (Bool)->()) {
        repository.isCurrentUserInterested(inEvent: inEvent) { isInterested in
            completion(isInterested)
        }
    }
    
    func interestedIn(event: Event, completion: @escaping (Bool)->()) {
        // First check if user is already interested
        isCurrentUserInterested(inEvent: event) { wasAlreadyInterested in
            // Then add them to interested list
            self.repository.interestedIn(event: event) { isInterested in
                if isInterested {
                    // Only send notification if user wasn't already interested
                    if !wasAlreadyInterested {
                        guard let currentUserID = UserManager.shared.currentUserID else {
                            completion(true)
                            return
                        }
                        
                        print("🔔 User became interested in event, sending notification")
                        
                        // Track first event join experience
                        if !UserDefaults.standard.bool(forKey: "has_joined_first_event") {
                            UserDefaults.standard.set(true, forKey: "has_joined_first_event")
                            print("🎉 User joined their first event!")
                        }
                        
                        EnhancedNotificationManager.shared.sendEventJoinNotification(
                            eventID: event.eventID,
                            joinerID: currentUserID,
                            eventTitle: event.name
                        ) { success in
                            print("📤 Event join notification sent: \(success)")
                            completion(true)
                        }
                    } else {
                        print("ℹ️ User was already interested, no notification needed")
                        completion(true)
                    }
                } else {
                    print("❌ Failed to add user to interested list")
                    completion(false)
                }
            }
        }
    }
    

    
    func removeInterestedIn(event: Event, completion: @escaping (Bool)->()) {
        repository.removeInterestedIn(event: event) { isNotInterested in
            completion(isNotInterested)
        }
    }
    
    // MARK: - Event Leave Functionality
    /// Safely removes a user from an event with proper error handling and notifications
    func leaveEvent(event: Event, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let currentUserID = UserManager.shared.currentUserID else {
            completion(.failure(NSError(domain: "EventManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        // First check if user is actually in the event
        isCurrentUserInterested(inEvent: event) { isInterested in
            guard isInterested else {
                // User is not in the event, return success but log warning
                print("⚠️ User \(currentUserID) attempted to leave event \(event.eventID) but was not interested")
                completion(.success(true))
                return
            }
            
            // Remove user from interested list
            self.removeInterestedIn(event: event) { success in
                if success {
                    print("✅ User \(currentUserID) successfully left event: \(event.name)")
                    
                    // Send leave notification to event host
                    EnhancedNotificationManager.shared.sendEventLeaveNotification(
                        eventID: event.eventID,
                        leaverID: currentUserID,
                        eventTitle: event.name
                    ) { notificationSuccess in
                        print("📤 Event leave notification sent: \(notificationSuccess)")
                        completion(.success(true))
                    }
                } else {
                    let error = NSError(domain: "EventManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to leave event"])
                    print("❌ Failed to remove user from event: \(event.name)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Async version of leaveEvent for modern Swift concurrency
    func leaveEvent(event: Event) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            leaveEvent(event: event) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func removeUserInterestedIn(userID: String, event: String, completion: @escaping (Bool)->()) {
        repository.removeUserInterestedIn(userID: userID, event: event) { isNotInterested in
            completion(isNotInterested)
        }
    }
    
    func getAllEvents(completion: @escaping ([Event]?) -> ()) {
        repository.getAllEvents { events in
            completion(events)
        }
    }
    
    func uploadNewCoverForEvent(data: Data, with eventID: String, completion: @escaping (Result<FirebaseStorageUploadStatus,Error>) -> Void) {
        repository.uploadNewCoverForEvent(data: data, with: eventID) { result in
            completion(result)
        }
    }
    
    func getTopFourInterestedPeople(of event: Event, completion: @escaping ([User]?) -> ()) {
        repository.getTopFourInterestedPeople(of: event) { users in
            completion(users)
        }
    }
    
    // FIXED: Improved updateEventWith method that properly preserves document data
    func updateEventWith(eventID: String, with values: [String : Any], completion: @escaping (Bool) -> ()) {
        repository.updateEventWith(eventID: eventID, with: values) { success in
            completion(success)
        }
    }
    
    func search(searchText: String, completion: @escaping ([Event]?) -> ()) {
        repository.search(searchText: searchText) { events in
            completion(events)
        }
    }
    
    func delete(event: Event, completion: @escaping (Bool) -> ()) {
        repository.delete(event: event) { success in
            completion(success)
        }
    }
    
    // Placeholder method for event metrics - simplified as requested
    func getEventMetrics(forUserID userID: String, completion: @escaping (Int, Double) -> ()) {
        // Return placeholder values since metrics functionality is not implemented
        completion(0, 0.0)
    }
}
