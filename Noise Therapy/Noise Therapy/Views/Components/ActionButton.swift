import SwiftUI

struct ActionButton: View {
    let isRunning: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            ZStack {
//                // Outer Halo - Intense
//                Circle()
//                    .stroke(Theme.active.opacity(0.2), lineWidth: 2)
//                    .scaleEffect(isRunning ? 2.5 : 0.8)
//                    .opacity(isRunning ? 0.0 : 0.6)
//                    .animation(
//                        .easeOut(duration: 1.5).repeatForever(autoreverses: false).delay(0.5),
//                        value: isRunning)
//
//                // Inner Pulse - Fast
//                Circle()
//                    .stroke(Theme.active.opacity(0.4), lineWidth: 2)
//                    .scaleEffect(isRunning ? 1.8 : 0.8)
//                    .opacity(isRunning ? 0.0 : 0.8)
//                    .animation(
//                        .easeOut(duration: 1.5).repeatForever(autoreverses: false),
//                        value: isRunning)

                RoundedRectangle(cornerRadius: 28)
                    .fill(isRunning ? Theme.active : Theme.surface)
                    .frame(height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Theme.active, lineWidth: 1)
                    )
                    .modifier(
                        Theme.glow(color: isRunning ? Theme.active : Color.clear, radius: 10)
                    )

                HStack {
                    Image(systemName: isRunning ? "waveform" : "play.fill")
                    Text(isRunning ? "STOP_NOISE" : "START_NOISE")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                }
                .foregroundColor(
                    isRunning
                        ? Theme.background
                        : Theme.active)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
    }
}
