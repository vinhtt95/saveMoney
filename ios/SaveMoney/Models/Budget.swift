import Foundation

struct Budget: Codable, Identifiable {
    let id: String
    let name: String
    let limit: Double           // server sends "limit" (not limitAmount)
    let dateStart: String
    let dateEnd: String
    let categoryIds: [String]

    // limitAmount convenience alias
    var limitAmount: Double { limit }
}

struct CreateBudgetRequest: Encodable {
    let name: String
    let limitAmount: Double
    let dateStart: String
    let dateEnd: String
    let categoryIds: [String]

    enum CodingKeys: String, CodingKey {
        case name, dateStart, dateEnd, categoryIds
        case limitAmount = "limit_amount"
    }
}
