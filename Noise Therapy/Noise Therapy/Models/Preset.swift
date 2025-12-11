import Foundation

struct Preset: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String

    // Global / Default
    var noiseType: NoiseType
    var volume: Float
    var centerFrequency: Float
    var bandwidth: Float

    // Left Overrides
    var noiseTypeLeft: NoiseType?
    var volumeLeft: Float?
    var centerFrequencyLeft: Float?
    var bandwidthLeft: Float?

    // Right Overrides
    var noiseTypeRight: NoiseType?
    var volumeRight: Float?
    var centerFrequencyRight: Float?
    var bandwidthRight: Float?
}
