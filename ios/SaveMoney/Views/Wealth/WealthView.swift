import SwiftUI

struct WealthView: View {
    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var vm = GoldViewModel()
    @State private var showAddSheet = false
    @Environment(\.colorScheme) var scheme

    private var totalGoldValueVND: Double {
        vm.totalValueVND(assets: appVM.goldAssets)
    }

    var body: some View {
        ZStack {
            DSMeshBackground().ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Net worth hero
                    GlassCard(radius: DSRadius.xl, padding: 0) {
                        VStack(spacing: 0) {
                            ZStack {
                                RoundedRectangle(cornerRadius: DSRadius.xl, style: .continuous)
                                    .fill(LinearGradient.dsCTAGradient(scheme: scheme))
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("TỔNG TÀI SẢN RÒNG")
                                        .font(.dsBody(10, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.75))
                                        .tracking(1.5)
                                    Text(Formatters.formatVND(totalGoldValueVND + appVM.totalBalance))
                                        .font(.dsDisplay(34))
                                        .foregroundStyle(.white)
                                        .minimumScaleFactor(0.6)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                            }

                            VStack(spacing: 0) {
                                wealthRow(icon: "circle.fill",
                                          colors: [Color(hex: "#fbbf24"), Color(hex: "#f97316")],
                                          label: "Tổng giá trị vàng",
                                          value: totalGoldValueVND,
                                          color: Color.dsGold)
                                Divider().opacity(0.15).padding(.horizontal, 16)
                                wealthRow(icon: "creditcard.fill",
                                          colors: [Color(hex: "#60a5fa"), Color(hex: "#3b82f6")],
                                          label: "Tổng số dư tài khoản",
                                          value: appVM.totalBalance,
                                          color: Color.dsIncome)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Gold assets
                    VStack(alignment: .leading, spacing: 12) {
                        DSSectionHeader(title: "Tài sản vàng")
                            .padding(.horizontal, 20)

                        if appVM.goldAssets.isEmpty {
                            GlassCard(radius: DSRadius.md, padding: 20) {
                                Text("Chưa có tài sản vàng nào")
                                    .font(.dsBody(14))
                                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(.horizontal, 20)
                        } else {
                            ForEach(appVM.goldAssets) { asset in
                                GoldAssetRow(asset: asset, vm: vm)
                                    .padding(.horizontal, 20)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            Task { await vm.deleteAsset(id: asset.id, appVM: appVM) }
                                        } label: {
                                            Label("Xóa", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }

                    Spacer(minLength: 20)
                }
            }
            .refreshable { await appVM.reload() }
        }
        .navigationTitle("Tài sản")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(LinearGradient.dsCTAGradient(scheme: scheme)))
                }
            }
        }
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .sheet(isPresented: $showAddSheet) {
            AddGoldAssetView(vm: vm).environmentObject(appVM)
        }
    }

    private func wealthRow(icon: String, colors: [Color], label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 12) {
            GradientCircleIcon(systemName: icon, colors: colors, size: 32)
            Text(label)
                .font(.dsBody(14))
                .foregroundStyle(Color.dsOnSurface(for: scheme))
            Spacer()
            Text(Formatters.formatVNDShort(value))
                .font(.dsTitle(14))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

struct GoldAssetRow: View {
    let asset: GoldAsset
    let vm: GoldViewModel
    @Environment(\.colorScheme) var scheme

    var body: some View {
        GlassCard(radius: DSRadius.md, padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(asset.productName)
                        .font(.dsTitle(14))
                        .foregroundStyle(Color.dsOnSurface(for: scheme))
                        .lineLimit(1)
                    Spacer()
                    Text(asset.brand.displayName)
                        .font(.dsBody(11, weight: .semibold))
                        .foregroundStyle(Color.dsGold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.dsGold.opacity(0.15)))
                }
                HStack {
                    Text(String(format: "%.4f lượng", asset.quantity))
                        .font(.dsBody(12))
                        .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                    Spacer()
                    if let price = vm.sellPrice(for: asset) {
                        Text(Formatters.formatVNDShort(asset.quantity * price))
                            .font(.dsTitle(14))
                            .foregroundStyle(Color.dsGold)
                    }
                }
                if let note = asset.note, !note.isEmpty {
                    Text(note)
                        .font(.dsBody(11))
                        .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                }
            }
        }
    }
}

struct AddGoldAssetView: View {
    @EnvironmentObject var appVM: AppViewModel
    @ObservedObject var vm: GoldViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var scheme

    @State private var brand: GoldBrand = .sjc
    @State private var productId = ""
    @State private var productName = ""
    @State private var quantity = ""
    @State private var note = ""

    var body: some View {
        NavigationView {
            ZStack {
                DSMeshBackground().ignoresSafeArea()
                VStack(spacing: 16) {
                    GlassCard(radius: DSRadius.lg, padding: 16) {
                        VStack(spacing: 14) {
                            HStack {
                                Text("Thương hiệu")
                                    .font(.dsBody(14))
                                    .foregroundStyle(Color.dsOnSurface(for: scheme))
                                Spacer()
                                Picker("Thương hiệu", selection: $brand) {
                                    ForEach(GoldBrand.allCases, id: \.self) {
                                        Text($0.displayName).tag($0)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Color.dsPrimary(for: scheme))
                            }
                            GlassFormField(label: "Mã sản phẩm", text: $productId)
                            GlassFormField(label: "Tên sản phẩm", text: $productName)
                            GlassFormField(label: "Số lượng (lượng)", text: $quantity, keyboardType: .decimalPad)
                            GlassFormField(label: "Ghi chú", text: $note, placeholder: "Tuỳ chọn...")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    if let err = vm.submitError {
                        Text(err).font(.dsBody(12)).foregroundStyle(Color.dsExpense)
                            .padding(.horizontal, 20)
                    }

                    GlassPillButton(label: vm.isSubmitting ? "Đang lưu..." : "Lưu") {
                        save()
                    }
                    .disabled(vm.isSubmitting || productName.isEmpty || quantity.isEmpty)
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationTitle("Thêm tài sản vàng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") { dismiss() }
                        .foregroundStyle(Color.dsPrimary(for: scheme))
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }

    private func save() {
        let q = Double(quantity.replacingOccurrences(of: ",", with: ".")) ?? 0
        let pid = productId.isEmpty
            ? productName.lowercased().replacingOccurrences(of: " ", with: "_")
            : productId
        let body = CreateGoldAssetRequest(
            brand: brand, productId: pid, productName: productName,
            quantity: q, note: note.isEmpty ? nil : note
        )
        Task {
            await vm.createAsset(body, appVM: appVM)
            if vm.submitError == nil { dismiss() }
        }
    }
}
