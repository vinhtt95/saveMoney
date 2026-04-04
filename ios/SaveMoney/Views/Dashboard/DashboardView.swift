import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.colorScheme) var scheme
    @State private var selectedPeriod: String = ""

    private var yyyyMM: String {
        selectedPeriod.isEmpty ? Formatters.currentYYYYMM() : selectedPeriod
    }

    private var stats: (income: Double, expense: Double) {
        appVM.monthlyStats(yyyyMM: yyyyMM)
    }

    private var recentTransactions: [Transaction] {
        Array(appVM.transactions
            .filter { selectedPeriod.isEmpty || $0.date.hasPrefix(yyyyMM) }
            .prefix(10))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Period picker + reload button
                HStack(spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            GlassPeriodChip(label: "Tháng này", isSelected: selectedPeriod.isEmpty) {
                                selectedPeriod = ""
                            }
                            ForEach(lastSixMonths(), id: \.self) { m in
                                GlassPeriodChip(label: m, isSelected: selectedPeriod == m) {
                                    selectedPeriod = m
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        Task { await appVM.reload() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.dsBrandAccent)
                            .frame(width: 36, height: 36)
                    }
                    .glassEffect(.regular, in: .circle)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Hero balance card
                heroBalanceCard
                    .padding(.horizontal, 20)

                // Stat cards grid
                statsGrid
                    .padding(.horizontal, 20)

                // Net worth card (shown when gold assets exist)
                if !appVM.goldAssets.isEmpty {
                    netWorthCard
                        .padding(.horizontal, 20)
                }

                // Recent transactions
                RecentTransactionsView(transactions: recentTransactions, appVM: appVM)
                    .padding(.horizontal, 20)

                Spacer(minLength: 20)
            }
        }
        .refreshable { await appVM.reload() }
    }

    // MARK: - Subviews

    private var heroBalanceCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DSRadius.xl, style: .continuous)
                .fill(LinearGradient.dsCTAGradient(scheme: scheme))

            VStack(alignment: .leading, spacing: 12) {
                Text("TỔNG TÀI KHOẢN")
                    .font(.dsBody(11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
                    .tracking(1.5)

                Text(Formatters.formatVND(appVM.totalBalance))
                    .font(.dsDisplay(38))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Thu nhập")
                            .font(.dsBody(11))
                            .foregroundStyle(.white.opacity(0.75))
                        Text(Formatters.formatVNDShort(stats.income))
                            .font(.dsTitle(14))
                            .foregroundStyle(.white)
                    }
                    Rectangle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 1, height: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Chi tiêu")
                            .font(.dsBody(11))
                            .foregroundStyle(.white.opacity(0.75))
                        Text(Formatters.formatVNDShort(stats.expense))
                            .font(.dsTitle(14))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    // Change indicator
                    let remaining = stats.income - stats.expense
                    HStack(spacing: 4) {
                        Image(systemName: remaining >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 11, weight: .bold))
                        Text(Formatters.formatVNDShort(abs(remaining)))
                            .font(.dsBody(12, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())
                }
            }
            .padding(20)
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCardView(title: "Thu nhập", amount: stats.income, color: .green, icon: "arrow.down.circle.fill")
            StatCardView(title: "Chi tiêu", amount: stats.expense, color: .red, icon: "arrow.up.circle.fill")
            StatCardView(title: "Còn lại", amount: stats.income - stats.expense, color: .blue, icon: "equal.circle.fill")
            StatCardView(title: "Tổng tài khoản", amount: appVM.totalBalance, color: .purple, icon: "creditcard.fill")
        }
    }

    private var netWorthCard: some View {
        GlassCard(radius: DSRadius.lg, padding: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TỔNG TÀI SẢN RÒNG")
                        .font(.dsBody(11, weight: .semibold))
                        .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                        .tracking(1)
                    Text(Formatters.formatVND(appVM.totalNetWorth))
                        .font(.dsTitle(22))
                        .foregroundStyle(Color.dsOnSurface(for: scheme))
                    HStack(spacing: 12) {
                        Text("TK: \(Formatters.formatVNDShort(appVM.totalBalance))")
                            .font(.dsBody(11))
                            .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                        Text("Vàng: \(Formatters.formatVNDShort(appVM.totalGoldValue))")
                            .font(.dsBody(11))
                            .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                    }
                }
                Spacer()
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(red: 0.85, green: 0.65, blue: 0.13))
            }
        }
    }

    // MARK: - Helpers

    private func lastSixMonths() -> [String] {
        var months: [String] = []
        let cal = Calendar.current
        var date = Date()
        for _ in 0..<6 {
            date = cal.date(byAdding: .month, value: -1, to: date)!
            months.append(Formatters.toYYYYMM(date))
        }
        return months
    }

}
