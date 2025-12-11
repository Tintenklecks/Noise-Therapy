import SwiftUI

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
