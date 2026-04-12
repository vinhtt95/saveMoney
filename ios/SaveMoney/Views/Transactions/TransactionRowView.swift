import SwiftUI

struct TransactionRowView: View {
    let tx: Transaction
    let app: AppViewModel
    
    private var categoryName: String { app.category(for: tx.categoryId)?.name ?? "—" }
    private var accountName: String { app.account(for: tx.accountId)?.name ?? "—" }
    
    // THÊM: Computed property để điều chỉnh số tiền hiển thị dựa trên EgoMode
    private var displayAmount: Double {
        // Chỉ áp dụng ảo giác nhân/chia 3 cho Thu nhập (Income)
        guard tx.type == .income else { return tx.amount }
        
        if app.egoMode == .humble {
            return tx.amount * app.humbleFactor
        } else if app.egoMode == .arrogant {
            return tx.amount * app.arrogantFactor
        }
        return tx.amount
    }
    
    var body: some View {
        // Tìm category object từ ID trong app state
        let category = app.categories.first(where: { $0.id == tx.categoryId })
        let categoryName = category?.name ?? "Khác"
        
        HStack(spacing: DSSpacing.md) {
            CategoryIconView(category: category, fallbackName: categoryName, size: 40)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(categoryName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                
                HStack(spacing: DSSpacing.xs) {
                    Image(systemName: "creditcard")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(accountName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                if let note = tx.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // SỬA: Thay tx.amount bằng displayAmount
            AmountText(amount: displayAmount, type: tx.type, font: .subheadline.weight(.bold).monospacedDigit())
        }
        .padding(.vertical, DSSpacing.sm)
    }
}
