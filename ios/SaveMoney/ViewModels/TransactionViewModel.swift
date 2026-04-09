import Foundation

@Observable
@MainActor
final class TransactionViewModel {
    var selectedCategoryId: String? = nil
    var selectedPeriod: String = toYYYYMM(Date())
    var page = 1
    var isSubmitting = false
    var errorMessage: String?

    private let app: AppViewModel

    init(app: AppViewModel) {
        self.app = app
    }

    var filteredTransactions: [Transaction] {
        app.transactions.filter { tx in
            let periodMatch = tx.date.hasPrefix(selectedPeriod)
            let categoryMatch = selectedCategoryId == nil || tx.categoryId == selectedCategoryId
            return periodMatch && categoryMatch
        }
    }

    var paginatedTransactions: [Transaction] {
        Array(filteredTransactions.prefix(page * Constants.pageSize))
    }

    var hasMore: Bool { filteredTransactions.count > page * Constants.pageSize }

    var groupedTransactions: [(String, [Transaction])] {
        let grouped = Dictionary(grouping: paginatedTransactions) { dateLabel($0.date) }
        let order = ["Hôm nay", "Hôm qua"]
        let sortedKeys = grouped.keys.sorted { a, b in
            let ai = order.firstIndex(of: a)
            let bi = order.firstIndex(of: b)
            if let ai, let bi { return ai < bi }
            if ai != nil { return true }
            if bi != nil { return false }
            // Both are date strings, sort descending
            return a > b
        }
        return sortedKeys.compactMap { key in
            guard let txs = grouped[key] else { return nil }
            return (key, txs)
        }
    }

    func loadMore() { page += 1 }

    func resetPage() { page = 1 }

    // MARK: - Top categories for filter chips
    var topCategories: [Category] {
        let counts = Dictionary(
            grouping: app.transactions.filter { $0.categoryId != nil },
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
