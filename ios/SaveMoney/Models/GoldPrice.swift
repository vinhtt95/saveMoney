import Foundation

struct GoldPriceItem: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var buyPrice: Double?
    var sellPrice: Double?
    var brand: GoldBrand
}

struct GoldPricesResponse: Codable {
    var items: [GoldPriceItem]
    var usdVnd: Double
    var fetchedAt: String
}

struct GoldPriceCache: Codable {
    var response: GoldPricesResponse
    var cachedAt: Date
}
