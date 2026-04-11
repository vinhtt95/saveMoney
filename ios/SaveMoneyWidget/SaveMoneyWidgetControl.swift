import AppIntents
import SwiftUI
import WidgetKit

struct SaveMoneyWidgetControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.yourdomain.SaveMoney.QuickAddControl",
            provider: Provider()
        ) { value in
            ControlWidgetButton(action: QuickAddTransactionIntent()) {
                Label("Thêm GD", systemImage: "plus.circle.fill")
            }
        }
        .displayName("Thêm Giao Dịch Nhanh")
        .description("Mở nhanh ứng dụng để thêm thu chi mới.")
    }
}

extension SaveMoneyWidgetControl {
    struct Provider: ControlValueProvider {
        var previewValue: Bool {
            false
        }

        func currentValue() async throws -> Bool {
            let isRunning = true // Logic kiểm tra trạng thái tương lai
            return isRunning
        }
    }
}

struct QuickAddTransactionIntent: AppIntent {
    static let title: LocalizedStringResource = "Mở Thêm Giao Dịch"
    
    // Mở app chính khi người dùng bấm vào Control Center
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // Xử lý deep link hoặc cấu hình app state tại đây
        return .result()
    }
}
