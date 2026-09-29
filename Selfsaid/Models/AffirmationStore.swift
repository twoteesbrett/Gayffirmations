import Foundation
import Observation

enum AffirmationStoreError: LocalizedError, Equatable {
    case blankText

    var errorDescription: String? {
        switch self {
        case .blankText:
            "An affirmation needs some text."
        }
    }
}

@MainActor
@Observable
final class AffirmationStore {
    private(set) var affirmations: [Affirmation]

    init(affirmations: [Affirmation] = []) {
        self.affirmations = affirmations
    }

    @discardableResult
    func add(text: String) throws -> Affirmation {
        let affirmation = Affirmation(text: try validatedText(text))
        affirmations.append(affirmation)
        return affirmation
    }

    func update(id: Affirmation.ID, text: String) throws {
        let text = try validatedText(text)

        guard let index = affirmations.firstIndex(where: { $0.id == id }) else {
            return
        }

        affirmations[index].text = text
    }

    func delete(id: Affirmation.ID) {
        affirmations.removeAll(where: { $0.id == id })
    }

    func toggleFavorite(id: Affirmation.ID) {
        guard let index = affirmations.firstIndex(where: { $0.id == id }) else {
            return
        }

        affirmations[index].isFavorite.toggle()
    }

    private func validatedText(_ text: String) throws -> String {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            throw AffirmationStoreError.blankText
        }

        return trimmedText
    }
}
