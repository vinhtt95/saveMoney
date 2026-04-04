import SwiftUI

struct TransactionsView: View {
    @Environment(AppViewModel.self) private var app
    @State private var viewModel: TransactionViewModel?
    @State private var editingTransaction: Transaction?
    @State private var showAddTransaction = false

    private var vm: TransactionViewModel {
        if let vm = viewModel { return vm }
        let vm = TransactionViewModel(app: app)
        return vm
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search + Filters
                VStack(spacing: DSSpacing.sm) {
                    GlassSearchBar(text: Binding(
                        get: { vm.searchText },
                        set: { vm.searchText = $0; vm.resetPage() }
                    ))

                    // Period Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DSSpacing.sm) {
                            ForEach(availablePeriods(), id: \.self) { period in
                                GlassPeriodChip(period: period, isSelected: period == vm.selectedPeriod) {
                                    vm.selectedPeriod = period
                                    vm.resetPage()
                                }
                            }
                        }
                    }

                    // Category Chips
                    if !vm.topCategories.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DSSpacing.sm) {
                                // All
                                Button {
                                    vm.selectedCategoryId = nil
                                    vm.resetPage()
                                } label: {
                                    Text("Tất cả")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(vm.selectedCategoryId == nil ? DSColors.accent : .secondary)
                                        .padding(.horizontal, DSSpacing.md)
                                        .padding(.vertical, DSSpacing.xs)
                                        .glassEffect(
                                            vm.selectedCategoryId == nil
                                                ? .regular.tint(DSColors.accent.opacity(0.15))
                                                : .regular,
                                            in: .capsule
                                        )
                                }
                                .buttonStyle(.plain)

                                ForEach(vm.topCategories) { cat in
                                    Button {
                                        vm.selectedCategoryId = cat.id
                                        vm.resetPage()
                                    } label: {
                                        Text(cat.name)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(vm.selectedCategoryId == cat.id ? DSColors.accent : .secondary)
                                            .padding(.horizontal, DSSpacing.md)
                                            .padding(.vertical, DSSpacing.xs)
                                            .glassEffect(
                                                vm.selectedCategoryId == cat.id
                                                    ? .regular.tint(DSColors.accent.opacity(0.15))
                                                    : .regular,
                                                in: .capsule
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, DSSpacing.lg)
                .padding(.vertical, DSSpacing.md)

                Divider().opacity(0.3)

                // Transaction List
                if vm.groupedTransactions.isEmpty {
                    EmptyStateView(
                        icon: "tray",
                        title: "Không có giao dịch",
                        message: "Thay đổi bộ lọc hoặc thêm giao dịch mới"
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(vm.groupedTransactions, id: \.0) { label, txs in
                            Section(label) {
                                ForEach(txs) { tx in
                                    TransactionRowView(tx: tx, app: app)
                                        .onTapGesture { editingTransaction = tx }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                Task { await vm.deleteTransaction(tx.id) }
                                            } label: {
                                                Label("Xóa", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }

                        if vm.hasMore {
                            Section {
                                Button("Tải thêm") { vm.loadMore() }
                                    .frame(maxWidth: .infinity)
                                    .foregroundStyle(DSColors.accent)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await app.loadInitData() }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddTransaction = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(DSColors.accent)
                    }
                }
            }
            .sheet(item: $editingTransaction) { tx in
                AddTransactionView(transaction: tx) { editingTransaction = nil }
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView(transaction: nil) { showAddTransaction = false }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = TransactionViewModel(app: app)
            }
        }
    }
}
