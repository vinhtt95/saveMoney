import SwiftUI

struct CategoriesView: View {
    @Environment(AppViewModel.self) private var app
    @State private var showAddForm = false
    @State private var editingCategory: Category?

    var body: some View {
        List {
            Section("Chi tiêu") {
                ForEach(app.expenseCategories) { cat in
                    CategoryRow(cat: cat, app: app, onEdit: { editingCategory = cat })
                }
            }
            Section("Thu nhập") {
                ForEach(app.incomeCategories) { cat in
                    CategoryRow(cat: cat, app: app, onEdit: { editingCategory = cat })
                }
            }
        }
        .navigationTitle("Danh mục")
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
            CategoryFormView(category: nil) { showAddForm = false }
        }
        .sheet(item: $editingCategory) { cat in
            CategoryFormView(category: cat) { editingCategory = nil }
        }
    }
}

private struct CategoryRow: View {
    let cat: Category
    let app: AppViewModel
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: DSSpacing.md) {
            CategoryIconView(category: cat, fallbackName: cat.name, size: 32)
            Text(cat.name)
                .font(.subheadline)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { onEdit() }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { try? await app.deleteCategory(cat.id) }
            } label: {
                Label("Xóa", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                onEdit()
            } label: {
                Label("Sửa", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}
