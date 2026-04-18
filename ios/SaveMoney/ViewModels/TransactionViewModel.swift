import Foundation

@Observable
@MainActor
final class TransactionViewModel {
    var selectedCategoryId: String? = nil
    var selectedPeriod: String = toYYYYMM(Date())
    var searchText: String = ""
    var page = 1
    var isSubmitting = false
    var errorMessage: String?
    
    private let app: AppViewModel
    
    init(app: AppViewModel) {
        self.app = app
    }
    
    var filteredTransactions: [Transaction] {
        app.visibleTransactions.filter { tx in
            // So sánh chuỗi trực tiếp (O(1)) thay vì dùng DateFormatter
            let periodMatch = tx.date.hasPrefix(selectedPeriod)
            
            let categoryMatch = selectedCategoryId == nil || tx.categoryId == selectedCategoryId
            let searchMatch = searchText.isEmpty ||
            (tx.note?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (app.category(for: tx.categoryId ?? "")?.name.localizedCaseInsensitiveContains(searchText) ?? false)
            
            return periodMatch && categoryMatch && searchMatch
        }
    }
    
    var paginatedTransactions: [Transaction] {
        Array(filteredTransactions.prefix(page * Constants.pageSize))
    }
    
    var hasMore: Bool { filteredTransactions.count > page * Constants.pageSize }
    
    var groupedTransactions: [(String, [Transaction])] {
        // 1. Gom nhóm theo chuỗi ngày chuẩn "yyyy-MM-dd" để đảm bảo sort chính xác
        let grouped = Dictionary(grouping: paginatedTransactions) { tx -> String in
            guard let date = parseStorageDate(tx.date) else {
                return String(tx.date.prefix(10))
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone.current
            return formatter.string(from: date)
        }
        
        // 2. Sắp xếp key "yyyy-MM-dd" theo thứ tự giảm dần (mới nhất lên đầu)
        let sortedKeys = grouped.keys.sorted(by: >)
        
        // 3. Map lại thành mảng tuple, lấy dateLabel từ giao dịch đầu tiên của nhóm
        return sortedKeys.compactMap { key in
            guard let txs = grouped[key], let firstTx = txs.first else { return nil }
            return (dateLabel(firstTx.date), txs)
        }
    }
    
    func loadMore() { page += 1 }
    
    func resetPage() { page = 1 }
    
    var topCategories: [Category] {
        let counts = Dictionary(
            grouping: app.visibleTransactions.filter { $0.categoryId != nil },
            by: { $0.categoryId! }
        ).mapValues { $0.count }
        let sorted = counts.sorted { $0.value > $1.value }
        return sorted.prefix(8).compactMap { app.category(for: $0.key) }
    }
    
    // MARK: - CRUD
    func addTransaction(
        date: String,
        type: TransactionType,
        categoryId: String?,
        accountId: String?,
        transferToId: String?,
        amount: Double,
        note: String?
    ) async {
        isSubmitting = true
        errorMessage = nil
        let dto = TransactionCreateDTO(
            date: date,
            type: type.rawValue,
            categoryId: categoryId,
            accountId: accountId,
            transferToId: transferToId,
            amount: type == .expense ? -abs(amount) : abs(amount),
            note: note?.isEmpty == true ? nil : note
        )
        do {
            try await app.addTransaction(dto)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
    
    func updateTransaction(
        id: String,
        date: String,
        type: TransactionType,
        categoryId: String?,
        accountId: String?,
        transferToId: String?,
        amount: Double,
        note: String?
    ) async {
        isSubmitting = true
        errorMessage = nil
        let dto = TransactionCreateDTO(
            date: date,
            type: type.rawValue,
            categoryId: categoryId,
            accountId: accountId,
            transferToId: transferToId,
            amount: type == .expense ? -abs(amount) : abs(amount),
            note: note?.isEmpty == true ? nil : note
        )
        do {
            try await app.updateTransaction(id, dto)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
    
    func deleteTransaction(_ id: String) async {
        do {
            try await app.deleteTransaction(id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
