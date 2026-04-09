import SwiftUI

import SwiftUI

struct LiquidGlassModifier<S: Shape>: ViewModifier {
    var shape: S
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .overlay {
                // Viền phản quang cực mảnh (0.5pt) đúng chuẩn iOS 18
                shape.stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.3 : 0.5),
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
                // Lớp Inner Glow tạo độ dày cho mặt kính
                shape
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2), lineWidth: 2)
                    .blur(radius: 1)
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
