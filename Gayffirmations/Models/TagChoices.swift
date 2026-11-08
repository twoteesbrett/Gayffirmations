import Foundation

enum TagChoices {
    static func available(_ tags: [String]) -> [String] {
        // Callers supply tags from visible entries and saved selections. Keep
        // those choices editable even if a bundled category is unavailable.
        sortedUnique(tags)
    }

    /// Preserve the first spelling of each tag while sorting choices for display.
    static func sortedUnique(_ tags: [String]) -> [String] {
        var uniqueTags: [String] = []
        for tag in tags.map(AffirmationTag.canonicalTag) {
            let alreadyIncluded = uniqueTags.contains {
                $0.compare(tag, options: .caseInsensitive) == .orderedSame
            }
            if !alreadyIncluded { uniqueTags.append(tag) }
        }
        return uniqueTags.sorted { first, second in
            let firstName = AffirmationTag(rawValue: first)?.name ?? first
            let secondName = AffirmationTag(rawValue: second)?.name ?? second
            return firstName.localizedStandardCompare(secondName) == .orderedAscending
        }
    }
}
