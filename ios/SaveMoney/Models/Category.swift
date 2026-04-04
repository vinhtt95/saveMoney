import Foundation

enum CategoryType: String, Codable, CaseIterable {
    case expense = "Expense"
    case income = "Income"

    var label: String {
        switch self {
        case .expense: "Chi tiêu"
        case .income: "Thu nhập"
        }
    }
}

struct Category: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var type: CategoryType
}

struct CategoryCreateDTO: Encodable {
    var name: String
    var type: String
}

struct CategoryUpdateDTO: Encodable {
    var name: String
}
