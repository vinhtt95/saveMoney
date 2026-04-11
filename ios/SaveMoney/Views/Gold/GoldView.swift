import SwiftUI

struct GoldView: View {
    @Environment(AppViewModel.self) private var app
    @State private var goldVM: GoldViewModel?
    @State private var isRefreshing = false

    private var vm: GoldViewModel { goldVM ?? GoldViewModel(app: app) }
    private var service: GoldPriceService { GoldPriceService.shared }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: DSSpacing.lg) {
                if vm.goldService.isLoading && vm.goldService.prices == nil {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let prices = vm.goldService.prices {
                    // USD/VND Rate
                    HStack {
                        Text("USD/VND")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(formatVND(prices.usdVnd ?? 0)) // Sửa lỗi Double?
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(DSColors.gold)
                    }
                    .padding(DSSpacing.md)
                    .glassEffect(.regular, in: .rect(cornerRadius: DSRadius.md))

                    let sjcItems = service.items(for: .sjc)
                    if !sjcItems.isEmpty {
                        GoldPriceSection(title: "SJC", items: sjcItems)
                    }

                    let btmcItems = service.items(for: .btmc)
                    if !btmcItems.isEmpty {
                        GoldPriceSection(title: "BTMC", items: btmcItems)
                    }

                    let worldItems = service.items(for: .world)
                    if !worldItems.isEmpty {
                        GoldPriceSection(title: "Vàng thế giới", items: worldItems)
                    }

                    Text("Cập nhật: \(prices.fetchedAt ?? "Vừa xong")") // Sửa lỗi String?
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let error = vm.goldService.error {
                    ErrorBanner(message: error)
                } else {
                    EmptyStateView(icon: "sun.max", title: "Không có dữ liệu", message: "Kiểm tra kết nối máy chủ")
                }
                Spacer(minLength: 80)
            }
            .padding(DSSpacing.lg)
        }
        .navigationTitle("Giá vàng")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        isRefreshing = true
                        await vm.loadPrices(forceRefresh: true)
                        isRefreshing = false
                    }
                } label: {
                    if isRefreshing { ProgressView().scaleEffect(0.8) }
                    else { Image(systemName: "arrow.clockwise") }
                }
            }
        }
        .task { await vm.loadPrices() }
        .onAppear {
            if goldVM == nil { goldVM = GoldViewModel(app: app) }
        }
    }
}

private struct GoldPriceSection: View {
    let title: String
    let items: [GoldPriceItem]

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text(title).font(.headline).padding(.horizontal, DSSpacing.xs)
            VStack(spacing: 1) {
                HStack {
                    Text("Sản phẩm").font(.caption.weight(.semibold)).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                    Text("Mua").font(.caption.weight(.semibold)).foregroundStyle(.secondary).frame(width: 100, alignment: .trailing)
                    Text("Bán").font(.caption.weight(.semibold)).foregroundStyle(.secondary).frame(width: 100, alignment: .trailing)
                }
                .padding(.horizontal, DSSpacing.md).padding(.bottom, DSSpacing.xs)

                ForEach(items) { item in
                    HStack {
                        Text(item.name) // Sửa lỗi String?
                            .font(.subheadline).lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                        Text(item.buyPrice.map { formatVNDShort($0) } ?? "—")
                            .font(.caption.monospacedDigit()).foregroundStyle(.secondary).frame(width: 100, alignment: .trailing)
                        Text(item.sellPrice.map { formatVNDShort($0) } ?? "—")
                            .font(.caption.monospacedDigit()).foregroundStyle(DSColors.gold).frame(width: 100, alignment: .trailing)
                    }
                    .padding(DSSpacing.md)
                    .glassEffect(.regular, in: .rect(cornerRadius: DSRadius.sm))
                }
            }
        }
    }
}
