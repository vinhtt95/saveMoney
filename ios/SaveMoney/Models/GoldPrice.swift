import Foundation

struct GoldPriceItem: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var buyPrice: Double?
    var sellPrice: Double?
    var brand: GoldBrand? // Dùng Optional để không bị crash nếu API đổi tên brand

    enum CodingKeys: String, CodingKey {
        case id, name, brand
        case buyPrice = "buy_price"   // Ánh xạ từ buy_price của API
        case sellPrice = "sell_price" // Ánh xạ từ sell_price của API
    }
}

struct GoldPricesResponse: Codable {
    var items: [GoldPriceItem]?
    var usdVnd: Double?
    var fetchedAt: String?

    enum CodingKeys: String, CodingKey {
        case items
        case usdVnd = "usd_vnd"       // Ánh xạ từ usd_vnd của API
        case fetchedAt = "fetched_at" // Ánh xạ từ fetched_at của API
    }
}

struct GoldPriceCache: Codable {
    var response: GoldPricesResponse
    var cachedAt: Date
}
