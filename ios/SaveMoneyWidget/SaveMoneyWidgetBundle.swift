import WidgetKit
import SwiftUI

@main
struct SaveMoneyWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Main Home Screen / Lock Screen Widget
        SaveMoneyWidget()
        
        // iOS 18 Control Center Widget
        SaveMoneyWidgetControl()
    }
}
