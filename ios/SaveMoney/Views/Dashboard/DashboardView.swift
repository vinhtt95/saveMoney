import SwiftUI

struct DashboardView: View {
    @Environment(AppViewModel.self) private var app
    @Namespace private var animationNamespace
    @State private var selectedPeriod = toYYYYMM(Date())
    @State private var periods = availablePeriods()
    @State private var isRefreshing = false
    // 1. Thêm State để lưu ID tài khoản đang hiển thị (nil nghĩa là "Tổng số dư")
    @State private var displayedAccountID: String? = nil
    
    private var income: Double { app.monthlyIncome(period: selectedPeriod) }
    private var expense: Double { app.monthlyExpense(period: selectedPeriod) }
    private var remaining: Double { income - expense }
    private var recentTxs: [Transaction] { Array(app.transactions.prefix(Constants.dashboardRecentCount)) }
    
    // 2. Computed property để lấy tiêu đề hiển thị (Tên tài khoản hoặc "Tổng số dư")
    private var balanceTitle: String {
        if let id = displayedAccountID, let account = app.accounts.first(where: { $0.id == id }) {
            return account.name
        }
        return "Tổng số dư"
    }
    
    // 3. Computed property để lấy số tiền hiển thị tương ứng
    private var displayBalance: Double {
        if let id = displayedAccountID {
            return app.computedBalance(for: id)
        }
        return app.totalBalance
    }
    
    // 4. Hàm logic để xoay vòng: Tổng -> Tài khoản 1 -> Tài khoản 2 -> ... -> Tổng
    private func toggleAccountBalance() {
        // Tạo danh sách ID bao gồm nil (tổng) và tất cả ID tài khoản hiện có
        let allIDs: [String?] = [nil] + app.accounts.map { $0.id }
        
        if let currentIndex = allIDs.firstIndex(of: displayedAccountID) {
            let nextIndex = (currentIndex + 1) % allIDs.count
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                displayedAccountID = allIDs[nextIndex]
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - iOS 18 Background Effect (Blurred Orbs)
                // Lớp nền mờ mờ phía sau để hiệu ứng Liquid Glass có thể phản chiếu ánh sáng và màu sắc
                GeometryReader { geo in
                    ZStack {
                        Circle()
                            .fill(DSColors.accent.opacity(0.3))
                            .blur(radius: 100)
                            .frame(width: geo.size.width * 0.8)
                            .offset(x: geo.size.width * 0.2, y: -geo.size.height * 0.2)
                        
                        Circle()
                            .fill(DSColors.income.opacity(0.2))
                            .blur(radius: 80)
                            .frame(width: geo.size.width * 0.6)
                            .offset(x: -geo.size.width * 0.2, y: geo.size.height * 0.1)
                    }
                }
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: DSSpacing.lg) {
                        // Hero Balance Card
                        VStack(spacing: DSSpacing.sm) {
                            Text(balanceTitle) // Sử dụng tiêu đề động
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(formatVND(displayBalance)) // Sử dụng số dư động
                                .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(displayBalance >= 0 ? DSColors.positive : DSColors.negative)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(DSSpacing.xl)
                        .liquidGlass(in: .rect(cornerRadius: DSRadius.xl), tint: DSColors.accent.opacity(0.1), material: .ultraThinMaterial)
                        .padding(.horizontal, DSSpacing.lg)
                        // 6. Thêm Double Tap Gesture vào card
                        .contentShape(Rectangle()) // Đảm bảo nhận diện tap trên toàn vùng card
                        .onTapGesture(count: 2) {
                            toggleAccountBalance()
                        }
                        
                        // Stat Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DSSpacing.sm) {
                            StatCardView(title: "Thu nhập", amount: income, icon: "arrow.down.circle.fill", color: DSColors.income)
                            StatCardView(title: "Chi tiêu", amount: expense, icon: "arrow.up.circle.fill", color: DSColors.expense)
                            StatCardView(title: "Còn lại", amount: remaining, icon: "equal.circle.fill", color: DSColors.accent, isBalance: true)
                            StatCardView(title: "Số dư", amount: app.totalBalance, icon: "creditcard.fill", color: .secondary, isBalance: true)
                        }
                        .padding(.horizontal, DSSpacing.lg)
                        
                        // Net Worth (shown when gold assets exist)
                        if !app.goldAssets.isEmpty {
                            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(DSColors.gold)
                                    Text("Tài sản ròng")
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                }
                                HStack(alignment: .firstTextBaseline) {
                                    Text(formatVND(app.netWorth))
                                        .font(.title2.weight(.bold).monospacedDigit())
                                        .foregroundStyle(DSColors.gold)
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("Tiền: \(formatVNDShort(app.totalBalance))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text("Vàng: \(formatVNDShort(app.totalGoldValue))")
                                            .font(.caption)
                                            .foregroundStyle(DSColors.gold)
                                    }
                                }
                            }
                            .padding(DSSpacing.lg)
                            // Áp dụng Liquid Glass
                            .liquidGlass(in: .rect(cornerRadius: DSRadius.lg), tint: DSColors.gold.opacity(0.1), material: .ultraThinMaterial)
                            .padding(.horizontal, DSSpacing.lg)
                        }
                        
                        // Recent Transactions
                        RecentTransactionsView(transactions: recentTxs, app: app)
                            .padding(.horizontal, DSSpacing.lg)
                        
                        Spacer(minLength: 80) // tab bar clearance
                    }
                    .padding(.top, DSSpacing.md)
                }
                .background(.clear) // Cực kỳ quan trọng: Giúp nhìn xuyên qua nền phía sau
            }
            .navigationTitle("") // Hoặc để trống "" nếu bạn đã ẩn title
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        // Sử dụng trực tiếp danh sách periods mày đã có
                        Picker("Chọn thời gian", selection: $selectedPeriod) {
                            ForEach(periods, id: \.self) { period in
                                // Dùng hàm periodLabel mày đã viết để hiển thị tên tháng
                                Text(periodLabel(period)).tag(period)
                            }
                        }
                    } label: {
                        // Hiển thị tháng đang chọn một cách gọn gàng trên thanh công cụ
                        HStack(spacing: 4) {
                            Text(periodLabel(selectedPeriod))
                                .font(.subheadline.weight(.medium))
                            
                            Image(systemName: "calendar.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .font(.title3)
                        }
                        .foregroundStyle(DSColors.accent)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
            .refreshable { await app.loadInitData() }
        }
    }
}
