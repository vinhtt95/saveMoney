import SwiftUI
import Charts

struct PinnedBudgetCard: View {
    let budget: Budget
    @Environment(AppViewModel.self) private var app
    
    // Animation state
    @State private var fillAnimation: CGFloat = 0.0
    
    // MARK: - Core Logic Thống Kê
    
    struct CategoryStat: Identifiable {
        let id = UUID()
        let name: String
        let amount: Double
        let color: Color
    }
    
    // 1. Phân tích số tiền đã chi theo từng danh mục và gắn màu
    var categoryBreakdown: [CategoryStat] {
        var statsMap: [String: Double] = [:]
        
        let relevantTxs = app.transactions.filter { tx in
            tx.type == .expense &&
            budget.categoryIds.contains(tx.categoryId ?? "") &&
            tx.date >= budget.dateStart &&
            tx.date <= budget.dateEnd
        }
        
        for tx in relevantTxs {
            if let catId = tx.categoryId {
                statsMap[catId, default: 0] += abs(tx.amount)
            }
        }
        
        // Sắp xếp từ cao xuống thấp
        let sortedStats = statsMap.compactMap { (catId, amount) -> (String, Double)? in
            guard let cat = app.category(for: catId) else { return nil }
            return (cat.name, amount)
        }.sorted { $0.1 > $1.1 }
        
        // Bảng màu cho các danh mục (giống style của Insight)
        let palette: [Color] = [.blue, .orange, .purple, .pink, .teal, .indigo]
        var breakdown: [CategoryStat] = []
        
        // Top 3 danh mục
        for (index, stat) in sortedStats.prefix(3).enumerated() {
            breakdown.append(CategoryStat(name: stat.0, amount: stat.1, color: palette[index % palette.count]))
        }
        
        // Gộp các khoản Khác
        if sortedStats.count > 3 {
            let othersAmount = sortedStats.dropFirst(3).reduce(0) { $0 + $1.1 }
            breakdown.append(CategoryStat(name: "Khác", amount: othersAmount, color: .gray.opacity(0.6)))
        }
        
        return breakdown
    }
    
    // 2. Dữ liệu gộp cho Biểu đồ (Bao gồm cả phần "Còn lại")
    struct ChartSegment: Identifiable {
        let id = UUID()
        let name: String
        let amount: Double
        let color: Color
        let isRemaining: Bool
    }
    
    var chartData: [ChartSegment] {
        // Nạp các phần đã chi vào biểu đồ
        var data = categoryBreakdown.map {
            ChartSegment(name: $0.name, amount: $0.amount, color: $0.color, isRemaining: false)
        }
        
        // Nếu chưa vượt ngân sách, nạp thêm phần nước "Còn lại"
        if !isOverspent && remainingAmount > 0 {
            data.append(ChartSegment(name: "Còn lại", amount: remainingAmount, color: DSColors.accent, isRemaining: true))
        }
        
        return data
    }
    
    // 3. Các con số tổng quát
    var spentAmount: Double { categoryBreakdown.reduce(0) { $0 + $1.amount } }
    var remainingAmount: Double { max(0, budget.limit - spentAmount) }
    var overspentAmount: Double { max(0, spentAmount - budget.limit) }
    var progress: Double { budget.limit > 0 ? (spentAmount / budget.limit) : 0 }
    var isOverspent: Bool { progress >= 1.0 }

    // MARK: - Giao diện
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            // Header
            HStack {
                Label(budget.name, systemImage: "chart.pie.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            
            HStack(alignment: .center, spacing: DSSpacing.xl) {
                // Biểu đồ Donut Đa sắc
                ZStack {
                    Chart(chartData) { item in
                        if item.isRemaining {
                            SectorMark(
                                angle: .value("Số tiền", item.amount * fillAnimation),
                                innerRadius: .ratio(0.65),
                                angularInset: 1.5
                            )
                            .foregroundStyle(DSColors.accent.gradient)
                            .cornerRadius(3)
                        } else {
                            SectorMark(
                                angle: .value("Số tiền", item.amount * fillAnimation),
                                innerRadius: .ratio(0.65),
                                angularInset: 1.5
                            )
                            .foregroundStyle(isOverspent ? DSColors.negative.opacity(0.8).gradient : item.color.gradient)
                            .cornerRadius(3)
                        }
                    }
                    .frame(width: 120, height: 120)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: fillAnimation)
                    
                    // Thông số ở tâm vòng tròn
                    VStack(spacing: 2) {
                        Text(isOverspent ? "Vượt mức" : "Còn lại")
                            .font(.caption2)
                            .foregroundStyle(isOverspent ? DSColors.negative : .secondary)
                        Text(formatVNDShort(isOverspent ? overspentAmount : remainingAmount))
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(isOverspent ? DSColors.negative : DSColors.accent)
                    }
                }
                
                // Thống kê phân rã (Legend) bên phải
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    HStack {
                        Text("Ngân sách")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatVNDShort(budget.limit))
                            .font(.caption.bold().monospacedDigit())
                    }
                    
                    ProgressView(value: min(progress, 1.0))
                        .tint(isOverspent ? DSColors.negative : DSColors.accent)
                        .padding(.bottom, 4)
                    
                    if categoryBreakdown.isEmpty {
                        Text("Chưa có dữ liệu chi tiêu")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    } else {
                        // Render trực tiếp các danh mục kèm chấm màu tương ứng trên Chart
                        ForEach(categoryBreakdown) { stat in
                            HStack {
                                Circle()
                                    .fill(isOverspent ? DSColors.negative.opacity(0.8) : stat.color)
                                    .frame(width: 8, height: 8)
                                Text(stat.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                                Spacer()
                                Text(formatVNDShort(stat.amount))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(DSSpacing.lg)
        .liquidGlass(in: .rect(cornerRadius: DSRadius.lg), tint: DSColors.accent.opacity(0.05))
        .onAppear {
            // Trigger animation sau một nhịp nhỏ để mượt hơn
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation { fillAnimation = 1.0 }
            }
        }
    }
}
