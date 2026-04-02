import SwiftUI

struct AccountFormView: View {
    @EnvironmentObject var appVM: AppViewModel
    @ObservedObject var vm: AccountViewModel
    let account: Account?
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var scheme

    @State private var name: String
    @State private var balance: String

    init(vm: AccountViewModel, account: Account?) {
        self.vm = vm
        self.account = account
        _name = State(initialValue: account?.name ?? "")
        _balance = State(initialValue: "")
    }

    var body: some View {
        NavigationView {
            ZStack {
                DSMeshBackground().ignoresSafeArea()
                VStack(spacing: 16) {
                    GlassCard(radius: DSRadius.lg, padding: 16) {
                        VStack(spacing: 14) {
                            GlassFormField(label: "Tên tài khoản", text: $name)
                            GlassFormField(label: "Số dư (VND)", text: $balance, keyboardType: .numberPad)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    if let err = vm.submitError {
                        Text(err).font(.dsBody(12)).foregroundStyle(Color.dsExpense)
                            .padding(.horizontal, 20)
                    }

                    GlassPillButton(label: vm.isSubmitting ? "Đang lưu..." : "Lưu") {
                        save()
                    }
                    .disabled(vm.isSubmitting || name.isEmpty)
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationTitle(account == nil ? "Thêm tài khoản" : "Sửa tài khoản")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") { dismiss() }
                        .foregroundStyle(Color.dsPrimary(for: scheme))
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
        .onAppear {
            if let acc = account {
                balance = String(appVM.balance(for: acc.id))
            }
        }
    }

    private func save() {
        let bal = Double(balance.replacingOccurrences(of: ",", with: ""))
        Task {
            if let acc = account {
                await vm.update(id: acc.id, body: UpdateAccountRequest(name: name, balance: bal), appVM: appVM)
            } else {
                await vm.create(CreateAccountRequest(name: name, balance: bal), appVM: appVM)
            }
            if vm.submitError == nil { dismiss() }
        }
    }
}
