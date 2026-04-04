import Foundation

@Observable
@MainActor
final class AppViewModel {
    // MARK: - State
    var transactions: [Transaction] = []
    var categories: [Category] = []
    var accounts: [Account] = []
    var accountBalances: [String: Double] = [:]
    var budgets: [Budget] = []
    var goldAssets: [GoldAsset] = []
    var settings: [String: String] = [:]

    var connectionState: ConnectionState = .loading
    var isLoading = true
    var errorMessage: String?

    let api = APIService()

    // MARK: - Computed
    var totalBalance: Double {
        accountBalances.values.reduce(0, +)
    }

    var totalGoldValue: Double {
        goldAssets.reduce(0) { $0 + ($1.currentSellPrice ?? 0) * $1.quantity }
    }

    var netWorth: Double { totalBalance + totalGoldValue }

    func monthlyIncome(period: String) -> Double {
        transactions
            .filter { $0.type == .income && $0.date.hasPrefix(period) }
            .reduce(0) { $0 + $1.amount }
    }

    func monthlyExpense(period: String) -> Double {
        transactions
            .filter { $0.type == .expense && $0.date.hasPrefix(period) }
            .reduce(0) { $0 + abs($1.amount) }
    }

    func computedBalance(for accountId: String) -> Double {
        let base = accountBalances[accountId] ?? 0
        let net = transactions.reduce(0.0) { sum, tx in
            if tx.type == .account { return sum }
            if tx.accountId == accountId {
                return sum + tx.amount
            }
            if tx.type == .transfer, tx.transferToId == accountId {
                return sum + abs(tx.amount)
            }
            return sum
        }
        return base + net
    }

    func category(for id: String?) -> Category? {
        guard let id else { return nil }
        return categories.first { $0.id == id }
    }

    func account(for id: String?) -> Account? {
        guard let id else { return nil }
        return accounts.first { $0.id == id }
    }

    var expenseCategories: [Category] { categories.filter { $0.type == .expense } }
    var incomeCategories: [Category] { categories.filter { $0.type == .income } }

    var defaultTransactionType: TransactionType {
        let raw = settings[SettingsKey.defaultTransactionType] ?? "Expense"
        return TransactionType(rawValue: raw) ?? .expense
    }
    var defaultAccountId: String? { settings[SettingsKey.defaultAccountId] }
    var defaultExpenseCategoryId: String? { settings[SettingsKey.defaultExpenseCategoryId] }
    var defaultIncomeCategoryId: String? { settings[SettingsKey.defaultIncomeCategoryId] }

    // MARK: - Load
    func loadInitData() async {
        isLoading = true
        connectionState = .loading
        errorMessage = nil
        do {
            let data = try await api.fetchInit()
            apply(data)
            connectionState = .connected
        } catch {
            connectionState = .disconnected
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func apply(_ data: AppInitData) {
        transactions = data.transactions.sorted { $0.date > $1.date }
        categories = data.categories
        accounts = data.accounts
        accountBalances = data.accountBalances
        budgets = data.budgets
        goldAssets = data.goldAssets
        settings = data.settings
    }

    // MARK: - Transaction CRUD
    func addTransaction(_ dto: TransactionCreateDTO) async throws {
        let tx = try await api.createTransaction(dto)
        transactions.insert(tx, at: 0)
        transactions.sort { $0.date > $1.date }
        // Refresh balances
        await refreshBalances()
    }

    func updateTransaction(_ id: String, _ dto: TransactionCreateDTO) async throws {
        let tx = try await api.updateTransaction(id, dto)
        if let idx = transactions.firstIndex(where: { $0.id == id }) {
            transactions[idx] = tx
        }
        transactions.sort { $0.date > $1.date }
        await refreshBalances()
    }

    func deleteTransaction(_ id: String) async throws {
        try await api.deleteTransaction(id)
        transactions.removeAll { $0.id == id }
        await refreshBalances()
    }

    private func refreshBalances() async {
        if let data = try? await api.fetchInit() {
            accountBalances = data.accountBalances
            goldAssets = data.goldAssets
        }
    }

    // MARK: - Account CRUD
    func addAccount(_ dto: AccountCreateDTO) async throws {
        let account = try await api.createAccount(dto)
        accounts.append(account)
        if let balance = dto.initialBalance {
            accountBalances[account.id] = balance
        }
        await refreshBalances()
    }

    func updateAccount(_ id: String, _ dto: AccountUpdateDTO) async throws {
        let account = try await api.updateAccount(id, dto)
        if let idx = accounts.firstIndex(where: { $0.id == id }) {
            accounts[idx] = account
        }
        await refreshBalances()
    }

    func deleteAccount(_ id: String) async throws {
        try await api.deleteAccount(id)
        accounts.removeAll { $0.id == id }
        accountBalances.removeValue(forKey: id)
    }

    // MARK: - Category CRUD
    func addCategory(_ dto: CategoryCreateDTO) async throws {
        let cat = try await api.createCategory(dto)
        categories.append(cat)
    }

    func updateCategory(_ id: String, _ dto: CategoryUpdateDTO) async throws {
        let cat = try await api.updateCategory(id, dto)
        if let idx = categories.firstIndex(where: { $0.id == id }) {
            categories[idx] = cat
        }
    }

    func deleteCategory(_ id: String) async throws {
        try await api.deleteCategory(id)
        categories.removeAll { $0.id == id }
    }

    // MARK: - Budget CRUD
    func addBudget(_ dto: BudgetCreateDTO) async throws {
        let budget = try await api.createBudget(dto)
        budgets.append(budget)
    }

    func deleteBudget(_ id: String) async throws {
        try await api.deleteBudget(id)
        budgets.removeAll { $0.id == id }
    }

    // MARK: - Gold Asset CRUD
    func addGoldAsset(_ dto: GoldAssetCreateDTO) async throws {
        let asset = try await api.createGoldAsset(dto)
        goldAssets.append(asset)
        await refreshBalances()
    }

    func deleteGoldAsset(_ id: String) async throws {
        try await api.deleteGoldAsset(id)
        goldAssets.removeAll { $0.id == id }
    }

    // MARK: - Settings
    func updateSetting(_ key: String, _ value: String) async throws {
        settings[key] = value
        try await api.updateSettings(settings)
    }
}
