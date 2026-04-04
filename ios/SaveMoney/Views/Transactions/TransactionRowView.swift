import SwiftUI

struct TransactionRowView: View {
    let tx: Transaction
    let app: AppViewModel

    private var categoryName: String { app.category(for: tx.categoryId)?.name ?? "—" }
    private var accountName: String { app.account(for: tx.accountId)?.name ?? "—" }

    var body: some View {
        HStack(spacing: DSSpacing.md) {
            CategoryIconView(name: categoryName, size: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(categoryName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: DSSpacing.xs) {
                    Image(systemName: "creditcard")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(accountName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let note = tx.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            AmountText(amount: tx.amount, type: tx.type, font: .subheadline.weight(.bold).monospacedDigit())
        }
        .padding(.vertical, DSSpacing.sm)
    }
}
