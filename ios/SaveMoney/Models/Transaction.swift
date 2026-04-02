import Foundation

enum TransactionType: String, Codable, CaseIterable {
    case expense = "Expense"
    case income = "Income"
    case account = "Account"
    case transfer = "Transfer"

    var displayName: String {
        switch self {
        case .expense: return "Chi tiêu"
        case .income: return "Thu nhập"
        case .account: return "Cập nhật số dư"
        case .transfer: return "Chuyển khoản"
        }
    }
}

struct Transaction: Codable, Identifiable {
    let id: String
    let date: String          // "YYYY-MM-DD"
    let type: TransactionType
    let categoryId: String?
    let accountId: String?
    let transferToId: String?
    let amount: Double
    let note: String?
    // CodingKeys not needed: server already sends camelCase aliases
}

struct CreateTransactionRequest: Encodable {
    let date: String
    let type: TransactionType
    let categoryId: String?
    let accountId: String?
    let transferToId: String?
    let amount: Double
    let note: String?
}

struct UpdateTransactionRequest: Encodable {
    let date: String
    let type: TransactionType
    let categoryId: String?
    let accountId: String?
    let transferToId: String?
    let amount: Double
    let note: String?
}
