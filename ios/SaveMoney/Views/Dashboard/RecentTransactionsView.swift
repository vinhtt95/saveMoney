import SwiftUI

struct RecentTransactionsView: View {
    let transactions: [Transaction]
    let app: AppViewModel
    @State private var editingTransaction: Transaction?

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("Giao dịch gần đây")
                .font(.headline)
                .padding(.horizontal, DSSpacing.xs)

            if transactions.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "Chưa có giao dịch",
                    message: "Nhấn + để thêm giao dịch mới"
                )
            } else {
                VStack(spacing: DSSpacing.xs) {
                    ForEach(transactions) { tx in
                        RecentTransactionRow(tx: tx, app: app)
                            .onTapGesture { editingTransaction = tx }
                    }
                }
            }
        }
        .sheet(item: $editingTransaction) { tx in
            AddTransactionView(transaction: tx) {
                editingTransaction = nil
            }
        }
    }
}

private struct RecentTransactionRow: View {
    let tx: Transaction
    let app: AppViewModel

    private var categoryName: String {
        app.category(for: tx.categoryId)?.name ?? "—"
    }

    private var accountName: String {
        app.account(for: tx.accountId)?.name ?? "—"
    }

    var body: some View {
        HStack(spacing: DSSpacing.md) {
            CategoryIconView(name: categoryName, size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(categoryName)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(tx.note?.isEmpty == false ? tx.note! : accountName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                AmountText(amount: tx.amount, type: tx.type, font: .subheadline.weight(.semibold).monospacedDigit())
                Text(formatDate(tx.date))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(DSSpacing.md)
        .glassEffect(.regular, in: .rect(cornerRadius: DSRadius.md))
    }
}
