import SwiftUI

struct RecentTransactionsView: View {
    let transactions: [Transaction]
    let appVM: AppViewModel
    @Environment(\.colorScheme) var scheme
    @State private var selectedTransaction: Transaction? = nil
    @State private var showEditSheet = false

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
                                showEditSheet = true
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let tx = selectedTransaction {
                AddTransactionView(isPresented: $showEditSheet, transaction: tx)
                    .environmentObject(appVM)
            }
        }
    }
}
