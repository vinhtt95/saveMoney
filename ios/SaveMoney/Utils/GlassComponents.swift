import SwiftUI

// MARK: - GlassCard

struct GlassCard<Content: View>: View {
    var radius: CGFloat = DSRadius.lg
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    // iOS 26 liquid glass: ultraThinMaterial in BOTH light and dark
                    .fill(.ultraThinMaterial)
                    // Specular highlight: top-edge white gradient (simulates glass reflection)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.40), .white.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: UnitPoint(x: 0.5, y: 0.35)
                                ),
                                lineWidth: 1
                            )
                    )
                    // Outer separator border for card definition
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            }
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
                    Capsule()
                        .fill(Color.dsBrandAccent)
                        .overlay(Capsule().fill(.ultraThinMaterial.opacity(0.15)))
                        .overlay(Capsule().stroke(.white.opacity(0.30), lineWidth: 1))
                }
        }
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
        .background {
            RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                        .stroke(Color(.separator).opacity(0.6), lineWidth: 0.5)
                )
        }
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
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color.dsBrandAccent)
                            .overlay(Capsule().fill(.ultraThinMaterial.opacity(0.10)))
                            .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
                    } else {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(Capsule().stroke(Color(.separator).opacity(0.5), lineWidth: 0.5))
                    }
                }
        }
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

// MARK: - DSTabBar (Split: left pill nav + right circle add)

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
        if #available(iOS 26.0, *) {
            liquidGlassBody
        } else {
            legacyBody
        }
    }

    // MARK: - iOS 26 Liquid Glass

    @available(iOS 26.0, *)
    private var liquidGlassBody: some View {
        HStack(alignment: .center, spacing: 10) {
            // Nav pill — expands to fill remaining width
            GlassEffectContainer {
                HStack(spacing: 0) {
                    ForEach(tabs, id: \.index) { tab in
                        liquidTabButton(tab: tab)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(4)
                .glassEffect(.regular, in: .capsule)
            }
            .frame(maxWidth: .infinity)

            // Add button — fixed size, separate glass element
            GlassEffectContainer {
                Button(action: onAddTap) {
                    ZStack {
                        Circle()
                            .fill(Color.dsBrandAccent.opacity(0.88))
                        Image(systemName: "plus")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 50, height: 50)
                }
                .glassEffect(.regular, in: .circle)
            }
            .frame(width: 50, height: 50)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }

    @available(iOS 26.0, *)
    private func liquidTabButton(tab: (icon: String, label: String, index: Int)) -> some View {
        let isSelected = selectedTab == tab.index
        return Button {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.42)) {
                selectedTab = tab.index
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.dsBrandAccent : Color(.secondaryLabel))
                Text(tab.label)
                    .font(.dsBody(10, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.dsBrandAccent : Color(.secondaryLabel))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.regularMaterial)
                        .matchedGeometryEffect(id: "tabIndicator", in: tabNamespace)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.38, dampingFraction: 0.42), value: isSelected)
    }

    // MARK: - Legacy fallback (iOS < 26)

    private var legacyBody: some View {
        HStack(alignment: .center, spacing: 10) {
            HStack(spacing: 0) {
                ForEach(tabs, id: \.index) { tab in
                    legacyTabButton(tab: tab)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(4)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.45), .white.opacity(0.08)],
                                    startPoint: .top, endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.20), radius: 20, x: 0, y: 6)
            }

            Button(action: onAddTap) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(Circle().fill(Color.dsBrandAccent.opacity(0.88)))
                        .overlay(
                            Circle().stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.50), .white.opacity(0.10)],
                                    startPoint: .top, endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                        )
                        .shadow(color: Color.dsBrandAccent.opacity(0.45), radius: 14, x: 0, y: 5)
                    Image(systemName: "plus")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 50, height: 50)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }

    private func legacyTabButton(tab: (icon: String, label: String, index: Int)) -> some View {
        let isSelected = selectedTab == tab.index
        return Button {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.42)) {
                selectedTab = tab.index
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.dsBrandAccent : Color(.secondaryLabel))
                Text(tab.label)
                    .font(.dsBody(10, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.dsBrandAccent : Color(.secondaryLabel))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.60), .white.opacity(0.05)],
                                        startPoint: .top, endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .matchedGeometryEffect(id: "tabIndicator", in: tabNamespace)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.38, dampingFraction: 0.42), value: isSelected)
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
                .background {
                    RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                                .stroke(Color(.separator).opacity(0.6), lineWidth: 0.5)
                        )
                }
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
