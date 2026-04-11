import Foundation

@Observable
@MainActor
final class GoldPriceService {
    static let shared = GoldPriceService()
    private(set) var prices: GoldPricesResponse?
    private(set) var isLoading = false
    private(set) var error: String?

    private init() { loadCache() }

    func fetchPrices(forceRefresh: Bool = false, api: APIService) async {
        if !forceRefresh, prices != nil, isCacheValid() { return }
        isLoading = true
        error = nil
        do {
            let result = try await api.fetchGoldPrices()
            self.prices = result
            saveCache(result)
        } catch {
            print("❌ GoldPriceService Error: \(error)")
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func items(for brand: GoldBrand) -> [GoldPriceItem] {
        return prices?.items?.filter { $0.brand == brand } ?? []
    }

    private func isCacheValid() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: Constants.goldPriceCacheKey),
              let cache = try? JSONDecoder().decode(GoldPriceCache.self, from: data) else { return false }
        return Date().timeIntervalSince(cache.cachedAt) < Constants.goldCacheTTL
    }

    private func loadCache() {
        if let data = UserDefaults.standard.data(forKey: Constants.goldPriceCacheKey),
           let cache = try? JSONDecoder().decode(GoldPriceCache.self, from: data) {
            prices = cache.response
        }
    }

    private func saveCache(_ response: GoldPricesResponse) {
        let cache = GoldPriceCache(response: response, cachedAt: Date())
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: Constants.goldPriceCacheKey)
        }
    }
}
