import Foundation

enum AffirmationSelection: Codable, Hashable {
    case all
    case favourites
    case tag(String)
    case sources(favourites: Bool, tags: [String])

    var includesFavourites: Bool {
        switch self {
        case .favourites: true
        case .sources(let favourites, _): favourites
        default: false
        }
    }

    var selectedTags: [String] {
        switch self {
        case .tag(let tag): [tag]
        case .sources(_, let tags): tags
        default: []
        }
    }

    var name: String {
        if self == .all { return "All affirmations" }
        let names = (includesFavourites ? ["Favourites"] : []) + selectedTags.map { $0.lowercased() }
        return names.isEmpty ? "None selected" : names.joined(separator: ", ")
    }

    var emptyMessage: String {
        switch self {
        case .all:
            "Add an affirmation in Library to begin."
        case .favourites:
            "Mark an affirmation as a favourite in Library or change your selection in Settings."
        case .tag(let tag):
            "Add the tag “\(tag.lowercased())” to an affirmation in Library or change your selection in Settings."
        case .sources:
            "Choose favourites or tags in Settings, or add matching entries in Library."
        }
    }

    func containsTag(_ tag: String) -> Bool {
        selectedTags.contains { $0.compare(tag, options: .caseInsensitive) == .orderedSame }
    }

    func selectingFavourites(_ included: Bool) -> AffirmationSelection {
        .sources(favourites: included, tags: selectedTags)
    }

    func selectingTag(_ tag: String, included: Bool) -> AffirmationSelection {
        var tags = selectedTags.filter { $0.compare(tag, options: .caseInsensitive) != .orderedSame }
        if included { tags.append(tag) }
        tags.sort { $0.localizedStandardCompare($1) == .orderedAscending }
        return .sources(favourites: includesFavourites, tags: tags)
    }

    func matchingAffirmations(in affirmations: [Affirmation]) -> [Affirmation] {
        guard self != .all else { return affirmations }
        // Filter once to preserve order and include each entry only once.
        return affirmations.filter { affirmation in
            (includesFavourites && affirmation.isFavorite)
                || affirmation.tags.contains(where: containsTag)
        }
    }
}
