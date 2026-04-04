import Foundation

struct AppInitData: Codable {
    var transactions: [Transaction]
    var categories: [Category]
    var accounts: [Account]
    var accountBalances: [String: Double]
    var budgets: [Budget]
    var goldAssets: [GoldAsset]
    var settings: [String: String]
}
