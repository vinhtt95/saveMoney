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
    // 1. Thử parse dạng ISO8601 từ server
    if let date = try? Date(string, strategy: .iso8601) {
        return date
    }
    
    // 2. Dự phòng cho format cũ yyyy-MM-dd
    let strategy = Date.ParseStrategy(
        format: "\(year: .padded(4))-\(month: .twoDigits)-\(day: .twoDigits)",
        timeZone: TimeZone(secondsFromGMT: 0)!
    )
    return try? Date(string, strategy: strategy)
}

func toStorageString(_ date: Date) -> String {
    // Trả về chuỗi ISO8601 chuẩn UTC
    return date.formatted(.iso8601)
}

func formatDate(_ dateString: String) -> String {
    guard let date = parseStorageDate(dateString) else { return dateString }
    // Tự động sử dụng múi giờ của thiết bị (Việt Nam)
    return date.formatted(date: .numeric, time: .omitted)
}

func toYYYYMM(_ date: Date) -> String {
    periodFormatter.string(from: date)
}

func dateLabel(_ dateString: String) -> String {
    guard let date = parseStorageDate(dateString) else { return dateString }
    let calendar = Calendar.current
    if calendar.isDateInToday(date) { return "Hôm nay" }
    if calendar.isDateInYesterday(date) { return "Hôm qua" }
    return date.formatted(date: .numeric, time: .omitted)
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

// MARK: - Currency trong file Formatters.swift
func formatBalance(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.groupingSeparator = "."
    formatter.maximumFractionDigits = 0
    let formatted = formatter.string(from: NSNumber(value: amount)) ?? "0"
    return "\(formatted)₫"
}
