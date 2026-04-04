import SwiftUI

// MARK: - Color Tokens (iOS 26 System Semantic)

extension Color {
    // MARK: System Semantic Backgrounds (auto dark/light via UIKit)
    static let dsBackground     = Color(.systemBackground)
    static let dsSurfaceLow     = Color(.secondarySystemBackground)
    static let dsSurfaceHigh    = Color(.tertiarySystemBackground)

    // MARK: System Semantic Text
    static let dsLabel          = Color(.label)
    static let dsSecondaryLabel = Color(.secondaryLabel)
    static let dsTertiaryLabel  = Color(.tertiaryLabel)

    // MARK: Separator / Ghost Border
    static let dsSeparator      = Color(.separator)

    // MARK: Brand Accent — single saturated purple, no per-scheme branching
    static let dsBrandAccent    = Color(red: 0.486, green: 0.227, blue: 0.929) // #7C3AED

    // MARK: Semantic Financial — iOS system palette, vibrant in both modes
    static let dsIncome  = Color(UIColor.systemTeal)
    static let dsExpense = Color(UIColor.systemRed)
    static let dsGold    = Color(UIColor.systemOrange)

    // MARK: Hex initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Adaptive Colors (preserved for call-site compatibility — scheme param no longer needed)

extension Color {
    static func dsBackground(for scheme: ColorScheme) -> Color        { .dsBackground }
    static func dsPrimary(for scheme: ColorScheme) -> Color           { .dsBrandAccent }
    static func dsSecondary(for scheme: ColorScheme) -> Color         { Color(UIColor.systemTeal) }
    static func dsOnSurface(for scheme: ColorScheme) -> Color         { .dsLabel }
    static func dsOnSurfaceVariant(for scheme: ColorScheme) -> Color  { .dsSecondaryLabel }
}

// MARK: - Corner Radius Tokens

enum DSRadius {
    static let full: CGFloat = 9999
    static let xl:   CGFloat = 32
    static let lg:   CGFloat = 24
    static let md:   CGFloat = 16
    static let sm:   CGFloat = 12
    static let xs:   CGFloat = 8
}

// MARK: - Typography

extension Font {
    static func dsDisplay(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func dsTitle(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func dsBody(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func dsMono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}

// MARK: - Gradient Helpers

extension LinearGradient {
    /// Primary CTA gradient — rich purple-indigo, works in both light and dark
    static func dsCTAGradient(scheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#7C3AED"), Color(hex: "#5B21B6")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    static func dsCardGradient(scheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [Color(.secondarySystemBackground), Color(.systemBackground)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    static func dsIncomeGradient() -> LinearGradient {
        LinearGradient(
            colors: [Color(UIColor.systemTeal), Color(hex: "#00968A")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    static func dsExpenseGradient() -> LinearGradient {
        LinearGradient(
            colors: [Color(UIColor.systemRed), Color(hex: "#C0392B")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

// MARK: - ThemeManager

class ThemeManager: ObservableObject {
    @AppStorage("colorSchemePreference") var preference: String = "system"

    var colorScheme: ColorScheme? {
        switch preference {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }
}

// MARK: - DSMeshBackground

struct DSMeshBackground: View {
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ZStack {
            // System background as the true base — auto dark/light via UIKit
            Color(.systemBackground).ignoresSafeArea()

            // Subtle ambient tints — low opacity so .ultraThinMaterial cards show real vibrancy
            GeometryReader { geo in
                ZStack {
                    // Warm purple ambient (top-left)
                    Circle()
                        .fill(Color.dsBrandAccent.opacity(scheme == .dark ? 0.10 : 0.04))
                        .frame(width: geo.size.width * 0.75)
                        .blur(radius: 90)
                        .offset(x: -geo.size.width * 0.15, y: -geo.size.height * 0.05)

                    // Cool teal ambient (bottom-right)
                    Circle()
                        .fill(Color(UIColor.systemTeal).opacity(scheme == .dark ? 0.07 : 0.03))
                        .frame(width: geo.size.width * 0.55)
                        .blur(radius: 80)
                        .offset(x: geo.size.width * 0.35, y: geo.size.height * 0.45)
                }
            }
            .ignoresSafeArea()
        }
    }
}

