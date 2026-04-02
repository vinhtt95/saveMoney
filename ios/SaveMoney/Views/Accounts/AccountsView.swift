import SwiftUI

struct AccountsView: View {
    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var vm = AccountViewModel()
    @State private var showAddSheet = false

    var body: some View {
        NavigationView {
            List {
                ForEach(appVM.accounts) { account in
                    AccountRow(account: account, vm: vm)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await vm.delete(id: account.id, appVM: appVM) }
                            } label: {
                                Label("Xóa", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Tài khoản")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AccountFormView(vm: vm, account: nil)
                    .environmentObject(appVM)
            }
            .refreshable { await appVM.reload() }
        }
    }
}

struct AccountRow: View {
    @EnvironmentObject var appVM: AppViewModel
    let account: Account
    let vm: AccountViewModel
    @State private var showEdit = false

    private var balance: Double {
        appVM.balance(for: account.id)
    }

    var body: some View {
        Button { showEdit = true } label: {
            HStack {
                Text(account.name).font(.subheadline.bold()).foregroundColor(.primary)
                Spacer()
                Text(Formatters.formatVND(balance))
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(balance >= 0 ? .primary : .red)
            }
        }
        .sheet(isPresented: $showEdit) {
            AccountFormView(vm: vm, account: account)
                .environmentObject(appVM)
        }
    }
}
