import Foundation

enum EarSetting: String, CaseIterable, Identifiable {
    case both = "both"
    case left = "left"
    case right = "right"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .both: return NSLocalizedString("BOTH", comment: "Both Ears")
        case .left: return NSLocalizedString("LEFT", comment: "Left Ear")
        case .right: return NSLocalizedString("RIGHT", comment: "Right Ear")
        }
    }
}
