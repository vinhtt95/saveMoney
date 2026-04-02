import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var appVM: AppViewModel
    @ObservedObject var vm: TransactionViewModel
    @Environment(\.dismiss) var dismiss

    @State private var type: TransactionType = .expense
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var selectedCategoryId: String? = nil
    @State private var selectedAccountId: String? = nil
    @State private var selectedTransferToId: String? = nil
    @State private var note: String = ""

    private var filteredCategories: [Category] {
        type == .expense ? appVM.expenseCategories : appVM.incomeCategories
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Loại giao dịch") {
                    Picker("Loại", selection: $type) {
                        ForEach([TransactionType.expense, .income, .transfer, .account], id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Chi tiết") {
                    TextField("Số tiền (VND)", text: $amount)
                        .keyboardType(.numberPad)

                    DatePicker("Ngày", selection: $date, displayedComponents: .date)

                    if type == .expense || type == .income {
                        Picker("Danh mục", selection: $selectedCategoryId) {
                            Text("Chọn danh mục").tag(Optional<String>(nil))
                            ForEach(filteredCategories) { cat in
                                Text(cat.name).tag(Optional(cat.id))
                            }
                        }
                    }

                    Picker("Tài khoản", selection: $selectedAccountId) {
                        Text("Chọn tài khoản").tag(Optional<String>(nil))
                        ForEach(appVM.accounts) { acc in
                            Text(acc.name).tag(Optional(acc.id))
                        }
                    }

                    if type == .transfer {
                        Picker("Tài khoản đích", selection: $selectedTransferToId) {
                            Text("Chọn tài khoản").tag(Optional<String>(nil))
                            ForEach(appVM.accounts) { acc in
                                Text(acc.name).tag(Optional(acc.id))
                            }
                        }
                    }

                    TextField("Ghi chú (tùy chọn)", text: $note)
                }

                if let err = vm.submitError {
                    Section {
                        Text(err).foregroundColor(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Thêm giao dịch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lưu") { save() }
                        .disabled(vm.isSubmitting || amount.isEmpty)
                }
            }
        }
    }

    private func save() {
        let parsedAmount = Double(amount.replacingOccurrences(of: ",", with: "")) ?? 0
        let signedAmount = type == .expense ? -abs(parsedAmount) : abs(parsedAmount)
        let body = CreateTransactionRequest(
            date: Formatters.toDateString(date),
            type: type,
            categoryId: selectedCategoryId,
            accountId: selectedAccountId,
            transferToId: selectedTransferToId,
            amount: signedAmount,
            note: note.isEmpty ? nil : note
        )
        Task {
            await vm.create(body, appVM: appVM)
            if vm.submitError == nil { dismiss() }
        }
    }
}
