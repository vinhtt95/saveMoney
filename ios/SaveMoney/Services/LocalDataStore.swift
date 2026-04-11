import Foundation
import SwiftData

// MARK: - SwiftData Models

@Model
final class LocalTransaction {
    @Attribute(.unique) var id: String
    var date: String
    var type: String
    var categoryId: String?
    var accountId: String?
    var transferToId: String?
    var amount: Double
    var note: String?
    
    init(from tx: Transaction) {
        self.id = tx.id
        self.date = tx.date
        self.type = tx.type.rawValue
        self.categoryId = tx.categoryId
        self.accountId = tx.accountId
        self.transferToId = tx.transferToId
        self.amount = tx.amount
        self.note = tx.note
    }
    
    func toTransaction() -> Transaction? {
        guard let txType = TransactionType(rawValue: type) else { return nil }
        return Transaction(
            id: id, date: date, type: txType,
            categoryId: categoryId, accountId: accountId,
            transferToId: transferToId, amount: amount, note: note
        )
    }
    
    func update(from tx: Transaction) {
        date = tx.date; type = tx.type.rawValue
        categoryId = tx.categoryId; accountId = tx.accountId
        transferToId = tx.transferToId; amount = tx.amount; note = tx.note
    }
}

@Model
final class LocalCategory {
    @Attribute(.unique) var id: String
    var name: String
    var type: String
    var icon: String?
    var color: String?
    
    init(from cat: Category) {
        self.id = cat.id
        self.name = cat.name
        self.type = cat.type.rawValue
        self.icon = cat.icon
        self.color = cat.color
    }
    
    func toCategory() -> Category? {
        guard let catType = CategoryType(rawValue: type) else { return nil }
        return Category(
            id: id,
            name: name,
            type: catType,
            icon: icon ?? "tag.fill",
            color: color ?? "accent"
        )
    }
}

@Model
final class LocalAccount {
    @Attribute(.unique) var id: String
    var name: String
    var icon: String?
    var color: String?
    var balance: Double?
    
    init(from account: Account) {
        self.id = account.id
        self.name = account.name
        self.icon = account.icon
        self.color = account.color
        self.balance = account.balance
    }
    
    func toAccount() -> Account {
        // Cung cấp giá trị mặc định để tránh lỗi crash với các dữ liệu Local cũ chưa có icon/color
        Account(
            id: id,
            name: name,
            icon: icon ?? "creditcard.fill",
            color: color ?? "accent",
            balance: balance ?? 0.0
        )
    }
}

@Model
final class LocalBudget {
    @Attribute(.unique) var id: String
    var name: String
    var limit: Double
    var dateStart: String
    var dateEnd: String
    var categoryIdsJSON: String  // JSON-encoded [String]
    
    init(from budget: Budget) {
        self.id = budget.id
        self.name = budget.name
        self.limit = budget.limit
        self.dateStart = budget.dateStart
        self.dateEnd = budget.dateEnd
        self.categoryIdsJSON = (try? String(data: JSONEncoder().encode(budget.categoryIds), encoding: .utf8)) ?? "[]"
    }
    
    func toBudget() -> Budget {
        let ids = (try? JSONDecoder().decode([String].self, from: Data(categoryIdsJSON.utf8))) ?? []
        return Budget(id: id, name: name, limit: limit, dateStart: dateStart, dateEnd: dateEnd, categoryIds: ids)
    }
}

@Model
final class LocalGoldAsset {
    @Attribute(.unique) var id: String
    var brand: String
    var productId: String
    var productName: String
    var quantity: Double
    var note: String?
    var createdAt: String?
    var currentSellPrice: Double?
    
    init(from asset: GoldAsset) {
        self.id = asset.id
        self.brand = asset.brand.rawValue
        self.productId = asset.productId
        self.productName = asset.productName
        self.quantity = asset.quantity
        self.note = asset.note
        self.createdAt = asset.createdAt
        self.currentSellPrice = asset.currentSellPrice
    }
    
