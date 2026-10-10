import Foundation

nonisolated enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case nature, disco, steel, concrete, outAndAbout

    var id: Self { self }
    var name: String { self == .outAndAbout ? "Out & About" : rawValue.capitalized }
    var description: String {
        switch self {
        case .nature: "Sea-glass tones. Room to breathe."
        case .steel: "Cool gunmetal. Quiet strength."
        case .disco: "Electric colour. Permission to play."
        case .concrete: "Sculpted space. Stillness in structure."
        case .outAndAbout: "Sunlit adventures. Into the evening."
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
        "bubblegum", "daydream", "muscle", "spectrum", "together", "fruity", "refined"
    ]
}
