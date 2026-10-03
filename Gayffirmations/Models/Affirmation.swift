import Foundation

nonisolated struct Affirmation: Codable, Identifiable, Equatable {
    let id: UUID
    var text: String
    var isFavorite: Bool
    var tags: [String]

    init(
        id: UUID = UUID(),
        text: String,
        isFavorite: Bool = false,
        tags: [String] = []
    ) {
        self.id = id
        self.text = text
        self.isFavorite = isFavorite
        self.tags = tags
    }

    private enum CodingKeys: String, CodingKey {
        case id, text, isFavorite, tags
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        // Entries saved before tags were introduced have no tags field.
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}
