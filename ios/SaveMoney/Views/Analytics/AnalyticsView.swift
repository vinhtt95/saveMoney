import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.colorScheme) var scheme
    @State private var selectedPeriod: String = ""

    private var yyyyMM: String {
        selectedPeriod.isEmpty ? Formatters.currentYYYYMM() : selectedPeriod
    }

    private var periodTransactions: [Transaction] {
        appVM.transactions.filter { $0.date.hasPrefix(yyyyMM) }
    }

    // Projected trajectory: extrapolate current month spend
    private var projectedMonthSpend: Double {
        let expenses = periodTransactions.filter { $0.type == .expense }
        guard !expenses.isEmpty else { return 0 }
        let cal = Calendar.current
        let today = cal.component(.day, from: Date())
        let daysInMonth = cal.range(of: .day, in: .month, for: Date())?.count ?? 30
        guard today > 0 else { return 0 }
        let totalSoFar = expenses.reduce(0) { $0 + abs($1.amount) }
        return (totalSoFar / Double(today)) * Double(daysInMonth)
    }

    private var currentMonthSpend: Double {
        periodTransactions.filter { $0.type == .expense }.reduce(0) { $0 + abs($1.amount) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                DSMeshBackground().ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("INTELLIGENCE ENGINE")
                                .font(.dsBody(10, weight: .semibold))
                                .foregroundStyle(Color.dsPrimary(for: scheme))
                                .tracking(1.5)
                            Text("Reports &\nAnalysis")
                                .font(.dsDisplay(32))
                                .foregroundStyle(Color.dsOnSurface(for: scheme))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        // Period picker
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
                            .padding(.horizontal, 20)
                            .padding(.vertical, 2)
                        }

                        // Flow Evolution chart
                        GlassCard(radius: DSRadius.lg, padding: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    DSSectionHeader(title: "Flow Evolution")
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Circle().fill(Color.dsIncome).frame(width: 6, height: 6)
                                        Text("Thu").font(.dsBody(10)).foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                                        Circle().fill(Color.dsExpense).frame(width: 6, height: 6)
                                        Text("Chi").font(.dsBody(10)).foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                                    }
                                }
                                MoMAreaChart(transactions: appVM.transactions)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Asset Allocation donut
                        GlassCard(radius: DSRadius.lg, padding: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                DSSectionHeader(title: "Asset Allocation")
                                CategoryBreakdownChart(
                                    transactions: periodTransactions,
                                    categories: appVM.categories
                                )
                            }
                        }
                        .padding(.horizontal, 20)

                        // Day of week
                        GlassCard(radius: DSRadius.lg, padding: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                DSSectionHeader(title: "Chi tiêu theo ngày")
                                DayOfWeekChart(transactions: periodTransactions)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Projected trajectory
                        projectedTrajectoryCard
                            .padding(.horizontal, 20)

                        Spacer(minLength: 20)
                    }
                }
                .refreshable { await appVM.reload() }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Projected Trajectory

    private var projectedTrajectoryCard: some View {
        GlassCard(radius: DSRadius.lg, padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                DSSectionHeader(title: "Projected Trajectory")

                Text("Dựa trên tốc độ chi tiêu hiện tại, tháng này bạn sẽ chi khoảng:")
                    .font(.dsBody(13))
                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))

                Text(Formatters.formatVND(projectedMonthSpend))
                    .font(.dsDisplay(28))
                    .foregroundStyle(Color.dsOnSurface(for: scheme))

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Hiện tại")
                            .font(.dsBody(11))
                            .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                        Text(Formatters.formatVNDShort(currentMonthSpend))
                            .font(.dsTitle(14))
                            .foregroundStyle(Color.dsExpense)
                    }
                    Rectangle()
                        .fill(Color(.separator).opacity(0.5))
                        .frame(width: 1, height: 30)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Dự báo cuối tháng")
                            .font(.dsBody(11))
                            .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                        Text(Formatters.formatVNDShort(projectedMonthSpend))
                            .font(.dsTitle(14))
                            .foregroundStyle(Color.dsPrimary(for: scheme))
                    }
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color(.separator).opacity(0.4))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(LinearGradient.dsCTAGradient(scheme: scheme))
                            .frame(width: projectedMonthSpend > 0
                                   ? min(geo.size.width * CGFloat(currentMonthSpend / projectedMonthSpend), geo.size.width)
                                   : 0,
                                   height: 6)
                    }
                }
                .frame(height: 6)
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

