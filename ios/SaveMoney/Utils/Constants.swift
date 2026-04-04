import Foundation

enum Constants {
    static let defaultBaseURL = "http://localhost:3001"
    static let goldCacheTTL: TimeInterval = 300 // 5 minutes
    static let pageSize = 20
    static let dashboardRecentCount = 10
    static let apiBaseURLKey = "api_base_url"
    static let goldPriceCacheKey = "gold_price_cache"
    static let themePreferenceKey = "theme_preference"
    // Gold conversion: 1 tael (lượng) = 37.5g = 1.2057 troy oz
    static let taelToGrams: Double = 37.5
    static let taelToTroyOz: Double = 1.2057
}

enum SettingsKey {
    static let defaultTransactionType = "default_transaction_type"
    static let defaultAccountId = "default_account_id"
    static let defaultExpenseCategoryId = "default_expense_category_id"
    static let defaultIncomeCategoryId = "default_income_category_id"
}
