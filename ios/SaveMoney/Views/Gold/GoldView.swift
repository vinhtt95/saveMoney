import SwiftUI

struct GoldView: View {
    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var goldService = GoldPriceService.shared

    var body: some View {
        NavigationView {
            List {
                Section {
                    if goldService.isFetching {
                        HStack {
                            ProgressView()
                            Text("Đang tải giá vàng...").foregroundColor(.secondary)
                        }
                    } else if let err = goldService.lastFetchError {
                        Text("Lỗi: \(err)").foregroundColor(.red).font(.caption)
                    } else if let fetchedAt = goldService.lastFetchedAt {
                        Text("Cập nhật: \(Formatters.formatDateTime(fetchedAt))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("SJC") {
                    ForEach(goldService.prices.filter { $0.brand == .sjc }) { item in
                        GoldPriceRow(item: item)
                    }
                }

                Section("BTMC") {
                    ForEach(goldService.prices.filter { $0.brand == .btmc }) { item in
                        GoldPriceRow(item: item)
                    }
                }

                Section("Vàng thế giới") {
                    ForEach(goldService.prices.filter { $0.brand == .world }) { item in
                        GoldPriceRow(item: item)
                    }
                    HStack {
                        Text("Tỷ giá USD/VND")
                            .font(.subheadline)
                        Spacer()
                        Text(Formatters.formatVND(goldService.usdVnd))
                            .font(.subheadline.monospacedDigit())
                    }
                }
            }
            .navigationTitle("Giá vàng")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await goldService.fetchFresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(goldService.isFetching)
                }
            }
            .task { await goldService.fetchIfNeeded() }
        }
    }
}
