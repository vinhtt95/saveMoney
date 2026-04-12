import SwiftUI

struct GoldView: View {
    @Environment(AppViewModel.self) private var app
    @State private var goldVM: GoldViewModel?
    @State private var selectedBrand: GoldBrand = .sjc
    @State private var isRefreshing = false
    
    // Namespace cho hiệu ứng chuyển Tab mượt mà (Matched Geometry)
    @Namespace private var animation
    
    private var vm: GoldViewModel { goldVM ?? GoldViewModel(app: app) }
    private var service: GoldPriceService { GoldPriceService.shared }
    
    var body: some View {
        ZStack {
            LiquiBackgroundViewNotAnimating()
            
            VStack(spacing: 5) {
                // 1. Top Tab Bar - Đưa lên trên cùng
                brandTopTabBar
                    .padding(.top, DSSpacing.sm)
                    .padding(.bottom, DSSpacing.md)
                
                // 2. Nội dung thay đổi theo Tab
                ScrollView {
                    LazyVStack(spacing: DSSpacing.md) {
                        if vm.goldService.isLoading && vm.goldService.prices == nil {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 200)
                        } else if let prices = vm.goldService.prices {
                            
                            // Tỷ giá USD/VND dạng Glass Card
                            usdRateCard(prices: prices)
                            
                            // Danh sách sản phẩm dựa trên Brand đã chọn
                            let currentItems = service.items(for: selectedBrand)
                            if !currentItems.isEmpty {
                                ForEach(currentItems) { item in
                                    GoldItemRowView(item: item)
                                }
                            } else {
                                EmptyStateView(icon: "mailbox.bolt.closed", title: "Không có dữ liệu", message: "Dữ liệu thương hiệu này hiện chưa sẵn sàng")
                            }
                            
                            Text("Cập nhật cuối: \(prices.fetchedAt ?? "Vừa xong")")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .padding(.top, DSSpacing.lg)
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
            }
        }
        .task { await vm.loadPrices() }
        .onAppear {
            if goldVM == nil { goldVM = GoldViewModel(app: app) }
        }
    }
    
    // MARK: - Components
    
    private var brandTopTabBar: some View {
        HStack(spacing: 0) {
            ForEach([GoldBrand.sjc, GoldBrand.btmc, GoldBrand.world], id: \.self) { brand in
                let label = brand == .sjc ? "SJC" : (brand == .btmc ? "BTMC" : "Thế giới")
                let isSelected = selectedBrand == brand
                
                Button {
                    withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                        selectedBrand = brand
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(label)
                            .font(.subheadline.weight(isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? .primary : .secondary)
                        
                        // Thanh gạch chân di chuyển mượt mà (Matched Geometry)
                        ZStack {
                            Capsule()
                                .fill(.clear)
                                .frame(height: 3)
                            if isSelected {
                                Capsule()
                                    .fill(DSColors.gold)
                                    .frame(height: 3)
                                    .matchedGeometryEffect(id: "activeTab", in: animation)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DSSpacing.lg)
    }
    
    @ViewBuilder
    private func usdRateCard(prices: GoldPricesResponse) -> some View {
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
        .liquidGlass(in: .rect(cornerRadius: DSRadius.md))
    }
}

// MARK: - Subview hiển thị danh sách theo Brand
private struct GoldPriceListView: View {
    let brand: GoldBrand
    let vm: GoldViewModel
    private var service: GoldPriceService { GoldPriceService.shared }
    
    var body: some View {
        ZStack {
            LiquiBackgroundViewNotAnimating()
            
            ScrollView {
                LazyVStack(spacing: DSSpacing.md) {
                    if vm.goldService.isLoading && vm.goldService.prices == nil {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let prices = vm.goldService.prices {
                        
                        // Tỷ giá USD/VND
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
                        .liquidGlass(in: .rect(cornerRadius: DSRadius.md))
                        
                        // Danh sách sản phẩm
                        let currentItems = service.items(for: brand)
                        if !currentItems.isEmpty {
                            ForEach(currentItems) { item in
                                GoldItemRowView(item: item)
                            }
                        } else {
                            EmptyStateView(icon: "mailbox.bolt.closed", title: "Không có dữ liệu", message: "Dữ liệu hiện chưa sẵn sàng")
                        }
                        
                        Text("Cập nhật cuối: \(prices.fetchedAt ?? "Vừa xong")")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, DSSpacing.lg)
                    } else if let error = vm.goldService.error {
                        ErrorBanner(message: error)
                    }
                }
                .padding(.horizontal, DSSpacing.lg)
                .padding(.top, DSSpacing.md)
            }
        }
    }
}

// MARK: - Gold Item Row
private struct GoldItemRowView: View {
    let item: GoldPriceItem
    
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            ZStack {
                Circle()
                    .fill(DSColors.gold.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "bitcoinsign.circle.fill")
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
        .liquidGlass(in: .rect(cornerRadius: DSRadius.md))
    }
}
