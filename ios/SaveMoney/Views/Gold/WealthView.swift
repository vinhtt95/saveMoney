import SwiftUI

struct WealthView: View {
    @Environment(AppViewModel.self) private var app
    @State private var goldVM: GoldViewModel?
    @State private var showAddAsset = false

    private var vm: GoldViewModel { goldVM ?? GoldViewModel(app: app) }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: DSSpacing.lg) {
                // Net Worth Hero
                VStack(spacing: DSSpacing.sm) {
                    Text("Tài sản ròng")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatVND(app.netWorth))
                        .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(DSColors.gold)
                }
                .frame(maxWidth: .infinity)
                .padding(DSSpacing.xl)
                .glassEffect(.regular.tint(DSColors.gold.opacity(0.08)), in: .rect(cornerRadius: DSRadius.xl))

                // Breakdown Cards
                HStack(spacing: DSSpacing.md) {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Label("Tiền mặt", systemImage: "creditcard.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(formatVNDShort(app.totalBalance))
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(DSColors.positive)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(DSSpacing.md)
                    .glassEffect(.regular, in: .rect(cornerRadius: DSRadius.md))

                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Label("Vàng", systemImage: "star.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(formatVNDShort(app.totalGoldValue))
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(DSColors.gold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(DSSpacing.md)
                    .glassEffect(.regular.tint(DSColors.gold.opacity(0.05)), in: .rect(cornerRadius: DSRadius.md))
                }

                // Gold Assets List
                if !app.goldAssets.isEmpty {
                    DSSection(title: "Danh sách vàng") {
                        VStack(spacing: DSSpacing.sm) {
                            ForEach(app.goldAssets) { asset in
                                GoldAssetRow(asset: asset, vm: vm)
                            }
                        }
                    }
                } else {
                    EmptyStateView(
                        icon: "star",
                        title: "Chưa có tài sản vàng",
                        message: "Thêm tài sản vàng để theo dõi giá trị"
                    )
                }

                Spacer(minLength: 80)
            }
            .padding(DSSpacing.lg)
        }
        .navigationTitle("Tài sản ròng")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddAsset = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(DSColors.accent)
                }
            }
        }
        .sheet(isPresented: $showAddAsset) {
            AddGoldAssetView { showAddAsset = false }
        }
        .task { await vm.loadPrices() }
        .onAppear {
            if goldVM == nil { goldVM = GoldViewModel(app: app) }
        }
    }
}

private struct GoldAssetRow: View {
    let asset: GoldAsset
    let vm: GoldViewModel

    var body: some View {
        HStack(spacing: DSSpacing.md) {
            ZStack {
                Circle()
                    .fill(DSColors.gold.opacity(0.15))
                    .frame(width: 40, height: 40)
                Text(asset.brand.label.prefix(1))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(DSColors.gold)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(asset.productName)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: DSSpacing.xs) {
                    Text(asset.brand.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text("\(String(format: "%.2f", asset.quantity)) lượng")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let note = asset.note, !note.isEmpty {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(formatVNDShort(vm.currentValue(asset: asset)))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(DSColors.gold)
        }
        .padding(DSSpacing.md)
        .glassEffect(.regular.tint(DSColors.gold.opacity(0.03)), in: .rect(cornerRadius: DSRadius.md))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { await vm.deleteGoldAsset(asset.id) }
            } label: {
                Label("Xóa", systemImage: "trash")
            }
        }
    }
}
