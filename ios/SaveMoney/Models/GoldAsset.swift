import Foundation

enum GoldBrand: String, Codable, CaseIterable {
    case sjc = "SJC"
    case btmc = "BTMC"
    case world = "World"

    var label: String {
        switch self {
        case .sjc: "SJC"
        case .btmc: "BTMC"
        case .world: "Thế giới"
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
}

struct GoldAssetCreateDTO: Encodable {
    var brand: String
    var productId: String
    var productName: String
    var quantity: Double
    var note: String?
}
