import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var vm = BudgetViewModel()
    @State private var showAddSheet = false

    var body: some View {
        NavigationView {
            List {
                if appVM.budgets.isEmpty {
                    Text("Chưa có ngân sách nào")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(appVM.budgets) { budget in
                        BudgetProgressRow(budget: budget, vm: vm)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await vm.delete(id: budget.id, appVM: appVM) }
                                } label: {
                                    Label("Xóa", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Ngân sách")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddBudgetView(vm: vm)
                    .environmentObject(appVM)
            }
            .refreshable { await appVM.reload() }
        }
    }
}

struct AddBudgetView: View {
    @EnvironmentObject var appVM: AppViewModel
    @ObservedObject var vm: BudgetViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var limitAmount = ""
    @State private var dateStart = Date()
    @State private var dateEnd = Date().addingTimeInterval(30 * 86400)
    @State private var selectedCategoryIds: Set<String> = []

    var body: some View {
        NavigationView {
            Form {
                Section("Thông tin") {
                    TextField("Tên ngân sách", text: $name)
                    TextField("Giới hạn chi tiêu (VND)", text: $limitAmount)
                        .keyboardType(.numberPad)
                }
                Section("Thời gian") {
                    DatePicker("Từ ngày", selection: $dateStart, displayedComponents: .date)
                    DatePicker("Đến ngày", selection: $dateEnd, displayedComponents: .date)
                }
                Section("Danh mục chi tiêu") {
                    ForEach(appVM.expenseCategories) { cat in
                        Button {
                            if selectedCategoryIds.contains(cat.id) {
                                selectedCategoryIds.remove(cat.id)
                            } else {
                                selectedCategoryIds.insert(cat.id)
                            }
                        } label: {
                            HStack {
                                Text(cat.name).foregroundColor(.primary)
                                Spacer()
                                if selectedCategoryIds.contains(cat.id) {
                                    Image(systemName: "checkmark").foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                if let err = vm.submitError {
                    Section { Text(err).foregroundColor(.red).font(.caption) }
                }
            }
            .navigationTitle("Tạo ngân sách")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Hủy") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lưu") { save() }
                        .disabled(vm.isSubmitting || name.isEmpty || limitAmount.isEmpty)
                }
            }
        }
    }

    private func save() {
        let limit = Double(limitAmount.replacingOccurrences(of: ",", with: "")) ?? 0
        let body = CreateBudgetRequest(
            name: name,
            limitAmount: limit,
            dateStart: Formatters.toDateString(dateStart),
            dateEnd: Formatters.toDateString(dateEnd),
            categoryIds: Array(selectedCategoryIds)
        )
        Task {
            await vm.create(body, appVM: appVM)
            if vm.submitError == nil { dismiss() }
        }
    }
}
