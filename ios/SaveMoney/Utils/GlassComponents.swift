import SwiftUI

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    var padding: CGFloat = DSSpacing.lg
    var cornerRadius: CGFloat = DSRadius.lg
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
    }
}

// MARK: - Glass Period Chip
struct GlassPeriodChip: View {
    let period: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(periodLabel(period))
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? DSColors.accent : .primary)
                .padding(.horizontal, DSSpacing.md)
                .padding(.vertical, DSSpacing.sm)
                .glassEffect(
                    isSelected ? .regular.tint(DSColors.accent.opacity(0.15)) : .regular,
                    in: .capsule
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? DSColors.accent.opacity(0.5) : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Glass Search Bar
struct GlassSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Tìm kiếm..."

    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.body)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm)
        .glassEffect(.regular, in: .rect(cornerRadius: DSRadius.md))
    }
}

// MARK: - Glass Pill Button
struct GlassPillButton: View {
    let title: String
    var icon: String? = nil
    var tint: Color = DSColors.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundStyle(tint)
            .padding(.horizontal, DSSpacing.lg)
            .padding(.vertical, DSSpacing.sm)
            .glassEffect(.regular.tint(tint.opacity(0.1)), in: .capsule)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Amount Display
struct AmountText: View {
    let amount: Double
    let type: TransactionType
    var font: Font = .body.monospacedDigit()

    private var displayAmount: Double { abs(amount) }

    private var color: Color {
        switch type {
        case .income: DSColors.income
        case .expense: DSColors.expense
        case .transfer: DSColors.transfer
        case .account: .secondary
        }
    }

    private var prefix: String {
        switch type {
        case .income: "+"
        case .expense: "-"
        case .transfer: "⇄"
        case .account: ""
        }
    }

    var body: some View {
        Text("\(prefix)\(formatVND(displayAmount))")
            .font(font)
            .foregroundStyle(color)
    }
}

// MARK: - Category Icon View
struct CategoryIconView: View {
    let name: String
    var size: CGFloat = 32

    var body: some View {
        ZStack {
            Circle()
                .fill(categoryColor(name).opacity(0.15))
                .frame(width: size, height: size)
            Image(systemName: categorySystemImage(name))
                .font(.system(size: size * 0.45))
                .foregroundStyle(categoryColor(name))
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(DSColors.accent)
            Text("Đang tải dữ liệu...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error Banner
struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.caption)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(DSSpacing.md)
        .glassEffect(.regular.tint(Color.red.opacity(0.1)), in: .rect(cornerRadius: DSRadius.md))
    }
}

// MARK: - Section Header
struct DSSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal, DSSpacing.xs)
            content()
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: DSSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}
