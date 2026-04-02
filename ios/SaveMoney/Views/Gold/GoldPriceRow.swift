import SwiftUI

struct GoldPriceRow: View {
    let item: GoldPriceItem
    @Environment(\.colorScheme) var scheme

    var body: some View {
        GlassCard(radius: DSRadius.md, padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.name)
                    .font(.dsTitle(14))
                    .foregroundStyle(Color.dsOnSurface(for: scheme))
                    .lineLimit(1)
                HStack {
                    if let buy = item.buyPrice {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mua")
                                .font(.dsBody(10))
                                .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                            Text(Formatters.formatVNDShort(buy))
                                .font(.dsTitle(13))
                                .foregroundStyle(Color.dsIncome)
                        }
                    }
                    Spacer()
                    if let sell = item.sellPrice {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Bán")
                                .font(.dsBody(10))
                                .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                            Text(Formatters.formatVNDShort(sell))
                                .font(.dsTitle(13))
                                .foregroundStyle(Color.dsExpense)
                        }
                    }
                }
            }
        }
    }
}
