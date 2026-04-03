import Foundation

@MainActor
class TransactionViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedCategoryId: String? = nil
    @Published var selectedAccountId: String? = nil
    @Published var selectedPeriod: String = ""
    @Published var currentPage = 1
    @Published var isSubmitting = false
    @Published var submitError: String?

    let pageSize = 20

    private let api = APIService.shared

    func filtered(_ transactions: [Transaction]) -> [Transaction] {
        transactions.filter { tx in
            (searchText.isEmpty || (tx.note?.localizedCaseInsensitiveContains(searchText) ?? false))
            && (selectedCategoryId == nil || tx.categoryId == selectedCategoryId)
            && (selectedAccountId == nil || tx.accountId == selectedAccountId)
            && (selectedPeriod.isEmpty || tx.date.hasPrefix(selectedPeriod))
        }
    }

    func paged(_ transactions: [Transaction]) -> [Transaction] {
        let f = filtered(transactions)
        return Array(f.prefix(currentPage * pageSize))
    }

    func hasMore(_ transactions: [Transaction]) -> Bool {
        filtered(transactions).count > currentPage * pageSize
    }

    func loadMore() { currentPage += 1 }
    func resetPaging() { currentPage = 1 }

    func create(_ body: CreateTransactionRequest, appVM: AppViewModel) async {
        isSubmitting = true
        submitError = nil
        do {
            let tx = try await api.createTransaction(body)
            appVM.transactions.insert(tx, at: 0)
        } catch {
            submitError = error.localizedDescription
        }
        isSubmitting = false
    }

    func update(id: String, body: UpdateTransactionRequest, appVM: AppViewModel) async {
        isSubmitting = true
        submitError = nil
        do {
            try await api.updateTransaction(id: id, body: body)
            if let idx = appVM.transactions.firstIndex(where: { $0.id == id }) {
                let updated = Transaction(
                    id: id,
                    date: body.date,
                    type: body.type,
                    categoryId: body.categoryId,
                    accountId: body.accountId,
                    transferToId: body.transferToId,
                    amount: body.amount,
                    note: body.note
                )
                appVM.transactions[idx] = updated
            }
        } catch {
            submitError = error.localizedDescription
        }
        isSubmitting = false
    }

    func delete(id: String, appVM: AppViewModel) async {
        do {
            try await api.deleteTransaction(id: id)
            appVM.transactions.removeAll { $0.id == id }
        } catch {
            submitError = error.localizedDescription
        }
    }
}
