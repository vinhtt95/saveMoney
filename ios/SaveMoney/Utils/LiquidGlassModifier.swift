import SwiftUI

struct LiquidGlassModifier<S: Shape>: ViewModifier {
    var shape: S
    var tint: Color?
    var material: Material
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            // 1. Lớp vật liệu kính (Blur) và Màu tint
            .background(
                ZStack {
                    if let tint {
                        tint.opacity(colorScheme == .dark ? 0.15 : 0.08)
                    }
                    Rectangle().fill(material)
                }
            )
            // Cắt theo hình dáng
            .clipShape(shape)
            // 2. Viền phản quang (Specular Highlight) - Yếu tố quan trọng nhất của Liquid Glass
            .overlay(
                shape.stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(colorScheme == .dark ? 0.3 : 0.8),
                            .white.opacity(0.1),
                            .clear,
                            .white.opacity(colorScheme == .dark ? 0.1 : 0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            )
            // 3. Đổ bóng tạo độ nổi (Drop shadow)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 15, x: 0, y: 8)
    }
}

extension View {
    func liquidGlass<S: Shape>(
        in shape: S,
        tint: Color? = nil,
        material: Material = .ultraThinMaterial // Dùng ultraThin cho iOS 18 look
    ) -> some View {
        self.modifier(LiquidGlassModifier(shape: shape, tint: tint, material: material))
    }
}
