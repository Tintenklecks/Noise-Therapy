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

    // Fonts
    static let labHeader = Font.system(size: 14, weight: .bold, design: .monospaced)
    static let labValue = Font.system(size: 24, weight: .light, design: .rounded)
    static let labLabel = Font.system(size: 12, weight: .medium, design: .default)
}

struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.3), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.1), radius: radius * 2, x: 0, y: 0)
    }
}

extension Font {
    static let labHeader = Font.system(size: 14, weight: .bold, design: .monospaced)
    static let labValue = Font.system(size: 24, weight: .light, design: .rounded)
    static let labLabel = Font.system(size: 12, weight: .medium, design: .default)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:  // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
