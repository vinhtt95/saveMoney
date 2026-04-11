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
        guard let prices = goldService.prices, let items = prices.items else { return 0 }
        return app.goldAssets.reduce(0) { sum, asset in
            let price = items.first { $0.id == asset.productId }?.buyPrice ?? asset.currentSellPrice ?? 0
            return sum + price * asset.quantity
        }
    }

    func currentValue(asset: GoldAsset) -> Double {
        var price: Double = 0.0
        
        // Sử dụng dữ liệu từ Service thay vì parse thủ công để đồng nhất logic
        if let items = goldService.prices?.items,
           let matchedItem = items.first(where: { $0.id == asset.productId }) {
            price = matchedItem.buyPrice ?? 0.0
        } else if let fallbackPrice = asset.currentBuyPrice {
            price = fallbackPrice
        }
        
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
