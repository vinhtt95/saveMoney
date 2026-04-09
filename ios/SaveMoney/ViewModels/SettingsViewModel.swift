import Foundation

@Observable
@MainActor
final class SettingsViewModel {
    var baseURL: String
    var isSubmitting = false
    var errorMessage: String?
    var saveSuccess = false
    
    var expenseCategories: [Category] {
        app.categories.filter { $0.type == .expense }
    }

    var incomeCategories: [Category] {
        app.categories.filter { $0.type == .income }
    }

    private let app: AppViewModel

    init(app: AppViewModel) {
        self.app = app
        self.baseURL = app.api.baseURL
    }

    func saveBaseURL() async {
        isSubmitting = true
        errorMessage = nil
        saveSuccess = false
        app.api.baseURL = baseURL
        do {
            try await app.updateSetting("base_url", baseURL)
            saveSuccess = true
        } catch {
            // Non-fatal: URL is saved locally regardless
            saveSuccess = true
        }
        isSubmitting = false
    }

    func updateDefaultType(_ type: TransactionType) async {
        try? await app.updateSetting(SettingsKey.defaultTransactionType, type.rawValue)
    }

    func updateDefaultAccount(_ id: String) async {
        try? await app.updateSetting(SettingsKey.defaultAccountId, id)
    }

    func updateDefaultExpenseCategory(_ id: String) async {
        try? await app.updateSetting(SettingsKey.defaultExpenseCategoryId, id)
    }

    func updateDefaultIncomeCategory(_ id: String) async {
        try? await app.updateSetting(SettingsKey.defaultIncomeCategoryId, id)
    }
}
