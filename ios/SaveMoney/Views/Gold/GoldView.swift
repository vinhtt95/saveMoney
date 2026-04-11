import SwiftUI

struct GoldView: View {
    @Environment(AppViewModel.self) private var app
    @State private var goldVM: GoldViewModel?
    @State private var selectedBrand: GoldBrand = .sjc
    @State private var isRefreshing = false
    
    // Namespace cho hiệu ứng chuyển tab mượt mà
    @Namespace private var animation
    
    private var vm: GoldViewModel { goldVM ?? GoldViewModel(app: app) }
    private var service: GoldPriceService { GoldPriceService.shared }

    var body: some View {
        ZStack {
            // Nền Liquid mượt mà
            LiquiBackgroundViewNotAnimating()
            
            VStack(spacing: 0) {
                // Tab chọn Brand theo phong cách Liquid
                brandPicker
                    .padding(.vertical, DSSpacing.md)
                
                ScrollView {
                    LazyVStack(spacing: DSSpacing.md) {
                        if vm.goldService.isLoading && vm.goldService.prices == nil {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 200)
                        } else if let prices = vm.goldService.prices {
                            
                            // Hiển thị tỷ giá USD/VND dạng Glass Card
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundStyle(DSColors.gold)
                                Text("Tỷ giá USD/VND")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(formatVND(prices.usdVnd ?? 0))
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(DSColors.gold)
                            }
                            .padding(DSSpacing.md)
                            .liquidGlass(in: .rect(cornerRadius: DSRadius.md)) // Sử dụng modifier custom
                            
                            // Danh sách sản phẩm theo Brand đã chọn
                            let currentItems = service.items(for: selectedBrand)
                            if !currentItems.isEmpty {
                                ForEach(currentItems) { item in
                                    GoldItemRowView(item: item)
                                }
                            } else {
                                EmptyStateView(icon: " mailbox.bolt.closed", title: "Không có dữ liệu", message: "Dữ liệu thương hiệu này hiện chưa sẵn sàng")
                            }

                            Text("Cập nhật cuối: \(prices.fetchedAt ?? "Vừa xong")")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .padding(.top, DSSpacing.lg)
                        } else if let error = vm.goldService.error {
                            ErrorBanner(message: error)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, DSSpacing.lg)
                }
            }
        }
        .navigationTitle("Giá vàng")
        .navigationBarTitleDisplayMode(.inline)
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
                .sensoryFeedback(.impact, trigger: isRefreshing) // iOS 18 Haptic
            }
        }
        .task { await vm.loadPrices() }
        .onAppear {
            if goldVM == nil { goldVM = GoldViewModel(app: app) }
        }
    }
    
    // Bộ chọn Brand dạng Tab
    private var brandPicker: some View {
        HStack(spacing: DSSpacing.sm) {
            ForEach([GoldBrand.sjc, GoldBrand.btmc, GoldBrand.world], id: \.self) { brand in
                let label = brand == .sjc ? "SJC" : (brand == .btmc ? "BTMC" : "Thế giới")
                let isSelected = selectedBrand == brand
                
                Button {
                    withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                        selectedBrand = brand
                    }
                } label: {
                    Text(label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .matchedGeometryEffect(id: "brandTab", in: animation)
                                    .liquidGlass(in: Capsule()) // Hiệu ứng iOS 18
                            }
                        }
                }
                .buttonStyle(LiquidButtonStyle()) // Hiệu ứng nhấn nhún
            }
        }
        .padding(4)
        .background(.black.opacity(0.05))
        .clipShape(Capsule())
    }
}

// MARK: - Gold Item Row (Dựa trên TransactionRowView)
private struct GoldItemRowView: View {
    let item: GoldPriceItem
    
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            // Icon bên trái tương tự CategoryIconView
            ZStack {
                Circle()
                    .fill(DSColors.gold.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "bitcoinsign.circle.fill") // Hoặc icon vàng
                    .font(.system(size: 18))
                    .foregroundStyle(DSColors.gold)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                
                HStack(spacing: DSSpacing.xs) {
                    Text("Bán ra:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(item.sellPrice.map { formatVNDShort($0) } ?? "—")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Giá bán hiển thị nổi bật như số tiền giao dịch
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.buyPrice.map { formatVNDShort($0) } ?? "—")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(DSColors.gold)
                Text("Mua")
                    .font(.system(size: 8, weight: .bold))
                    .textCase(.uppercase)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(DSColors.gold.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(DSSpacing.md)
        .liquidGlass(in: .rect(cornerRadius: DSRadius.md)) // Áp dụng Liquid Glass toàn diện
    }
}
