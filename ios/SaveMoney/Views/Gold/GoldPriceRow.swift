import SwiftUI

struct GoldPriceRow: View {
    let item: GoldPriceItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.name)
                .font(.subheadline.bold())
            HStack {
                if let buy = item.buyPrice {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mua").font(.caption).foregroundColor(.secondary)
                        Text(Formatters.formatVND(buy))
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.green)
                    }
                }
                Spacer()
                if let sell = item.sellPrice {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Bán").font(.caption).foregroundColor(.secondary)
                        Text(Formatters.formatVND(sell))
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
