import SwiftUI
import Charts

struct CategoryBreakdownChart: View {
    let transactions: [Transaction]
    let categories: [Category]

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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Chi tiêu theo danh mục")
                .font(.headline)
            if data.isEmpty {
                Text("Không có dữ liệu")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .center)
            } else {
                Chart(data) { item in
                    SectorMark(
                        angle: .value("Chi tiêu", item.amount),
                        innerRadius: .ratio(0.55)
                    )
                    .foregroundStyle(by: .value("Danh mục", item.name))
                }
                .frame(height: 200)

                ForEach(data) { item in
                    HStack {
                        Text(item.name).font(.subheadline)
                        Spacer()
                        Text(Formatters.formatVND(item.amount))
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
