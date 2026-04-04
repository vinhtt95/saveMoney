import Foundation

@Observable
@MainActor
final class GoldPriceService {
    static let shared = GoldPriceService()

    private(set) var prices: GoldPricesResponse?
    private(set) var isLoading = false
    private(set) var error: String?

    private init() { loadCache() }

    private func loadCache() {
        guard let data = UserDefaults.standard.data(forKey: Constants.goldPriceCacheKey),
              let cache = try? JSONDecoder().decode(GoldPriceCache.self, from: data),
              Date().timeIntervalSince(cache.cachedAt) < Constants.goldCacheTTL else { return }
        prices = cache.response
    }

    func fetchPrices(forceRefresh: Bool = false, api: APIService) async {
        if !forceRefresh, let prices, isCacheValid() {
            _ = prices
            return
        }
        isLoading = true
        error = nil
        do {
            let result = try await api.fetchGoldPrices()
            prices = result
            saveCache(result)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func isCacheValid() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: Constants.goldPriceCacheKey),
              let cache = try? JSONDecoder().decode(GoldPriceCache.self, from: data) else { return false }
        return Date().timeIntervalSince(cache.cachedAt) < Constants.goldCacheTTL
    }

    private func saveCache(_ response: GoldPricesResponse) {
        let cache = GoldPriceCache(response: response, cachedAt: Date())
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: Constants.goldPriceCacheKey)
        }
    }

    func items(for brand: GoldBrand) -> [GoldPriceItem] {
        prices?.items.filter { $0.brand == brand } ?? []
    }
}
