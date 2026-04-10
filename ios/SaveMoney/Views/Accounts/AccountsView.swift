import SwiftUI

struct AccountsView: View {
    @Environment(AppViewModel.self) private var app
    @State private var showAddForm = false
    @State private var editingAccount: Account?
    
    var body: some View {
        List {
            ForEach(app.accounts) { account in
                let balance = app.computedBalance(for: account.id)
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(CategoryColorHelper.map(account.color).opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: account.icon)
                            .foregroundColor(CategoryColorHelper.map(account.color))
                            .font(.system(size: 20, weight: .semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(account.name)
                            .font(.subheadline.weight(.semibold))
                        Text(formatVND(balance))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(balance >= 0 ? DSColors.positive : DSColors.negative)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
                .onTapGesture { editingAccount = account }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task {
                            let vm = AccountViewModel(app: app)
                            await vm.deleteAccount(account.id)
                        }
                    } label: {
                        Label("Xóa", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Tài khoản")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddForm = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(DSColors.accent)
                }
            }
        }
        .sheet(isPresented: $showAddForm) {
            AccountFormView(account: nil) { showAddForm = false }
        }
        .sheet(item: $editingAccount) { acc in
            AccountFormView(account: acc) { editingAccount = nil }
        }
    }
}
