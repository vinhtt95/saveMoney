import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var vm = TransactionViewModel()
    @Environment(\.colorScheme) var scheme
    @State private var selectedTransaction: Transaction? = nil

    private var grouped: [(String, [Transaction])] {
        let txs = vm.paged(appVM.transactions)
        let dict = Dictionary(grouping: txs) { $0.date }
        return dict.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationView {
            ZStack {
                DSMeshBackground().ignoresSafeArea()

                VStack(spacing: 0) {
                    // Sticky header
                    VStack(spacing: 10) {
                        GlassSearchBar(text: $vm.searchText, placeholder: "Tìm kiếm giao dịch...")
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .onChange(of: vm.searchText) { _ in vm.resetPaging() }

                        // Filter chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                GlassPeriodChip(label: "Tất cả", isSelected: vm.selectedCategoryId == nil && vm.selectedAccountId == nil) {
                                    vm.selectedCategoryId = nil
                                    vm.selectedAccountId = nil
                                    vm.resetPaging()
                                }
                                ForEach(appVM.categories.prefix(8)) { cat in
                                    GlassPeriodChip(label: cat.name, isSelected: vm.selectedCategoryId == cat.id) {
                                        vm.selectedCategoryId = vm.selectedCategoryId == cat.id ? nil : cat.id
                                        vm.resetPaging()
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.bottom, 8)

                    // Transaction list
                    List {
                        ForEach(grouped, id: \.0) { date, txs in
                            Section {
                                ForEach(txs) { tx in
                                    TransactionRowView(transaction: tx, appVM: appVM) {
                                        selectedTransaction = tx
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            Task { await vm.delete(id: tx.id, appVM: appVM) }
                                        } label: {
                                            Label("Xóa", systemImage: "trash")
                                        }
                                    }
                                }
                            } header: {
                                Text(sectionTitle(date))
                                    .font(.dsBody(12, weight: .semibold))
                                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                                    .textCase(nil)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 4)
                                    .listRowInsets(EdgeInsets())
                            }
                        }

                        if vm.hasMore(appVM.transactions) {
                            Button {
                                vm.loadMore()
                            } label: {
                                Text("Tải thêm")
                                    .font(.dsBody(14, weight: .medium))
                                    .foregroundStyle(Color.dsPrimary(for: scheme))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .refreshable { await appVM.reload() }
                }
            }
            .navigationBarHidden(true)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .sheet(item: $selectedTransaction) { tx in
                AddTransactionView(isPresented: Binding(
                    get: { selectedTransaction != nil },
                    set: { if !$0 { selectedTransaction = nil } }
                ), transaction: tx)
                .environmentObject(appVM)
            }
        }
    }

    private func sectionTitle(_ date: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let d = formatter.date(from: date) else { return date }
        if Calendar.current.isDateInToday(d) { return "Hôm nay" }
        if Calendar.current.isDateInYesterday(d) { return "Hôm qua" }
        let out = DateFormatter()
        out.dateFormat = "dd/MM/yyyy"
        return out.string(from: d)
    }
}
