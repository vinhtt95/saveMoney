import WidgetKit
import SwiftUI

// MARK: - Model & Entry
struct DashboardWidgetData {
    var totalBalance: Double
    var income: Double
    var expense: Double
    var budgetName: String
    var budgetLimit: Double
    var budgetSpent: Double
}

struct SaveMoneyEntry: TimelineEntry {
    let date: Date
    let data: DashboardWidgetData
}

// MARK: - Provider
struct SaveMoneyWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SaveMoneyEntry {
        SaveMoneyEntry(date: Date(), data: .init(totalBalance: 25000000, income: 30000000, expense: 5000000, budgetName: "Ăn uống", budgetLimit: 5000000, budgetSpent: 3500000))
    }

    func getSnapshot(in context: Context, completion: @escaping (SaveMoneyEntry) -> Void) {
        let entry = SaveMoneyEntry(date: Date(), data: .init(totalBalance: 25000000, income: 30000000, expense: 5000000, budgetName: "Ăn uống", budgetLimit: 5000000, budgetSpent: 3500000))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SaveMoneyEntry>) -> Void) {
        // ĐIỀN ĐÚNG APP GROUP ID
        // ENTER THE EXACT APP GROUP ID
        let defaults = UserDefaults(suiteName: "group.com.yourdomain.SaveMoney")
        
        let totalBalance = defaults?.double(forKey: "widget_totalBalance") ?? 0.0
        let income = defaults?.double(forKey: "widget_income") ?? 0.0
        let expense = defaults?.double(forKey: "widget_expense") ?? 0.0
        
        let budgetName = defaults?.string(forKey: "widget_budgetName") ?? "Chưa ghim"
        let budgetLimit = defaults?.double(forKey: "widget_budgetLimit") ?? 1.0 // Tránh chia cho 0
        let budgetSpent = defaults?.double(forKey: "widget_budgetSpent") ?? 0.0
        
        let realData = DashboardWidgetData(
            totalBalance: totalBalance,
            income: income,
            expense: expense,
            budgetName: budgetName,
            budgetLimit: budgetLimit,
            budgetSpent: budgetSpent
        )
        
        let entry = SaveMoneyEntry(date: Date(), data: realData)
        
        // Policy .never nghĩa là Widget sẽ không tự động làm mới theo thời gian.
        // Nó chỉ làm mới khi Main App gọi lệnh `WidgetCenter.shared.reloadAllTimelines()`
        // The .never policy means the Widget won't auto-refresh over time.
        // It only refreshes when the Main App calls `WidgetCenter.shared.reloadAllTimelines()`
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - Views
struct SmallBudgetWidgetView: View {
    var entry: SaveMoneyEntry
    
    private var progress: Double {
        min(entry.data.budgetSpent / max(entry.data.budgetLimit, 1), 1.0)
    }
    
    var body: some View {
        VStack(spacing: DSSpacing.md) {
            HStack {
                Text(entry.data.budgetName)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "pin.fill")
                    .font(.caption2)
                    .foregroundStyle(DSColors.accent)
            }
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 10)
                
                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(
                        progress > 0.9 ? DSColors.expense : DSColors.accent,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.subheadline.bold())
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Text(formatVND(entry.data.budgetLimit))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(DSSpacing.md)
        .liquidGlass(in: .rect(cornerRadius: DSRadius.lg))
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
        .configurationDisplayName("SaveMoney Dashboard")
        .description("Theo dõi ngân sách và tổng quan thu chi nhanh chóng.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
