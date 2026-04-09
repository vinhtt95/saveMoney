import SwiftUI

struct StatCardView: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    var isBalance: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(formatVNDShort(amount))
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(isBalance ? (amount >= 0 ? DSColors.positive : DSColors.negative) : color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(DSSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(in: .rect(cornerRadius: DSRadius.md), tint: color.opacity(0.3), material: .thinMaterial)
    }
}
