import Foundation

struct TicketType: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var description: String
    var price: Double
    var quantity: Int?
    var maxPerUser: Int
    
    init(id: String = UUID().uuidString,
         name: String,
         description: String,
         price: Double,
         quantity: Int? = nil,
         maxPerUser: Int = 2) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.quantity = quantity
        self.maxPerUser = maxPerUser
    }
}

