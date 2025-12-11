import SwiftUI

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
