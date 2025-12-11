import SwiftUI

struct EarButton: View {
    let icon: String
    let label: LocalizedStringKey
    let isSelected: Bool
    let isPartiallySelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    if isSelected || isPartiallySelected {
                        Circle()
                            .fill(Theme.active.opacity(isSelected ? 0.2 : 0.05))
                            .frame(width: 80, height: 80)
                            .modifier(Theme.glow(color: Theme.active, radius: isSelected ? 15 : 5))
                    }

                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .thin))
                        .foregroundColor(
                            isSelected
                                ? Theme.active
                                : (isPartiallySelected ? Theme.textMain : Theme.textDim)
                        )
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    isSelected
                                        ? Theme.active
                                        : (isPartiallySelected
                                            ? Theme.textMain.opacity(0.3) : Color.clear),
                                    Color.clear,
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

                if isSelected {
                    Text(label)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.active)
                        .tracking(1)
                }
            }
        }
    }
}
