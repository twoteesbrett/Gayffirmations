import Foundation

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case nature, steel, refined, disco

    var id: Self { self }
    var name: String { rawValue.capitalized }
    var description: String {
        switch self {
        case .nature: "Sea-glass tones. Room to breathe."
        case .steel: "Cool gunmetal. Quiet strength."
        case .refined: "Warm cream. A little sophistication."
        case .disco: "Electric colour. Permission to play."
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let name = try container.decode(String.self)
        if let theme = Self(rawValue: name) {
            self = theme
        } else if Self.retiredThemeNames.contains(name) {
            self = .nature
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown theme: \(name)")
        }
    }

    // Retired IDs fall back without blocking the rest of the saved library.
    private static let retiredThemeNames: Set<String> = [
        "ember", "warm", "midnight", "pop", "playful", "neutral", "paper",
        "slate", "coast", "forest", "goldenHour", "afterHours", "cherry",
        "bubblegum", "daydream", "muscle", "spectrum"
    ]
}
