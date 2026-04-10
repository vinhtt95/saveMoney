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
    var pendingOps: [PendingSyncOperation] = []

    init(app: AppViewModel) {
        self.app = app
        self.baseURL = app.api.baseURL
        refreshPendingOps()
    }
    
    func refreshPendingOps() {
        // Lấy danh sách các thao tác chưa đồng bộ từ Store
        pendingOps = app.store.fetchPendingOps()
    }
    
    func deletePendingOp(_ op: PendingSyncOperation) {
        app.store.dequeueSyncOp(op)
        refreshPendingOps()
    }
    
    func manualReconnect() async {
        isSubmitting = true
        // Việc gọi loadInitData sẽ cập nhật app.connectionState dựa trên kết quả API thực tế
        await app.loadInitData()
        refreshPendingOps()
        isSubmitting = false
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
