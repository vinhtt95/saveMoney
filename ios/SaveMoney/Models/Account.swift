import Foundation

struct Account: Identifiable, Codable, Equatable {
    var id: String
    var name: String
}

struct AccountCreateDTO: Encodable {
    var name: String
    var initialBalance: Double?
}

struct AccountUpdateDTO: Encodable {
    var name: String
    var balance: Double?
}
