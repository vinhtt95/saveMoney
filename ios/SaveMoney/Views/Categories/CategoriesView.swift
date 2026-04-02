import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var showAddSheet = false
    @State private var deleteError: String?
    private let api = APIService.shared

    var body: some View {
        NavigationView {
            List {
                Section("Chi tiêu") {
                    ForEach(appVM.expenseCategories) { cat in
                        Text(cat.name)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { delete(cat) } label: {
                                    Label("Xóa", systemImage: "trash")
                                }
                            }
                    }
                }
                Section("Thu nhập") {
                    ForEach(appVM.incomeCategories) { cat in
                        Text(cat.name)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { delete(cat) } label: {
                                    Label("Xóa", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .navigationTitle("Danh mục")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                CategoryFormView()
                    .environmentObject(appVM)
            }
            .refreshable { await appVM.reload() }
        }
    }

    private func delete(_ cat: Category) {
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
