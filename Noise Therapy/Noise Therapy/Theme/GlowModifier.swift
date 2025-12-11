import SwiftUI

struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.3), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.1), radius: radius * 2, x: 0, y: 0)
    }
}
