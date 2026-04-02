import Foundation

enum Constants {
    // Gold unit (BR-08)
    static let luongToGrams: Double = 37.5
    static let luongToTroyOz: Double = 1.2057

    // Fallback exchange rate (BR-16)
    static let fallbackUSDVND: Double = 25_400

    // Cache
    static let goldPriceCacheTTL: TimeInterval = 5 * 60  // 5 minutes (BR-09)

    // Pagination
    static let transactionPageSize = 20
}
