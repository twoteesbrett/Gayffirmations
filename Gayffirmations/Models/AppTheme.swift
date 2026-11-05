import Foundation

nonisolated enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case outAndAbout, together, ages, steel

    var id: Self { self }
    var name: String { self == .outAndAbout ? "Out & About" : rawValue.capitalized }
    var description: String {
        switch self {
        case .ages: "Friendship and love through the years."
        case .together: "Growing, loving and becoming. Through the years."
        case .steel: "Cool gunmetal. Quiet strength."
        case .outAndAbout: "Sunlit adventures. Into the evening."
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let name = try container.decode(String.self)
        if let theme = Self(rawValue: name) {
            self = theme
        } else if Self.retiredThemeNames.contains(name) {
            self = .outAndAbout
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown theme: \(name)")
        }
    }

    // Retired IDs fall back without blocking the rest of the saved library.
    private static let retiredThemeNames: Set<String> = [
        "eden", "disco", "concrete", "nature", "ember", "warm", "midnight", "pop", "playful", "neutral", "paper",
        "slate", "coast", "forest", "goldenHour", "afterHours", "cherry",
        "bubblegum", "daydream", "muscle", "spectrum", "fruity", "refined"
    ]
}
