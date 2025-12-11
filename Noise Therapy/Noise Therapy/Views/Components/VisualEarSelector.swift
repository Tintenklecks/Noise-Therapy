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
