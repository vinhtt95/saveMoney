import Foundation

@Observable
@MainActor
final class GoldViewModel {
    var isSubmitting = false
    var errorMessage: String?

    private let app: AppViewModel
    let goldService = GoldPriceService.shared

    init(app: AppViewModel) {
        self.app = app
    }

    func loadPrices(forceRefresh: Bool = false) async {
        await goldService.fetchPrices(forceRefresh: forceRefresh, api: app.api)
    }

    func totalGoldValue() -> Double {
        guard let prices = goldService.prices else { return 0 }
        return app.goldAssets.reduce(0) { sum, asset in
            let price = prices.items.first { $0.id == asset.productId }?.buyPrice ?? asset.currentSellPrice ?? 0
            return sum + price * asset.quantity
        }
    }

    func currentValue(asset: GoldAsset) -> Double {
        // Tạo cấu trúc nội bộ để đọc JSON (tránh đụng chạm đến các file model khác)
        struct CacheData: Codable {
            struct Item: Codable {
                var id: String
                var buy_price: Double
                var sell_price: Double
            }
            var items: [Item]
        }
        
        var price: Double = 0.0
        
        // 1. Parse giá trị trực tiếp từ chuỗi cache mới nhất trong settings
        if let cacheString = app.settings["goldPriceCache"],
           let data = cacheString.data(using: .utf8),
           let cache = try? JSONDecoder().decode(CacheData.self, from: data),
           let matchedItem = cache.items.first(where: { $0.id == asset.productId }) {
            
            // Tìm thấy -> Lấy giá MUA (buy_price)
            price = matchedItem.buy_price
        }
        // 2. Fallback: Nếu không đọc được cache, dùng giá đã lưu ở local (currentBuyPrice)
        else if let fallbackPrice = asset.currentBuyPrice {
            price = fallbackPrice
        }
        
        // 3. Tính tổng giá trị
        return price * asset.quantity
    }

    func addGoldAsset(brand: GoldBrand, productId: String, productName: String, quantity: Double, note: String?) async {
        isSubmitting = true
        errorMessage = nil
        let dto = GoldAssetCreateDTO(
            brand: brand.rawValue,
            productId: productId,
            productName: productName,
            quantity: quantity,
            note: note?.isEmpty == true ? nil : note
        )
        do {
            try await app.addGoldAsset(dto)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }

    func deleteGoldAsset(_ id: String) async {
        do {
            try await app.deleteGoldAsset(id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
