import SwiftUI

struct AddGoldAssetView: View {
    @Environment(AppViewModel.self) private var app
    let onDismiss: () -> Void

    @State private var goldVM: GoldViewModel?
    @State private var selectedBrand: GoldBrand = .sjc
    @State private var selectedItem: GoldPriceItem?
    @State private var quantityText = ""
    @State private var note = ""
    @State private var errorMessage: String?

    private var vm: GoldViewModel { goldVM ?? GoldViewModel(app: app) }
    private var brandItems: [GoldPriceItem] { GoldPriceService.shared.items(for: selectedBrand) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Thương hiệu") {
                    Picker("Thương hiệu", selection: $selectedBrand) {
                        ForEach(GoldBrand.allCases, id: \.self) { brand in
                            Text(brand.label).tag(brand)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedBrand) { _, _ in selectedItem = nil }
                }

                if !brandItems.isEmpty {
                    Section("Sản phẩm") {
                        Picker("Sản phẩm", selection: $selectedItem) {
                            Text("— Chọn —").tag(GoldPriceItem?.none)
                            ForEach(brandItems) { item in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name ?? "Không rõ tên") // Sửa lỗi String?
                                    if let sell = item.sellPrice {
                                        Text("Bán: \(formatVND(sell))/lượng")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .tag(GoldPriceItem?.some(item))
                            }
                        }
                        .pickerStyle(.inline)
                    }
                } else {
                    Section {
                        Text("Không có dữ liệu giá. Hãy tải giá vàng trước.")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }

                Section("Số lượng") {
                    HStack {
                        TextField("0", text: $quantityText)
                            .keyboardType(.decimalPad)
                        Text("lượng")
                            .foregroundStyle(.secondary)
                    }
                    if let qty = Double(quantityText), let item = selectedItem, let sell = item.sellPrice {
                        Text("Giá trị: \(formatVND(qty * sell))")
                            .font(.caption)
                            .foregroundStyle(DSColors.gold)
                    }
                }

                Section("Ghi chú") {
                    TextField("Không bắt buộc", text: $note)
                }

                if let errorMessage {
                    Section { ErrorBanner(message: errorMessage) }
                }
            }
            .navigationTitle("Thêm tài sản vàng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Hủy") { onDismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Thêm") {
                        Task { await handleSubmit() }
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedItem == nil || quantityText.isEmpty || vm.isSubmitting)
                }
            }
        }
        .task { await vm.loadPrices() }
        .onAppear {
            if goldVM == nil { goldVM = GoldViewModel(app: app) }
        }
    }

    private func handleSubmit() async {
        // Chỉ giải nén selectedItem và quantityText
        guard let item = selectedItem,
              let quantity = Double(quantityText) else { return }
        
        // item.id và item.name trong model GoldPriceItem hiện là String (không ?), dùng trực tiếp:
        await vm.addGoldAsset(
            brand: selectedBrand,
            productId: item.id,
            productName: item.name,
            quantity: quantity,
            note: note.isEmpty ? nil : note
        )
        
        if let err = vm.errorMessage {
            errorMessage = err
        } else {
            onDismiss()
        }
    }
}
