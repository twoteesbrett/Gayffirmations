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

    // Hooks allow the coordinator to block overlapping updates and refresh delivery after saving.
    var willChangeAffirmations: (([Affirmation]) throws -> Void)?
    var didChangeAffirmations: (([Affirmation]) -> Void)?

    private let repository: (any AffirmationRepository)?
    let defaultAffirmations: [Affirmation]

    var availableTags: [String] {
        TagChoices.sortedUnique(affirmations.flatMap(\.tags))
    }

    func affirmations(tagged tag: String) -> [Affirmation] {
        AffirmationSelection.tag(tag).matchingAffirmations(in: affirmations)
    }

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
    func add(text: String, tags: [String] = []) throws -> Affirmation {
        let affirmation = Affirmation(
            text: try validatedText(text),
            tags: normalizedTags(tags)
        )
        try persist(affirmations + [affirmation])
        return affirmation
    }

    // Omitting tags preserves them for callers that only edit text.
    func update(id: Affirmation.ID, text: String, tags: [String]? = nil) throws {
        let text = try validatedText(text, excluding: id)

        guard let index = affirmations.firstIndex(where: { $0.id == id }) else {
            return
        }

        var updatedAffirmations = affirmations
        updatedAffirmations[index].text = text
        if let tags {
            updatedAffirmations[index].tags = normalizedTags(tags)
        }
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

    func applyPersistedDefaults() {
        affirmations = defaultAffirmations
    }

    private func persist(_ updatedAffirmations: [Affirmation]) throws {
        if let persistenceErrorMessage {
            throw PersistenceUnavailableError(reason: persistenceErrorMessage)
        }

        guard updatedAffirmations != affirmations else { return }
        try willChangeAffirmations?(updatedAffirmations)
        try repository?.saveAffirmations(updatedAffirmations)
        let previousAffirmations = affirmations
        affirmations = updatedAffirmations
        didChangeAffirmations?(previousAffirmations)
    }

    private func normalizedTags(_ tags: [String]) -> [String] {
        let existingTags = availableTags
        var result: [String] = []
        for tag in tags {
            let name = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }
            let isDuplicate = result.contains { tagsMatch($0, name) }
            if !isDuplicate {
                // Reuse the spelling already used elsewhere in the library.
                result.append(existingTags.first { tagsMatch($0, name) } ?? name)
            }
        }
        return result
    }

    private func tagsMatch(_ first: String, _ second: String) -> Bool {
        first.compare(second, options: .caseInsensitive) == .orderedSame
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
