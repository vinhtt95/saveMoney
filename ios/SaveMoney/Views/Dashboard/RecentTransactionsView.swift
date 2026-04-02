import SwiftUI

struct RecentTransactionsView: View {
    let transactions: [Transaction]
    let appVM: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Giao dịch gần đây")
                .font(.headline)
            if transactions.isEmpty {
                Text("Chưa có giao dịch nào")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(transactions) { tx in
                    TransactionRowView(transaction: tx, appVM: appVM)
                    if tx.id != transactions.last?.id {
                        Divider()
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
