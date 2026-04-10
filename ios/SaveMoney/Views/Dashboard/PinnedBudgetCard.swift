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
    }
    
    // 1. Phân tích số tiền đã chi theo từng danh mục
    var categoryStats: [CategoryStat] {
        var statsMap: [String: Double] = [:]
        
        let relevantTxs = app.transactions.filter { tx in
            tx.type == .expense &&
            budget.categoryIds.contains(tx.categoryId ?? "") &&
            tx.date >= budget.dateStart &&
            tx.date <= budget.dateEnd
        }
        
        // Cộng dồn tiền theo ID. Dùng abs() để đảm bảo trị tuyệt đối (fix lỗi cộng dồn số âm)
        for tx in relevantTxs {
            if let catId = tx.categoryId {
                statsMap[catId, default: 0] += abs(tx.amount)
            }
        }
        
        // Map ID sang Tên và sắp xếp từ cao xuống thấp
        return statsMap.compactMap { (catId, amount) in
            guard let cat = app.category(for: catId) else { return nil }
            return CategoryStat(name: cat.name, amount: amount)
        }
        .sorted { $0.amount > $1.amount }
    }
    
    // 2. Các con số tổng quát
    var spentAmount: Double {
        categoryStats.reduce(0) { $0 + $1.amount }
    }
    
    var remainingAmount: Double {
        max(0, budget.limit - spentAmount)
    }
    
    var overspentAmount: Double {
        max(0, spentAmount - budget.limit)
    }
    
    var progress: Double {
        budget.limit > 0 ? (spentAmount / budget.limit) : 0
    }
    
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
            
            HStack(alignment: .top, spacing: DSSpacing.xl) {
                // Biểu đồ Donut bên trái
                ZStack {
                    Chart {
                        // Trục đã chi (Màu xám hoặc Đỏ nếu vượt)
                        SectorMark(
                            angle: .value("Đã chi", min(spentAmount, budget.limit) * fillAnimation),
                            innerRadius: .ratio(0.65),
                            angularInset: 1
                        )
                        .foregroundStyle(isOverspent ? DSColors.negative.opacity(0.8) : Color.secondary.opacity(0.2))
                        
                        // Trục còn lại (Màu xanh)
                        if !isOverspent {
                            SectorMark(
                                angle: .value("Còn lại", remainingAmount * fillAnimation),
                                innerRadius: .ratio(0.65),
                                angularInset: 1
                            )
                            .foregroundStyle(DSColors.accent.gradient)
                            .cornerRadius(4)
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
                
                // Thống kê phân rã (Breakdown) bên phải
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
                    
                    if categoryStats.isEmpty {
                        Text("Chưa có dữ liệu")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    } else {
                        // Hiển thị top 3 danh mục tiêu nhiều nhất
                        ForEach(categoryStats.prefix(3)) { stat in
                            HStack {
                                Text(stat.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                                Spacer()
                                Text(formatVNDShort(stat.amount))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        // Gom các danh mục còn lại vào mục "Khác" để UI không bị tràn
                        if categoryStats.count > 3 {
                            let others = categoryStats.dropFirst(3).reduce(0) { $0 + $1.amount }
                            HStack {
                                Text("Khác")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(formatVNDShort(others))
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
            withAnimation { fillAnimation = 1.0 }
        }
    }
}
