import SwiftUI

struct BudgetProgressRow: View {
    @EnvironmentObject var appVM: AppViewModel
    let budget: Budget
    let vm: BudgetViewModel
    @Environment(\.colorScheme) var scheme

    private var spent: Double { vm.spentAmount(for: budget, transactions: appVM.transactions) }
    private var progress: Double { vm.progress(for: budget, transactions: appVM.transactions) }
    private var remaining: Double { budget.limitAmount - spent }
    private var isOver: Bool { spent > budget.limitAmount }

    private var progressColor: Color {
        isOver ? Color.dsExpense : (progress > 0.8 ? Color.dsGold : Color.dsIncome)
    }

    var body: some View {
        GlassCard(radius: DSRadius.md, padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(budget.name)
                        .font(.dsTitle(15))
                        .foregroundStyle(Color.dsOnSurface(for: scheme))
                    Spacer()
                    Text(isOver ? "Vượt ngân sách" : Formatters.formatVNDShort(remaining))
                        .font(.dsBody(12, weight: .semibold))
                        .foregroundStyle(isOver ? Color.dsExpense : Color.dsIncome)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill((isOver ? Color.dsExpense : Color.dsIncome).opacity(0.15))
                        )
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color(.separator).opacity(0.4))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(LinearGradient(
                                colors: isOver
                                    ? [Color.dsExpense, Color(hex: "#e84393")]
                                    : [Color.dsPrimary(for: scheme), Color.dsSecondary(for: scheme)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: min(geo.size.width * CGFloat(progress), geo.size.width), height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Label(Formatters.formatVNDShort(spent), systemImage: "arrow.up.circle")
                        .font(.dsBody(11))
                        .foregroundStyle(Color.dsExpense)
                    Spacer()
                    Label(Formatters.formatVNDShort(budget.limitAmount), systemImage: "equal.circle")
                        .font(.dsBody(11))
                        .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                }

                Text("\(budget.dateStart) → \(budget.dateEnd)")
                    .font(.dsBody(10))
                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
            }
        }
    }
}
