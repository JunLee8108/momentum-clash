import SwiftUI

/// 커스텀 Liquid Glass 배경 modifier
struct LiquidGlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 16
    var opacity: Double = 0.6

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(opacity)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

/// Liquid Glass 버튼 스타일
struct LiquidGlassButtonStyle: ButtonStyle {
    var color: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .opacity(configuration.isPressed ? 0.4 : 0.7)
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                color.opacity(0.5),
                                color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
            .shadow(color: color.opacity(0.2), radius: 6, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 16, opacity: Double = 0.6) -> some View {
        modifier(LiquidGlassBackground(cornerRadius: cornerRadius, opacity: opacity))
    }
}
