import Foundation

enum TransactionType: String, Codable, CaseIterable {
    case expense = "Expense"
    case income = "Income"
    case account = "Account"
    case transfer = "Transfer"

    var label: String {
        switch self {
        case .expense: "Chi tiêu"
        case .income: "Thu nhập"
        case .account: "Tài khoản"
        case .transfer: "Chuyển khoản"
        }
    }
}

struct Transaction: Identifiable, Codable, Equatable {
    var id: String
    var date: String
    var type: TransactionType
    var categoryId: String?
    var accountId: String?
    var transferToId: String?
    var amount: Double
    var note: String?

    enum CodingKeys: String, CodingKey {
        case id, date, type, categoryId, accountId, transferToId, amount, note
    }
}

// MARK: - DTOs
struct TransactionCreateDTO: Encodable {
    var date: String
    var type: String
    var categoryId: String?
    var accountId: String?
    var transferToId: String?
    var amount: Double
    var note: String?
}
