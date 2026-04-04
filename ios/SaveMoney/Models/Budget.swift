import Foundation

struct Budget: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var limit: Double
    var dateStart: String
    var dateEnd: String
    var categoryIds: [String]

    enum CodingKeys: String, CodingKey {
        case id, name, dateStart, dateEnd, categoryIds
        case limit = "limit"
    }
}

struct BudgetCreateDTO: Encodable {
    var name: String
    var limitAmount: Double
    var dateStart: String
    var dateEnd: String
    var categoryIds: [String]
}
