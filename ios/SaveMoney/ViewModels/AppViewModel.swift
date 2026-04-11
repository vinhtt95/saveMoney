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
    private var isSyncingAndFetching = false
    
    var connectionState: ConnectionState = .loading
    var isLoading = true
    var errorMessage: String?
    private var isFetchingInit = false
    private var lastFetchTime: Date? = nil
    
    let api = APIService()
    let store = LocalDataStore.shared
    private(set) var syncService: OfflineSyncService!
    
    var networkMonitor: NetworkMonitor?
    
    // MARK: - State Caching (Performance Optimization)
    private(set) var totalBalance: Double = 0.0
    private(set) var totalGoldValue: Double = 0.0
    private(set) var accountNetTotals: [String: Double] = [:]
    
    init() {
        self.networkMonitor = NetworkMonitor()
        syncService = OfflineSyncService(api: api, store: store)
        
        // Nhận tín hiệu từ SyncService: Quá 3 lần lỗi -> Chuyển thành Offline
        syncService.onSyncHalted = { [weak self] in
            self?.connectionState = .disconnected
        }
    }
    
    // Luồng xử lý tiêu chuẩn: Đồng bộ đẩy lên (nếu có) -> Tải dữ liệu mới về
    func syncAndFetch() async {
        // 1. NGAY LẬP TỨC đổ data Local ra UI (Mất 0.01 giây), không bắt user đợi
        // 1. IMMEDIATELY load Local data to UI (Takes 0.01s), no waiting
        loadFromLocal()
        isLoading = false
        
        // 2. Khóa luồng đồng bộ / Sync Lock
        guard !isSyncingAndFetching else { return }
        isSyncingAndFetching = true
        defer { isSyncingAndFetching = false }
        
        if isOnline {
            connectionState = .loading
            
            // 3. Fast Ping với timeout siêu ngắn 1 giây
            // 3. Fast Ping with a super short 1-second timeout
            let isReachable = await checkServerReachability(timeout: 1.0)
            
            if isReachable {
                // Server sống -> Chạy hàng đợi đẩy dữ liệu lên
                await syncService.syncPending(isOnline: true)
                
                // Nếu hàng đợi đã dọn sạch -> Kéo data mới nhất từ Server về
                if store.fetchPendingOps().isEmpty {
                    await loadInitData(bypassOfflineCheck: true)
                } else {
                    print("⚠️ Sync queue is not empty due to errors. Skipping server fetch to protect local data.")
                    connectionState = .disconnected
                }
            } else {
                // Server chết/lag -> Ép về Offline, user dùng tiếp data Local ở Bước 1
                // Server dead/lagging -> Force Offline, user continues with Local data from Step 1
                print("🔴 Fast Ping (1s) failed. Ép App vào trạng thái Offline ngay lập tức.")
                connectionState = .disconnected
            }
        } else {
            connectionState = .disconnected
        }
    }
    
    // Gọi khi App mở lại từ nền
    func handleAppActive() {
        syncService.resetSession()
        Task { await syncAndFetch() }
    }
    
    /// Called by the SwiftUI layer via .onChange(of: networkMonitor.isOnline)
    func handleNetworkChange(from wasOnline: Bool, to isNowOnline: Bool) {
        guard !wasOnline && isNowOnline else { return }
        print("📶 Network restored")
        Task { await syncAndFetch() }
    }
    
    /// Kiểm tra nhanh xem Server có thực sự phản hồi không (Timeout siêu ngắn: 3s)
    func checkServerReachability(timeout: TimeInterval = 3.0) async -> Bool {
        guard isOnline else { return false }
        guard let url = URL(string: "\(api.baseURL)/api/settings") else { return false }
        
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "HEAD"
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode < 500 {
                return true
            }
            return false
        } catch {
            return false
        }
    }
    
    // MARK: - Computed
    var isOnline: Bool { networkMonitor?.isOnline ?? true }
    
    var netWorth: Double { totalBalance + totalGoldValue }
    
    // Hàm trung tâm tính toán lại tất cả các thông số tài chính (Chỉ gọi khi data thay đổi)
    func recalculateFinancials() {
        // 1. Tính toán Account Net Totals (O(N) 1 lần duy nhất)
        var map: [String: Double] = [:]
        for tx in transactions {
            guard let accountId = tx.accountId else { continue }
            if tx.type == .transfer {
                map[accountId, default: 0] -= abs(tx.amount)
                if let toId = tx.transferToId {
                    map[toId, default: 0] += abs(tx.amount)
                }
            } else {
                map[accountId, default: 0] += tx.amount
            }
        }
        self.accountNetTotals = map
        
        // 2. Tính Total Balance
        self.totalBalance = accounts.reduce(0.0) { sum, account in
            let base = accountBalances[account.id] ?? 0
            let net = map[account.id] ?? 0
            return sum + base + net
        }
        
        // 3. Tính Total Gold Value (Chỉ chạy JSONDecoder 1 lần)
        if let cacheString = settings["goldPriceCache"],
           let data = cacheString.data(using: .utf8),
           let cacheData = try? JSONDecoder().decode(GoldPriceCacheData.self, from: data) {
            
            var priceMap: [String: Double] = [:]
            for item in cacheData.items {
                priceMap[item.id] = item.buy_price
            }
            
            self.totalGoldValue = goldAssets.reduce(0.0) { sum, asset in
                let price = priceMap[asset.productId] ?? 0.0
                return sum + (price * asset.quantity)
            }
        } else {
            self.totalGoldValue = 0.0
        }
        
        updateWidget()
    }
    
    var pinnedBudgetId: String? {
        get {
            let id = settings["pinned_budget_id"]
            return (id?.isEmpty == true) ? nil : id
        }
        set {
            settings["pinned_budget_id"] = newValue ?? ""
            Task {
                try? await updateSetting("pinned_budget_id", newValue ?? "")
            }
        }
    }
    
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
        let net = accountNetTotals[accountId] ?? 0
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
    func loadInitData(bypassOfflineCheck: Bool = false) async {
        guard !isFetchingInit else { return }
        
        // 🛡️ CHẶN GHI ĐÈ: Ưu tiên dữ liệu Local hơn dữ liệu Server
        if !bypassOfflineCheck {
            let pendingOps = store.fetchPendingOps()
            if !pendingOps.isEmpty {
                if isOnline {
                    print("⚠️ Dữ liệu Local đang chờ Push. Chuyển hướng sang Sync trước khi Fetch.")
                    Task { await syncAndFetch() }
                } else {
                    print("⚠️ Đang offline. Bỏ qua lệnh lấy từ Server để tránh ghi đè dữ liệu sửa đổi.")
                    loadFromLocal() // Đảm bảo UI hiện đúng data người dùng vừa sửa/xóa
                    isLoading = false
                    connectionState = .disconnected
                }
                return
            }
        }
        
        // CHẶN THỜI GIAN (THROTTLE)
        if let last = lastFetchTime, Date().timeIntervalSince(last) < 3.0 {
            return
        }
        
        isFetchingInit = true
        defer { isFetchingInit = false }
        
        loadFromLocal()
        isLoading = false
        connectionState = .loading
        errorMessage = nil
        
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
                lastFetchTime = Date()
                
            } catch {
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
        
        recalculateFinancials()
    }
    
    private func apply(_ data: AppInitData) {
        transactions = data.transactions.sorted { $0.date > $1.date }
        categories = data.categories
        accounts = data.accounts
        accountBalances = data.accountBalances
        budgets = data.budgets
        goldAssets = data.goldAssets
        settings = data.settings
        
        recalculateFinancials()
    }
    
    // MARK: - Transaction CRUD
    
    func addTransaction(_ dto: TransactionCreateDTO, forceOffline: Bool = false) async throws {
        if !forceOffline && isOnline {
            do {
                let tx = try await api.createTransaction(dto)
                transactions.insert(tx, at: 0)
                transactions.sort { $0.date > $1.date }
                store.upsertTransaction(tx)
                await refreshBalances()
                recalculateFinancials()
                return
            } catch APIError.networkError {
                print("⚠️ Server unreachable, saving offline")
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
    
    func updateTransaction(_ id: String, _ dto: TransactionCreateDTO, forceOffline: Bool = false) async throws {
        if !forceOffline && isOnline {
            do {
                let tx = try await api.updateTransaction(id, dto)
                if let idx = transactions.firstIndex(where: { $0.id == id }) {
                    transactions[idx] = tx
                }
                transactions.sort { $0.date > $1.date }
                store.upsertTransaction(tx)
                await refreshBalances()
                recalculateFinancials()
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
        recalculateFinancials()
    }
    
    func deleteTransaction(_ id: String, forceOffline: Bool = false) async throws {
        if !forceOffline && isOnline {
            do {
                try await api.deleteTransaction(id)
                transactions.removeAll { $0.id == id }
                store.deleteTransaction(id: id)
                await refreshBalances()
                recalculateFinancials()
                return
            } catch { // <--- Xóa "APIError.networkError" để bắt MỌI LỖI (500, Timeout...)
                print("⚠️ Lỗi API khi xóa: \(error), tự động lưu vào hàng đợi Offline")
                // Code sẽ tự động lọt xuống khối Offline bên dưới
            }
        }
        
        // Luồng Offline
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
        recalculateFinancials()
    }
    
    private func refreshBalances() async {
        if let data = try? await api.fetchInit() {
            accountBalances = data.accountBalances
            goldAssets = data.goldAssets
            recalculateFinancials()
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
        recalculateFinancials()
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
    
    func updateBudget(_ id: String, _ dto: BudgetCreateDTO) async throws {
        let updatedBudget = try await api.updateBudget(id, dto)
        if let index = budgets.firstIndex(where: { $0.id == id }) {
            budgets[index] = updatedBudget
        }
        store.saveBudgets(budgets)
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
        recalculateFinancials()
    }
    
    // MARK: - Settings
    func updateSetting(_ key: String, _ value: String) async throws {
        settings[key] = value
        if key == "goldPriceCache" {
            recalculateFinancials()
        }
        try await api.updateSettings(settings)
    }
    
    // MARK: - Widget Update
    private func updateWidget() {
        // 1. Lấy tháng hiện tại (Định dạng: "yyyy-MM", ví dụ: "2026-04")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let currentMonth = formatter.string(from: Date())
        
        // 2. Tính thu chi trong tháng
        let income = monthlyIncome(period: currentMonth)
        let expense = monthlyExpense(period: currentMonth)
        
        // 3. Xử lý Budget đang ghim
        var wBudgetName = "Chưa ghim"
        var wBudgetLimit = 1.0 // Để 1.0 tránh lỗi chia cho 0 ở Widget
        var wBudgetSpent = 0.0
        
        if let pinnedId = pinnedBudgetId, let budget = budgets.first(where: { $0.id == pinnedId }) {
            wBudgetName = budget.name
            wBudgetLimit = budget.limit
            
            // Tính tổng tiền đã tiêu cho các category của budget này trong khoảng thời gian của budget
            wBudgetSpent = transactions.filter { tx in
                tx.type == .expense &&
                tx.date >= budget.dateStart &&
                tx.date <= budget.dateEnd &&
                budget.categoryIds.contains(tx.categoryId ?? "")
            }.reduce(0) { $0 + abs($1.amount) }
        }
        
        // 4. Đẩy sang WidgetDataManager
        WidgetDataManager.shared.updateWidgetData(
            totalBalance: self.totalBalance, // Bạn có thể đổi thành self.netWorth nếu muốn hiện cả vàng
            income: income,
            expense: expense,
            budgetName: wBudgetName,
            budgetLimit: wBudgetLimit,
            budgetSpent: wBudgetSpent
        )
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
