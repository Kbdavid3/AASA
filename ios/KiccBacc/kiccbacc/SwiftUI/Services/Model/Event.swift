import Foundation

struct Event: Codable {
    var eventID: String
    var eventBannerUrl: String
    var name: String
    var description: String
    var hostIDs: [String]
    var from: Date
    var to: Date
    var type: String
    var customType: String?
    var interestedUserIDs: [String]
    var contactNumber: String?
    var localeIdentifier: String?
    var paymentAmount: String?
    var createdAt: Date
    var password: String?
    var soldCount: String?
    var totalTickets: Int?
    var maxTicketsPerUser: Int?
    var ticketPrice: Double?
    var ticketTypes: [TicketType]?
    var isFeatured: Bool = false // New field for featured events
    
    // Event properties section
    var showStories: Bool = true // Toggle to show/hide stories for this event
    var showTicketsSold: Bool = true // Toggle to show/hide tickets sold count
    
    // Event location data
    var venueName: String
    var latitude: Double
    var longitude: Double
    var streetName: String?
    var streetNumber: String?
    var city: String?
    var neighbourhood: String?
    var state: String?
    var county: String?
    var zipCode: String?
    var catalog_id: String?
    var catalog_status: String?
}

extension Event {
    var location: EventLocation {
        EventLocation(
            venueName: self.venueName,
            latitude: self.latitude,
            longitude: self.longitude,
            streetName: self.streetName,
            streetNumber: self.streetNumber,
            city: self.city,
            neighbourhood: self.neighbourhood,
            state: self.state,
            county: self.county,
            zipCode: self.zipCode
        )
    }
    
    // Helper to get the ticket price as a Double
    var ticketPriceValue: Double {
        return ticketPrice ?? (Double(paymentAmount ?? "0") ?? 0.0)
    }
}


extension Event {
    init() {
        self.init(
            eventID: "C22F2CBC-F2C8-40B4-958B-7B4EDC18CD6A",
            eventBannerUrl: "https://firebasestorage.googleapis.com/v0/b/kiccbacc-b538e.appspot.com/o/events%2Fcovers%2FC22F2CBC-F2C8-40B4-958B-7B4EDC18CD6A%2FC22F2CBC-F2C8-40B4-958B-7B4EDC18CD6A.png?alt=media&token=9b42daa5-fceb-4a94-88d6-ec713239e970",
            name: "Club night showcase party",
            description: "(null)",
            hostIDs: [],
            from: Date(),
            to: Date(),
            type: "Design",
            customType: "",
            interestedUserIDs: [],
            contactNumber: nil,
            localeIdentifier: nil,
            paymentAmount: "10",
            createdAt: Date(),
            soldCount: "0",
            totalTickets: nil,
            maxTicketsPerUser: nil,
            ticketPrice: 10.0,
            showStories: true,
            showTicketsSold: true,
            venueName: "Times Square",
            latitude: 40.75773,
            longitude: -73.985708,
            streetName: nil,
            streetNumber: nil,
            city: "Manhattan",
            neighbourhood: nil,
            state: "New York",
            county: "United States",
            zipCode: "10036"
        )
    }
    
    init(
        eventID: String,
        eventBannerUrl: String,
        name: String,
        description: String,
        hostIDs: [String],
        from: Date,
        to: Date,
        type: String,
        customType: String?,
        interestedUserIDs: [String],
        contactNumber: String?,
        localeIdentifier: String?,
        paymentAmount: String?,
        password: String?,
        createdAt: Date,
        location: EventLocation,
        totalTickets: Int?,
        maxTicketsPerUser: Int?,
        ticketPrice: Double? = nil,
        ticketTypes: [TicketType]? = nil,
        showStories: Bool = true,
        showTicketsSold: Bool = true) {
            self.eventID = eventID
            self.eventBannerUrl = eventBannerUrl
            self.name = name
            self.description = description
            self.hostIDs = hostIDs
            self.from = from
            self.to = to
            self.type = type
            self.customType = customType
            self.interestedUserIDs = interestedUserIDs
            self.contactNumber = contactNumber
            self.localeIdentifier = localeIdentifier
            self.paymentAmount = paymentAmount
            self.password = password
            self.createdAt = createdAt
            self.venueName = location.venueName
            self.latitude = location.latitude
            self.longitude = location.longitude
            self.streetName = location.streetName
            self.streetNumber = location.streetNumber
            self.city = location.city
            self.neighbourhood = location.neighbourhood
            self.state = location.state
            self.county = location.county
            self.zipCode = location.zipCode
            self.totalTickets = totalTickets
            self.maxTicketsPerUser = maxTicketsPerUser
            self.ticketPrice = ticketPrice
            self.ticketTypes = ticketTypes
            self.showStories = showStories
            self.showTicketsSold = showTicketsSold
            self.soldCount = "0"
        }
}

