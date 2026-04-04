import SwiftUI

struct AddTransactionView: View {
    @Environment(AppViewModel.self) private var app
    let transaction: Transaction?
    let onDismiss: () -> Void

    @State private var type: TransactionType = .expense
    @State private var amountText = ""
    @State private var categoryId: String? = nil
    @State private var accountId: String? = nil
    @State private var transferToId: String? = nil
    @State private var date = Date()
    @State private var note = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var isEditMode: Bool { transaction != nil }

    private var title: String { isEditMode ? "Sửa giao dịch" : "Thêm giao dịch" }

    private var amount: Double { Double(amountText.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: ".", with: "")) ?? 0 }

    private var availableCategories: [Category] {
        switch type {
        case .expense: app.expenseCategories
        case .income: app.incomeCategories
        default: app.categories
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Type Picker
                Section {
                    Picker("Loại", selection: $type) {
                        Text("Chi tiêu").tag(TransactionType.expense)
                        Text("Thu nhập").tag(TransactionType.income)
                        Text("Chuyển khoản").tag(TransactionType.transfer)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: type) { _, _ in
                        categoryId = nil
                    }
                }

                // Amount
                Section("Số tiền") {
                    HStack {
                        TextField("0", text: $amountText)
                            .keyboardType(.numberPad)
                            .font(.title2.weight(.semibold).monospacedDigit())
                        Text("₫")
                            .foregroundStyle(.secondary)
                    }
                    if amount > 0 {
                        Text(formatVND(amount))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Category
                if type != .transfer {
                    Section("Danh mục") {
                        Picker("Danh mục", selection: $categoryId) {
                            Text("— Chọn —").tag(String?.none)
                            ForEach(availableCategories) { cat in
                                Text(cat.name).tag(String?.some(cat.id))
                            }
                        }
                    }
                }

                // Account
                Section("Tài khoản") {
                    Picker("Từ tài khoản", selection: $accountId) {
                        Text("— Chọn —").tag(String?.none)
                        ForEach(app.accounts) { acc in
                            HStack {
                                Text(acc.name)
                                Spacer()
                                Text(formatVNDShort(app.computedBalance(for: acc.id)))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            .tag(String?.some(acc.id))
                        }
                    }

                    if type == .transfer {
                        Picker("Đến tài khoản", selection: $transferToId) {
                            Text("— Chọn —").tag(String?.none)
                            ForEach(app.accounts.filter { $0.id != accountId }) { acc in
                                Text(acc.name).tag(String?.some(acc.id))
                            }
                        }
                    }
                }

                // Date
                Section("Ngày") {
                    DatePicker("Ngày giao dịch", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "vi_VN"))
                }

                // Note
                Section("Ghi chú") {
                    TextField("Không bắt buộc", text: $note, axis: .vertical)
                        .lineLimit(3, reservesSpace: false)
                }

                // Error
                if let errorMessage {
                    Section {
                        ErrorBanner(message: errorMessage)
                    }
                }

                // Delete (edit mode)
                if isEditMode {
                    Section {
                        Button(role: .destructive) {
                            Task { await handleDelete() }
                        } label: {
                            HStack {
                                Spacer()
                                Label("Xóa giao dịch", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Hủy") { onDismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditMode ? "Lưu" : "Thêm") {
                        Task { await handleSubmit() }
                    }
                    .fontWeight(.semibold)
                    .disabled(amount <= 0 || isSubmitting)
                }
            }
        }
        .onAppear { prefill() }
    }

    private func prefill() {
        if let tx = transaction {
            type = tx.type
            amountText = String(Int(abs(tx.amount)))
            categoryId = tx.categoryId
            accountId = tx.accountId
            transferToId = tx.transferToId
            date = parseStorageDate(tx.date) ?? Date()
            note = tx.note ?? ""
        } else {
            type = app.defaultTransactionType
            accountId = app.defaultAccountId
            categoryId = type == .expense ? app.defaultExpenseCategoryId : app.defaultIncomeCategoryId
        }
    }

    private func handleSubmit() async {
        isSubmitting = true
        errorMessage = nil
        let dateString = toYYYYMM(date) + "-" + String(format: "%02d", Calendar.current.component(.day, from: date))
        let storageDate = storageFormatter(date)
        let dto = TransactionCreateDTO(
            date: storageDate,
            type: type.rawValue,
            categoryId: categoryId,
            accountId: accountId,
            transferToId: transferToId,
            amount: type == .expense ? -amount : amount,
            note: note.isEmpty ? nil : note
        )
        do {
            if let tx = transaction {
                try await app.updateTransaction(tx.id, dto)
            } else {
                try await app.addTransaction(dto)
            }
            onDismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }

    private func handleDelete() async {
        guard let tx = transaction else { return }
        isSubmitting = true
        do {
            try await app.deleteTransaction(tx.id)
            onDismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }

    private func storageFormatter(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
