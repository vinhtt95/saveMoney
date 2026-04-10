import SwiftUI

// MARK: - Colors
enum DSColors {
    static let accent = Color(red: 0.49, green: 0.23, blue: 0.93)
    static let income = Color.teal
    static let expense = Color.red
    static let gold = Color.orange
    static let transfer = Color.blue
    static let positive = Color.green
    static let negative = Color.red
}

// MARK: - Radius
enum DSRadius {
    static let full: CGFloat = 36
    static let xl: CGFloat = 24
    static let lg: CGFloat = 16
    static let md: CGFloat = 12
    static let sm: CGFloat = 8
    static let xs: CGFloat = 4
}

// MARK: - Spacing
enum DSSpacing {
    static let xl: CGFloat = 24
    static let lg: CGFloat = 16
    static let md: CGFloat = 12
    static let sm: CGFloat = 8
    static let xs: CGFloat = 4
}

// MARK: - Theme Manager
enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var label: String {
        switch self {
        case .system: "Tự động"
        case .light: "Sáng"
        case .dark: "Tối"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

@Observable
final class ThemeManager {
    var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Constants.themePreferenceKey) }
    }

    var colorScheme: ColorScheme? { theme.colorScheme }

    init() {
        let stored = UserDefaults.standard.string(forKey: Constants.themePreferenceKey) ?? "system"
        self.theme = AppTheme(rawValue: stored) ?? .system
    }
}

// MARK: - Connection State
enum ConnectionState {
    case loading, connected, disconnected

    var label: String {
        switch self {
        case .loading: "Đang kết nối"
        case .connected: "Đã kết nối"
        case .disconnected: "Mất kết nối"
        }
    }

    var color: Color {
        switch self {
        case .loading: Color(red: 0.5, green: 0.9, blue: 0.5)
        case .connected: .green
        case .disconnected: .red
        }
    }
}

// MARK: - Category Color Mapping
func categoryColor(_ name: String) -> Color {
    let lower = name.lowercased()
    if lower.contains("ăn") || lower.contains("food") || lower.contains("nhà hàng") { return .orange }
    if lower.contains("di chuyển") || lower.contains("xăng") || lower.contains("xe") { return .blue }
    if lower.contains("mua sắm") || lower.contains("quần áo") { return .pink }
    if lower.contains("giải trí") || lower.contains("du lịch") { return .purple }
    if lower.contains("sức khỏe") || lower.contains("y tế") { return .red }
    if lower.contains("giáo dục") || lower.contains("học") { return .indigo }
    if lower.contains("tiết kiệm") || lower.contains("đầu tư") { return .green }
    if lower.contains("lương") || lower.contains("thu nhập") { return .teal }
    if lower.contains("điện") || lower.contains("nước") || lower.contains("internet") { return .yellow }
    return DSColors.accent
}

func categorySystemImage(_ name: String) -> String {
    let lower = name.lowercased()
    if lower.contains("ăn") || lower.contains("food") || lower.contains("nhà hàng") { return "fork.knife" }
    if lower.contains("di chuyển") || lower.contains("xăng") || lower.contains("xe") { return "car.fill" }
    if lower.contains("mua sắm") || lower.contains("quần áo") { return "bag.fill" }
    if lower.contains("giải trí") { return "gamecontroller.fill" }
    if lower.contains("du lịch") { return "airplane" }
    if lower.contains("sức khỏe") || lower.contains("y tế") { return "heart.fill" }
    if lower.contains("giáo dục") || lower.contains("học") { return "book.fill" }
    if lower.contains("tiết kiệm") || lower.contains("đầu tư") { return "chart.line.uptrend.xyaxis" }
    if lower.contains("lương") { return "banknote.fill" }
    if lower.contains("điện") { return "bolt.fill" }
    if lower.contains("nước") { return "drop.fill" }
    if lower.contains("internet") { return "wifi" }
    return "tag.fill"
}

struct CategoryColorHelper {
    static func map(_ colorName: String) -> Color {
        switch colorName {
        case "orange": return .orange
        case "blue": return .blue
        case "pink": return .pink
        case "purple": return .purple
        case "red": return .red
        case "indigo": return .indigo
        case "green": return .green
        case "teal": return .teal
        case "yellow": return .yellow
        case "brown": return .brown
        case "gray": return .gray
        default: return DSColors.accent
        }
    }
}
