import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var vm = BudgetViewModel()
    @State private var showAddSheet = false
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ZStack {
            DSMeshBackground().ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    HStack {
                        Text("Ngân sách")
                            .font(.dsDisplay(28))
                            .foregroundStyle(Color.dsOnSurface(for: scheme))
                        Spacer()
                        Button { showAddSheet = true } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(LinearGradient.dsCTAGradient(scheme: scheme)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    if appVM.budgets.isEmpty {
                        GlassCard(radius: DSRadius.lg, padding: 24) {
                            Text("Chưa có ngân sách nào")
                                .font(.dsBody(14))
                                .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.horizontal, 20)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(appVM.budgets) { budget in
                                BudgetProgressRow(budget: budget, vm: vm)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            Task { await vm.delete(id: budget.id, appVM: appVM) }
                                        } label: {
                                            Label("Xóa", systemImage: "trash")
                                        }
                                    }
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                    Spacer(minLength: 20)
                }
            }
            .refreshable { await appVM.reload() }
        }
        .navigationTitle("Ngân sách")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .sheet(isPresented: $showAddSheet) {
            AddBudgetView(vm: vm)
                .environmentObject(appVM)
        }
    }
}

struct AddBudgetView: View {
    @EnvironmentObject var appVM: AppViewModel
    @ObservedObject var vm: BudgetViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var scheme

    @State private var name = ""
    @State private var limitAmount = ""
    @State private var dateStart = Date()
    @State private var dateEnd = Date().addingTimeInterval(30 * 86400)
    @State private var selectedCategoryIds: Set<String> = []

    var body: some View {
        NavigationView {
            ZStack {
                DSMeshBackground().ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        GlassCard(radius: DSRadius.lg, padding: 16) {
                            VStack(spacing: 14) {
                                GlassFormField(label: "Tên ngân sách", text: $name)
                                GlassFormField(label: "Giới hạn chi tiêu (VND)", text: $limitAmount,
                                               keyboardType: .numberPad)
                            }
                        }
                        .padding(.horizontal, 20)

                        GlassCard(radius: DSRadius.lg, padding: 16) {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Từ ngày")
                                        .font(.dsBody(14))
                                        .foregroundStyle(Color.dsOnSurface(for: scheme))
                                    Spacer()
                                    DatePicker("", selection: $dateStart, displayedComponents: .date)
                                        .labelsHidden()
                                        .tint(Color.dsPrimary(for: scheme))
                                }
                                Divider().opacity(0.15)
                                HStack {
                                    Text("Đến ngày")
                                        .font(.dsBody(14))
                                        .foregroundStyle(Color.dsOnSurface(for: scheme))
                                    Spacer()
                                    DatePicker("", selection: $dateEnd, displayedComponents: .date)
                                        .labelsHidden()
                                        .tint(Color.dsPrimary(for: scheme))
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        GlassCard(radius: DSRadius.lg, padding: 16) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Danh mục chi tiêu")
                                    .font(.dsTitle(14))
                                    .foregroundStyle(Color.dsOnSurface(for: scheme))
                                ForEach(appVM.expenseCategories) { cat in
                                    Button {
                                        if selectedCategoryIds.contains(cat.id) {
                                            selectedCategoryIds.remove(cat.id)
                                        } else {
                                            selectedCategoryIds.insert(cat.id)
                                        }
                                    } label: {
                                        HStack {
                                            GradientCircleIcon(systemName: categorySystemIcon(for: cat.name),
                                                               colors: categoryIconColors(for: cat.name),
                                                               size: 30)
                                            Text(cat.name)
                                                .font(.dsBody(14))
                                                .foregroundStyle(Color.dsOnSurface(for: scheme))
                                            Spacer()
                                            if selectedCategoryIds.contains(cat.id) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(Color.dsPrimary(for: scheme))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        if let err = vm.submitError {
                            Text(err).font(.dsBody(12)).foregroundStyle(Color.dsExpense)
                                .padding(.horizontal, 20)
                        }

                        GlassPillButton(label: vm.isSubmitting ? "Đang lưu..." : "Tạo ngân sách") {
                            save()
                        }
                        .disabled(vm.isSubmitting || name.isEmpty || limitAmount.isEmpty)
                        .padding(.horizontal, 20)

                        Spacer(minLength: 20)
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Tạo ngân sách")
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
