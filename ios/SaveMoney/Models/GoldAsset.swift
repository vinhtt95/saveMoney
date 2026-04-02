import Foundation

enum GoldBrand: String, Codable, CaseIterable {
    case sjc = "SJC"
    case btmc = "BTMC"
    case world = "world"

    var displayName: String {
        switch self {
        case .sjc: return "SJC"
        case .btmc: return "BTMC"
        case .world: return "Vàng thế giới"
        }
    }
}

struct GoldAsset: Codable, Identifiable {
    let id: String
    let brand: GoldBrand
    let productId: String
    let productName: String
    let quantity: Double
    let note: String?
    let createdAt: String?
}

struct CreateGoldAssetRequest: Encodable {
    let brand: GoldBrand
    let productId: String
    let productName: String
    let quantity: Double
    let note: String?
}
