import SwiftUI

struct DashboardView: View {
    @Environment(AppViewModel.self) private var app
    @Namespace private var animationNamespace
    @State private var selectedPeriod = toYYYYMM(Date())
    @State private var periods = availablePeriods()
    @State private var isRefreshing = false

    private var income: Double { app.monthlyIncome(period: selectedPeriod) }
    private var expense: Double { app.monthlyExpense(period: selectedPeriod) }
    private var remaining: Double { income - expense }
    private var recentTxs: [Transaction] { Array(app.transactions.prefix(Constants.dashboardRecentCount)) }

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
                        // Period Selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DSSpacing.sm) {
                                ForEach(periods, id: \.self) { period in
                                    Button(periodLabel(period)) {
                                        withAnimation(.snappy(duration: 0.3, extraBounce: 0.2)) {
                                            selectedPeriod = period
                                        }
                                    }
                                    .buttonStyle(LiquidGlassButtonStyle(
                                        shape: Capsule(),
                                        isSelected: period == selectedPeriod
                                    ))
                                }
                            }
                            .padding(.horizontal, DSSpacing.lg)
                            // FIX: Thêm padding dọc để viền và shadow không bị cắt
                            .padding(.vertical, 1)
                        }
                        // Chỉnh khoảng cách giữa list tháng và card phía dưới nếu cần
                        .padding(.top, 1)

                        // Hero Balance Card
                        VStack(spacing: DSSpacing.sm) {
                            Text("Tổng số dư")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(formatVND(app.totalBalance))
                                .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(app.totalBalance >= 0 ? DSColors.positive : DSColors.negative)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(DSSpacing.xl)
                        // Áp dụng Liquid Glass
                        .liquidGlass(in: .rect(cornerRadius: DSRadius.xl), tint: DSColors.accent.opacity(0.1), material: .ultraThinMaterial)
                        .padding(.horizontal, DSSpacing.lg)

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
            .navigationTitle("Flow")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await app.loadInitData() }
        }
    }
}
