import Foundation

private let CACHE_TTL: TimeInterval = 5 * 60 // 5 minutes (BR-09)
private let CACHE_KEY = "gold_price_cache"

@MainActor
class GoldPriceService: ObservableObject {
    static let shared = GoldPriceService()

    @Published var prices: [GoldPriceItem] = []
    @Published var usdVnd: Double = Constants.fallbackUSDVND
    @Published var isFetching = false
    @Published var lastFetchError: String?
    @Published var lastFetchedAt: Date?

    private let api = APIService.shared

    func fetchIfNeeded() async {
        if let cached = loadCache(), Date().timeIntervalSince(cached.fetchedAt) < CACHE_TTL {
            prices = cached.items
            usdVnd = cached.usdVnd
            lastFetchedAt = cached.fetchedAt
            return
        }
        await fetchFresh()
    }

    func fetchFresh() async {
        isFetching = true
        lastFetchError = nil
        defer { isFetching = false }

        do {
            let resp = try await api.getGoldPrices()
            prices = resp.items
            usdVnd = resp.usdVnd
            let fetchedAt = ISO8601DateFormatter().date(from: resp.fetchedAt) ?? Date()
            let cache = GoldPriceCache(items: resp.items, fetchedAt: fetchedAt, usdVnd: resp.usdVnd)
            saveCache(cache)
            lastFetchedAt = fetchedAt
        } catch {
            lastFetchError = error.localizedDescription
        }
    }

    // MARK: - Cache

    private func loadCache() -> GoldPriceCache? {
        guard let data = UserDefaults.standard.data(forKey: CACHE_KEY) else { return nil }
        return try? JSONDecoder().decode(GoldPriceCache.self, from: data)
    }

    private func saveCache(_ cache: GoldPriceCache) {
        let data = try? JSONEncoder().encode(cache)
        UserDefaults.standard.set(data, forKey: CACHE_KEY)
    }
}
