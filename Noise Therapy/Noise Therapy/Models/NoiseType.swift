import Foundation

enum NoiseType: String, CaseIterable, Identifiable, Codable {
    case white = "white"
    case pink = "pink"
    case brown = "brown"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .white: return NSLocalizedString("WHITE", comment: "White Noise")
        case .pink: return NSLocalizedString("PINK", comment: "Pink Noise")
        case .brown: return NSLocalizedString("BROWN", comment: "Brown Noise")
        }
    }
}
