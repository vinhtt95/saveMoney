import SwiftUI

import SwiftUI

struct LiquidGlassModifier<S: Shape>: ViewModifier {
    var shape: S
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .overlay {
                // Viền sáng rực hơn ở góc Top-Leading để tạo cảm giác mặt kính cong
                shape.stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.4 : 0.7),
                            Color.white.opacity(0.1),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
            }
            .background {
                // Inner Glow mỏng nhưng sắc nét để tạo độ nổi
                shape
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3), lineWidth: 1.5)
                    .blur(radius: 0.5)
                    .mask(shape)
            }
    }
}

extension View {
    func liquidGlass<S: Shape>(
        in shape: S,
        tint: Color? = nil,
        material: Material = .ultraThinMaterial // Dùng ultraThin cho iOS 18 look
    ) -> some View {
        self.modifier(LiquidGlassModifier(shape: shape))
    }
}
