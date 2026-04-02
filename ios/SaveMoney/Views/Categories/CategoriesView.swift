import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var showAddSheet = false
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
