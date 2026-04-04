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
            let price = prices.items.first { $0.id == asset.productId }?.sellPrice ?? asset.currentSellPrice ?? 0
            return sum + price * asset.quantity
        }
    }

    func currentValue(asset: GoldAsset) -> Double {
        let price = goldService.prices?.items.first { $0.id == asset.productId }?.sellPrice
            ?? asset.currentSellPrice ?? 0
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
