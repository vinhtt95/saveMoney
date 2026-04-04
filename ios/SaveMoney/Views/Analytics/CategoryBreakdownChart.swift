import SwiftUI
import Charts

struct CategoryBreakdownData: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let color: Color
}

struct CategoryBreakdownChart: View {
    let data: [CategoryBreakdownData]

    var total: Double { data.reduce(0) { $0 + $1.amount } }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            if data.isEmpty {
                EmptyStateView(icon: "chart.pie", title: "Chưa có dữ liệu", message: "Thêm giao dịch chi tiêu để xem phân tích")
            } else {
                // Donut Chart
                HStack(spacing: DSSpacing.xl) {
                    Chart(data) { item in
                        SectorMark(
                            angle: .value("Số tiền", item.amount),
                            innerRadius: .ratio(0.55),
                            angularInset: 2
                        )
                        .foregroundStyle(item.color)
                        .cornerRadius(4)
                    }
                    .frame(width: 140, height: 140)
                    .overlay {
                        VStack(spacing: 2) {
                            Text(formatVNDShort(total))
                                .font(.caption.weight(.bold).monospacedDigit())
                                .foregroundStyle(DSColors.expense)
                            Text("Chi tiêu")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Legend
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        ForEach(data) { item in
                            HStack(spacing: DSSpacing.sm) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 10, height: 10)
                                Text(item.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Text(formatVNDShort(item.amount))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Day of Week Chart
struct DayOfWeekData: Identifiable {
    let id = UUID()
    let day: String
    let amount: Double
}

struct DayOfWeekChart: View {
    let data: [DayOfWeekData]

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Ngày", item.day),
                y: .value("Chi tiêu", item.amount)
            )
            .foregroundStyle(DSColors.expense.gradient)
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(formatVNDShort(amount))
                            .font(.caption2)
                    }
                }
            }
        }
        .frame(height: 160)
    }
}
