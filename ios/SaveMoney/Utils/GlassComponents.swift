import SwiftUI

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    var padding: CGFloat = DSSpacing.lg
    var cornerRadius: CGFloat = DSRadius.lg
    var tint: Color? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            // Áp dụng Liquid Glass
            .liquidGlass(in: .rect(cornerRadius: cornerRadius), tint: tint, material: .ultraThinMaterial)
    }
}

// MARK: - Liquid Button Style (iOS 18 Feedback)
struct LiquidButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .sensoryFeedback(.selection, trigger: configuration.isPressed) // Phản hồi rung nhẹ
    }
}

// MARK: - Glass Period Chip (Sửa lỗi và nâng cấp)
struct GlassPeriodChip: View {
    let period: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(periodLabel(period))
                .font(.caption.weight(.semibold))
                // FIX LỖI: Sử dụng Color.primary thay vì .primary để dùng opacity mượt mà
                .foregroundStyle(isSelected ? DSColors.accent : Color.primary.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .contentShape(Capsule())
                .background {
                    if isSelected {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .matchedGeometryEffect(id: "activeTab", in: namespace)
                            .liquidGlass(in: Capsule()) // Dùng modifier mới
                    }
                }
        }
        .buttonStyle(LiquidButtonStyle()) // Hiệu ứng nhún native
    }
}

struct LiquidGlassButtonStyle<S: Shape>: ButtonStyle {
    var shape: S
    var isSelected: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if isSelected || configuration.isPressed {
                    shape
                        .fill(.ultraThinMaterial)
                        .liquidGlass(in: shape)
                }
            }
            // 1. Tăng độ nén khi nhấn (nhấn sâu hơn một chút)
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            // 2. Sử dụng Spring "Nẩy" (Bounce cao)
            // Duration ngắn (0.2) + Bounce cao (0.4) tạo hiệu ứng giọt nước cực nhanh
            .animation(.spring(duration: 0.2, bounce: 0.4), value: configuration.isPressed)
            // 3. Thay đổi Haptic sang .impact (Cảm giác click cơ học thật hơn)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed)
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
    let category: Category? // Truyền cả object vào
    let fallbackName: String // Tên để dự phòng
    var size: CGFloat = 32

var body: some View {
        // Lấy icon: Ưu tiên từ DB -> fallback theo tên
        let iconName = category?.icon ?? categorySystemImage(fallbackName)
        
        // Lấy màu: Ưu tiên từ DB -> fallback theo tên
        let themeColor = category != nil
            ? CategoryColorHelper.map(category!.color)
            : categoryColor(fallbackName)

        ZStack {
            Circle()
                .fill(themeColor.opacity(0.15))
                .frame(width: size, height: size)
            Image(systemName: iconName)
                .font(.system(size: size * 0.45))
                .foregroundStyle(themeColor)
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
