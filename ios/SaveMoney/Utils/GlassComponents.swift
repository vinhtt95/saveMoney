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

// MARK: - Liquid Background
struct LiquidBackgroundView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Nền cơ bản
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            // Các đốm màu (Orbs)
            Circle()
                .fill(DSColors.accent.opacity(0.4))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: isAnimating ? 100 : -100, y: isAnimating ? -150 : 150)
            
            Circle()
                .fill(Color.orange.opacity(0.3))
                .frame(width: 250, height: 250)
                .blur(radius: 60)
                .offset(x: isAnimating ? -150 : 150, y: isAnimating ? 150 : -100)
            
            Circle()
                .fill(Color.purple.opacity(0.3))
                .frame(width: 350, height: 350)
                .blur(radius: 100)
                .offset(x: isAnimating ? 150 : -50, y: isAnimating ? 200 : -200)
        }
        .ignoresSafeArea()
        // Tạo animation di chuyển nhẹ nhàng liên tục
        .onAppear {
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Static Random Liquid Background
struct LiquiBackgroundViewNotAnimating: View {
    
    // Cấu trúc lưu trữ thông số của mỗi đốm màu (Orb)
    private struct OrbConfig {
        let color: Color
        let width: CGFloat
        let height: CGFloat
        let offsetX: CGFloat // Tỉ lệ vị trí theo chiều ngang màn hình
        let offsetY: CGFloat // Tỉ lệ vị trí theo chiều dọc màn hình
        let blur: CGFloat
    }
    
    @State private var orb1: OrbConfig
    @State private var orb2: OrbConfig
    @State private var orb3: OrbConfig
    
    init() {
        // Bảng màu (Palette) dùng để random. Bạn có thể thay bằng DSColors nếu muốn.
        let palette: [Color] = [.orange, .purple, .teal, .pink, .blue, .mint, .indigo, DSColors.income, DSColors.accent]
        
        // Orb 1: Vùng ngẫu nhiên ở khu vực dưới / phải
        _orb1 = State(initialValue: OrbConfig(
            color: palette.randomElement() ?? .orange,
            width: CGFloat.random(in: 250...350),
            height: CGFloat.random(in: 300...400),
            offsetX: CGFloat.random(in: 0.15...0.4),
            offsetY: CGFloat.random(in: 0.15...0.4),
            blur: CGFloat.random(in: 70...100)
        ))
        
        // Orb 2: Vùng ngẫu nhiên ở khu vực giữa trung tâm
        _orb2 = State(initialValue: OrbConfig(
            color: palette.randomElement() ?? .purple,
            width: CGFloat.random(in: 350...550),
            height: CGFloat.random(in: 200...350),
            offsetX: CGFloat.random(in: -0.15...0.15),
            offsetY: CGFloat.random(in: -0.15...0.15),
            blur: CGFloat.random(in: 80...110)
        ))
        
        // Orb 3: Vùng ngẫu nhiên ở khu vực trên / trái
        _orb3 = State(initialValue: OrbConfig(
            color: palette.randomElement() ?? .teal,
            width: CGFloat.random(in: 250...400),
            height: CGFloat.random(in: 300...450),
            offsetX: CGFloat.random(in: -0.4 ... -0.15),
            offsetY: CGFloat.random(in: -0.4 ... -0.15),
            blur: CGFloat.random(in: 80...110)
        ))
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Nền cơ bản
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                // Orb 1 (Dưới phải)
                Circle()
                    .fill(orb1.color.opacity(0.35))
                    .frame(width: orb1.width, height: orb1.height)
                    .blur(radius: orb1.blur)
                    .offset(x: geo.size.width * orb1.offsetX, y: geo.size.height * orb1.offsetY)
                
                // Orb 2 (Giữa)
                Circle()
                    .fill(orb2.color.opacity(0.3))
                    .frame(width: orb2.width, height: orb2.height)
                    .blur(radius: orb2.blur)
                    .offset(x: geo.size.width * orb2.offsetX, y: geo.size.height * orb2.offsetY)
                
                // Orb 3 (Trên trái)
                Circle()
                    .fill(orb3.color.opacity(0.35))
                    .frame(width: orb3.width, height: orb3.height)
                    .blur(radius: orb3.blur)
                    .offset(x: geo.size.width * orb3.offsetX, y: geo.size.height * orb3.offsetY)
            }
        }
        .ignoresSafeArea()
    }
}
