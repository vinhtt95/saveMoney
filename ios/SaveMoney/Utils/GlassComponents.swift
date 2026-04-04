import SwiftUI

// MARK: - GlassCard

struct GlassCard<Content: View>: View {
    var radius: CGFloat = DSRadius.lg
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .glassEffect(.regular, in: .rect(cornerRadius: radius, style: .continuous))
    }
}

// MARK: - GradientCard (for hero sections)

struct GradientCard<Content: View>: View {
    var radius: CGFloat = DSRadius.xl
    var padding: CGFloat = 20
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(LinearGradient.dsCTAGradient(scheme: .dark))
                    // Glass sheen over the gradient
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.08))
                    )
                    // Specular top-edge highlight
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.50), .clear],
                                    startPoint: .top,
                                    endPoint: UnitPoint(x: 0.5, y: 0.25)
                                ),
                                lineWidth: 1
                            )
                    )
            }
    }
}

// MARK: - GlassPillButton

struct GlassPillButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.dsBody(15, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 13)
                .background {
                    Capsule().fill(Color.dsBrandAccent)
                }
        }
        .glassEffect(.regular, in: .capsule)
    }
}

// MARK: - GlassSearchBar

struct GlassSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Tìm kiếm..."

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color(.secondaryLabel))
                .font(.system(size: 15, weight: .medium))

            TextField(placeholder, text: $text)
                .font(.dsBody(15))
                .foregroundStyle(Color(.label))

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(.secondaryLabel))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .glassEffect(.regular, in: .rect(cornerRadius: DSRadius.md, style: .continuous))
    }
}

// MARK: - GlassPeriodChip

struct GlassPeriodChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.dsBody(13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : Color(.secondaryLabel))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
        }
        .glassEffect(.regular, in: .capsule)
        .tint(isSelected ? Color.dsBrandAccent : Color(.secondaryLabel))
    }
}

// MARK: - GradientCircleIcon

