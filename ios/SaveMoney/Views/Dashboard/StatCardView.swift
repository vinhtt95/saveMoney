import SwiftUI

struct StatCardView: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    @Environment(\.colorScheme) var scheme

    var body: some View {
        GlassCard(radius: DSRadius.lg, padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                GradientCircleIcon(
                    systemName: icon,
                    colors: iconGradient,
                    size: 36
                )
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.dsBody(12))
                        .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                    Text(Formatters.formatVNDShort(abs(amount)))
                        .font(.dsTitle(16))
                        .foregroundStyle(amountColor)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var amountColor: Color {
        if color == .green { return Color.dsIncome }
        if color == .red   { return Color.dsExpense }
        return Color.dsOnSurface(for: scheme)
    }

    private var iconGradient: [Color] {
        if color == .green { return [Color(hex: "#4af8e3"), Color(hex: "#059669")] }
        if color == .red   { return [Color(hex: "#ff6b8a"), Color(hex: "#e84393")] }
        if color == .blue  { return [Color(hex: "#60a5fa"), Color(hex: "#3b82f6")] }
        return [Color(hex: "#c799ff"), Color(hex: "#4af8e3")]
    }
}
