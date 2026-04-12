import SwiftUI

struct RecentTransactionsView: View {
    let transactions: [Transaction]
    let app: AppViewModel
    @State private var editingTransaction: Transaction?

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) { // Tăng spacing để thoáng hơn
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
                VStack(spacing: DSSpacing.sm) { // Spacing giữa các card thoáng hơn
                    ForEach(transactions) { tx in
                        RecentTransactionRow(tx: tx, app: app)
                            .contentShape(Rectangle()) // MỞ RỘNG VÙNG CLICK: Giúp click được toàn bộ vùng tile
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
    
    private var displayAmount: Double {
        guard tx.type == .income else { return tx.amount }
        
        if app.egoMode == .humble {
            return tx.amount * app.humbleFactor
        } else if app.egoMode == .arrogant {
            return tx.amount * app.arrogantFactor
        }
        return tx.amount
    }

    var body: some View {
        let cat = app.category(for: tx.categoryId)
        
        HStack(spacing: DSSpacing.md) {
            // Icon danh mục với kích thước lớn hơn một chút
            CategoryIconView(category: cat, fallbackName: categoryName, size: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(categoryName)
                    .font(.subheadline.weight(.semibold)) // Tăng weight để rõ ràng hơn
                    .lineLimit(1)
                
                // Hiển thị cả tài khoản và ghi chú (nếu có) để layout đầy đủ hơn
                HStack(spacing: 4) {
                    Text(accountName)
                    if let note = tx.note, !note.isEmpty {
                        Text("•")
                        Text(note)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                AmountText(amount: displayAmount, type: tx.type, font: .subheadline.weight(.bold).monospacedDigit())
                Text(formatDate(tx.date))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(DSSpacing.md)
        .glassEffect(.regular.tint(DSColors.expense.opacity(0.05)), in: .rect(cornerRadius: DSRadius.lg))
    }
}
