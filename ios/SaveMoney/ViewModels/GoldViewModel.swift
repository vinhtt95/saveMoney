import Foundation

@MainActor
class GoldViewModel: ObservableObject {
    @Published var isSubmitting = false
    @Published var submitError: String?

    let goldPriceService = GoldPriceService.shared
    private let api = APIService.shared

    func totalValueVND(assets: [GoldAsset]) -> Double {
        assets.reduce(0) { sum, asset in
            let price = sellPrice(for: asset)
            return sum + asset.quantity * (price ?? 0)
        }
    }

    func sellPrice(for asset: GoldAsset) -> Double? {
        goldPriceService.prices
            .first { $0.brand == asset.brand && $0.id.contains(asset.productId) }?
            .sellPrice
    }

    func createAsset(_ body: CreateGoldAssetRequest, appVM: AppViewModel) async {
        isSubmitting = true
        submitError = nil
        do {
            let asset = try await api.createGoldAsset(body)
            appVM.goldAssets.append(asset)
        } catch {
            submitError = error.localizedDescription
        }
        isSubmitting = false
    }

    func deleteAsset(id: String, appVM: AppViewModel) async {
        do {
            try await api.deleteGoldAsset(id: id)
            appVM.goldAssets.removeAll { $0.id == id }
        } catch {
            submitError = error.localizedDescription
        }
    }
}
