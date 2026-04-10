import SwiftUI
import Charts

struct PinnedBudgetCard: View {
    let budget: Budget
    let selectedPeriod: String
    @Environment(AppViewModel.self) private var app
    
    // Animation state
    @State private var fillAnimation: CGFloat = 0.0
    
    // Tính toán số tiền đã chi cho các danh mục thuộc ngân sách này trong tháng
    var spentAmount: Double {
        app.transactions
            .filter { tx in
                tx.type == .expense &&
                // Thêm ?? "" ở đây để unwrap Optional an toàn
                budget.categoryIds.contains(tx.categoryId ?? "") && 
                tx.date.starts(with: selectedPeriod) // Format YYYY-MM
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    var remainingAmount: Double {
        max(0, budget.limit - spentAmount)
    }
    
    var progress: Double {
        budget.limit > 0 ? (spentAmount / budget.limit) : 0
    }
    
    var isOverspent: Bool { progress >= 1.0 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            HStack {
                Label(budget.name, systemImage: "chart.pie.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            
            HStack(spacing: DSSpacing.xl) {
                // Biểu đồ Donut với hiệu ứng "Cạn nước"
                ZStack {
                    Chart {
                        // Phần đã chi (Nền xám/đỏ)
                        SectorMark(
                            angle: .value("Đã chi", spentAmount * fillAnimation),
                            innerRadius: .ratio(0.65),
                            angularInset: 1
                        )
                        .foregroundStyle(isOverspent ? DSColors.negative.opacity(0.8) : Color.secondary.opacity(0.2))
                        
                        // Phần còn lại (Nước - màu xanh)
                        if !isOverspent {
                            SectorMark(
                                angle: .value("Còn lại", remainingAmount * fillAnimation),
                                innerRadius: .ratio(0.65),
                                angularInset: 1
                            )
                            .foregroundStyle(DSColors.accent.gradient) // Dùng gradient cho giống chất lỏng
                            .cornerRadius(4)
                        }
                    }
                    .frame(width: 140, height: 140)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: fillAnimation)
                    
                    // Text trung tâm hiển thị số tiền còn lại
                    VStack(spacing: 2) {
                        Text(isOverspent ? "Vượt mức" : "Còn lại")
                            .font(.caption2)
                            .foregroundStyle(isOverspent ? DSColors.negative : .secondary)
                        Text(formatVNDShort(isOverspent ? (spentAmount - budget.limit) : remainingAmount))
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(isOverspent ? DSColors.negative : DSColors.accent)
                    }
                }
                
                // Legend chi tiết
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    legendRow(title: "Ngân sách", amount: budget.limit, color: .secondary)
                    legendRow(title: "Đã chi", amount: spentAmount, color: isOverspent ? DSColors.negative : .secondary.opacity(0.5))
                    
                    ProgressView(value: min(progress, 1.0))
                        .tint(isOverspent ? DSColors.negative : DSColors.accent)
                        .padding(.top, 4)
                }
            }
        }
        .padding(DSSpacing.lg)
        .liquidGlass(in: .rect(cornerRadius: DSRadius.lg), tint: DSColors.accent.opacity(0.05))
        .onAppear {
            // Trigger animation khi view xuất hiện
            withAnimation {
                fillAnimation = 1.0
            }
        }
        .onChange(of: selectedPeriod) {
            // Reset animation khi đổi tháng
            fillAnimation = 0.0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation { fillAnimation = 1.0 }
            }
        }
    }
    
    private func legendRow(title: String, amount: Double, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title).font(.caption)
            Spacer()
            Text(formatVNDShort(amount)).font(.caption.monospacedDigit())
        }
    }
}
