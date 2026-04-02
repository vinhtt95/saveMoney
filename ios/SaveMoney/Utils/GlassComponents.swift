import SwiftUI

// MARK: - GlassCard

struct GlassCard<Content: View>: View {
    var radius: CGFloat = DSRadius.lg
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content
    @Environment(\.colorScheme) var scheme

    var body: some View {
        content()
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(scheme == .dark ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.dsCardLight))
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(
                                scheme == .dark ? Color.dsGhostBorder : Color.black.opacity(0.05),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: scheme == .dark ? Color.clear : Color.black.opacity(0.07),
                        radius: 12, x: 0, y: 4
                    )
            }
    }
}

// MARK: - GradientCard (for hero sections)

struct GradientCard<Content: View>: View {
    var radius: CGFloat = DSRadius.xl
    var padding: CGFloat = 20
    @ViewBuilder var content: () -> Content
    @Environment(\.colorScheme) var scheme

    var body: some View {
        content()
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(LinearGradient.dsCTAGradient(scheme: scheme))
            }
    }
}

// MARK: - GlassPillButton

struct GlassPillButton: View {
    let label: String
    let action: () -> Void
    @Environment(\.colorScheme) var scheme

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.dsBody(15, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 13)
                .background(LinearGradient.dsCTAGradient(scheme: scheme))
                .clipShape(Capsule())
        }
    }
}

// MARK: - GlassSearchBar

struct GlassSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Tìm kiếm..."
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                .font(.system(size: 15, weight: .medium))

            TextField(placeholder, text: $text)
                .font(.dsBody(15))
                .foregroundStyle(Color.dsOnSurface(for: scheme))

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background {
            RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                .fill(scheme == .dark ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(Color.dsSurfaceLight))
                .overlay(
                    RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                        .stroke(Color.dsGhostBorder, lineWidth: 1)
                )
        }
    }
}

// MARK: - GlassPeriodChip

struct GlassPeriodChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var scheme

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.dsBody(13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.white : Color.dsOnSurfaceVariant(for: scheme))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(LinearGradient.dsCTAGradient(scheme: scheme))
                    } else {
                        Capsule()
                            .fill(scheme == .dark
                                  ? AnyShapeStyle(.ultraThinMaterial)
                                  : AnyShapeStyle(Color.dsSurfaceLight))
                            .overlay(Capsule().stroke(Color.dsGhostBorder, lineWidth: 1))
                    }
                }
        }
    }
}

// MARK: - GradientCircleIcon

struct GradientCircleIcon: View {
    let systemName: String
    var colors: [Color] = [Color(hex: "#c799ff"), Color(hex: "#4af8e3")]
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

// MARK: - Category icon color mapping

func categoryIconColors(for name: String) -> [Color] {
    let lower = name.lowercased()
    if lower.contains("ăn") || lower.contains("food") || lower.contains("nhà hàng") || lower.contains("dining") {
        return [Color(hex: "#ff6b8a"), Color(hex: "#ff9a9e")]
    } else if lower.contains("di chuyển") || lower.contains("xăng") || lower.contains("travel") || lower.contains("transport") {
        return [Color(hex: "#4af8e3"), Color(hex: "#36d1c4")]
    } else if lower.contains("mua sắm") || lower.contains("shop") {
        return [Color(hex: "#a78bfa"), Color(hex: "#7c3aed")]
    } else if lower.contains("giải trí") || lower.contains("cinema") || lower.contains("entertain") {
        return [Color(hex: "#fbbf24"), Color(hex: "#f59e0b")]
    } else if lower.contains("sức khỏe") || lower.contains("health") || lower.contains("y tế") {
        return [Color(hex: "#6ee7b7"), Color(hex: "#10b981")]
    } else if lower.contains("lương") || lower.contains("salary") || lower.contains("income") || lower.contains("thu nhập") {
        return [Color(hex: "#4af8e3"), Color(hex: "#059669")]
    } else if lower.contains("tiết kiệm") || lower.contains("saving") {
        return [Color(hex: "#60a5fa"), Color(hex: "#3b82f6")]
    }
    return [Color(hex: "#c799ff"), Color(hex: "#4af8e3")]
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
    @Environment(\.colorScheme) var scheme

    private let tabs: [(icon: String, label: String, index: Int)] = [
        ("house.fill",          "Flow",    0),
        ("clock.fill",          "History", 1),
        ("chart.bar.fill",      "Insight", 3),
        ("gearshape.fill",      "Profile", 4)
    ]

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer()
                HStack(alignment: .center, spacing: 0) {
                    // First 2 tabs
                    ForEach(tabs.prefix(2), id: \.index) { tab in
                        tabButton(tab: tab)
                    }

                    // Center FAB
                    centerFAB
                        .frame(maxWidth: .infinity)

                    // Last 2 tabs
                    ForEach(tabs.suffix(2), id: \.index) { tab in
                        tabButton(tab: tab)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, geo.safeAreaInsets.bottom + 8)
                .padding(.horizontal, 8)
                .background {
                    UnevenRoundedRectangle(
                        topLeadingRadius: DSRadius.xl,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: DSRadius.xl,
                        style: .continuous
                    )
                    .fill(scheme == .dark
                          ? AnyShapeStyle(.ultraThinMaterial)
                          : AnyShapeStyle(Color.dsCardLight.opacity(0.95)))
                    .overlay(
                        UnevenRoundedRectangle(
                            topLeadingRadius: DSRadius.xl,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: DSRadius.xl,
                            style: .continuous
                        )
                        .stroke(Color.dsGhostBorder, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -5)
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
                    .foregroundStyle(isSelected
                                     ? Color.dsPrimary(for: scheme)
                                     : Color.dsOnSurfaceVariant(for: scheme))

                Text(tab.label)
                    .font(.dsBody(10, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected
                                     ? Color.dsPrimary(for: scheme)
                                     : Color.dsOnSurfaceVariant(for: scheme))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var centerFAB: some View {
        Button(action: onAddTap) {
            ZStack {
                Circle()
                    .fill(LinearGradient.dsCTAGradient(scheme: scheme))
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.dsPrimary(for: scheme).opacity(0.4), radius: 12, x: 0, y: 4)

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
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.dsBody(12, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant(for: scheme))
            TextField(placeholder.isEmpty ? label : placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocorrectionDisabled(disableAutocorrect)
                .textInputAutocapitalization(autocapitalization)
                .font(.dsBody(15))
                .foregroundStyle(Color.dsOnSurface(for: scheme))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                        .fill(scheme == .dark
                              ? AnyShapeStyle(Color.dsBackgroundDark.opacity(0.6))
                              : AnyShapeStyle(Color.dsSurfaceLight))
                        .overlay(
                            RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                                .stroke(Color.dsGhostBorder, lineWidth: 1)
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
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack {
            Text(title)
                .font(.dsTitle(16))
                .foregroundStyle(Color.dsOnSurface(for: scheme))
            Spacer()
            if let action, let onAction {
                Button(action: onAction) {
                    Text(action)
                        .font(.dsBody(13, weight: .medium))
                        .foregroundStyle(Color.dsPrimary(for: scheme))
                }
            }
        }
    }
}
