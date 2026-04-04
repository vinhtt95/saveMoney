import Foundation

@Observable
@MainActor
final class AccountViewModel {
    var isSubmitting = false
    var errorMessage: String?

    private let app: AppViewModel

    init(app: AppViewModel) {
        self.app = app
    }

    func addAccount(name: String, initialBalance: Double?) async {
        isSubmitting = true
        errorMessage = nil
        let dto = AccountCreateDTO(name: name, initialBalance: initialBalance)
        do {
            try await app.addAccount(dto)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }

    func updateAccount(id: String, name: String, balance: Double?) async {
        isSubmitting = true
        errorMessage = nil
        let dto = AccountUpdateDTO(name: name, balance: balance)
        do {
            try await app.updateAccount(id, dto)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }

    func deleteAccount(_ id: String) async {
        do {
            try await app.deleteAccount(id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
