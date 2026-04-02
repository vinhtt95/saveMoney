import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var vm = TransactionViewModel()
    @State private var showAddSheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    SearchBar(text: $vm.searchText, placeholder: "Tìm kiếm ghi chú...")
                        .onChange(of: vm.searchText) { _ in vm.resetPaging() }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Picker("Danh mục", selection: $vm.selectedCategoryId) {
                                Text("Tất cả danh mục").tag(Optional<String>(nil))
                                ForEach(appVM.categories) { cat in
                                    Text(cat.name).tag(Optional(cat.id))
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: vm.selectedCategoryId) { _ in vm.resetPaging() }

                            Picker("Tài khoản", selection: $vm.selectedAccountId) {
                                Text("Tất cả tài khoản").tag(Optional<String>(nil))
                                ForEach(appVM.accounts) { acc in
                                    Text(acc.name).tag(Optional(acc.id))
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: vm.selectedAccountId) { _ in vm.resetPaging() }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
                .background(Color(.systemGroupedBackground))

                List {
                    ForEach(vm.paged(appVM.transactions)) { tx in
                        TransactionRowView(transaction: tx, appVM: appVM)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await vm.delete(id: tx.id, appVM: appVM) }
                                } label: {
                                    Label("Xóa", systemImage: "trash")
                                }
                            }
                    }
                    if vm.hasMore(appVM.transactions) {
                        Button("Tải thêm") { vm.loadMore() }
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Giao dịch")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddTransactionView(vm: vm)
                    .environmentObject(appVM)
            }
            .refreshable { await appVM.reload() }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Tìm kiếm..."

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
