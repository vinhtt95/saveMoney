import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    let appVM: AppViewModel

    private var categoryName: String {
        appVM.category(for: transaction.categoryId)?.name ?? "—"
    }

    private var accountName: String {
        appVM.account(for: transaction.accountId)?.name ?? "—"
    }

    private var amountColor: Color {
        switch transaction.type {
        case .income: return .green
        case .expense: return .red
        default: return .primary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(categoryName)
                        .font(.subheadline.bold())
                    Text(accountName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Formatters.formatVND(transaction.amount))
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundColor(amountColor)
                    Text(transaction.date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            if let note = transaction.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}
