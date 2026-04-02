import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var selectedPeriod: String = ""   // "" = current month

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
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    PeriodPickerView(selectedPeriod: $selectedPeriod)
                        .padding(.horizontal)

                    // Stat cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCardView(title: "Thu nhập", amount: stats.income, color: .green, icon: "arrow.down.circle.fill")
                        StatCardView(title: "Chi tiêu", amount: stats.expense, color: .red, icon: "arrow.up.circle.fill")
                        StatCardView(title: "Còn lại", amount: stats.income - stats.expense, color: .blue, icon: "equal.circle.fill")
                        StatCardView(title: "Tổng tài khoản", amount: appVM.totalBalance, color: .purple, icon: "creditcard.fill")
                    }
                    .padding(.horizontal)

                    // Monthly trend chart
                    MonthlyTrendChartView(transactions: appVM.transactions)
                        .padding(.horizontal)

                    // Category breakdown
                    CategoryBreakdownSectionView(
                        transactions: appVM.transactions.filter { $0.date.hasPrefix(yyyyMM) },
                        categories: appVM.categories
                    )
                    .padding(.horizontal)

                    // Recent transactions
                    RecentTransactionsView(transactions: recentTransactions, appVM: appVM)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Tổng quan")
            .refreshable { await appVM.reload() }
        }
    }
}

struct PeriodPickerView: View {
    @Binding var selectedPeriod: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                PeriodChip(label: "Tháng này", value: "", selected: $selectedPeriod)
                ForEach(lastSixMonths(), id: \.self) { m in
                    PeriodChip(label: m, value: m, selected: $selectedPeriod)
                }
            }
            .padding(.vertical, 4)
        }
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
}

struct PeriodChip: View {
    let label: String
    let value: String
    @Binding var selected: String

    var body: some View {
        Button(label) { selected = value }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selected == value ? Color.accentColor : Color(.systemGray5))
            .foregroundColor(selected == value ? .white : .primary)
            .clipShape(Capsule())
            .font(.subheadline)
    }
}

struct MonthlyTrendChartView: View {
    let transactions: [Transaction]

    private struct MonthData: Identifiable {
        let id: String
        let income: Double
        let expense: Double
    }

    private var chartData: [MonthData] {
        let cal = Calendar.current
        var date = Date()
        return (0..<6).reversed().compactMap { i -> MonthData? in
            guard let d = cal.date(byAdding: .month, value: -i, to: date) else { return nil }
            let ym = Formatters.toYYYYMM(d)
            let filtered = transactions.filter { $0.date.hasPrefix(ym) }
            let inc = filtered.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let exp = filtered.filter { $0.type == .expense }.reduce(0) { $0 + abs($1.amount) }
            return MonthData(id: ym, income: inc, expense: exp)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Xu hướng 6 tháng")
                .font(.headline)
            Chart(chartData) { item in
                LineMark(x: .value("Tháng", item.id), y: .value("Thu nhập", item.income))
                    .foregroundStyle(.green)
                LineMark(x: .value("Tháng", item.id), y: .value("Chi tiêu", item.expense))
                    .foregroundStyle(.red)
            }
            .frame(height: 160)
            .chartYAxis { AxisMarks { v in
                AxisValueLabel { if let d = v.as(Double.self) { Text(Formatters.formatVNDShort(d)) } }
            }}
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

struct CategoryBreakdownSectionView: View {
    let transactions: [Transaction]
    let categories: [Category]

    private var breakdown: [(Category, Double)] {
        let expenses = transactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenses, by: { $0.categoryId })
        return categories
            .filter { $0.type == .expense }
            .compactMap { cat -> (Category, Double)? in
                let total = grouped[Optional(cat.id)]?.reduce(0) { $0 + abs($1.amount) } ?? 0
                return total > 0 ? (cat, total) : nil
            }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Chi tiêu theo danh mục")
                .font(.headline)
            if breakdown.isEmpty {
                Text("Không có dữ liệu")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(breakdown.prefix(5), id: \.0.id) { cat, amount in
                    HStack {
                        Text(cat.name).font(.subheadline)
                        Spacer()
                        Text(Formatters.formatVND(amount))
                            .font(.subheadline.monospacedDigit())
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}
