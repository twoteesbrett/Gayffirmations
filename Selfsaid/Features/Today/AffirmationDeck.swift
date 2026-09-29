import Foundation

struct AffirmationDeck {
    private(set) var affirmations: [Affirmation]
    private(set) var currentIndex = 0

    var currentAffirmation: Affirmation? {
        guard affirmations.indices.contains(currentIndex) else {
            return nil
        }

        return affirmations[currentIndex]
    }

    var canNavigate: Bool {
        affirmations.count > 1
    }

    mutating func showNext() {
        guard !affirmations.isEmpty else {
            return
        }

        currentIndex = (currentIndex + 1) % affirmations.count
    }

    mutating func showPrevious() {
        guard !affirmations.isEmpty else {
            return
        }

        currentIndex = (currentIndex - 1 + affirmations.count) % affirmations.count
    }

    mutating func replaceAffirmations(with updatedAffirmations: [Affirmation]) {
        let currentID = currentAffirmation?.id
        affirmations = updatedAffirmations

        guard !affirmations.isEmpty else {
            currentIndex = 0
            return
        }

        if let currentID,
           let updatedIndex = affirmations.firstIndex(where: { $0.id == currentID }) {
            currentIndex = updatedIndex
        } else {
            currentIndex = min(currentIndex, affirmations.count - 1)
        }
    }
}
