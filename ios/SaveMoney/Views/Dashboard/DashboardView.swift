import SwiftUI

struct DashboardView: View {
    @Environment(AppViewModel.self) private var app
    @Namespace private var animationNamespace
    @State private var selectedPeriod = toYYYYMM(Date())
    @State private var periods = availablePeriods()
    @State private var isRefreshing = false
    
    // 1. Dùng @AppStorage lưu vĩnh viễn trạng thái chọn Account ("" nghĩa là "Tổng số dư")
    @AppStorage("dashboardDisplayedAccountID", store: UserDefaults(suiteName: Constants.appGroup))
    private var displayedAccountID: String = ""
    
    private var income: Double { app.monthlyIncome(period: selectedPeriod) }
    private var expense: Double { app.monthlyExpense(period: selectedPeriod) }
    private var remaining: Double { income - expense }
    private var recentTxs: [Transaction] { Array(app.visibleTransactions.prefix(Constants.dashboardRecentCount)) }
    
    // 2. Computed property lấy tên tài khoản (hoặc "Tổng số dư")
    private var balanceTitle: String {
        if !displayedAccountID.isEmpty, let account = app.accounts.first(where: { $0.id == displayedAccountID }) {
            return account.name
        }
        return "Tổng số dư"
    }
    
    // 3. Computed property lấy số dư
    private var displayBalance: Double {
        if !displayedAccountID.isEmpty {
            return app.computedBalance(for: displayedAccountID)
        }
        return app.totalBalance
    }
    
    // 4. Hàm đồng bộ Widget (Gọi khi thay đổi account hoặc có giao dịch mới làm tiền thay đổi)
    private func syncWidgetData() {
        WidgetDataManager.shared.updateSelectedAccount(title: balanceTitle, balance: displayBalance)
    }
    
    // 5. Hàm logic xoay vòng: Tổng -> Tài khoản 1 -> Tài khoản 2 -> ... -> Tổng
    private func toggleAccountBalance() {
        let allIDs: [String] = [""] + app.accounts.map { $0.id }
        let currentIndex = allIDs.firstIndex(of: displayedAccountID) ?? 0
        let nextIndex = (currentIndex + 1) % allIDs.count
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            displayedAccountID = allIDs[nextIndex]
        }
        
        // Đồng bộ lên widget ngay khi xoay vòng
        syncWidgetData()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - iOS 18 Background Effect
//                LiquidBackgroundView()
                LiquiBackgroundViewNotAnimating()
                
                ScrollView {
                    LazyVStack(spacing: DSSpacing.lg) {
                        // Hero Balance Card
                        VStack(spacing: DSSpacing.sm) {
                            Text(balanceTitle) // Sử dụng tiêu đề động
                                .font(.caption)
                                .foregroundStyle(.primary)
                            Text(formatVND(displayBalance)) // Sử dụng số dư động
                                .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(displayBalance >= 0 ? DSColors.positive : DSColors.negative)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(DSSpacing.xl)
                        .glassEffect(.regular.tint(DSColors.expense.opacity(0.05)), in: .rect(cornerRadius: DSRadius.lg))
                        .padding(.horizontal, DSSpacing.lg)
                        .contentShape(Rectangle()) // Đảm bảo nhận diện tap
                        .onTapGesture(count: 2) {
                            toggleAccountBalance()
                        }
                        
                        // Stat Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DSSpacing.sm) {
                            StatCardView(title: "Thu nhập", amount: income, icon: "arrow.down.circle.fill", color: DSColors.income)
                            StatCardView(title: "Chi tiêu", amount: expense, icon: "arrow.up.circle.fill", color: DSColors.expense)
                            StatCardView(title: "Còn lại", amount: remaining, icon: "equal.circle.fill", color: DSColors.accent)
                            StatCardView(title: "Số dư", amount: app.totalBalance, icon: "creditcard.fill", color: DSColors.transfer)
                        }
                        .padding(.horizontal, DSSpacing.lg)
                        
                        // Net Worth
                        if !app.goldAssets.isEmpty {
                            HStack(alignment: .firstTextBaseline, spacing: DSSpacing.sm){
                                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundStyle(DSColors.gold)
                                        Text("Tài sản ròng")
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                    }
                                    Text(formatVND(app.netWorth))
                                        .font(.title2.weight(.bold).monospacedDigit())
                                        .foregroundStyle(DSColors.gold)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Tiền: \(formatVNDShort(app.totalBalance))")
                                        .font(.caption)
                                        .foregroundStyle(DSColors.positive)
                                    Text("Vàng: \(formatVNDShort(app.totalGoldValue))")
                                        .font(.caption)
                                        .foregroundStyle(DSColors.gold)
                                }
                            }
                            .padding(DSSpacing.lg)
                            .glassEffect(.regular.tint(DSColors.expense.opacity(0.05)), in: .rect(cornerRadius: DSRadius.lg))
                            .padding(.horizontal, DSSpacing.lg)
                        }
                        
                        // Pinned Budget Card
                        if let pinnedId = app.pinnedBudgetId,
                           let pinnedBudget = app.budgets.first(where: { $0.id == pinnedId }) {
                            PinnedBudgetCard(budget: pinnedBudget)
                                .padding(.horizontal, DSSpacing.lg)
                        }
                        
                        // Recent Transactions
                        RecentTransactionsView(transactions: recentTxs, app: app)
                            .padding(.horizontal, DSSpacing.lg)
                        
                        Spacer(minLength: 80) // tab bar clearance
                    }
                    .padding(.top, DSSpacing.md)
                }
                .background(.clear)
            }
            .navigationTitle(Text("Hello Jackie"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Chọn thời gian", selection: $selectedPeriod) {
                            ForEach(periods, id: \.self) { period in
                                Text(periodLabel(period)).tag(period)
                            }
                        }
                    } label: {
                        Image(systemName: "calendar")
                            .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(DSColors.accent)
                        .clipShape(Capsule())
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            switch app.egoMode {
                            case .normal: app.egoMode = .humble
                            case .humble: app.egoMode = .arrogant
                            case .arrogant: app.egoMode = .normal
                            }
                        }
                    }) {
                        Image(systemName: app.egoMode == .humble ? "tortoise.fill" : (app.egoMode == .arrogant ? "hare.fill" : "peacesign"))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(app.egoMode == .arrogant ? DSColors.gold : DSColors.accent)
                    }
                }
            }
            .refreshable { await app.loadInitData() }
            // Tự động update sang Widget khi có giao dịch mới (số dư thay đổi) hoặc sửa tài khoản
            .onChange(of: app.transactions) { syncWidgetData() }
            .onChange(of: app.accounts) { syncWidgetData() }
            .onAppear { syncWidgetData() }
        }
    }
}
