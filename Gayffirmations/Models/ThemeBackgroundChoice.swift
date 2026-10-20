import Foundation

struct ThemeBackgroundChoice: Codable, Equatable {
    var usesImage = false
    var imageDimming: Double? = nil
    var outlinesText: Bool? = nil

    static func snappedDimming(_ value: Double) -> Double {
        let clamped = min(1, max(-1, value))
        return abs(clamped) < 0.06 ? 0 : clamped
    }

    static func overlayOpacity(default opacity: Double, adjustment: Double) -> Double {
        let adjustment = min(1, max(-1, adjustment))
        return adjustment < 0 ? opacity * (1 + adjustment) : opacity + (0.85 - opacity) * adjustment
    }

    // Preserve the stored preference key for existing installations.
    private enum CodingKeys: String, CodingKey {
        case usesImage = "usesPhoto"
        case imageDimming
        case outlinesText
    }
}
