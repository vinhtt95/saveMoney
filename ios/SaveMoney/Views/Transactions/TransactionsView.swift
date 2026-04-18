import SwiftUI

struct TransactionsView: View {
    @Environment(AppViewModel.self) private var app
    @Environment(NetworkMonitor.self) private var networkMonitor
    @Namespace private var animationNamespace
    @State private var viewModel: TransactionViewModel?
    @State private var editingTransaction: Transaction?
    @State private var showAddTransaction = false
    @State private var isSearchPresented = false
    
    private var vm: TransactionViewModel {
        if let vm = viewModel { return vm }
        let vm = TransactionViewModel(app: app)
        return vm
    }
    
    var body: some View {
        let _ = app.transactions
        NavigationStack {
            ZStack {
                // MARK: - Nền hiệu ứng giống trang Flow
//                LiquidBackgroundView()
                LiquiBackgroundViewNotAnimating()
                
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
                                        //                                        .liquidGlass(in: .rect(cornerRadius: DSRadius.lg))
                                        .glassEffect(.regular.tint(DSColors.expense.opacity(0.05)), in: .rect(cornerRadius: DSRadius.lg))
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
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            vm.selectedCategoryId = nil
                            vm.resetPage()
                        } label: {
                            HStack {
                                Text("Tất cả danh mục")
                                if vm.selectedCategoryId == nil {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Lấy danh sách danh mục từ ViewModel
                        ForEach(vm.topCategories) { cat in
                            Button {
                                vm.selectedCategoryId = cat.id
                                vm.resetPage()
                            } label: {
                                HStack {
                                    Text(cat.name)
                                    if vm.selectedCategoryId == cat.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        // Biểu tượng filter sẽ đổi màu/kiểu khi đang có lọc
                        Image(systemName: vm.selectedCategoryId == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(vm.selectedCategoryId == nil ? .primary : DSColors.accent)
                    }
                }
                ToolbarSpacer(placement: .topBarTrailing)
                ToolbarItemGroup(placement: .topBarTrailing){
                    Menu {
                        Picker("Chọn thời gian", selection: Bindable(vm).selectedPeriod) {
                            ForEach(availablePeriods(), id: \.self) { period in
                                Text(periodLabel(period)).tag(period)
                            }
                        }
                    } label: {
                        // Hiển thị tháng đang chọn một cách gọn gàng trên thanh công cụ
                        Image(systemName: "calendar")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(DSColors.accent)
                            .clipShape(Capsule())
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
