import SwiftUI

struct BudgetProgressRow: View {
    @EnvironmentObject var appVM: AppViewModel
    let budget: Budget
    let vm: BudgetViewModel

    private var spent: Double { vm.spentAmount(for: budget, transactions: appVM.transactions) }
    private var progress: Double { vm.progress(for: budget, transactions: appVM.transactions) }
    private var remaining: Double { budget.limitAmount - spent }
    private var isOver: Bool { spent > budget.limitAmount }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(budget.name).font(.headline)
                Spacer()
                Text(isOver ? "Vượt ngân sách" : "Còn lại: \(Formatters.formatVND(remaining))")
                    .font(.caption)
                    .foregroundColor(isOver ? .red : .secondary)
            }
            ProgressView(value: progress)
                .tint(isOver ? .red : progress > 0.8 ? .orange : .green)
            HStack {
                Text("Đã chi: \(Formatters.formatVND(spent))")
                    .font(.caption)
                    .foregroundColor(.red)
                Spacer()
                Text("Giới hạn: \(Formatters.formatVND(budget.limitAmount))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text("\(budget.dateStart) → \(budget.dateEnd)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
