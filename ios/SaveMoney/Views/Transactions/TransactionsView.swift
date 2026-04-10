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
            ZStack {
                // MARK: - Nền hiệu ứng giống trang Flow
                GeometryReader { geo in
                    ZStack {
                        Circle()
                            .fill(DSColors.accent.opacity(0.15))
                            .blur(radius: 100)
                            .frame(width: geo.size.width * 0.8)
                            .offset(x: geo.size.width * 0.3, y: -geo.size.height * 0.1)
                        
                        Circle()
                            .fill(DSColors.income.opacity(0.1))
                            .blur(radius: 80)
                            .frame(width: geo.size.width * 0.6)
                            .offset(x: -geo.size.width * 0.2, y: geo.size.height * 0.2)
                    }
                }
                .ignoresSafeArea()

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

                    ScrollView {
                        LazyVStack(spacing: DSSpacing.lg) {
                            
                            // MARK: - Period Selector (Giống Flow)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: DSSpacing.sm) {
                                    ForEach(availablePeriods(), id: \.self) { period in
                                        Button(periodLabel(period)) {
                                            withAnimation(.snappy) {
                                                vm.selectedPeriod = period
                                            }
                                        }
                                        .buttonStyle(LiquidGlassButtonStyle(
                                            shape: Capsule(),
                                            isSelected: period == vm.selectedPeriod
                                        ))
                                    }
                                }
                                .padding(.horizontal, DSSpacing.lg)
                                .padding(.vertical, 2)
                            }

                            // MARK: - Category Chips
                            if !vm.topCategories.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: DSSpacing.sm) {
                                        // Nút "Tất cả"
                                        Button {
                                            vm.selectedCategoryId = nil
                                            vm.resetPage()
                                        } label: {
                                            Text("Tất cả")
                                                .font(.caption.weight(.medium))
                                                .foregroundStyle(vm.selectedCategoryId == nil ? .white : .secondary)
                                                .padding(.horizontal, DSSpacing.md)
                                                .padding(.vertical, DSSpacing.xs)
                                                .background {
                                                    if vm.selectedCategoryId == nil {
                                                        Capsule().fill(DSColors.accent)
                                                    } else {
                                                        Capsule().fill(.ultraThinMaterial)
                                                    }
                                                }
                                        }
                                        .buttonStyle(.plain)

                                        ForEach(vm.topCategories) { cat in
                                            Button {
                                                vm.selectedCategoryId = cat.id
                                                vm.resetPage()
                                            } label: {
                                                Text(cat.name)
                                                    .font(.caption.weight(.medium))
                                                    .foregroundStyle(vm.selectedCategoryId == cat.id ? .white : .secondary)
                                                    .padding(.horizontal, DSSpacing.md)
                                                    .padding(.vertical, DSSpacing.xs)
                                                    .background {
                                                        if vm.selectedCategoryId == cat.id {
                                                            Capsule().fill(DSColors.accent)
                                                        } else {
                                                            Capsule().fill(.ultraThinMaterial)
                                                        }
                                                    }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, DSSpacing.lg)
                                }
                            }

                            // MARK: - Transaction List bọc trong GlassCard
                            if vm.groupedTransactions.isEmpty {
                                EmptyStateView(
                                    icon: "tray",
                                    title: "Không có giao dịch",
                                    message: "Thay đổi bộ lọc hoặc thêm giao dịch mới"
                                )
                                .padding(.top, 100)
                            } else {
                                ForEach(vm.groupedTransactions, id: \.0) { label, txs in
                                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                                        Text(label)
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, DSSpacing.lg)
                                        
                                        // Nhóm các giao dịch cùng ngày vào 1 card
                                        VStack(spacing: 0) {
                                            ForEach(txs) { tx in
                                                TransactionRowView(tx: tx, app: app)
                                                    .padding(.vertical, DSSpacing.sm)
                                                    .contentShape(Rectangle())
                                                    .onTapGesture { editingTransaction = tx }
                                                
                                                if tx.id != txs.last?.id {
                                                    Divider().padding(.leading, 50).opacity(0.3)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, DSSpacing.md)
                                        .liquidGlass(in: .rect(cornerRadius: DSRadius.lg))
                                        .padding(.horizontal, DSSpacing.lg)
                                    }
                                }

                                if vm.hasMore {
                                    Button("Tải thêm") { vm.loadMore() }
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(DSColors.accent)
                                        .padding(.vertical, DSSpacing.md)
                                }
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.top, DSSpacing.md)
                    }
                    .refreshable { await app.loadInitData() }
                }
            }
            .navigationTitle("")
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
