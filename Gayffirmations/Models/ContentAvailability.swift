/// Comment out an entry to make it available. Saved content and selections
/// keep their IDs so they can become available again later.
nonisolated enum ContentAvailability {
    static let disabledThemes: Set<AppTheme> = [
//        .outAndAbout,
//        .together,
        .ages,
//        .steel,
//        .gayWonderland,
//        .shitHappens,
    ]

    static let disabledCategories: Set<AffirmationTag> = [
//        .food,
//        .critic,
//        .gay,
        .human,
//        .roleModel,
    ]

    // Keep one usable theme even if the configuration disables the entire catalogue.
    static let fallbackTheme = AppTheme.allCases.first { !disabledThemes.contains($0) } ?? .outAndAbout

    static func allowsTheme(_ theme: AppTheme) -> Bool {
        theme == fallbackTheme || !disabledThemes.contains(theme)
    }

    static func allowsTag(_ tag: String) -> Bool {
        guard let category = AffirmationTag(rawValue: AffirmationTag.canonicalTag(tag).lowercased()) else {
            return true
        }
        return !disabledCategories.contains(category)
    }

    static func allowsAffirmation(_ affirmation: Affirmation) -> Bool {
        !affirmation.isBundled || affirmation.tags.allSatisfy(allowsTag)
    }
}
