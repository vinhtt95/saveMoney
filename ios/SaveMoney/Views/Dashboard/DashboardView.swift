import SwiftUI

struct DashboardView: View {
    @Environment(AppViewModel.self) private var app
    @State private var selectedPeriod = toYYYYMM(Date())
    @State private var periods = availablePeriods()
    @State private var isRefreshing = false

    private var income: Double { app.monthlyIncome(period: selectedPeriod) }
    private var expense: Double { app.monthlyExpense(period: selectedPeriod) }
    private var remaining: Double { income - expense }
    private var recentTxs: [Transaction] { Array(app.transactions.prefix(Constants.dashboardRecentCount)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: DSSpacing.lg) {
                    // Period Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DSSpacing.sm) {
                            ForEach(periods, id: \.self) { period in
                                GlassPeriodChip(period: period, isSelected: period == selectedPeriod) {
                                    selectedPeriod = period
                                }
                            }
                        }
                        .padding(.horizontal, DSSpacing.lg)
                    }

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
                    .glassEffect(.regular, in: .rect(cornerRadius: DSRadius.xl))
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
                        .glassEffect(.regular.tint(DSColors.gold.opacity(0.05)), in: .rect(cornerRadius: DSRadius.lg))
                        .padding(.horizontal, DSSpacing.lg)
                    }

                    // Recent Transactions
                    RecentTransactionsView(transactions: recentTxs, app: app)
                        .padding(.horizontal, DSSpacing.lg)

                    Spacer(minLength: 80) // tab bar clearance
                }
                .padding(.top, DSSpacing.md)
            }
            .navigationTitle("Flow")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            isRefreshing = true
                            await app.loadInitData()
                            isRefreshing = false
                        }
                    } label: {
                        if isRefreshing {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .refreshable { await app.loadInitData() }
        }
    }
}
