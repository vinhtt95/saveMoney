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
    let store = LocalDataStore.shared
    private(set) var syncService: OfflineSyncService!

    var networkMonitor: NetworkMonitor?

    init() {
        syncService = OfflineSyncService(api: api, store: store)
        syncService.onSyncCompleted = { [weak self] in
            await self?.loadInitData()
        }
    }

    /// Called by the SwiftUI layer via .onChange(of: networkMonitor.isOnline)
    func handleNetworkChange(from wasOnline: Bool, to isNowOnline: Bool) {
        guard !wasOnline && isNowOnline else { return }
        print("📶 Network restored — starting sync")
        Task { await syncService.syncPending() }
    }

    // MARK: - Computed
    var isOnline: Bool { networkMonitor?.isOnline ?? true }

    var totalBalance: Double {
        let netTotals = getAccountNetTotals()
        return accounts.reduce(0.0) { sum, account in
            let base = accountBalances[account.id] ?? 0
            let net = netTotals[account.id] ?? 0
            return sum + base + net
        }
    }
    
    private func getAccountNetTotals() -> [String: Double] {
        var map: [String: Double] = [:]
        
        for tx in transactions {
            // 1. Unwrap accountId an toàn. Nếu tx không có accountId thì bỏ qua giao dịch này.
            guard let accountId = tx.accountId else { continue }
            
            // 2. Sử dụng biến accountId (lúc này đã là String chắc chắn 100%, không còn dấu ?)
            if map[accountId] == nil { map[accountId] = 0 }
            
            if tx.type == .transfer {
                // Tài khoản nguồn bị trừ tiền
                map[accountId, default: 0] -= abs(tx.amount)
                
                // Tài khoản đích được cộng tiền (nếu có)
                if let toId = tx.transferToId {
                    if map[toId] == nil { map[toId] = 0 }
                    map[toId, default: 0] += abs(tx.amount)
                }
            } else {
                // Các loại giao dịch khác (Income, Expense, Account)
                map[accountId, default: 0] += tx.amount
            }
        }
        return map
    }
    
    var pinnedBudgetId: String? {
        get {
            // Lấy trực tiếp từ settings cache (đã được load khi mở app)
            let id = settings["pinned_budget_id"]
            return (id?.isEmpty == true) ? nil : id
        }
        set {
            // 1. Cập nhật ngay lên RAM để UI phản hồi tức thì
            settings["pinned_budget_id"] = newValue ?? ""
            
            // 2. Chạy ngầm việc lưu xuống LocalStore & Server
            Task {
                try? await updateSetting("pinned_budget_id", newValue ?? "")
            }
        }
    }
    
    var totalGoldValue: Double {
        // 1. Lấy chuỗi JSON từ cấu hình settings
        guard let cacheString = settings["goldPriceCache"],
              let data = cacheString.data(using: .utf8),
              let cacheData = try? JSONDecoder().decode(GoldPriceCacheData.self, from: data) else {
            return 0.0 // Trả về 0 nếu chưa có cache
        }
        
        // 2. Tạo một Map (Từ điển) để tra cứu giá nhanh theo ID (productId)
        var priceMap: [String: Double] = [:]
        for item in cacheData.items {
            // Lưu giá mua vào dictionary với key là id (vd: "sjc_001")
            priceMap[item.id] = item.buy_price
        }
        
        // 3. Duyệt qua danh sách tài sản vàng để tính tổng tiền
        return goldAssets.reduce(0.0) { sum, asset in
            // Lấy giá dựa vào productId. Nếu không tìm thấy trong Map thì gán = 0.0
            let price = priceMap[asset.productId] ?? 0.0
            return sum + (price * asset.quantity)
        }
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
        let netTotals = getAccountNetTotals()
        let net = netTotals[accountId] ?? 0
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
        // 1. Tải dữ liệu từ local ngay lập tức để hiện UI
        loadFromLocal()
        isLoading = false
        
        connectionState = .loading
        errorMessage = nil

        // 2. Nếu online, thực hiện cập nhật dữ liệu từ server ngầm
        if isOnline {
            do {
                let data = try await api.fetchInit()
                apply(data)
                store.saveInitData(
                    transactions: data.transactions,
                    categories: data.categories,
                    accounts: data.accounts,
                    accountBalances: data.accountBalances,
                    budgets: data.budgets,
                    goldAssets: data.goldAssets,
                    settings: data.settings
                )
                connectionState = .connected
            } catch {
                // Nếu lỗi mạng, vẫn giữ data local đã load, chỉ cập nhật trạng thái kết nối
                connectionState = .disconnected
                print("Background sync failed: \(error.localizedDescription)")
            }
        } else {
            connectionState = .disconnected
        }
    }

    private func loadFromLocal() {
        let localTxs = store.fetchAllTransactions()
        if !localTxs.isEmpty {
            transactions = localTxs.sorted { $0.date > $1.date }
        }
        let localCategories = store.fetchAllCategories()
        if !localCategories.isEmpty { categories = localCategories }

        let localAccounts = store.fetchAllAccounts()
        if !localAccounts.isEmpty { accounts = localAccounts }

        let localBudgets = store.fetchAllBudgets()
        if !localBudgets.isEmpty { budgets = localBudgets }

        let localGoldAssets = store.fetchAllGoldAssets()
        if !localGoldAssets.isEmpty { goldAssets = localGoldAssets }

        let localBalances = store.fetchAccountBalances()
        if !localBalances.isEmpty { accountBalances = localBalances }

        let localSettings = store.fetchSettings()
        if !localSettings.isEmpty { settings = localSettings }
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
        if isOnline {
            do {
                let tx = try await api.createTransaction(dto)
                transactions.insert(tx, at: 0)
                transactions.sort { $0.date > $1.date }
                store.upsertTransaction(tx)
                await refreshBalances()
                return
            } catch APIError.networkError {
                // Network unavailable despite isOnline flag — fall through to offline path
            }
        }
        saveTransactionOffline(dto)
    }

    private func saveTransactionOffline(_ dto: TransactionCreateDTO) {
        let tempId = "offline_\(UUID().uuidString)"
        let tx = Transaction(
            id: tempId,
            date: dto.date,
            type: TransactionType(rawValue: dto.type) ?? .expense,
            categoryId: dto.categoryId,
            accountId: dto.accountId,
            transferToId: dto.transferToId,
            amount: dto.amount,
            note: dto.note
        )
        transactions.insert(tx, at: 0)
        transactions.sort { $0.date > $1.date }
        store.upsertTransaction(tx)
        let payload = try? JSONEncoder().encode(dto)
        store.enqueueSyncOp(operationType: "create", entityId: tempId, payload: payload)
    }

    func updateTransaction(_ id: String, _ dto: TransactionCreateDTO) async throws {
        if isOnline {
            do {
                let tx = try await api.updateTransaction(id, dto)
                if let idx = transactions.firstIndex(where: { $0.id == id }) {
                    transactions[idx] = tx
                }
                transactions.sort { $0.date > $1.date }
                store.upsertTransaction(tx)
                await refreshBalances()
                return
            } catch APIError.networkError {
                // Fall through to offline path
            }
        }
        let tx = Transaction(
            id: id,
            date: dto.date,
            type: TransactionType(rawValue: dto.type) ?? .expense,
            categoryId: dto.categoryId,
            accountId: dto.accountId,
            transferToId: dto.transferToId,
            amount: dto.amount,
            note: dto.note
        )
        if let idx = transactions.firstIndex(where: { $0.id == id }) {
            transactions[idx] = tx
        }
        transactions.sort { $0.date > $1.date }
        store.upsertTransaction(tx)
        let payload = try? JSONEncoder().encode(dto)
        let existing = store.fetchPendingOps().first(where: { $0.entityId == id })
        if let existing {
            existing.payload = payload
            try? store.container.mainContext.save()
        } else {
            store.enqueueSyncOp(operationType: "update", entityId: id, payload: payload)
        }
    }

    func deleteTransaction(_ id: String) async throws {
        if isOnline {
            do {
                try await api.deleteTransaction(id)
                transactions.removeAll { $0.id == id }
                store.deleteTransaction(id: id)
                await refreshBalances()
                return
            } catch APIError.networkError {
                // Fall through to offline path
            }
        }
        transactions.removeAll { $0.id == id }
        store.deleteTransaction(id: id)
        if store.hasPendingCreateOp(for: id) {
            store.removePendingOps(for: id)
        } else {
            store.replacePendingUpdateWithDelete(for: id)
            let hasPending = !store.fetchPendingOps().filter { $0.entityId == id }.isEmpty
            if !hasPending {
                store.enqueueSyncOp(operationType: "delete", entityId: id)
            }
        }
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
        let updatedCat = try await api.updateCategory(id, dto)
        
        if let index = categories.firstIndex(where: { $0.id == id }) {
            categories[index] = updatedCat
        }
        
        // Sửa lỗi: Gọi 'store' thay vì 'localStore'
        store.saveCategories(categories)
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

struct GoldPriceCacheData: Codable {
    struct Item: Codable {
        var id: String
        var buy_price: Double
        var sell_price: Double
    }
    var items: [Item]
}
