import Foundation
import Firebase
import FirebaseFirestore

class FeaturedEventManager: ObservableObject {
    @Published var featuredEvents: [Event] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    
    func loadFeaturedEvents() {
        isLoading = true
        error = nil
        
        db.collection("events")
            .whereField("isFeatured", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.error = "Failed to load featured events: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.error = "No featured events found"
                        return
                    }
                    
                    self?.featuredEvents = documents.compactMap { document in
                        do {
                            let data = document.data()
                            let jsonData = try JSONSerialization.data(withJSONObject: data)
                            let event = try JSONDecoder().decode(Event.self, from: jsonData)
                            return event
                        } catch {
                            print("Error decoding event: \(error)")
                            return nil
                        }
                    }
                }
            }
    }
    
    func addEventToFeatured(eventID: String, completion: @escaping (Bool) -> Void) {
        db.collection("events").document(eventID).updateData([
            "isFeatured": true
        ]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error adding event to featured: \(error)")
                    completion(false)
                } else {
                    completion(true)
                    // Reload featured events
                    self.loadFeaturedEvents()
                }
            }
        }
    }
    
    func removeEventFromFeatured(eventID: String, completion: @escaping (Bool) -> Void) {
        db.collection("events").document(eventID).updateData([
            "isFeatured": false
        ]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error removing event from featured: \(error)")
                    completion(false)
                } else {
                    completion(true)
                    // Reload featured events
                    self.loadFeaturedEvents()
                }
            }
        }
    }
    
    func isEventFeatured(eventID: String) -> Bool {
        return featuredEvents.contains { $0.eventID == eventID }
    }
}

// MARK: - Admin Functions (for future admin panel)
extension FeaturedEventManager {
    func setFeaturedOrder(eventIDs: [String], completion: @escaping (Bool) -> Void) {
        // This function can be used to set a specific order for featured events
        // You might want to add a "featuredOrder" field to events
        
        let batch = db.batch()
        
        for (index, eventID) in eventIDs.enumerated() {
            let eventRef = db.collection("events").document(eventID)
            batch.updateData([
                "featuredOrder": index,
                "isFeatured": true
            ], forDocument: eventRef)
        }
        
        batch.commit { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error setting featured order: \(error)")
                    completion(false)
                } else {
                    completion(true)
                    self.loadFeaturedEvents()
                }
            }
        }
    }
}

