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
                // Inline header
                dashboardHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                // Period picker
                periodPicker
                    .padding(.horizontal, 20)

                // Hero balance card
                heroBalanceCard
                    .padding(.horizontal, 20)

                // Stat cards grid
                statsGrid
                    .padding(.horizontal, 20)

                // Expense flow chart
                expenseFlowChart
                    .padding(.horizontal, 20)

                // Recent transactions
                RecentTransactionsView(transactions: recentTransactions, appVM: appVM)
                    .padding(.horizontal, 20)

                Spacer(minLength: 20)
            }
        }
        .refreshable { await appVM.reload() }
    }

    // MARK: - Subviews

    private var dashboardHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText)
                    .font(.dsBody(14))
                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                Text("The Ethereal Ledger")
                    .font(.dsDisplay(22))
                    .foregroundStyle(Color.dsOnSurface(for: scheme))
            }
            Spacer()
            Button {
                Task { await appVM.reload() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.dsPrimary(for: scheme))
                    .padding(10)
                    .background {
                        Circle()
                            .fill(.ultraThinMaterial)
                    }
            }
        }
    }

    private var periodPicker: some View {
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
    }

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

    private var expenseFlowChart: some View {
        GlassCard(radius: DSRadius.lg, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                DSSectionHeader(title: "Expense Flow")

                Chart(chartData) { item in
                    AreaMark(
                        x: .value("Tháng", item.id),
                        y: .value("Chi tiêu", item.expense)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dsExpense.opacity(0.6), Color.dsExpense.opacity(0.05)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    LineMark(
                        x: .value("Tháng", item.id),
                        y: .value("Chi tiêu", item.expense)
                    )
                    .foregroundStyle(Color.dsExpense)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Tháng", item.id),
                        y: .value("Thu nhập", item.income)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dsIncome.opacity(0.5), Color.dsIncome.opacity(0.05)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    LineMark(
                        x: .value("Tháng", item.id),
                        y: .value("Thu nhập", item.income)
                    )
                    .foregroundStyle(Color.dsIncome)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .frame(height: 140)
                .chartXAxis {
                    AxisMarks { v in
                        AxisValueLabel {
                            if let s = v.as(String.self) {
                                Text(s.suffix(2))
                                    .font(.dsBody(10))
                                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { v in
                        AxisValueLabel {
                            if let d = v.as(Double.self) {
                                Text(Formatters.formatVNDShort(d))
                                    .font(.dsBody(9))
                                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                            }
                        }
                    }
                }

                // Legend
                HStack(spacing: 16) {
                    legendItem(color: Color.dsIncome, label: "Thu nhập")
                    legendItem(color: Color.dsExpense, label: "Chi tiêu")
                }
            }
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.dsBody(12))
                .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
        }
    }

    // MARK: - Helpers

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Chào buổi sáng" }
        if hour < 18 { return "Chào buổi chiều" }
        return "Chào buổi tối"
    }

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

    private struct MonthData: Identifiable {
        let id: String
        let income: Double
        let expense: Double
    }

    private var chartData: [MonthData] {
        let cal = Calendar.current
        let date = Date()
        return (0..<6).reversed().compactMap { i -> MonthData? in
            guard let d = cal.date(byAdding: .month, value: -i, to: date) else { return nil }
            let ym = Formatters.toYYYYMM(d)
            let filtered = appVM.transactions.filter { $0.date.hasPrefix(ym) }
            let inc = filtered.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let exp = filtered.filter { $0.type == .expense }.reduce(0) { $0 + abs($1.amount) }
            return MonthData(id: ym, income: inc, expense: exp)
        }
    }
}
