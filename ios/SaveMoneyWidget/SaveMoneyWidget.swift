import WidgetKit
import SwiftUI
import Charts

// MARK: - Model & Entry
struct DashboardWidgetData {
    var totalBalance: Double
    var income: Double
    var expense: Double
    var budgetName: String
    var budgetLimit: Double
    var budgetSpent: Double
    var categories: [WidgetCategoryStat]
}

struct SaveMoneyEntry: TimelineEntry {
    let date: Date
    let data: DashboardWidgetData
}

// MARK: - Provider
struct SaveMoneyWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SaveMoneyEntry {
        SaveMoneyEntry(date: Date(), data: .init(totalBalance: 25000000, income: 30000000, expense: 5000000, budgetName: "Ăn uống", budgetLimit: 5000000, budgetSpent: 3500000, categories: []))
    }

    func getSnapshot(in context: Context, completion: @escaping (SaveMoneyEntry) -> Void) {
        let entry = SaveMoneyEntry(date: Date(), data: .init(totalBalance: 25000000, income: 30000000, expense: 5000000, budgetName: "Ăn uống", budgetLimit: 5000000, budgetSpent: 3500000, categories: []))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SaveMoneyEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.com.vinhtt.savemoney")
        
        let totalBalance = defaults?.double(forKey: "widget_totalBalance") ?? 0.0
        let income = defaults?.double(forKey: "widget_income") ?? 0.0
        let expense = defaults?.double(forKey: "widget_expense") ?? 0.0
        
        let budgetName = defaults?.string(forKey: "widget_budgetName") ?? "Chưa ghim"
        let budgetLimit = defaults?.double(forKey: "widget_budgetLimit") ?? 1.0
        let budgetSpent = defaults?.double(forKey: "widget_budgetSpent") ?? 0.0
        
        // Đọc mảng categories
        var decodedCategories: [WidgetCategoryStat] = []
        if let data = defaults?.data(forKey: "widget_categories"),
           let cats = try? JSONDecoder().decode([WidgetCategoryStat].self, from: data) {
            decodedCategories = cats
        }
        
        let realData = DashboardWidgetData(
            totalBalance: totalBalance,
            income: income,
            expense: expense,
            budgetName: budgetName,
            budgetLimit: budgetLimit,
            budgetSpent: budgetSpent,
            categories: decodedCategories
        )
        
        let entry = SaveMoneyEntry(date: Date(), data: realData)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - Views
struct SmallBudgetWidgetView: View {
    var entry: SaveMoneyEntry
    
    var spent: Double { entry.data.budgetSpent }
    var limit: Double { max(entry.data.budgetLimit, 1) }
    var remaining: Double { max(0, limit - spent) }
    var isOverspent: Bool { spent >= limit }
    var overspentAmount: Double { max(0, spent - limit) }
    
    // Segment biểu đồ
    struct ChartSegment: Identifiable {
        let id = UUID()
        let name: String
        let amount: Double
        let color: Color
        let isRemaining: Bool
    }
    
    var chartData: [ChartSegment] {
        var data: [ChartSegment] = []
        let palette: [Color] = [.blue, .orange, .purple, .pink, .teal, .indigo]
        
        // 1. Phân rã danh mục từ App truyền sang
        for (index, cat) in entry.data.categories.enumerated() {
            let color = (cat.name == "Khác") ? Color.gray.opacity(0.6) : palette[index % palette.count]
            data.append(ChartSegment(name: cat.name, amount: cat.amount, color: color, isRemaining: false))
        }
        
        // Fallback: Nếu app chưa truyền danh mục sang nhưng đã có số liệu chi
        if data.isEmpty && spent > 0 {
            data.append(ChartSegment(name: "Đã chi", amount: spent, color: DSColors.expense, isRemaining: false))
        }
        
        // 2. Thêm phần "Còn lại" nếu chưa vượt mức
        if !isOverspent && remaining > 0 {
            data.append(ChartSegment(name: "Còn lại", amount: remaining, color: DSColors.accent, isRemaining: true))
        }
        
        return data
    }
    
    // Hàm format số tiền viết tắt (Ví dụ: 3tr, 500k)
    private func formatShortVND(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.decimalSeparator = ","
        
        let val = abs(amount)
        if val >= 1_000_000_000 {
            let num = NSNumber(value: val / 1_000_000_000)
            return (formatter.string(from: num) ?? "") + "tỷ"
        } else if val >= 1_000_000 {
            let num = NSNumber(value: val / 1_000_000)
            return (formatter.string(from: num) ?? "") + "tr"
        } else if val >= 1_000 {
            let num = NSNumber(value: val / 1_000)
            return (formatter.string(from: num) ?? "") + "k"
        } else {
            return "\(Int(val))đ"
        }
    }
    
    var body: some View {
        VStack(spacing: DSSpacing.xs) {
        
            ZStack {
                Chart(chartData) { item in
                    SectorMark(
                        angle: .value("Số tiền", item.amount),
                        innerRadius: .ratio(0.65),
                        angularInset: 1.5
                    )
                    // Nếu vượt mức, ép tất cả các khối đã chi thành màu đỏ. "Còn lại" giữ nguyên (mặc dù lúc này Còn lại = 0 nên sẽ không vẽ)
                    .foregroundStyle(item.isRemaining ? item.color.gradient : (isOverspent ? DSColors.negative.opacity(0.8).gradient : item.color.gradient))
                    .cornerRadius(3)
                }
                
                VStack(spacing: 2) {
                    Text(isOverspent ? "Vượt mức" : "Còn lại")
                        .font(.system(size: 10))
                        .foregroundStyle(isOverspent ? DSColors.negative : .secondary)
                    
                    Text(formatShortVND(isOverspent ? overspentAmount : remaining))
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(isOverspent ? DSColors.negative : DSColors.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(DSSpacing.md)
    }
}

struct MediumOverviewWidgetView: View {
    var entry: SaveMoneyEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Tổng số dư")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                AmountText(amount: entry.data.totalBalance, type: .account, font: .title3.bold())
            }
            .padding(.horizontal, DSSpacing.md)
            
            HStack(spacing: DSSpacing.md) {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    HStack {
                        Image(systemName: "arrow.down.left.circle.fill")
                            .foregroundStyle(DSColors.income)
                        Text("Thu nhập")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    AmountText(amount: entry.data.income, type: .income, font: .subheadline.bold())
                }
                .padding(DSSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .liquidGlass(in: .rect(cornerRadius: DSRadius.md))
                
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    HStack {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .foregroundStyle(DSColors.expense)
                        Text("Chi tiêu")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    AmountText(amount: entry.data.expense, type: .expense, font: .subheadline.bold())
                }
                .padding(DSSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .liquidGlass(in: .rect(cornerRadius: DSRadius.md))
            }
            .padding(.horizontal, DSSpacing.xs)
        }
        .padding(.vertical, DSSpacing.md)
    }
}

struct SaveMoneyWidgetEntryView: View {
    var entry: SaveMoneyWidgetProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DSColors.accent.opacity(0.15), Color(UIColor.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            switch family {
            case .systemSmall:
                SmallBudgetWidgetView(entry: entry)
                    .padding(DSSpacing.xs)
            case .systemMedium:
                MediumOverviewWidgetView(entry: entry)
                    .padding(DSSpacing.xs)
            default:
                EmptyView()
            }
        }
        .containerBackground(for: .widget) {
            Color(UIColor.systemGroupedBackground)
        }
    }
}

// MARK: - Configuration
struct SaveMoneyWidget: Widget {
    let kind: String = "SaveMoneyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SaveMoneyWidgetProvider()) { entry in
            SaveMoneyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Save Money Dashboard")
        .description("Theo dõi ngân sách và tổng quan thu chi nhanh chóng.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
