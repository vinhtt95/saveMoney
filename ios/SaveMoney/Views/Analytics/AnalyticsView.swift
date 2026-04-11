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
        NavigationStack{
            ZStack {
//                LiquidBackgroundView()
                GeometryReader { geo in
                    ZStack {
                        
                        Color(.systemGroupedBackground).ignoresSafeArea()
                        
                        // Các đốm màu (Orbs)
                        Circle()
                            .fill(DSColors.income.opacity(0.4))
                            .frame(width: 300, height: 360)
                            .blur(radius: 80)
                            .offset(x: geo.size.width * 0.3, y: geo.size.height * 0.3)
                        
                        Circle()
                            .fill(Color.orange.opacity(0.3))
                            .frame(width: 500, height: 250)
                            .blur(radius: 90)
                            .offset(x: geo.size.width * 0.0, y: geo.size.height * 0.0)
                        
                        Circle()
                            .fill(Color.purple.opacity(0.3))
                            .frame(width: 300, height: 350)
                            .blur(radius: 100)
                            .offset(x: -geo.size.width * 0.3, y: -geo.size.height * 0.4)
                    }
                }
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: DSSpacing.lg) {
                        // Category Breakdown
                        GlassCard {
                            DSSection(title: "Phân tích danh mục") {
                                CategoryBreakdownChart(data: categoryBreakdown)
                            }
                        }
                        .glassEffect(.regular.tint(DSColors.expense.opacity(0.05)), in: .rect(cornerRadius: DSRadius.lg))
                        .padding(.horizontal, DSSpacing.lg)
                        
                        // Day of Week
                        GlassCard {
                            DSSection(title: "Chi tiêu theo ngày trong tuần") {
                                DayOfWeekChart(data: dayOfWeekData)
                            }
                        }
                        .glassEffect(.regular.tint(DSColors.expense.opacity(0.05)), in: .rect(cornerRadius: DSRadius.lg))
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
            }
            .navigationTitle("Insight")
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
                        Image(systemName: "calendar")
                            .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(DSColors.accent)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }
}
