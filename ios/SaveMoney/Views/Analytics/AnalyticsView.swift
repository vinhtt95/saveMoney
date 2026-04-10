import SwiftUI
import Charts

struct AnalyticsView: View {
    @Environment(AppViewModel.self) private var app
    @Namespace private var animationNamespace
    @State private var periods = availablePeriods()
    @State private var selectedPeriod = toYYYYMM(Date())

    private var periodTransactions: [Transaction] {
        app.transactions.filter { $0.type == .expense && $0.date.hasPrefix(selectedPeriod) }
    }

    private var categoryBreakdown: [CategoryBreakdownData] {
        let grouped = Dictionary(grouping: periodTransactions) { $0.categoryId ?? "" }
        let totals = grouped.map { (id, txs) -> (String, Double) in
            let name = app.category(for: id)?.name ?? "Khác"
            let total = txs.reduce(0) { $0 + abs($1.amount) }
            return (name, total)
        }.sorted { $0.1 > $1.1 }

        let top5 = totals.prefix(5)
        let otherTotal = totals.dropFirst(5).reduce(0) { $0 + $1.1 }

        let colors: [Color] = [DSColors.expense, DSColors.accent, DSColors.gold, DSColors.income, DSColors.transfer]
        var result = top5.enumerated().map { idx, item in
            CategoryBreakdownData(name: item.0, amount: item.1, color: colors[idx % colors.count])
        }
        if otherTotal > 0 {
            result.append(CategoryBreakdownData(name: "Khác", amount: otherTotal, color: .secondary))
        }
        return result
    }

    private var dayOfWeekData: [DayOfWeekData] {
        let dayNames = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]
        var totals = [Double](repeating: 0, count: 7)
        let cal = Calendar.current
        for tx in periodTransactions {
            guard let date = parseStorageDate(tx.date) else { continue }
            let weekday = cal.component(.weekday, from: date) - 1 // 0=Sun
            totals[weekday] += abs(tx.amount)
        }
        return dayNames.enumerated().map { DayOfWeekData(day: $0.element, amount: totals[$0.offset]) }
    }

    private var totalExpense: Double { periodTransactions.reduce(0) { $0 + abs($1.amount) } }
    private var elapsed: Int { max(1, elapsedDaysInMonth(period: selectedPeriod)) }
    private var daysTotal: Int { daysInMonth(period: selectedPeriod) }
    private var projected: Double { (totalExpense / Double(elapsed)) * Double(daysTotal) }

    var body: some View {
        ZStack {
            LiquidBackgroundView()
            ScrollView {
                LazyVStack(spacing: DSSpacing.lg) {
                    // Category Breakdown
                    GlassCard {
                        DSSection(title: "Phân tích danh mục") {
                            CategoryBreakdownChart(data: categoryBreakdown)
                        }
                    }
                    .padding(.horizontal, DSSpacing.lg)

                    // Day of Week
                    GlassCard {
                        DSSection(title: "Chi tiêu theo ngày trong tuần") {
                            DayOfWeekChart(data: dayOfWeekData)
                        }
                    }
                    .padding(.horizontal, DSSpacing.lg)

                    // Projected Spend
                    if totalExpense > 0 {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundStyle(DSColors.accent)
                                Text("Dự báo chi tiêu tháng")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                            }
                            HStack(alignment: .firstTextBaseline) {
                                Text(formatVND(projected))
                                    .font(.title2.weight(.bold).monospacedDigit())
                                    .foregroundStyle(DSColors.expense)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Đã dùng: \(formatVNDShort(totalExpense))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("Ngày \(elapsed)/\(daysTotal)")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .padding(DSSpacing.lg)
                        .glassEffect(.regular.tint(DSColors.expense.opacity(0.05)), in: .rect(cornerRadius: DSRadius.lg))
                        .padding(.horizontal, DSSpacing.lg)
                    }

                    Spacer(minLength: 80)
                }
                .padding(.top, DSSpacing.md)
            }
            .navigationTitle("")
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
                            
                            Image(systemName: "calendar")
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
        }
    }
}
