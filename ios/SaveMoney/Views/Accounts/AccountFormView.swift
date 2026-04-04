import SwiftUI

struct AccountFormView: View {
    @Environment(AppViewModel.self) private var app
    let account: Account?
    let onDismiss: () -> Void

    @State private var name = ""
    @State private var balanceText = ""
    @State private var vm: AccountViewModel?
    @State private var errorMessage: String?

    private var isEditMode: Bool { account != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Thông tin") {
                    TextField("Tên tài khoản", text: $name)
                    if !isEditMode {
                        HStack {
                            TextField("Số dư ban đầu (0)", text: $balanceText)
                                .keyboardType(.numberPad)
                            Text("₫").foregroundStyle(.secondary)
                        }
                    }
                }
                if let errorMessage {
                    Section { ErrorBanner(message: errorMessage) }
                }
            }
            .navigationTitle(isEditMode ? "Sửa tài khoản" : "Thêm tài khoản")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Hủy") { onDismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditMode ? "Lưu" : "Thêm") {
                        Task { await handleSubmit() }
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            vm = AccountViewModel(app: app)
            name = account?.name ?? ""
        }
    }

    private func handleSubmit() async {
        guard let vm else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let balance = Double(balanceText.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: ".", with: ""))

        if let account {
            await vm.updateAccount(id: account.id, name: trimmedName, balance: nil)
        } else {
            await vm.addAccount(name: trimmedName, initialBalance: balance)
        }

        if let err = vm.errorMessage {
            errorMessage = err
        } else {
            onDismiss()
        }
    }
}
