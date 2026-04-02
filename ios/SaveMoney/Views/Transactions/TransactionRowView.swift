import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    let appVM: AppViewModel
    @Environment(\.colorScheme) var scheme

    private var categoryName: String {
        appVM.category(for: transaction.categoryId)?.name ?? "—"
    }

    private var accountName: String {
        appVM.account(for: transaction.accountId)?.name ?? "—"
    }

    private var amountColor: Color {
        switch transaction.type {
        case .income:   return Color.dsIncome
        case .expense:  return Color.dsExpense
        default:        return Color.dsOnSurfaceVariant(for: scheme)
        }
    }

    private var amountPrefix: String {
        switch transaction.type {
        case .income:  return "+"
        case .expense: return "-"
        default:       return ""
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            GradientCircleIcon(
                systemName: categorySystemIcon(for: categoryName),
                colors: categoryIconColors(for: categoryName),
                size: 42
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(categoryName)
                    .font(.dsBody(15, weight: .semibold))
                    .foregroundStyle(Color.dsOnSurface(for: scheme))
                Text(accountName)
                    .font(.dsBody(12))
                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.dsBody(12))
                        .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(amountPrefix)\(Formatters.formatVNDShort(abs(transaction.amount)))")
                    .font(.dsTitle(15))
                    .foregroundStyle(amountColor)
                Text(Formatters.formatDate(transaction.date))
                    .font(.dsBody(11))
                    .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
            }
        }
        .padding(.vertical, 4)
    }
}
