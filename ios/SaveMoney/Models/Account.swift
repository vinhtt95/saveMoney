import Foundation

struct Account: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var icon: String
    var color: String
    var balance: Double
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon, color, balance
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        // Sử dụng decodeIfPresent để tương thích ngược với dữ liệu cũ
        icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? "creditcard.fill"
        color = try container.decodeIfPresent(String.self, forKey: .color) ?? "accent"
        balance = try container.decodeIfPresent(Double.self, forKey: .balance) ?? 0.0
    }
    
    init(id: String, name: String, icon: String, color: String, balance: Double) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.balance = balance
    }
}

struct AccountCreateDTO: Encodable {
    var name: String
    var initialBalance: Double?
    var icon: String
    var color: String
}

struct AccountUpdateDTO: Encodable {
    var name: String
    var balance: Double?
    var icon: String
    var color: String
}
