import Foundation

@MainActor
class AccountViewModel: ObservableObject {
    @Published var isSubmitting = false
    @Published var submitError: String?

    private let api = APIService.shared

    func create(_ body: CreateAccountRequest, appVM: AppViewModel) async {
        isSubmitting = true
        submitError = nil
        do {
            let account = try await api.createAccount(body)
            appVM.accounts.append(account)
            if let bal = body.balance {
                appVM.accountBalances[account.id] = bal
            }
        } catch {
            submitError = error.localizedDescription
        }
        isSubmitting = false
    }

    func update(id: String, body: UpdateAccountRequest, appVM: AppViewModel) async {
        isSubmitting = true
        submitError = nil
        do {
            let updated = try await api.updateAccount(id: id, body: body)
            if let idx = appVM.accounts.firstIndex(where: { $0.id == id }) {
                appVM.accounts[idx] = updated
            }
            if let bal = body.balance {
                appVM.accountBalances[id] = bal
            }
        } catch {
            submitError = error.localizedDescription
        }
        isSubmitting = false
    }

    func delete(id: String, appVM: AppViewModel) async {
        do {
            try await api.deleteAccount(id: id)
            appVM.accounts.removeAll { $0.id == id }
            appVM.accountBalances.removeValue(forKey: id)
        } catch {
            submitError = error.localizedDescription
        }
    }
}
