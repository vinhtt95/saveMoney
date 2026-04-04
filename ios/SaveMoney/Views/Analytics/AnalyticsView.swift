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
                        .padding(.top, 12)

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
