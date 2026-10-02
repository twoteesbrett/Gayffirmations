import Foundation

enum TagChoices {
    /// Preserve the first spelling of each tag while sorting choices for display.
    static func sortedUnique(_ tags: [String]) -> [String] {
        var uniqueTags: [String] = []
        for tag in tags {
            let alreadyIncluded = uniqueTags.contains {
                $0.compare(tag, options: .caseInsensitive) == .orderedSame
            }
            if !alreadyIncluded { uniqueTags.append(tag) }
        }
        return uniqueTags.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }
}
