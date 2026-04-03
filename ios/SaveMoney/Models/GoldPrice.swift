import Foundation

struct GoldPriceItem: Codable, Identifiable {
    let id: String
    let name: String
    let buyPrice: Double?
    let sellPrice: Double?
    let brand: GoldBrand

    enum CodingKeys: String, CodingKey {
        case id, name, brand
        case buyPrice = "buy_price"
        case sellPrice = "sell_price"
    }
}

struct GoldPriceCache: Codable {
    let items: [GoldPriceItem]
    let fetchedAt: Date
    let usdVnd: Double
}

/// Response from GET /api/gold-prices (backend-stored cache saved by the web app).
struct GoldPricesResponse: Decodable {
    let items: [GoldPriceItem]
    let usdVnd: Double
    let fetchedAt: String   // ISO 8601 string

    enum CodingKeys: String, CodingKey {
        case items
        case usdVnd = "usd_vnd"
        case fetchedAt = "fetched_at"
    }
}

struct GoldHistoryPoint: Codable, Identifiable {
    let id: String    // "YYYY-MM-DD"
    let price: Double // VND per luong
    let brand: GoldBrand
}
