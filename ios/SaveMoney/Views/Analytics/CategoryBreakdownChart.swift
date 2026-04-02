import SwiftUI
import Charts

struct CategoryBreakdownChart: View {
    let transactions: [Transaction]
    let categories: [Category]
    @Environment(\.colorScheme) var scheme

    private struct CategoryData: Identifiable {
        let id: String
        let name: String
        let amount: Double
    }

    private var data: [CategoryData] {
        let expenses = transactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenses, by: { $0.categoryId })
        return categories
            .filter { $0.type == .expense }
            .compactMap { cat -> CategoryData? in
                let total = grouped[Optional(cat.id)]?.reduce(0) { $0 + abs($1.amount) } ?? 0
                return total > 0 ? CategoryData(id: cat.id, name: cat.name, amount: total) : nil
            }
            .sorted { $0.amount > $1.amount }
    }

    private let gradientColors: [[Color]] = [
        [Color(hex: "#c799ff"), Color(hex: "#4af8e3")],
        [Color(hex: "#ff6b8a"), Color(hex: "#fbbf24")],
        [Color(hex: "#60a5fa"), Color(hex: "#a78bfa")],
        [Color(hex: "#4af8e3"), Color(hex: "#059669")],
        [Color(hex: "#fbbf24"), Color(hex: "#f97316")]
    ]

    var body: some View {
        if data.isEmpty {
            Text("Không có dữ liệu chi tiêu")
                .font(.dsBody(14))
                .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
        } else {
            VStack(spacing: 16) {
                // Donut chart
                Chart(data) { item in
                    SectorMark(
                        angle: .value("Chi tiêu", item.amount),
                        innerRadius: .ratio(0.55),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Danh mục", item.name))
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .chartLegend(.hidden)
                .overlay {
                    VStack(spacing: 2) {
                        Text("Total")
                            .font(.dsBody(11))
                            .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                        Text(Formatters.formatVNDShort(data.reduce(0) { $0 + $1.amount }))
                            .font(.dsTitle(15))
                            .foregroundStyle(Color.dsOnSurface(for: scheme))
                    }
                }

                // Legend rows
                VStack(spacing: 8) {
                    ForEach(data.prefix(5)) { item in
                        HStack(spacing: 10) {
                            GradientCircleIcon(
                                systemName: categorySystemIcon(for: item.name),
                                colors: categoryIconColors(for: item.name),
                                size: 28
                            )
                            Text(item.name)
                                .font(.dsBody(13))
                                .foregroundStyle(Color.dsOnSurface(for: scheme))
                            Spacer()
                            Text(Formatters.formatVNDShort(item.amount))
                                .font(.dsTitle(13))
                                .foregroundStyle(Color.dsExpense)
                        }
                    }
                }
            }
        }
    }
}
