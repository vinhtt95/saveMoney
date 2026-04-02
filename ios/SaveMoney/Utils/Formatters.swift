import Foundation

enum Formatters {
    // MARK: - VND

    static func formatVND(_ amount: Double) -> String {
        let absAmount = abs(amount)
        let formatted = Int(absAmount)
        let numStr = String(formatted)
        var result = ""
        let chars = Array(numStr)
        for (i, c) in chars.enumerated() {
            if i > 0 && (chars.count - i) % 3 == 0 { result += "." }
            result.append(c)
        }
        let prefix = amount < 0 ? "-" : ""
        return "\(prefix)\(result) ₫"
    }

    static func formatVNDShort(_ amount: Double) -> String {
        let abs = Swift.abs(amount)
        switch abs {
        case 1_000_000_000...: return String(format: "%.1fT", abs / 1_000_000_000)
        case 1_000_000...: return String(format: "%.1fTr", abs / 1_000_000)
        case 1_000...: return String(format: "%.0fK", abs / 1_000)
        default: return String(format: "%.0f", abs)
        }
    }

    // MARK: - Date

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "vi_VN")
        return f
    }()

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        f.locale = Locale(identifier: "vi_VN")
        return f
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm dd/MM/yyyy"
        f.locale = Locale(identifier: "vi_VN")
        return f
    }()

    static func toDateString(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    static func parseDate(_ string: String) -> Date? {
        dateFormatter.date(from: string)
    }

    static func formatDate(_ string: String) -> String {
        guard let d = parseDate(string) else { return string }
        return displayFormatter.string(from: d)
    }

    static func formatDateTime(_ date: Date) -> String {
        dateTimeFormatter.string(from: date)
    }

    // MARK: - Period

    static func toYYYYMM(_ date: Date) -> String {
        let cal = Calendar.current
        let year = cal.component(.year, from: date)
        let month = cal.component(.month, from: date)
        return String(format: "%04d-%02d", year, month)
    }

    static func currentYYYYMM() -> String {
        toYYYYMM(Date())
    }
}
