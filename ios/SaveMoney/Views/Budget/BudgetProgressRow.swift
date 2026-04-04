import SwiftUI

struct BudgetProgressRow: View {
    let budget: Budget
    let vm: BudgetViewModel
    let app: AppViewModel

    private var spent: Double { vm.spentAmount(budget: budget) }
    private var progress: Double { vm.progress(budget: budget) }

    private var progressColor: Color {
        if progress >= 1.0 { return .red }
        if progress >= 0.8 { return .orange }
        return .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HStack {
                Text(budget.name)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(formatVNDShort(budget.limit - spent))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(progress >= 1 ? .red : .secondary)
            }

            ProgressView(value: min(progress, 1.0))
                .tint(progressColor)
                .scaleEffect(y: 1.5)

            HStack {
                Text("\(formatVNDShort(spent)) / \(formatVNDShort(budget.limit))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(formatDate(budget.dateStart)) → \(formatDate(budget.dateEnd))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Category tags
            let cats = budget.categoryIds.compactMap { app.category(for: $0) }
            if !cats.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DSSpacing.xs) {
                        ForEach(cats) { cat in
                            Text(cat.name)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.secondary.opacity(0.1), in: Capsule())
                        }
                    }
                }
            }
        }
        .padding(DSSpacing.md)
    }
}
