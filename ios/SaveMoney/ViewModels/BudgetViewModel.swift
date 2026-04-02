import Foundation

@MainActor
class BudgetViewModel: ObservableObject {
    @Published var isSubmitting = false
    @Published var submitError: String?

    private let api = APIService.shared

    func spentAmount(for budget: Budget, transactions: [Transaction]) -> Double {
        transactions
            .filter { tx in
                tx.type == .expense
                && budget.categoryIds.contains(tx.categoryId ?? "")
                && tx.date >= budget.dateStart
                && tx.date <= budget.dateEnd
            }
            .reduce(0) { $0 + abs($1.amount) }
    }

    func progress(for budget: Budget, transactions: [Transaction]) -> Double {
        guard budget.limitAmount > 0 else { return 0 }
        return min(spentAmount(for: budget, transactions: transactions) / budget.limitAmount, 1.0)
    }

    func create(_ body: CreateBudgetRequest, appVM: AppViewModel) async {
        isSubmitting = true
        submitError = nil
        do {
            let budget = try await api.createBudget(body)
            appVM.budgets.append(budget)
        } catch {
            submitError = error.localizedDescription
        }
        isSubmitting = false
    }

    func delete(id: String, appVM: AppViewModel) async {
        do {
            try await api.deleteBudget(id: id)
            appVM.budgets.removeAll { $0.id == id }
        } catch {
            submitError = error.localizedDescription
        }
    }
}
