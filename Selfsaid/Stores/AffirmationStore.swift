import Foundation
import Observation

enum AffirmationStoreError: LocalizedError, Equatable {
    case blankText
    case duplicateText

    var errorDescription: String? {
        switch self {
        case .blankText:
            "An affirmation needs some text."
        case .duplicateText:
            "This affirmation is already in your library."
        }
    }
}

@MainActor
@Observable
final class AffirmationStore {
    private(set) var affirmations: [Affirmation]
    private(set) var persistenceErrorMessage: String?

    private let repository: (any AffirmationRepository)?
    private let defaultAffirmations: [Affirmation]

    init(
        affirmations: [Affirmation] = [],
        repository: (any AffirmationRepository)? = nil
    ) {
        self.affirmations = affirmations
        self.defaultAffirmations = affirmations
        self.repository = repository
    }

    init(
        repository: any AffirmationRepository,
        defaultAffirmations: [Affirmation]
    ) {
        self.repository = repository
        self.defaultAffirmations = defaultAffirmations

        do {
            if let savedAffirmations = try repository.loadAffirmations() {
                affirmations = savedAffirmations
            } else {
                affirmations = defaultAffirmations
                try repository.saveAffirmations(defaultAffirmations)
            }
        } catch {
            affirmations = defaultAffirmations
            persistenceErrorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func add(text: String) throws -> Affirmation {
        let affirmation = Affirmation(text: try validatedText(text))
        try persist(affirmations + [affirmation])
        return affirmation
    }

    func update(id: Affirmation.ID, text: String) throws {
        let text = try validatedText(text, excluding: id)

        guard let index = affirmations.firstIndex(where: { $0.id == id }) else {
            return
        }

        var updatedAffirmations = affirmations
        updatedAffirmations[index].text = text
        try persist(updatedAffirmations)
    }

    func delete(id: Affirmation.ID) throws {
        try persist(affirmations.filter { $0.id != id })
    }

    func toggleFavorite(id: Affirmation.ID) throws {
        guard let index = affirmations.firstIndex(where: { $0.id == id }) else {
            return
        }

        var updatedAffirmations = affirmations
        updatedAffirmations[index].isFavorite.toggle()
        try persist(updatedAffirmations)
    }

    func restoreDefaults() throws {
        try persist(defaultAffirmations)
    }

    private func persist(_ updatedAffirmations: [Affirmation]) throws {
        if let persistenceErrorMessage {
            throw PersistenceUnavailableError(reason: persistenceErrorMessage)
        }

        try repository?.saveAffirmations(updatedAffirmations)
        affirmations = updatedAffirmations
    }

    private func validatedText(
        _ text: String,
        excluding excludedID: Affirmation.ID? = nil
    ) throws -> String {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            throw AffirmationStoreError.blankText
        }

        let isDuplicate = affirmations.contains { affirmation in
            affirmation.id != excludedID
                && affirmation.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    .compare(trimmedText, options: .caseInsensitive) == .orderedSame
        }

        guard !isDuplicate else {
            throw AffirmationStoreError.duplicateText
        }

        return trimmedText
    }
}