// MARK: - MoM Area Chart

struct MoMAreaChart: View {
    let transactions: [Transaction]
    @Environment(\.colorScheme) var scheme

    private struct MonthData: Identifiable {
        let id: String
        let income: Double
        let expense: Double
    }

    private var data: [MonthData] {
        let cal = Calendar.current
        let date = Date()
        return (0..<6).reversed().compactMap { i -> MonthData? in
            guard let d = cal.date(byAdding: .month, value: -i, to: date) else { return nil }
            let ym = Formatters.toYYYYMM(d)
            let filtered = transactions.filter { $0.date.hasPrefix(ym) }
            let inc = filtered.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let exp = filtered.filter { $0.type == .expense }.reduce(0) { $0 + abs($1.amount) }
            return MonthData(id: String(ym.suffix(5)), income: inc, expense: exp)
        }
    }

    var body: some View {
        Chart(data) { item in
            AreaMark(x: .value("Tháng", item.id), y: .value("Thu nhập", item.income))
                .foregroundStyle(LinearGradient(colors: [Color.dsIncome.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom))
            LineMark(x: .value("Tháng", item.id), y: .value("Thu nhập", item.income))
                .foregroundStyle(Color.dsIncome)
                .lineStyle(StrokeStyle(lineWidth: 2))
            AreaMark(x: .value("Tháng", item.id), y: .value("Chi tiêu", item.expense))
                .foregroundStyle(LinearGradient(colors: [Color.dsExpense.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom))
            LineMark(x: .value("Tháng", item.id), y: .value("Chi tiêu", item.expense))
                .foregroundStyle(Color.dsExpense)
                .lineStyle(StrokeStyle(lineWidth: 2))
        }
        .frame(height: 150)
        .chartYAxis {
            AxisMarks { v in
                AxisValueLabel {
                    if let d = v.as(Double.self) {
                        Text(Formatters.formatVNDShort(d)).font(.dsBody(9))
                            .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                    }
                }
            }
        }
    }
}

// MARK: - DayOfWeekChart

struct DayOfWeekChart: View {
    let transactions: [Transaction]
    @Environment(\.colorScheme) var scheme

    private let dayNames = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]

    private struct DayData: Identifiable {
        let id: Int
        let name: String
        let total: Double
    }

    private var data: [DayData] {
        let cal = Calendar.current
        let expenses = transactions.filter { $0.type == .expense }
        var totals = Array(repeating: 0.0, count: 7)
        for tx in expenses {
            if let date = Formatters.parseDate(tx.date) {
                let weekday = cal.component(.weekday, from: date) - 1
                totals[weekday] += abs(tx.amount)
            }
        }
        return (0..<7).map { DayData(id: $0, name: dayNames[$0], total: totals[$0]) }
    }

    var body: some View {
        Chart(data) { item in
            BarMark(x: .value("Ngày", item.name), y: .value("Chi tiêu", item.total))
                .foregroundStyle(LinearGradient.dsCTAGradient(scheme: scheme))
                .cornerRadius(6)
        }
        .frame(height: 130)
        .chartYAxis {
            AxisMarks { v in
                AxisValueLabel {
                    if let d = v.as(Double.self) {
                        Text(Formatters.formatVNDShort(d)).font(.dsBody(9))
                            .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                    }
                }
            }
        }
    }
}
