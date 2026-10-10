import Foundation

nonisolated struct Affirmation: Codable, Identifiable, Equatable {
    nonisolated enum Source: String, Codable {
        case bundled
        case user
    }

    let source: Source
    var isBundled: Bool { source == .bundled }

    let id: UUID
    var text: String
    var isFavorite: Bool
    var tags: [String]

    init(
        id: UUID = UUID(),
        text: String,
        isFavorite: Bool = false,
        tags: [String] = [],
        source: Source = .user
    ) {
        self.source = source
        self.id = id
        self.text = text
        self.isFavorite = isFavorite
        self.tags = tags
    }

    private enum CodingKeys: String, CodingKey {
        case id, text, isFavorite, tags, source
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        // Entries saved before tags were introduced have no tags field.
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        if let savedSource = try container.decodeIfPresent(Source.self, forKey: .source) {
            source = savedSource
        } else {
            // Preserve previously customised starter messages as editable user content.
            let savedID = id
            let candidates = (Self.legacyStarterAffirmations + Self.starterAffirmations)
                .filter { $0.id == savedID }
            let isOriginalNameMessage = id == UUID(uuidString: "B7E77000-0000-4000-8000-000000000015")
                && text == "Stop comparing. You're the only Brett in the room."
            let savedText = text
            let savedTags = tags
            let matchesBundle = candidates.contains {
                ($0.text == savedText || isOriginalNameMessage) && $0.tags == savedTags
            }
            source = matchesBundle ? .bundled : .user
        }
    }
}

nonisolated extension Affirmation {
    var usesName: Bool { text.contains("{name}") }

    func resolved(name: String) -> Affirmation? {
        guard usesName else { return self }
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        var result = self
        result.text = text.replacingOccurrences(of: "{name}", with: name)
        return result
    }
}