// ✅ Fixed `displayEvent` with Correct `paymentAmount` and `ticketPrice`
extension Event {
    var displayEvent: Event {
        var event = Event(
            eventID: "01DD60F0-ADF9-49EE-BE1C-D80642EDA1C7",
            eventBannerUrl: "https://firebasestorage.googleapis.com/v0/b/kiccbacc-b538e.appspot.com/o/events%2Fcovers%2F01DD60F0-ADF9-49EE-BE1C-D80642EDA1C7%2F01DD60F0-ADF9-49EE-BE1C-D80642EDA1C7.png?alt=media&token=c6f869ce-fef3-4df4-9ddd-962b82db8a64",
            name: "Projekt X",
            description: "Bare Kom",
            hostIDs: ["zFU1CCzc0nhUbYybucLreQIqndJ2"],
            from: Date(),
            to: Date(),
            type: "Concert",
            customType: "",
            interestedUserIDs: ["TI2IRr1swCX9W5N4jxcGm9IOcDm2", "zFU1CCzc0nhUbYybucLreQIqndJ2"],
            contactNumber: nil,
            localeIdentifier: "en",
            paymentAmount: "10.0",
            createdAt: Date(),
            soldCount: "0",
            totalTickets: 100,
            maxTicketsPerUser: 5,
            ticketPrice: 10.0,
            showStories: true,
            showTicketsSold: true,
            venueName: "Kildeparken",
            latitude: 57.0422266,
            longitude: 9.9144133,
            streetName: "Vesterbro",
            streetNumber: "2",
            city: "Aalborg",
            neighbourhood: "Aalborg",
            state: "Region Nordjylland",
            county: "US",
            zipCode: "9000"
        )
        // Ensure the catalog ID is set for payment
        event.catalog_id = "event-\(event.eventID)"
        return event
    }
}

// Make sure the CodingKeys enum includes ticketTypes if it exists
enum CodingKeys: String, CodingKey {
    case eventID, eventBannerUrl, name, description, hostIDs, from, to, type, customType
    case interestedUserIDs, contactNumber, localeIdentifier, paymentAmount, createdAt
    case password, soldCount, totalTickets, maxTicketsPerUser, ticketPrice, ticketTypes
    case isFeatured, showStories, showTicketsSold
    case venueName, latitude, longitude, streetName, streetNumber, city, neighbourhood
    case state, county, zipCode, catalog_id, catalog_status
}

// Custom decoder to handle missing fields gracefully
extension Event {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        eventID = try container.decode(String.self, forKey: .eventID)
        eventBannerUrl = try container.decode(String.self, forKey: .eventBannerUrl)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        hostIDs = try container.decode([String].self, forKey: .hostIDs)
        from = try container.decode(Date.self, forKey: .from)
        to = try container.decode(Date.self, forKey: .to)
        type = try container.decode(String.self, forKey: .type)
        customType = try container.decodeIfPresent(String.self, forKey: .customType)
        interestedUserIDs = try container.decode([String].self, forKey: .interestedUserIDs)
        contactNumber = try container.decodeIfPresent(String.self, forKey: .contactNumber)
        localeIdentifier = try container.decodeIfPresent(String.self, forKey: .localeIdentifier)
        paymentAmount = try container.decodeIfPresent(String.self, forKey: .paymentAmount)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        password = try container.decodeIfPresent(String.self, forKey: .password)
        soldCount = try container.decodeIfPresent(String.self, forKey: .soldCount)
        totalTickets = try container.decodeIfPresent(Int.self, forKey: .totalTickets)
        maxTicketsPerUser = try container.decodeIfPresent(Int.self, forKey: .maxTicketsPerUser)
        ticketPrice = try container.decodeIfPresent(Double.self, forKey: .ticketPrice)
        ticketTypes = try container.decodeIfPresent([TicketType].self, forKey: .ticketTypes)
        
        // Handle new properties with default values for backward compatibility
        isFeatured = try container.decodeIfPresent(Bool.self, forKey: .isFeatured) ?? false
        showStories = try container.decodeIfPresent(Bool.self, forKey: .showStories) ?? true
        showTicketsSold = try container.decodeIfPresent(Bool.self, forKey: .showTicketsSold) ?? true
        
        // Location data
        venueName = try container.decode(String.self, forKey: .venueName)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        streetName = try container.decodeIfPresent(String.self, forKey: .streetName)
        streetNumber = try container.decodeIfPresent(String.self, forKey: .streetNumber)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        neighbourhood = try container.decodeIfPresent(String.self, forKey: .neighbourhood)
        state = try container.decodeIfPresent(String.self, forKey: .state)
        county = try container.decodeIfPresent(String.self, forKey: .county)
        zipCode = try container.decodeIfPresent(String.self, forKey: .zipCode)
        catalog_id = try container.decodeIfPresent(String.self, forKey: .catalog_id)
        catalog_status = try container.decodeIfPresent(String.self, forKey: .catalog_status)
    }
}
