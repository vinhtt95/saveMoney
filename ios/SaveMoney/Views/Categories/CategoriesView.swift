import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var showAddSheet = false
    @State private var editingCategory: Category? = nil
    @State private var deleteError: String?
    @Environment(\.colorScheme) var scheme
    private let api = APIService.shared

    var body: some View {
        ZStack {
            DSMeshBackground().ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("Danh mục")
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
                .padding(.bottom, 8)

                if let err = deleteError {
                    Text(err)
                        .font(.dsBody(12))
                        .foregroundStyle(Color.dsExpense)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 4)
                }

                List {
                    Section {
                        ForEach(appVM.expenseCategories) { cat in
                            categoryRow(cat)
                        }
                    } header: {
                        Text("Chi tiêu")
                            .font(.dsBody(12, weight: .semibold))
                            .foregroundStyle(Color.dsExpense)
                            .textCase(nil)
                    }

                    Section {
                        ForEach(appVM.incomeCategories) { cat in
                            categoryRow(cat)
                        }
                    } header: {
                        Text("Thu nhập")
                            .font(.dsBody(12, weight: .semibold))
                            .foregroundStyle(Color.dsIncome)
                            .textCase(nil)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable { await appVM.reload() }
            }
        }
        .navigationTitle("Danh mục")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .sheet(isPresented: $showAddSheet) {
            CategoryFormView().environmentObject(appVM)
        }
        .sheet(item: $editingCategory) { cat in
            CategoryEditView(category: cat).environmentObject(appVM)
        }
    }

    private func categoryRow(_ cat: Category) -> some View {
        HStack(spacing: 12) {
            GradientCircleIcon(
                systemName: categorySystemIcon(for: cat.name),
                colors: categoryIconColors(for: cat.name),
                size: 36
            )
            Text(cat.name)
                .font(.dsBody(15))
                .foregroundStyle(Color.dsOnSurface(for: scheme))
            Spacer()
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
        .swipeActions(edge: .leading) {
            Button {
                editingCategory = cat
            } label: {
                Label("Sửa", systemImage: "pencil")
            }
            .tint(Color.dsBrandAccent)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { deleteCategory(cat) } label: {
                Label("Xóa", systemImage: "trash")
            }
        }
    }

    private func deleteCategory(_ cat: Category) {
        Task {
            do {
                try await api.deleteCategory(id: cat.id)
                appVM.categories.removeAll { $0.id == cat.id }
            } catch {
                deleteError = error.localizedDescription
            }
        }
    }
}

// MARK: - Category Edit View

struct CategoryEditView: View {
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var scheme

    let category: Category
    private let api = APIService.shared

    @State private var name: String
    @State private var isSubmitting = false
    @State private var error: String?

    init(category: Category) {
        self.category = category
        _name = State(initialValue: category.name)
    }

    var body: some View {
        NavigationView {
            ZStack {
                DSMeshBackground().ignoresSafeArea()
                VStack(spacing: 16) {
                    GlassCard(radius: DSRadius.lg, padding: 16) {
                        VStack(spacing: 14) {
                            GlassFormField(label: "Tên danh mục", text: $name)

                            HStack(spacing: 8) {
                                GradientCircleIcon(
                                    systemName: categorySystemIcon(for: name.isEmpty ? category.name : name),
                                    colors: categoryIconColors(for: name.isEmpty ? category.name : name),
                                    size: 34
                                )
                                Text("Preview")
                                    .font(.dsBody(13))
                                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                                Spacer()
                                Text(category.type.displayName)
                                    .font(.dsBody(12, weight: .medium))
                                    .foregroundStyle(category.type == .expense ? Color.dsExpense : Color.dsIncome)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule().fill(
                                            (category.type == .expense ? Color.dsExpense : Color.dsIncome).opacity(0.12)
                                        )
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    if let err = error {
                        Text(err).font(.dsBody(12)).foregroundStyle(Color.dsExpense)
                            .padding(.horizontal, 20)
                    }

                    GlassPillButton(label: isSubmitting ? "Đang lưu..." : "Lưu thay đổi") {
                        save()
                    }
                    .disabled(isSubmitting || name.isEmpty || name == category.name)
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationTitle("Sửa danh mục")
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
        isSubmitting = true
        Task {
            do {
                try await api.updateCategory(id: category.id, name: name)
                if let idx = appVM.categories.firstIndex(where: { $0.id == category.id }) {
                    appVM.categories[idx] = Category(id: category.id, name: name, type: category.type)
                }
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}
