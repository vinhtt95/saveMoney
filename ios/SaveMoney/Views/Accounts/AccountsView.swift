import SwiftUI

struct AccountsView: View {
    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var vm = AccountViewModel()
    @State private var showAddSheet = false
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ZStack {
            DSMeshBackground().ignoresSafeArea()
            VStack(spacing: 0) {
                List {
                    ForEach(appVM.accounts) { account in
                        AccountRow(account: account, vm: vm)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
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
                .scrollContentBackground(.hidden)
                .refreshable { await appVM.reload() }
            }
        }
        .navigationTitle("Tài khoản")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(LinearGradient.dsCTAGradient(scheme: scheme)))
                }
            }
        }
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .sheet(isPresented: $showAddSheet) {
            AccountFormView(vm: vm, account: nil)
                .environmentObject(appVM)
        }
    }
}

struct AccountRow: View {
    @EnvironmentObject var appVM: AppViewModel
    let account: Account
    let vm: AccountViewModel
    @State private var showEdit = false
    @Environment(\.colorScheme) var scheme

    private var balance: Double { appVM.balance(for: account.id) }

    var body: some View {
        Button { showEdit = true } label: {
            GlassCard(radius: DSRadius.md, padding: 14) {
                HStack(spacing: 12) {
                    GradientCircleIcon(
                        systemName: "creditcard.fill",
                        colors: [Color(hex: "#60a5fa"), Color(hex: "#3b82f6")],
                        size: 38
                    )
                    Text(account.name)
                        .font(.dsBody(15, weight: .semibold))
                        .foregroundStyle(Color.dsOnSurface(for: scheme))
                    Spacer()
                    Text(Formatters.formatVNDShort(balance))
                        .font(.dsTitle(15))
                        .foregroundStyle(balance >= 0 ? Color.dsIncome : Color.dsExpense)
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            AccountFormView(vm: vm, account: account)
                .environmentObject(appVM)
        }
    }
}
