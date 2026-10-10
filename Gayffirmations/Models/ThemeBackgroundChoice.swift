import Foundation

struct ThemeBackgroundChoice: Codable, Equatable {
    var usesImage = false

    // Preserve the stored preference key for existing installations.
    private enum CodingKeys: String, CodingKey {
        case usesImage = "usesPhoto"
    }
}
