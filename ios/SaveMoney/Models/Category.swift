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
    var icon: String
    var color: String
}

struct CategoryCreateDTO: Encodable {
    var id: String
    var name: String
    var type: String
    var icon: String
    var color: String
}

struct CategoryUpdateDTO: Encodable {
    var name: String
    var icon: String
    var color: String
}
