import Foundation
import WidgetKit

struct WidgetDataManager {
    static let shared = WidgetDataManager()
    
    // ĐIỀN ĐÚNG APP GROUP ID ĐÃ TẠO Ở BƯỚC 4
    // ENTER THE EXACT APP GROUP ID CREATED IN STEP 4
    private let appGroupID = "group.com.yourdomain.SaveMoney"
    
    func updateWidgetData(
        totalBalance: Double,
        income: Double,
        expense: Double,
        budgetName: String,
        budgetLimit: Double,
        budgetSpent: Double
    ) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            print("Lỗi: Không tìm thấy App Group. Vui lòng kiểm tra lại ID.")
            return
        }
        
        defaults.set(totalBalance, forKey: "widget_totalBalance")
        defaults.set(income, forKey: "widget_income")
        defaults.set(expense, forKey: "widget_expense")
        
        defaults.set(budgetName, forKey: "widget_budgetName")
        defaults.set(budgetLimit, forKey: "widget_budgetLimit")
        defaults.set(budgetSpent, forKey: "widget_budgetSpent")
        
        // Kích hoạt lệnh yêu cầu hệ điều hành vẽ lại Widget ngay lập tức
        // Trigger the OS to redraw the Widget immediately
        WidgetCenter.shared.reloadAllTimelines()
    }
}