struct GradientCircleIcon: View {
    let systemName: String
    var colors: [Color] = [Color(hex: "#7C3AED"), Color(hex: "#5B21B6")]
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(colors: colors,
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .frame(width: size, height: size)

            Image(systemName: systemName)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Category icon color mapping (iOS system palette)

func categoryIconColors(for name: String) -> [Color] {
    let lower = name.lowercased()
    if lower.contains("ăn") || lower.contains("food") || lower.contains("nhà hàng") || lower.contains("dining") {
        return [Color(UIColor.systemPink), Color(hex: "#FF2D55")]
    } else if lower.contains("di chuyển") || lower.contains("xăng") || lower.contains("travel") || lower.contains("transport") {
        return [Color(UIColor.systemTeal), Color(hex: "#00968A")]
    } else if lower.contains("mua sắm") || lower.contains("shop") {
        return [Color(hex: "#7C3AED"), Color(hex: "#5B21B6")]
    } else if lower.contains("giải trí") || lower.contains("cinema") || lower.contains("entertain") {
        return [Color(UIColor.systemOrange), Color(UIColor.systemYellow)]
    } else if lower.contains("sức khỏe") || lower.contains("health") || lower.contains("y tế") {
        return [Color(UIColor.systemGreen), Color(hex: "#30D158")]
    } else if lower.contains("lương") || lower.contains("salary") || lower.contains("income") || lower.contains("thu nhập") {
        return [Color(UIColor.systemTeal), Color(UIColor.systemGreen)]
    } else if lower.contains("tiết kiệm") || lower.contains("saving") {
        return [Color(UIColor.systemBlue), Color(hex: "#0A84FF")]
    }
    return [Color(hex: "#7C3AED"), Color(hex: "#5B21B6")]
}

func categorySystemIcon(for name: String) -> String {
    let lower = name.lowercased()
    if lower.contains("ăn") || lower.contains("food") || lower.contains("nhà hàng") || lower.contains("dining") {
        return "fork.knife"
    } else if lower.contains("di chuyển") || lower.contains("xăng") || lower.contains("travel") || lower.contains("transport") {
        return "car.fill"
    } else if lower.contains("mua sắm") || lower.contains("shop") {
        return "bag.fill"
    } else if lower.contains("giải trí") || lower.contains("cinema") || lower.contains("entertain") {
        return "film.fill"
    } else if lower.contains("sức khỏe") || lower.contains("health") || lower.contains("y tế") {
        return "heart.fill"
    } else if lower.contains("lương") || lower.contains("salary") || lower.contains("thu nhập") {
        return "arrow.down.circle.fill"
    } else if lower.contains("tiết kiệm") || lower.contains("saving") {
        return "banknote.fill"
    } else if lower.contains("nhà") || lower.contains("house") || lower.contains("rent") {
        return "house.fill"
    } else if lower.contains("điện") || lower.contains("nước") || lower.contains("utility") {
        return "bolt.fill"
    } else if lower.contains("giáo dục") || lower.contains("education") || lower.contains("học") {
        return "book.fill"
    }
    return "creditcard.fill"
}

// MARK: - DSTabBar (iOS 26 Liquid Glass: left pill nav + right circle add)

struct DSTabBar: View {
    @Binding var selectedTab: Int
    let onAddTap: () -> Void
    @Namespace private var tabNamespace

    private let tabs: [(icon: String, label: String, index: Int)] = [
        ("house.fill",     "Flow",    0),
        ("clock.fill",     "History", 1),
        ("chart.bar.fill", "Insight", 3),
        ("gearshape.fill", "Profile", 4)
    ]

    var body: some View {
        GlassEffectContainer {
            HStack(alignment: .center, spacing: 10) {
                // Left nav pill — tab buttons with sliding indicator overlay
                pillNav
                    .glassEffect(.regular, in: .capsule)

                // Right add button
                Button(action: onAddTap) {
                    ZStack {
                        Circle().fill(Color.dsBrandAccent)
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 52, height: 52)
                }
                .glassEffect(.regular, in: .circle)
                .frame(width: 52, height: 52)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 4)
        }
        .contentShape(Rectangle())
    }

    // The pill nav is a separate computed property so matchedGeometryEffect
    // can use the namespace cleanly outside GlassEffectContainer internals
    private var pillNav: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.index) { tab in
                tabButton(tab: tab)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(4)
        // Sliding highlight — rendered as overlay on the pill, driven by geometry reader
        .overlay(alignment: .leading) {
            GeometryReader { geo in
                let count = CGFloat(tabs.count)
                let index = CGFloat(tabs.firstIndex(where: { $0.index == selectedTab }) ?? 0)
                let w = geo.size.width / count
                Capsule()
                    .fill(.regularMaterial)
                    .frame(width: w, height: geo.size.height)
                    .offset(x: index * w)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedTab)
            }
        }
    }

    private func tabButton(tab: (icon: String, label: String, index: Int)) -> some View {
        let isSelected = selectedTab == tab.index
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTab = tab.index
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.dsBrandAccent : Color(.tertiaryLabel))
                    .scaleEffect(isSelected ? 1.08 : 1.0)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelected)
                Text(tab.label)
                    .font(.dsBody(10, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.dsBrandAccent : Color(.tertiaryLabel))
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelected)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            // No background here — indicator is drawn as overlay on the whole pill
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Glass Form Field

struct GlassFormField: View {
    let label: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var placeholder: String = ""
    var disableAutocorrect: Bool = false
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.dsBody(12, weight: .medium))
                .foregroundStyle(Color(.secondaryLabel))
            TextField(placeholder.isEmpty ? label : placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocorrectionDisabled(disableAutocorrect)
                .textInputAutocapitalization(autocapitalization)
                .font(.dsBody(15))
                .foregroundStyle(Color(.label))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .glassEffect(.regular, in: .rect(cornerRadius: DSRadius.sm, style: .continuous))
        }
    }
}

// MARK: - Section Header

struct DSSectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.dsTitle(16))
                .foregroundStyle(Color(.label))
            Spacer()
            if let action, let onAction {
                Button(action: onAction) {
                    Text(action)
                        .font(.dsBody(13, weight: .medium))
                        .foregroundStyle(Color.dsBrandAccent)
                }
            }
        }
    }
}
