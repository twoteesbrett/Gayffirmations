import Foundation

struct TagPreset: Identifiable {
    let name: String
    let tags: [String]

    var id: String { name }

    static let predefined: [TagPreset] = [
        TagPreset(name: "Feel Good", tags: ["self-worth", "confidence", "joy"]),
        TagPreset(name: "Playful", tags: ["playful"]),
        TagPreset(name: "Being Me", tags: ["gay identity", "pride", "authenticity", "shame"]),
        TagPreset(name: "My Body", tags: ["body image", "appearance", "masculinity", "ageing"]),
        TagPreset(name: "Love & Dating", tags: ["dating", "relationships", "rejection", "intimacy"]),
        TagPreset(name: "Connection", tags: ["friends", "chosen family", "belonging", "loneliness"]),
        TagPreset(name: "Tough Days", tags: ["anxiety", "setbacks", "uncertainty", "starting again"])
    ]

    /// Keeps existing spelling and adds built-in choices only in the editor.
    static func tagChoices(from tags: [String], includePredefined: Bool = false) -> [String] {
        var uniqueTags: [String] = []
        let choices = tags + (includePredefined ? predefined.flatMap(\.tags) : [])
        for tag in choices where !uniqueTags.contains(where: { matches($0, tag) }) {
            uniqueTags.append(tag)
        }
        return uniqueTags.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    static func presets(for availableTags: [String]) -> [TagPreset] {
        predefined.compactMap { preset in
            let tags = preset.tags.compactMap { name in
                availableTags.first { matches($0, name) }
            }
            return tags.isEmpty ? nil : TagPreset(name: preset.name, tags: tags)
        }
    }

    func applying(to selection: AffirmationSelection) -> AffirmationSelection {
        .sources(favourites: selection.includesFavourites, tags: tags)
    }

    func matchesSelection(_ selection: AffirmationSelection) -> Bool {
        selection.selectedTags.count == tags.count && tags.allSatisfy(selection.containsTag)
    }

    private static func matches(_ lhs: String, _ rhs: String) -> Bool {
        lhs.compare(rhs, options: .caseInsensitive) == .orderedSame
    }
}
