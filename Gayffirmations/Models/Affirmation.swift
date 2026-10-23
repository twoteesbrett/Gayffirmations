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
        self.tags = AffirmationTag.canonicalTags(tags)
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
        tags = container.contains(.tags) ? try container.decode([String].self, forKey: .tags) : []
        if container.contains(.source) {
            source = try container.decode(Source.self, forKey: .source)
        } else {
            // Preserve previously customised starter messages as editable user content.
            let savedID = id
            let candidates = Self.starterAffirmations
                .filter { $0.id == savedID }
            let savedText = text
            let savedTags = AffirmationTag.canonicalTags(tags)
            let matchesBundle = candidates.contains {
                $0.text == savedText && $0.tags == savedTags
            } || LegacyAffirmationCatalog.contains(id: id, text: text, tags: tags)
            source = matchesBundle ? .bundled : .user
        }
        // Validate the original saved tags before migration can merge categories.
        try AffirmationValidation.validate([self])
        tags = AffirmationTag.canonicalTags(tags)
    }
}

nonisolated extension Affirmation {
    var usesName: Bool { text.contains("{name}") }

    func resolved(name: String) -> Affirmation? {
        var result = self
        if usesName {
            let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            result.text = text.replacingOccurrences(of: "{name}", with: name)
        }
        // Preserve historical source in the library, but only display or deliver
        // entries with meaningful text after personalisation and markup parsing.
        return MessageMarkup(result.text).hasVisibleText ? result : nil
    }
}
