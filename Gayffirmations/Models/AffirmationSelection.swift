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
        case .tag(let tag): [AffirmationTag.canonicalTag(tag)]
        case .sources(_, let tags): AffirmationTag.canonicalTags(tags)
        default: []
        }
    }

    /// Library returns to all affirmations when the final filter is cleared.
    var usingAllWhenEmpty: AffirmationSelection {
        includesFavourites || !selectedTags.isEmpty ? self : .all
    }

    var name: String {
        if self == .all { return "All affirmations" }
        let names = (includesFavourites ? ["Favourites"] : []) + selectedTags.map { AffirmationTag(rawValue: $0)?.name ?? $0.lowercased() }
        return names.isEmpty ? "None selected" : names.joined(separator: ", ")
    }

    var emptyMessage: String {
        switch self {
        case .all:
            "Add an affirmation in Library to begin."
        case .favourites:
            "Mark an affirmation as a favourite in Library or choose All in Library."
        case .tag(let tag):
            "Add the tag “\(tag.lowercased())” to an affirmation in Library or choose All in Library."
        case .sources:
            "Choose All, favourites, or tags in Library, or add matching entries in Library."
        }
    }

    func containsTag(_ tag: String) -> Bool {
        selectedTags.contains { $0.compare(AffirmationTag.canonicalTag(tag), options: .caseInsensitive) == .orderedSame }
    }

    func selectingFavourites(_ included: Bool) -> AffirmationSelection {
        .sources(favourites: included, tags: selectedTags)
    }

    func selectingTag(_ tag: String, included: Bool) -> AffirmationSelection {
        var tags = selectedTags.filter { $0.compare(AffirmationTag.canonicalTag(tag), options: .caseInsensitive) != .orderedSame }
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

/// Library source choices are independent of favourites and tags.
struct LibrarySourceFilter {
    private(set) var includesBundled = false
    private(set) var includesMine = false

    var isEmpty: Bool { !includesBundled && !includesMine }

    var name: String {
        [includesBundled ? "Bundled" : nil, includesMine ? "Mine" : nil]
            .compactMap { $0 }.joined(separator: ", ")
    }

    mutating func toggle(_ source: Affirmation.Source) {
        switch source {
        case .bundled: includesBundled.toggle()
        case .user: includesMine.toggle()
        }
    }

    func matchingAffirmations(in affirmations: [Affirmation]) -> [Affirmation] {
        guard !isEmpty else { return affirmations }
        return affirmations.filter {
            ($0.isBundled && includesBundled) || (!$0.isBundled && includesMine)
        }
    }
}
