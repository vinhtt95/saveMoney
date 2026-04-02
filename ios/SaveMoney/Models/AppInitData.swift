import Foundation

struct AppInitData: Codable {
    let transactions: [Transaction]
    let categories: [Category]
    let accounts: [Account]
    let accountBalances: [String: Double]   // account_id -> balance
    let budgets: [Budget]
    let goldAssets: [GoldAsset]
    let settings: [String: String]
}
