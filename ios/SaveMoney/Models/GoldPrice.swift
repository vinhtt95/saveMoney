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

struct GoldHistoryPoint: Codable, Identifiable {
    let id: String    // "YYYY-MM-DD"
    let price: Double // VND per luong
    let brand: GoldBrand
}
