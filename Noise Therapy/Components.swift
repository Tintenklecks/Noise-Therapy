import SwiftUI

struct VisualEarSelector: View {
    @Binding var selectedEar: EarSetting

    var body: some View {
        HStack(spacing: 20) {
            // Left Ear
            EarButton(
                icon: "earbuds.in.ear.left",
                label: "LEFT",
                isSelected: selectedEar == .left,
                isPartiallySelected: selectedEar == .both
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedEar = (selectedEar == .left) ? .both : .left
                }
            }

            // Right Ear
            EarButton(
                icon: "earbuds.in.ear.right",
                label: "RIGHT",
                isSelected: selectedEar == .right,
                isPartiallySelected: selectedEar == .both
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedEar = (selectedEar == .right) ? .both : .right
                }
            }
        }
    }
}

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

struct NoiseTypeSelector: View {
    @Binding var selection: NoiseType

    var body: some View {
        HStack(spacing: 12) {
            ForEach(NoiseType.allCases) { type in
                TypeButton(type: type, isSelected: selection == type) {
                    withAnimation { selection = type }
                }
            }
        }
    }
}

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

struct LabSlider: View {
    let label: LocalizedStringKey
    @Binding var value: Float
    let range: ClosedRange<Float>
    let unit: String
    var format: String = "%.0f"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label)
                    .font(Theme.labLabel)
                    .foregroundColor(Theme.textDim)

                Spacer()

                Text("\(String(format: format, value)) \(unit)")
                    .font(Theme.labValue)
                    .foregroundColor(Theme.active)
            }

            Slider(value: $value, in: range)
                .accentColor(Theme.active)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Theme.textDim.opacity(0.1), Color.clear],
                                startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
        )
    }
}

struct StartButton: View {
    @Binding var isRunning: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isRunning {
                    Circle()
                        .stroke(Theme.active.opacity(0.3), lineWidth: 1)
                        .scaleEffect(1.5)
                        .opacity(0.5)
                        .scaleEffect(isRunning ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: 2).repeatForever(autoreverses: false),
                            value: isRunning)
                }

                RoundedRectangle(cornerRadius: 28)
                    .fill(isRunning ? Theme.active : Theme.surface)
                    .frame(height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Theme.active, lineWidth: 1)
                    )
                    .modifier(Theme.glow(color: isRunning ? Theme.active : Color.clear, radius: 10))

                HStack {
                    Image(systemName: isRunning ? "waveform" : "play.fill")
                    Text(isRunning ? "STOP_NOISE" : "START_NOISE")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                }
                .foregroundColor(isRunning ? Theme.background : Theme.active)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
    }
}
