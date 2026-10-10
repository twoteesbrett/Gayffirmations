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

    /// Creates an in-memory library for previews and isolated UI tests.
    init(affirmations: [Affirmation] = []) {
        self.affirmations = affirmations
        self.defaultAffirmations = affirmations
        self.repository = nil
    }

    /// A repository always loads saved content before using first-launch defaults.
    init(
        repository: any AffirmationRepository,
        defaultAffirmations: [Affirmation]
    ) {
        self.repository = repository
        self.defaultAffirmations = defaultAffirmations

        var fallback: [Affirmation] = []
        do {
            try AffirmationValidation.validate(defaultAffirmations)
            fallback = defaultAffirmations
            if let savedAffirmations = try repository.loadAffirmations() {
                try AffirmationValidation.validate(savedAffirmations)
                affirmations = savedAffirmations
            } else {
                affirmations = defaultAffirmations
                try repository.saveAffirmations(defaultAffirmations)
            }
        } catch {
            affirmations = fallback
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
        guard let index = affirmations.firstIndex(where: { $0.id == id }) else {
            return
        }

        let text = try validatedText(text, excluding: id)
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
        let defaultIDs = Set(defaultAffirmations.map(\.id))
        var reservedIDs = Set(affirmations.map(\.id)).union(defaultIDs)
        let personal = affirmations.filter { !$0.isBundled }.map { entry in
            guard defaultIDs.contains(entry.id) else { return entry }
            // Legacy personal rewrites retain bundled IDs. Move the personal copy
            // once, in the same save that restores the catalogue's stable identity.
            var newID = UUID()
            while reservedIDs.contains(newID) { newID = UUID() }
            reservedIDs.insert(newID)
            return Affirmation(
                id: newID, text: entry.text, isFavorite: entry.isFavorite,
                tags: entry.tags, source: .user
            )
        }
        let favourites = Set(affirmations.filter { $0.isBundled && $0.isFavorite }.map(\.id))
        try persist(defaultAffirmations.map {
            var original = $0
            original.isFavorite = favourites.contains($0.id)
            return original
        } + personal)
    }

    func canRestoreOriginal(id: Affirmation.ID) -> Bool {
        affirmations.contains { $0.id == id && $0.isBundled }
            && defaultAffirmations.contains { $0.id == id }
    }

    func restoreOriginal(id: Affirmation.ID) throws {
        // Personal ownership takes precedence over a historical catalogue ID.
        guard !affirmations.contains(where: { $0.id == id && !$0.isBundled }) else { return }
        guard var original = defaultAffirmations.first(where: { $0.id == id }) else { return }
        var updated = affirmations
        if let index = updated.firstIndex(where: { $0.id == id }) {
            original.isFavorite = updated[index].isFavorite
            updated[index] = original
        } else {
            updated.append(original)
        }
        try persist(updated)
    }

    func applyPersistedDefaults() {
        affirmations = defaultAffirmations
        persistenceErrorMessage = nil
    }

    private func persist(_ updatedAffirmations: [Affirmation]) throws {
        if let persistenceErrorMessage {
            throw PersistenceUnavailableError(reason: persistenceErrorMessage)
        }

        try AffirmationValidation.validate(updatedAffirmations)
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
