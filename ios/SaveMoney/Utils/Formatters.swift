import Foundation

// MARK: - Currency
func formatVND(_ amount: Double) -> String {
    let absAmount = abs(amount)
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.groupingSeparator = "."
    formatter.maximumFractionDigits = 0
    let formatted = formatter.string(from: NSNumber(value: absAmount)) ?? "0"
    return "\(formatted)₫"
}

func formatVNDShort(_ amount: Double) -> String {
    let absAmount = abs(amount)
    switch absAmount {
    case 1_000_000_000...:
        return String(format: "%.1fT₫", absAmount / 1_000_000_000)
    case 1_000_000...:
        return String(format: "%.1ftr₫", absAmount / 1_000_000)
    case 1_000...:
        return String(format: "%.0fK₫", absAmount / 1_000)
    default:
        return formatVND(absAmount)
    }
}

func formatVNDSigned(_ amount: Double) -> String {
    let prefix = amount >= 0 ? "+" : "-"
    return "\(prefix)\(formatVND(amount))"
}

// MARK: - Dates
private let storageFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.locale = Locale(identifier: "vi_VN")
    return f
}()

private let displayFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "dd/MM/yyyy"
    f.locale = Locale(identifier: "vi_VN")
    return f
}()

private let periodFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM"
    f.locale = Locale(identifier: "vi_VN")
    return f
}()

func parseStorageDate(_ string: String) -> Date? {
    storageFormatter.date(from: string)
}

func formatDate(_ dateString: String) -> String {
    guard let date = parseStorageDate(dateString) else { return dateString }
    return displayFormatter.string(from: date)
}

func toYYYYMM(_ date: Date) -> String {
    periodFormatter.string(from: date)
}

func dateLabel(_ dateString: String) -> String {
    guard let date = parseStorageDate(dateString) else { return dateString }
    let calendar = Calendar.current
    if calendar.isDateInToday(date) { return "Hôm nay" }
    if calendar.isDateInYesterday(date) { return "Hôm qua" }
    return displayFormatter.string(from: date)
}

func availablePeriods(count: Int = 6) -> [String] {
    var periods: [String] = []
    let calendar = Calendar.current
    var date = Date()
    for _ in 0..<count {
        periods.append(toYYYYMM(date))
        date = calendar.date(byAdding: .month, value: -1, to: date) ?? date
    }
    return periods
}

func periodLabel(_ period: String) -> String {
    let parts = period.split(separator: "-")
    guard parts.count == 2,
          let month = Int(parts[1]),
          let year = Int(parts[0]) else { return period }
    let currentPeriod = toYYYYMM(Date())
    if period == currentPeriod { return "Tháng này" }
    return "Th\(month)/\(year)"
}

func daysInMonth(period: String) -> Int {
    let parts = period.split(separator: "-")
    guard parts.count == 2,
          let month = Int(parts[1]),
          let year = Int(parts[0]) else { return 30 }
    var components = DateComponents()
    components.year = year
    components.month = month
    let calendar = Calendar.current
    guard let firstDay = calendar.date(from: components),
          let range = calendar.range(of: .day, in: .month, for: firstDay) else { return 30 }
    return range.count
}

func elapsedDaysInMonth(period: String) -> Int {
    let currentPeriod = toYYYYMM(Date())
    if period != currentPeriod { return daysInMonth(period: period) }
    return Calendar.current.component(.day, from: Date())
}
