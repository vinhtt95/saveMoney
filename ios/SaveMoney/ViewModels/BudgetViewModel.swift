import Foundation
import SwiftUI

@Observable
@MainActor
final class BudgetViewModel {
    var isSubmitting = false
    var errorMessage: String?

    private let app: AppViewModel

    init(app: AppViewModel) {
        self.app = app
    }

    func spentAmount(budget: Budget) -> Double {
        app.transactions
            .filter { tx in
                guard tx.type == .expense,
                      let catId = tx.categoryId,
                      budget.categoryIds.contains(catId) else { return false }
                return tx.date >= budget.dateStart && tx.date <= budget.dateEnd
            }
            .reduce(0) { $0 + abs($1.amount) }
    }

    func progress(budget: Budget) -> Double {
        guard budget.limit > 0 else { return 0 }
        return spentAmount(budget: budget) / budget.limit
    }

    func progressColor(budget: Budget) -> some ShapeStyle {
        let p = progress(budget: budget)
        if p >= 1.0 { return AnyShapeStyle(Color.red) }
        if p >= 0.8 { return AnyShapeStyle(Color.orange) }
        return AnyShapeStyle(Color.green)
    }

    func addBudget(
        name: String,
        limit: Double,
        dateStart: String,
        dateEnd: String,
        categoryIds: [String]
    ) async {
        isSubmitting = true
        errorMessage = nil
        let dto = BudgetCreateDTO(
            name: name,
            limitAmount: limit,
            dateStart: dateStart,
            dateEnd: dateEnd,
            categoryIds: categoryIds
        )
        do {
            try await app.addBudget(dto)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }

    func deleteBudget(_ id: String) async {
        do {
            try await app.deleteBudget(id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
