import Foundation

@MainActor
class AppViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var categories: [Category] = []
    @Published var accounts: [Account] = []
    @Published var accountBalances: [String: Double] = [:]
    @Published var budgets: [Budget] = []
    @Published var goldAssets: [GoldAsset] = []
    @Published var settings: [String: String] = [:]

    @Published var isLoading = false
    @Published var loadError: String?
    @Published var isConnected = false

    private let api = APIService.shared

    func loadInitData() async {
        isLoading = true
        loadError = nil
        do {
            let data = try await api.getInitData()
            transactions = data.transactions
            categories = data.categories
            accounts = data.accounts
            accountBalances = data.accountBalances
            budgets = data.budgets
            goldAssets = data.goldAssets
            settings = data.settings
            isConnected = true
        } catch {
            loadError = error.localizedDescription
            isConnected = false
        }
        isLoading = false
    }

    func reload() async {
        await loadInitData()
    }

    // MARK: - Convenience

    func category(for id: String?) -> Category? {
        guard let id else { return nil }
        return categories.first { $0.id == id }
    }

    func account(for id: String?) -> Account? {
        guard let id else { return nil }
        return accounts.first { $0.id == id }
    }

    func balance(for accountId: String) -> Double {
        accountBalances[accountId] ?? 0
    }

    var expenseCategories: [Category] {
        categories.filter { $0.type == .expense }
    }

    var incomeCategories: [Category] {
        categories.filter { $0.type == .income }
    }

    var totalBalance: Double {
        accounts.reduce(0) { $0 + balance(for: $1.id) }
    }

    func monthlyStats(yyyyMM: String) -> (income: Double, expense: Double) {
        let filtered = transactions.filter { $0.date.hasPrefix(yyyyMM) }
        let income = filtered.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expense = filtered.filter { $0.type == .expense }.reduce(0) { $0 + abs($1.amount) }
        return (income, expense)
    }
}
