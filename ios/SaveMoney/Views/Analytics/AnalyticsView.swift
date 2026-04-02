import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var selectedPeriod: String = ""

    private var yyyyMM: String {
        selectedPeriod.isEmpty ? Formatters.currentYYYYMM() : selectedPeriod
    }

    private var periodTransactions: [Transaction] {
        appVM.transactions.filter { $0.date.hasPrefix(yyyyMM) }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    PeriodPickerView(selectedPeriod: $selectedPeriod)
                        .padding(.horizontal)

                    CategoryBreakdownChart(
                        transactions: periodTransactions,
                        categories: appVM.categories
                    )
                    .padding(.horizontal)

                    DayOfWeekChart(transactions: periodTransactions)
                        .padding(.horizontal)

                    MoMComparisonChart(transactions: appVM.transactions)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Thống kê")
            .refreshable { await appVM.reload() }
        }
    }
}

struct DayOfWeekChart: View {
    let transactions: [Transaction]

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
        VStack(alignment: .leading, spacing: 8) {
            Text("Chi tiêu theo ngày trong tuần")
                .font(.headline)
            Chart(data) { item in
                BarMark(x: .value("Ngày", item.name), y: .value("Chi tiêu", item.total))
                    .foregroundStyle(.red.gradient)
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

struct MoMComparisonChart: View {
    let transactions: [Transaction]

    private struct MoMData: Identifiable {
        let id: String
        let income: Double
        let expense: Double
    }

    private var data: [MoMData] {
        let cal = Calendar.current
        var date = Date()
        return (0..<6).reversed().compactMap { i -> MoMData? in
            guard let d = cal.date(byAdding: .month, value: -i, to: date) else { return nil }
            let ym = Formatters.toYYYYMM(d)
            let filtered = transactions.filter { $0.date.hasPrefix(ym) }
            let inc = filtered.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let exp = filtered.filter { $0.type == .expense }.reduce(0) { $0 + abs($1.amount) }
            return MoMData(id: String(ym.suffix(5)), income: inc, expense: exp)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("So sánh thu - chi theo tháng")
                .font(.headline)
            Chart(data) { item in
                BarMark(x: .value("Tháng", item.id), y: .value("Thu nhập", item.income))
                    .foregroundStyle(.green.gradient)
                    .position(by: .value("Loại", "Thu nhập"))
                BarMark(x: .value("Tháng", item.id), y: .value("Chi tiêu", item.expense))
                    .foregroundStyle(.red.gradient)
                    .position(by: .value("Loại", "Chi tiêu"))
            }
            .frame(height: 180)
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
