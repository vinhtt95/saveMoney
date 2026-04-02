import SwiftUI

struct GoldView: View {
    @StateObject private var goldService = GoldPriceService.shared
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ZStack {
            DSMeshBackground().ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Giá vàng")
                                .font(.dsDisplay(28))
                                .foregroundStyle(Color.dsOnSurface(for: scheme))
                            if let fetchedAt = goldService.lastFetchedAt {
                                Text("Cập nhật: \(Formatters.formatDateTime(fetchedAt))")
                                    .font(.dsBody(11))
                                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                            }
                        }
                        Spacer()
                        Button {
                            Task { await goldService.fetchFresh() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.dsPrimary(for: scheme))
                                .frame(width: 36, height: 36)
                                .background {
                                    Circle()
                                        .fill(scheme == .dark
                                              ? AnyShapeStyle(.ultraThinMaterial)
                                              : AnyShapeStyle(Color.dsSurfaceLight))
                                }
                        }
                        .disabled(goldService.isFetching)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    if goldService.isFetching {
                        GlassCard(radius: DSRadius.md, padding: 20) {
                            HStack(spacing: 10) {
                                ProgressView().tint(Color.dsPrimary(for: scheme))
                                Text("Đang tải giá vàng...")
                                    .font(.dsBody(14))
                                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                            }
                        }
                        .padding(.horizontal, 20)
                    } else if let err = goldService.lastFetchError {
                        GlassCard(radius: DSRadius.md, padding: 16) {
                            Text("Lỗi: \(err)")
                                .font(.dsBody(12))
                                .foregroundStyle(Color.dsExpense)
                        }
                        .padding(.horizontal, 20)
                    }

                    // USD/VND rate
                    GlassCard(radius: DSRadius.lg, padding: 14) {
                        HStack {
                            GradientCircleIcon(systemName: "dollarsign.circle.fill",
                                               colors: [Color(hex: "#60a5fa"), Color(hex: "#3b82f6")],
                                               size: 36)
                            Text("Tỷ giá USD/VND")
                                .font(.dsBody(14))
                                .foregroundStyle(Color.dsOnSurface(for: scheme))
                            Spacer()
                            Text(Formatters.formatVNDShort(goldService.usdVnd))
                                .font(.dsTitle(15))
                                .foregroundStyle(Color.dsPrimary(for: scheme))
                        }
                    }
                    .padding(.horizontal, 20)

                    goldSection("SJC", brand: .sjc,
                                colors: [Color(hex: "#fbbf24"), Color(hex: "#f97316")])
                    goldSection("BTMC", brand: .btmc,
                                colors: [Color(hex: "#fbbf24"), Color(hex: "#f59e0b")])
                    goldSection("Vàng thế giới", brand: .world,
                                colors: [Color(hex: "#c799ff"), Color(hex: "#4af8e3")])

                    Spacer(minLength: 20)
                }
            }
        }
        .navigationTitle("Giá vàng")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .task { await goldService.fetchIfNeeded() }
    }

    private func goldSection(_ title: String, brand: GoldBrand, colors: [Color]) -> some View {
        let items = goldService.prices.filter { $0.brand == brand }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                GradientCircleIcon(systemName: "circle.fill", colors: colors, size: 28)
                Text(title)
                    .font(.dsTitle(16))
                    .foregroundStyle(Color.dsOnSurface(for: scheme))
            }
            .padding(.horizontal, 20)

            if items.isEmpty {
                Text("Không có dữ liệu")
                    .font(.dsBody(13))
                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                    .padding(.horizontal, 20)
            } else {
                ForEach(items) { item in
                    GoldPriceRow(item: item)
                        .padding(.horizontal, 20)
                }
            }
        }
    }
}
