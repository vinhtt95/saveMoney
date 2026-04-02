import SwiftUI

struct WealthView: View {
    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var vm = GoldViewModel()
    @State private var showAddSheet = false

    private var totalGoldValueVND: Double {
        vm.totalValueVND(assets: appVM.goldAssets)
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text("Tổng giá trị vàng")
                            .font(.subheadline)
                        Spacer()
                        Text(Formatters.formatVND(totalGoldValueVND))
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundColor(.orange)
                    }
                    HStack {
                        Text("Tổng số dư tài khoản")
                            .font(.subheadline)
                        Spacer()
                        Text(Formatters.formatVND(appVM.totalBalance))
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundColor(.blue)
                    }
                    HStack {
                        Text("Tổng tài sản ròng")
                            .font(.headline)
                        Spacer()
                        Text(Formatters.formatVND(totalGoldValueVND + appVM.totalBalance))
                            .font(.headline.monospacedDigit())
                            .foregroundColor(.green)
                    }
                } header: { Text("Tổng quan") }

                Section {
                    if appVM.goldAssets.isEmpty {
                        Text("Chưa có tài sản vàng nào")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(appVM.goldAssets) { asset in
                            GoldAssetRow(asset: asset, vm: vm)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task { await vm.deleteAsset(id: asset.id, appVM: appVM) }
                                    } label: {
                                        Label("Xóa", systemImage: "trash")
                                    }
                                }
                        }
                    }
                } header: { Text("Tài sản vàng") }
            }
            .navigationTitle("Tài sản")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddGoldAssetView(vm: vm)
                    .environmentObject(appVM)
            }
            .refreshable { await appVM.reload() }
        }
    }
}

struct GoldAssetRow: View {
    let asset: GoldAsset
    let vm: GoldViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(asset.productName).font(.subheadline.bold())
                Spacer()
                Text(asset.brand.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
            }
            HStack {
                Text("\(String(format: "%.4f", asset.quantity)) lượng")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let price = vm.sellPrice(for: asset) {
                    Text(Formatters.formatVND(asset.quantity * price))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.orange)
                }
            }
            if let note = asset.note, !note.isEmpty {
                Text(note).font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddGoldAssetView: View {
    @EnvironmentObject var appVM: AppViewModel
    @ObservedObject var vm: GoldViewModel
    @Environment(\.dismiss) var dismiss

    @State private var brand: GoldBrand = .sjc
    @State private var productId = ""
    @State private var productName = ""
    @State private var quantity = ""
    @State private var note = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Thông tin") {
                    Picker("Thương hiệu", selection: $brand) {
                        ForEach(GoldBrand.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    TextField("Mã sản phẩm", text: $productId)
                    TextField("Tên sản phẩm", text: $productName)
                    TextField("Số lượng (lượng)", text: $quantity)
                        .keyboardType(.decimalPad)
                    TextField("Ghi chú (tùy chọn)", text: $note)
                }
                if let err = vm.submitError {
                    Section { Text(err).foregroundColor(.red).font(.caption) }
                }
            }
            .navigationTitle("Thêm tài sản vàng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Hủy") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lưu") { save() }
                        .disabled(vm.isSubmitting || productName.isEmpty || quantity.isEmpty)
                }
            }
        }
    }

    private func save() {
        let q = Double(quantity.replacingOccurrences(of: ",", with: ".")) ?? 0
        let pid = productId.isEmpty
            ? productName.lowercased().replacingOccurrences(of: " ", with: "_")
            : productId
        let body = CreateGoldAssetRequest(
            brand: brand,
            productId: pid,
            productName: productName,
            quantity: q,
            note: note.isEmpty ? nil : note
        )
        Task {
            await vm.createAsset(body, appVM: appVM)
            if vm.submitError == nil { dismiss() }
        }
    }
}
