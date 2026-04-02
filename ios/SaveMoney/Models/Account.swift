import Foundation

struct Account: Codable, Identifiable {
    let id: String
    let name: String
    // balance comes from accountBalances map in /api/init, not embedded
}

struct CreateAccountRequest: Encodable {
    let name: String
    let balance: Double?
}

struct UpdateAccountRequest: Encodable {
    let name: String
    let balance: Double?
}
