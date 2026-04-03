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

// MARK: - DSTabBar

struct DSTabBar: View {
    @Binding var selectedTab: Int
    let onAddTap: () -> Void

    private let tabs: [(icon: String, label: String, index: Int)] = [
        ("house.fill",     "Flow",    0),
        ("clock.fill",     "History", 1),
        ("chart.bar.fill", "Insight", 3),
        ("gearshape.fill", "Profile", 4)
    ]

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer()
                HStack(alignment: .center, spacing: 0) {
                    ForEach(tabs.prefix(2), id: \.index) { tab in
                        tabButton(tab: tab)
                    }

                    centerFAB
                        .frame(maxWidth: .infinity)

                    ForEach(tabs.suffix(2), id: \.index) { tab in
                        tabButton(tab: tab)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, geo.safeAreaInsets.bottom + 8)
                .padding(.horizontal, 8)
                .background {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        // Single top-edge separator line — native iOS tab bar style
                        .overlay(
                            Rectangle()
                                .frame(height: 0.5)
                                .foregroundStyle(Color(.separator).opacity(0.6)),
                            alignment: .top
                        )
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .frame(height: 90)
    }

    private func tabButton(tab: (icon: String, label: String, index: Int)) -> some View {
        let isSelected = selectedTab == tab.index
        return Button {
            selectedTab = tab.index
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.dsBrandAccent : Color(.secondaryLabel))

                Text(tab.label)
                    .font(.dsBody(10, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.dsBrandAccent : Color(.secondaryLabel))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var centerFAB: some View {
        Button(action: onAddTap) {
            ZStack {
                Circle()
                    .fill(.regularMaterial)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle().fill(Color.dsBrandAccent.opacity(0.88))
                    )
                    .overlay(
                        Circle().stroke(.white.opacity(0.30), lineWidth: 1)
                    )
                    .shadow(color: Color.dsBrandAccent.opacity(0.45), radius: 12, x: 0, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .offset(y: -16)
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
