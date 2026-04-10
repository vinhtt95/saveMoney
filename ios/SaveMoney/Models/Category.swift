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

    enum CodingKeys: String, CodingKey {
        case id, name, type, icon, color
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(CategoryType.self, forKey: .type)
        
        // Sử dụng decodeIfPresent để không bị crash nếu thiếu Key
        icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? "tag.fill"
        color = try container.decodeIfPresent(String.self, forKey: .color) ?? "accent"
    }
    
    // Đừng quên thêm init thông thường để các phần khác của app không lỗi
    init(id: String, name: String, type: CategoryType, icon: String, color: String) {
        self.id = id
        self.name = name
        self.type = type
        self.icon = icon
        self.color = color
    }
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
