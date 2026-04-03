import SwiftUI

struct RecentTransactionsView: View {
    let transactions: [Transaction]
    let appVM: AppViewModel
    @Environment(\.colorScheme) var scheme
    @State private var selectedTransaction: Transaction? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DSSectionHeader(title: "Giao dịch gần đây")

            if transactions.isEmpty {
                GlassCard(radius: DSRadius.md, padding: 20) {
                    Text("Chưa có giao dịch nào")
                        .font(.dsBody(14))
                        .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                        .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(transactions) { tx in
                        GlassCard(radius: DSRadius.md, padding: 12) {
                            TransactionRowView(transaction: tx, appVM: appVM) {
                                selectedTransaction = tx
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedTransaction) { tx in
            AddTransactionView(isPresented: Binding(
                get: { selectedTransaction != nil },
                set: { if !$0 { selectedTransaction = nil } }
            ), transaction: tx)
            .environmentObject(appVM)
        }
    }
}
