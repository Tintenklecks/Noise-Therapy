import SwiftUI

struct TypeButton: View {
    let type: NoiseType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(colorForType(type))
                    .frame(width: 6, height: 6)

                Text(type.localizedName.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(isSelected ? Theme.textMain : Theme.textDim)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Theme.surface.opacity(0.8) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? Theme.active.opacity(0.5) : Theme.textDim.opacity(0.2),
                                lineWidth: 1)
                    )
            )
        }
    }

    func colorForType(_ type: NoiseType) -> Color {
        switch type {
        case .white: return .white
        case .pink: return Color(hex: "#FFB2C1")
        case .brown: return Color(hex: "#8D6E63")
        }
    }
}