    func toGoldAsset() -> GoldAsset? {
        guard let brand = GoldBrand(rawValue: brand) else { return nil }
        return GoldAsset(id: id, brand: brand, productId: productId, productName: productName,
                         quantity: quantity, note: note, createdAt: createdAt, currentSellPrice: currentSellPrice)
    }
}

/// Stores flat key-value settings and account balances
@Model
final class LocalKeyValue {
    @Attribute(.unique) var key: String
    var value: String
    
    init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

@Model
final class PendingSyncOperation {
    @Attribute(.unique) var id: UUID
    /// "create", "update", "delete"
    var operationType: String
    /// The transaction ID (may be a local temp ID for "create" ops)
    var entityId: String
    /// JSON-encoded TransactionCreateDTO (nil for "delete")
    var payload: Data?
    var createdAt: Date
    var retryCount: Int
    
    init(operationType: String, entityId: String, payload: Data? = nil) {
        self.id = UUID()
        self.operationType = operationType
        self.entityId = entityId
        self.payload = payload
        self.createdAt = Date()
        self.retryCount = 0
    }
}

// MARK: - LocalDataStore

@MainActor
final class LocalDataStore {
    static let shared = LocalDataStore()
    
    let container: ModelContainer
    
    private init() {
        let schema = Schema([
            LocalTransaction.self,
            LocalCategory.self,
            LocalAccount.self,
            LocalBudget.self,
            LocalGoldAsset.self,
            LocalKeyValue.self,
            PendingSyncOperation.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    private var context: ModelContext { container.mainContext }
    
    // MARK: - Save all init data from server
    
    func saveInitData(
        transactions: [Transaction],
        categories: [Category],
        accounts: [Account],
        accountBalances: [String: Double],
        budgets: [Budget],
        goldAssets: [GoldAsset],
        settings: [String: String]
    ) {
        saveTransactions(transactions)
        saveCategories(categories)
        saveAccounts(accounts)
        saveBudgets(budgets)
        saveGoldAssets(goldAssets)
        saveAccountBalances(accountBalances)
        saveSettings(settings)
    }
    
    // MARK: - Transactions
    
    func saveTransactions(_ transactions: [Transaction]) {
        let existing = (try? context.fetch(FetchDescriptor<LocalTransaction>())) ?? []
        let existingMap = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        for tx in transactions {
            if let local = existingMap[tx.id] { local.update(from: tx) }
            else { context.insert(LocalTransaction(from: tx)) }
        }
        // Keep pending-create IDs; remove the rest that aren't on server
        let serverIds = Set(transactions.map { $0.id })
        let pendingCreateIds = Set(fetchPendingOps().filter { $0.operationType == "create" }.map { $0.entityId })
        for local in existing where !serverIds.contains(local.id) && !pendingCreateIds.contains(local.id) {
            context.delete(local)
        }
        try? context.save()
    }
    
    func fetchAllTransactions() -> [Transaction] {
        (try? context.fetch(FetchDescriptor<LocalTransaction>()))?.compactMap { $0.toTransaction() } ?? []
    }
    
    func upsertTransaction(_ tx: Transaction) {
        let id = tx.id
        let descriptor = FetchDescriptor<LocalTransaction>(predicate: #Predicate { $0.id == id })
        if let existing = try? context.fetch(descriptor).first { existing.update(from: tx) }
        else { context.insert(LocalTransaction(from: tx)) }
        try? context.save()
    }
    
    func deleteTransaction(id: String) {
        let descriptor = FetchDescriptor<LocalTransaction>(predicate: #Predicate { $0.id == id })
        if let local = try? context.fetch(descriptor).first {
            context.delete(local)
            try? context.save()
        }
    }
    
    func updateTransactionId(from tempId: String, to realId: String) {
        let descriptor = FetchDescriptor<LocalTransaction>(predicate: #Predicate { $0.id == tempId })
        if let local = try? context.fetch(descriptor).first {
            local.id = realId
            try? context.save()
        }
    }
    
    // MARK: - Categories
    
    func saveCategories(_ categories: [Category]) {
        let existing = (try? context.fetch(FetchDescriptor<LocalCategory>())) ?? []
        let existingMap = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        
        for cat in categories {
            if let local = existingMap[cat.id] {
                // Cập nhật thông tin nếu đã tồn tại
                local.name = cat.name
                local.type = cat.type.rawValue
                local.icon = cat.icon   // Thêm dòng này
                local.color = cat.color // Thêm dòng này
            } else {
                // Thêm mới nếu chưa có
                context.insert(LocalCategory(from: cat))
            }
        }
        
        let serverIds = Set(categories.map { $0.id })
        for local in existing where !serverIds.contains(local.id) {
            context.delete(local)
        }
        try? context.save()
    }
    
    func fetchAllCategories() -> [Category] {
        (try? context.fetch(FetchDescriptor<LocalCategory>()))?.compactMap { $0.toCategory() } ?? []
    }
    
    // MARK: - Accounts
    
    func saveAccounts(_ accounts: [Account]) {
        let existing = (try? context.fetch(FetchDescriptor<LocalAccount>())) ?? []
        let existingMap = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        for acc in accounts {
            if let local = existingMap[acc.id] {
                local.name = acc.name
                local.icon = acc.icon
                local.color = acc.color
            }
            else { context.insert(LocalAccount(from: acc)) }
        }
        let serverIds = Set(accounts.map { $0.id })
        for local in existing where !serverIds.contains(local.id) { context.delete(local) }
        try? context.save()
    }
    
    func fetchAllAccounts() -> [Account] {
        (try? context.fetch(FetchDescriptor<LocalAccount>()))?.map { $0.toAccount() } ?? []
    }
    
    // MARK: - Budgets
    
    func saveBudgets(_ budgets: [Budget]) {
        let existing = (try? context.fetch(FetchDescriptor<LocalBudget>())) ?? []
        let existingMap = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        for budget in budgets {
            if let local = existingMap[budget.id] {
                local.name = budget.name; local.limit = budget.limit
                local.dateStart = budget.dateStart; local.dateEnd = budget.dateEnd
                local.categoryIdsJSON = (try? String(data: JSONEncoder().encode(budget.categoryIds), encoding: .utf8)) ?? "[]"
            } else { context.insert(LocalBudget(from: budget)) }
        }
        let serverIds = Set(budgets.map { $0.id })
        for local in existing where !serverIds.contains(local.id) { context.delete(local) }
        try? context.save()
    }
    
    func fetchAllBudgets() -> [Budget] {
        (try? context.fetch(FetchDescriptor<LocalBudget>()))?.map { $0.toBudget() } ?? []
    }
    
    // MARK: - Gold Assets
    
    func saveGoldAssets(_ assets: [GoldAsset]) {
        let existing = (try? context.fetch(FetchDescriptor<LocalGoldAsset>())) ?? []
        let existingMap = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        for asset in assets {
            if let local = existingMap[asset.id] {
                local.brand = asset.brand.rawValue; local.productId = asset.productId
                local.productName = asset.productName; local.quantity = asset.quantity
                local.note = asset.note; local.createdAt = asset.createdAt
                local.currentSellPrice = asset.currentSellPrice
            } else { context.insert(LocalGoldAsset(from: asset)) }
        }
        let serverIds = Set(assets.map { $0.id })
        for local in existing where !serverIds.contains(local.id) { context.delete(local) }
        try? context.save()
    }
    
    func fetchAllGoldAssets() -> [GoldAsset] {
        (try? context.fetch(FetchDescriptor<LocalGoldAsset>()))?.compactMap { $0.toGoldAsset() } ?? []
    }
    
    // MARK: - Key-Value (settings + account balances)
    
    private func saveKeyValues(_ dict: [String: String], prefix: String) {
        let existing = (try? context.fetch(FetchDescriptor<LocalKeyValue>())) ?? []
        let existingMap = Dictionary(uniqueKeysWithValues: existing.map { ($0.key, $0) })
        for (k, v) in dict {
            let fullKey = "\(prefix):\(k)"
            if let local = existingMap[fullKey] { local.value = v }
            else { context.insert(LocalKeyValue(key: fullKey, value: v)) }
        }
        // Remove stale keys for this prefix
        let newKeys = Set(dict.keys.map { "\(prefix):\($0)" })
        for local in existing where local.key.hasPrefix("\(prefix):") && !newKeys.contains(local.key) {
            context.delete(local)
        }
        try? context.save()
    }
    
    private func fetchKeyValues(prefix: String) -> [String: String] {
        let existing = (try? context.fetch(FetchDescriptor<LocalKeyValue>())) ?? []
        var result: [String: String] = [:]
        let prefixWithColon = "\(prefix):"
        for kv in existing where kv.key.hasPrefix(prefixWithColon) {
            let trimmedKey = String(kv.key.dropFirst(prefixWithColon.count))
            result[trimmedKey] = kv.value
        }
        return result
    }
    
    func saveSettings(_ settings: [String: String]) {
        saveKeyValues(settings, prefix: "settings")
    }
    
    func fetchSettings() -> [String: String] {
        fetchKeyValues(prefix: "settings")
    }
    
    func saveAccountBalances(_ balances: [String: Double]) {
        let stringBalances = balances.mapValues { String($0) }
        saveKeyValues(stringBalances, prefix: "balance")
    }
    
    func fetchAccountBalances() -> [String: Double] {
        fetchKeyValues(prefix: "balance").compactMapValues { Double($0) }
    }
    
    // MARK: - Pending Sync Operations
    
    func enqueueSyncOp(operationType: String, entityId: String, payload: Data? = nil) {
        let op = PendingSyncOperation(operationType: operationType, entityId: entityId, payload: payload)
        context.insert(op)
        try? context.save()
    }
    
    func fetchPendingOps() -> [PendingSyncOperation] {
        var descriptor = FetchDescriptor<PendingSyncOperation>(sortBy: [SortDescriptor(\.createdAt)])
        descriptor.fetchLimit = 100
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func dequeueSyncOp(_ op: PendingSyncOperation) {
        context.delete(op)
        try? context.save()
    }
    
    func incrementRetry(_ op: PendingSyncOperation) {
        op.retryCount += 1
        try? context.save()
    }
    
    func removePendingOps(for entityId: String) {
        let descriptor = FetchDescriptor<PendingSyncOperation>(
            predicate: #Predicate { $0.entityId == entityId }
        )
        let ops = (try? context.fetch(descriptor)) ?? []
        for op in ops { context.delete(op) }
        try? context.save()
    }
    
    func hasPendingCreateOp(for entityId: String) -> Bool {
        let descriptor = FetchDescriptor<PendingSyncOperation>(
            predicate: #Predicate { $0.entityId == entityId && $0.operationType == "create" }
        )
        return ((try? context.fetch(descriptor)) ?? []).isEmpty == false
    }
    
    func replacePendingUpdateWithDelete(for entityId: String) {
        let descriptor = FetchDescriptor<PendingSyncOperation>(
            predicate: #Predicate { $0.entityId == entityId && $0.operationType == "update" }
        )
        if let op = try? context.fetch(descriptor).first {
            op.operationType = "delete"
            op.payload = nil
            try? context.save()
        }
    }
    
    func updatePendingOpsId(from tempId: String, to realId: String) {
        let descriptor = FetchDescriptor<PendingSyncOperation>(
            predicate: #Predicate { $0.entityId == tempId }
        )
        if let ops = try? context.fetch(descriptor) {
            for op in ops {
                op.entityId = realId
            }
            try? context.save()
        }
    }
}
