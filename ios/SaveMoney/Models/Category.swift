import Foundation

enum CategoryType: String, Codable, CaseIterable {
    case expense = "Expense"
    case income = "Income"

    var displayName: String {
        switch self {
        case .expense: return "Chi tiêu"
        case .income: return "Thu nhập"
        }
    }
}

struct Category: Codable, Identifiable {
    let id: String
    let name: String
    let type: CategoryType
}

struct CreateCategoryRequest: Encodable {
    let name: String
    let type: CategoryType
}
