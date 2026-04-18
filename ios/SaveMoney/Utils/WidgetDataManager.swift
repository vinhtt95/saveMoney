import Foundation
import WidgetKit

// Model trung gian để App gửi mảng danh mục sang Widget
struct WidgetCategoryStat: Codable, Hashable {
    let name: String
    let amount: Double
}

struct WidgetDataManager {
    static let shared = WidgetDataManager()
    
    // Sử dụng Constants.appGroup
    private let appGroupID = Constants.appGroup
    
    func updateWidgetData(
        totalBalance: Double,
        income: Double,
        expense: Double,
        budgetName: String,
        budgetLimit: Double,
        budgetSpent: Double,
        categories: [WidgetCategoryStat] = []
    ) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            print("Lỗi: Không tìm thấy App Group.")
            return
        }
        
        defaults.set(totalBalance, forKey: "widget_totalBalance")
        defaults.set(income, forKey: "widget_income")
        defaults.set(expense, forKey: "widget_expense")
        
        defaults.set(budgetName, forKey: "widget_budgetName")
        defaults.set(budgetLimit, forKey: "widget_budgetLimit")
        defaults.set(budgetSpent, forKey: "widget_budgetSpent")
        
        // Encode mảng danh mục thành Data để lưu vào UserDefaults
        if let encoded = try? JSONEncoder().encode(categories) {
            defaults.set(encoded, forKey: "widget_categories")
        } else {
            defaults.removeObject(forKey: "widget_categories")
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // Hàm mới: Chỉ cập nhật Account đã chọn mà không đụng tới lịch sử / ngân sách khác
    func updateSelectedAccount(title: String, balance: Double) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.set(title, forKey: "widget_balanceTitle")
        defaults.set(balance, forKey: "widget_displayBalance")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
