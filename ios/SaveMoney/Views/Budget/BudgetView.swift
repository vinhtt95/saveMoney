import SwiftUI

struct BudgetView: View {
    @Environment(AppViewModel.self) private var app
    @State private var budgetVM: BudgetViewModel?
    @State private var showAddForm = false

    private var vm: BudgetViewModel {
        budgetVM ?? BudgetViewModel(app: app)
    }

    var body: some View {
        List {
            if app.budgets.isEmpty {
                EmptyStateView(
                    icon: "chart.bar.doc.horizontal",
                    title: "Chưa có ngân sách",
                    message: "Thêm ngân sách để theo dõi chi tiêu"
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(app.budgets) { budget in
                    Section {
                        BudgetProgressRow(budget: budget, vm: vm, app: app)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await vm.deleteBudget(budget.id) }
                        } label: {
                            Label("Xóa", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Ngân sách")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddForm = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(DSColors.accent)
                }
            }
        }
        .sheet(isPresented: $showAddForm) {
            AddBudgetView { showAddForm = false }
        }
        .onAppear {
            if budgetVM == nil { budgetVM = BudgetViewModel(app: app) }
        }
    }
}

// MARK: - Add Budget Sheet
struct AddBudgetView: View {
    @Environment(AppViewModel.self) private var app
    let onDismiss: () -> Void

    @State private var name = ""
    @State private var limitText = ""
    @State private var dateStart = Date()
    @State private var dateEnd = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var selectedCategoryIds: Set<String> = []
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private func storageDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Thông tin ngân sách") {
                    TextField("Tên ngân sách", text: $name)
                    HStack {
                        TextField("Hạn mức (VNĐ)", text: $limitText)
                            .keyboardType(.numberPad)
                        Text("₫").foregroundStyle(.secondary)
                    }
                }

                Section("Thời gian") {
                    DatePicker("Từ ngày", selection: $dateStart, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "vi_VN"))
                    DatePicker("Đến ngày", selection: $dateEnd, in: dateStart..., displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "vi_VN"))
                }

                Section("Danh mục áp dụng") {
                    ForEach(app.expenseCategories) { cat in
                        HStack {
                            CategoryIconView(name: cat.name, size: 24)
                            Text(cat.name)
                            Spacer()
                            if selectedCategoryIds.contains(cat.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(DSColors.accent)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedCategoryIds.contains(cat.id) {
                                selectedCategoryIds.remove(cat.id)
                            } else {
                                selectedCategoryIds.insert(cat.id)
                            }
                        }
                    }
                }

                if let errorMessage {
                    Section { ErrorBanner(message: errorMessage) }
                }
            }
            .navigationTitle("Thêm ngân sách")
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
                    .disabled(name.isEmpty || limitText.isEmpty || isSubmitting)
                }
            }
        }
    }

    private func handleSubmit() async {
        isSubmitting = true
        errorMessage = nil
        let limit = Double(limitText.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: ".", with: "")) ?? 0
        let vm = BudgetViewModel(app: app)
        await vm.addBudget(
            name: name.trimmingCharacters(in: .whitespaces),
            limit: limit,
            dateStart: storageDate(dateStart),
            dateEnd: storageDate(dateEnd),
            categoryIds: Array(selectedCategoryIds)
        )
        if let err = vm.errorMessage {
            errorMessage = err
        } else {
            onDismiss()
        }
        isSubmitting = false
    }
}
