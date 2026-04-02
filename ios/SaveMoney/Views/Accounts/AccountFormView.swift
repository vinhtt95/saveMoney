import SwiftUI

struct AccountFormView: View {
    @EnvironmentObject var appVM: AppViewModel
    @ObservedObject var vm: AccountViewModel
    let account: Account?
    @Environment(\.dismiss) var dismiss

    @State private var name: String
    @State private var balance: String

    init(vm: AccountViewModel, account: Account?) {
        self.vm = vm
        self.account = account
        _name = State(initialValue: account?.name ?? "")
        // balance comes from accountBalances — accessed via appVM, not account
        _balance = State(initialValue: "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Thông tin tài khoản") {
                    TextField("Tên tài khoản", text: $name)
                    TextField("Số dư ban đầu (VND)", text: $balance)
                        .keyboardType(.numberPad)
                }
                if let err = vm.submitError {
                    Section { Text(err).foregroundColor(.red).font(.caption) }
                }
            }
            .navigationTitle(account == nil ? "Thêm tài khoản" : "Sửa tài khoản")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Hủy") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lưu") { save() }
                        .disabled(vm.isSubmitting || name.isEmpty)
                }
            }
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
