import Foundation

enum AffirmationSelection: Codable, Hashable {
    case all
    case favourites
    case tag(String)

    func matchingAffirmations(in affirmations: [Affirmation]) -> [Affirmation] {
        switch self {
        case .all:
            affirmations
        case .favourites:
            affirmations.filter(\.isFavorite)
        case .tag(let name):
            affirmations.filter { affirmation in
                affirmation.tags.contains {
                    $0.compare(name, options: .caseInsensitive) == .orderedSame
                }
            }
        }
    }
}
