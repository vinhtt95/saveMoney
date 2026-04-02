import SwiftUI

// MARK: - Color Tokens

extension Color {
    // MARK: Dark Mode (Aura Liquid)
    static let dsBackgroundDark    = Color(hex: "#0c0e17")
    static let dsSurfaceLow        = Color(hex: "#13162a")
    static let dsSurfaceHigh       = Color(hex: "#1e2140")
    static let dsPrimaryDark       = Color(hex: "#c799ff")   // violet
    static let dsSecondaryDark     = Color(hex: "#4af8e3")   // cyan
    static let dsOnSurfaceDark     = Color(hex: "#f0f0fd")
    static let dsOnSurfaceVarDark  = Color(hex: "#aaaab7")
    static let dsGhostBorder       = Color(hex: "#464752").opacity(0.15)

    // MARK: Light Mode (Luminous Etherealism)
    static let dsBackgroundLight   = Color(hex: "#f5f7f9")
    static let dsSurfaceLight      = Color(hex: "#eef1f3")
    static let dsCardLight         = Color(hex: "#ffffff")
    static let dsPrimaryLight      = Color(hex: "#702ae1")
    static let dsPrimaryContainer  = Color(hex: "#b28cff")
    static let dsOnSurfaceLight    = Color(hex: "#2c2f31")
    static let dsOnSurfaceVarLight = Color(hex: "#6b7280")

    // MARK: Semantic
    static let dsIncome  = Color(hex: "#4af8e3")
    static let dsExpense = Color(hex: "#ff6b8a")
    static let dsGold    = Color(hex: "#fbbf24")

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

// MARK: - Adaptive Colors (auto dark/light)

extension Color {
    static func dsBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .dsBackgroundDark : .dsBackgroundLight
    }
    static func dsPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .dsPrimaryDark : .dsPrimaryLight
    }
    static func dsSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .dsSecondaryDark : .dsPrimaryContainer
    }
    static func dsOnSurface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .dsOnSurfaceDark : .dsOnSurfaceLight
    }
    static func dsOnSurfaceVariant(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .dsOnSurfaceVarDark : .dsOnSurfaceVarLight
    }
}

// MARK: - Corner Radius Tokens

enum DSRadius {
    static let full: CGFloat = 9999
    static let xl:   CGFloat = 32
    static let lg:   CGFloat = 24
    static let md:   CGFloat = 16
    static let sm:   CGFloat = 10
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
    static func dsCTAGradient(scheme: ColorScheme) -> LinearGradient {
        scheme == .dark
        ? LinearGradient(colors: [Color(hex: "#c799ff"), Color(hex: "#4af8e3")],
                         startPoint: .topLeading, endPoint: .bottomTrailing)
        : LinearGradient(colors: [Color(hex: "#702ae1"), Color(hex: "#b28cff")],
                         startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func dsCardGradient(scheme: ColorScheme) -> LinearGradient {
        scheme == .dark
        ? LinearGradient(colors: [Color(hex: "#1e1040"), Color(hex: "#0c0e17")],
                         startPoint: .topLeading, endPoint: .bottomTrailing)
        : LinearGradient(colors: [Color(hex: "#f0eaff"), Color(hex: "#e8f4ff")],
                         startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func dsIncomeGradient() -> LinearGradient {
        LinearGradient(colors: [Color(hex: "#4af8e3"), Color(hex: "#36d1c4")],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func dsExpenseGradient() -> LinearGradient {
        LinearGradient(colors: [Color(hex: "#ff6b8a"), Color(hex: "#e84393")],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
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
            if scheme == .dark {
                darkBackground
            } else {
                Color.dsBackgroundLight.ignoresSafeArea()
            }
        }
    }

    @ViewBuilder
    private var darkBackground: some View {
        Color.dsBackgroundDark.ignoresSafeArea()
        // Ambient gradient blobs
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(Color.dsPrimaryDark.opacity(0.18))
                    .frame(width: geo.size.width * 0.8)
                    .blur(radius: 80)
                    .offset(x: -geo.size.width * 0.2, y: -geo.size.height * 0.1)

                Circle()
                    .fill(Color.dsSecondaryDark.opacity(0.12))
                    .frame(width: geo.size.width * 0.6)
                    .blur(radius: 70)
                    .offset(x: geo.size.width * 0.3, y: geo.size.height * 0.4)
            }
        }
        .ignoresSafeArea()
    }
}
