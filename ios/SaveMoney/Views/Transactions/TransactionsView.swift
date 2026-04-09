import SwiftUI

struct TransactionsView: View {
    @Environment(AppViewModel.self) private var app
    @Environment(NetworkMonitor.self) private var networkMonitor
    @Namespace private var animationNamespace
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
                // Offline banner
                if !networkMonitor.isOnline {
                    HStack(spacing: 6) {
                        Image(systemName: "wifi.slash")
                        Text("Offline — thay đổi sẽ được đồng bộ khi có mạng")
                            .font(.caption)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.85))
                }

                // Search + Filters
                VStack(spacing: DSSpacing.sm) {

                    // Period Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DSSpacing.sm) {
                            ForEach(availablePeriods(), id: \.self) { period in
                                GlassPeriodChip(
                                    period: period,
                                    isSelected: period == vm.selectedPeriod,
                                    namespace: animationNamespace // Truyền biến namespace vào đây
                                ) {
                                    // Bọc trong withAnimation để kính trượt mượt mà
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        vm.selectedPeriod = period
                                    }
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
