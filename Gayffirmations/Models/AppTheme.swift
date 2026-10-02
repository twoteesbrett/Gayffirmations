import Foundation

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case neutral

    var id: Self { self }
    var name: String { "Neutral" }
    var description: String { "A simple, neutral starting point." }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let name = try container.decode(String.self)
        if let theme = Self(rawValue: name) {
            self = theme
        } else if Self.retiredThemeNames.contains(name) {
            self = .neutral
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown theme: \(name)")
        }
    }

    // Retired IDs fall back without blocking the rest of the saved library.
    private static let retiredThemeNames: Set<String> = [
        "ember", "warm", "midnight", "pop", "playful", "refined", "paper",
        "slate", "coast", "forest", "goldenHour", "afterHours", "cherry",
        "bubblegum", "daydream", "steel", "muscle", "disco", "spectrum"
    ]
}
