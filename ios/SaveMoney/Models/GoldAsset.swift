import Foundation

enum GoldBrand: String, Codable, CaseIterable {
    case sjc = "SJC"     // Khớp với "SJC" từ API
    case btmc = "BTMC"   // Khớp với "BTMC" từ API
    case world = "world" // Khớp với "world" từ API
    
    var label: String {
        switch self {
        case .sjc: return "SJC"
        case .btmc: return "Bảo Tín Minh Châu"
        case .world: return "Vàng thế giới"
        }
    }
}

struct GoldAsset: Identifiable, Codable, Equatable {
    var id: String
    var brand: GoldBrand
    var productId: String
    var productName: String
    var quantity: Double
    var note: String?
    var createdAt: String?
    var currentSellPrice: Double?
    var currentBuyPrice: Double?
}

struct GoldAssetCreateDTO: Encodable {
    var brand: String
    var productId: String
    var productName: String
    var quantity: Double
    var note: String?
}
