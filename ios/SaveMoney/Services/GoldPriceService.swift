import Foundation

// Gold unit constants (BR-08)
// 1 lượng = 37.5g = 1.2057 troy oz
private let LUONG_TO_TROY_OZ = 1.2057
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
            // Fetch USD/VND rate
            let rate = await fetchUSDVND()
            usdVnd = rate

            // Fetch gold prices from backend proxies
            async let sjcItems = fetchSJC()
            async let btmcItems = fetchBTMC()
            async let worldItems = fetchWorldGold(usdVnd: rate)

            let all = try await [sjcItems, btmcItems, worldItems].flatMap { $0 }
            prices = all
            let cache = GoldPriceCache(items: all, fetchedAt: Date(), usdVnd: rate)
            saveCache(cache)
            lastFetchedAt = cache.fetchedAt
        } catch {
            lastFetchError = error.localizedDescription
        }
    }

    // MARK: - Private helpers

    private func fetchUSDVND() async -> Double {
        // Try backend proxy; fallback to constant (BR-16)
        struct FXResponse: Decodable { let rates: [String: Double] }
        do {
            let resp: FXResponse = try await api.request("/api/fx?base=USD")
            return resp.rates["VND"] ?? Constants.fallbackUSDVND
        } catch {
            return Constants.fallbackUSDVND
        }
    }

    private func fetchSJC() async throws -> [GoldPriceItem] {
        struct SJCRow: Decodable {
            let id: String
            let name: String
            let buy: Double?
            let sell: Double?
        }
        struct SJCResp: Decodable { let data: [SJCRow] }
        do {
            let resp: SJCResp = try await api.request("/api/sjc")
            return resp.data.map {
                GoldPriceItem(id: "sjc_\($0.id)", name: $0.name, buyPrice: $0.buy, sellPrice: $0.sell, brand: .sjc)
            }
        } catch {
            return []
        }
    }

    private func fetchBTMC() async throws -> [GoldPriceItem] {
        struct BTMCRow: Decodable {
            let id: String
            let name: String
            let buy: Double?
            let sell: Double?
        }
        struct BTMCResp: Decodable { let data: [BTMCRow] }
        do {
            let resp: BTMCResp = try await api.request("/api/btmc")
            return resp.data.map {
                GoldPriceItem(id: "btmc_\($0.id)", name: $0.name, buyPrice: $0.buy, sellPrice: $0.sell, brand: .btmc)
            }
        } catch {
            return []
        }
    }

    private func fetchWorldGold(usdVnd: Double) async throws -> [GoldPriceItem] {
        struct YahooQuote: Decodable {
            let regularMarketPrice: Double?
        }
        struct YahooResult: Decodable { let result: [YahooQuote]? }
        struct YahooResp: Decodable { let quoteResponse: YahooResult }

        do {
            let resp: YahooResp = try await api.request("/api/gold-futures")
            let pricePerOz = resp.quoteResponse.result?.first?.regularMarketPrice ?? 0
            let pricePerLuong = pricePerOz * LUONG_TO_TROY_OZ * usdVnd
            return [
                GoldPriceItem(
                    id: "world_xauusd",
                    name: "Vàng thế giới (XAUUSD)",
                    buyPrice: pricePerLuong,
                    sellPrice: pricePerLuong,
                    brand: .world
                )
            ]
        } catch {
            return []
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
