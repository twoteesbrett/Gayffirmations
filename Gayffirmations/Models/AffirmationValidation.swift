import Foundation

nonisolated enum AffirmationValidationError: LocalizedError, Equatable {
    case duplicateIdentity
    case blankText
    case invalidTags

    var errorDescription: String? {
        switch self {
        case .duplicateIdentity:
            "Saved affirmations contain repeated identities. The original data has been preserved."
        case .blankText:
            "A saved affirmation has no text. The original data has been preserved."
        case .invalidTags:
            "A saved affirmation has blank, padded, or repeated tags. The original data has been preserved."
        }
    }
}

nonisolated enum AffirmationValidation {
    /// Validate without rewriting or discarding historical messages. Distinct IDs
    /// may legitimately have the same text, particularly after bundled restoration.
    static func validate(_ affirmations: [Affirmation]) throws {
        var identities = Set<UUID>()
        for affirmation in affirmations {
            guard identities.insert(affirmation.id).inserted else {
                throw AffirmationValidationError.duplicateIdentity
            }
            guard !affirmation.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw AffirmationValidationError.blankText
            }
            var seenTags: [String] = []
            for tag in affirmation.tags {
                let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty, trimmed == tag,
                      !seenTags.contains(where: {
                          $0.compare(tag, options: .caseInsensitive) == .orderedSame
                      }) else {
                    throw AffirmationValidationError.invalidTags
                }
                seenTags.append(tag)
            }
        }
    }
}
