import SwiftUI

struct Theme {
    static let background = Color(hex: "#050814")  // Deep Void
    static let surface = Color(hex: "#0F1426")  // Dark Navy surface
    static let active = Color(hex: "#00E5FF")  // Electric Cyan
    static let warn = Color(hex: "#FFB74D")  // Soft Amber
    static let textMain = Color(hex: "#E0E6ED")  // Off-white / Silver
    static let textDim = Color(hex: "#78879E")  // Blue-grey dim

    static let gradientBackground = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "#02040A"),
            Color(hex: "#0A1124"),
        ]),
        startPoint: .top,
        endPoint: .bottom
    )

    static func glow(color: Color, radius: CGFloat = 10) -> some ViewModifier {
        GlowModifier(color: color, radius: radius)
    }

    // Fonts (These could be moved to Font extension entirely, but keeping here for compatibility with existing code calling Theme.labHeader)
    static let labHeader = Font.system(size: 14, weight: .bold, design: .monospaced)
    static let labValue = Font.system(size: 24, weight: .light, design: .rounded)
    static let labLabel = Font.system(size: 12, weight: .medium, design: .default)
}
