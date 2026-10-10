import Foundation
import Testing
@testable import Gayffirmations

@MainActor
struct AffirmationStoreTests {
    @Test("Tags share spelling across entries and filtering ignores case")
    func sharedTagsAndFiltering() throws {
        let store = AffirmationStore()
        let first = try store.add(text: "First", tags: ["Work", "Calm"])
        let second = try store.add(text: "Second", tags: ["work"])
        let untagged = try store.add(text: "Third")

        #expect(second.tags == ["Work"])
        #expect(store.availableTags == ["Calm", "Work"])
        #expect(store.affirmations(tagged: "WORK") == [first, second])
        #expect(store.affirmations(tagged: "Missing").isEmpty)
        #expect(store.affirmations == [first, second, untagged])

        try store.update(id: first.id, text: first.text, tags: [])
        try store.delete(id: second.id)
        #expect(store.availableTags.isEmpty)
        #expect(store.affirmations(tagged: "Work").isEmpty)
    }

    @Test("Tags are trimmed and blanks and case-insensitive duplicates are removed")
    func normalizesTags() throws {
        let store = AffirmationStore()
        let affirmation = try store.add(
            text: "Tagged", tags: [" Work ", "", "work", "\nConfidence\n"]
        )
        #expect(affirmation.tags == ["Work", "Confidence"])
    }

    @Test("Tag edits persist without changing favourites and notify change observers")
    func editsTags() throws {
        let original = Affirmation(text: "Keep me", isFavorite: true, tags: ["Work"])
        let repository = InMemoryAffirmationRepository(affirmations: [original])
        let store = AffirmationStore(repository: repository, defaultAffirmations: [])
        var reminderChanges = 0
        store.willChangeAffirmations = { _ in reminderChanges += 1 }
        store.didChangeAffirmations = { _ in reminderChanges += 1 }

        try store.update(id: original.id, text: original.text, tags: [" Calm ", "calm"])
        let restarted = AffirmationStore(repository: repository, defaultAffirmations: [])
        #expect(restarted.affirmations.first?.tags == ["Calm"])
        #expect(restarted.affirmations.first?.isFavorite == true)
        #expect(reminderChanges == 2)

        try store.update(id: original.id, text: "New text")
        #expect(store.affirmations.first?.tags == ["Calm"])
        try store.update(id: original.id, text: "New text", tags: [])
        #expect(store.affirmations.first?.tags == [])
    }

    @Test("An affirmation can be added")
    func add() throws {
        let store = AffirmationStore()

        let affirmation = try store.add(text: "  I can do this.  ")

        #expect(store.affirmations == [affirmation])
        #expect(affirmation.text == "I can do this.")
    }

    @Test("An affirmation can be edited")
    func edit() throws {
        let affirmation = Affirmation(text: "Before")
        let store = AffirmationStore(affirmations: [affirmation])

        try store.update(id: affirmation.id, text: "After")

        #expect(store.affirmations.first?.text == "After")
    }

    @Test("An affirmation can be deleted")
    func delete() throws {
        let affirmation = Affirmation(text: "Temporary")
        let store = AffirmationStore(affirmations: [affirmation])

        try store.delete(id: affirmation.id)

        #expect(store.affirmations.isEmpty)
    }

    @Test("Bundled affirmations can be deleted and notify observers")
    func bundledDeletion() throws {
        let bundled = Affirmation(text: "System", source: .bundled)
        let custom = Affirmation(text: "Custom")
        let original = [bundled, custom]
        let repository = InMemoryAffirmationRepository(affirmations: original)
        let store = AffirmationStore(repository: repository, defaultAffirmations: [])
        var notified = false
        store.willChangeAffirmations = { _ in notified = true }
        store.didChangeAffirmations = { _ in notified = true }

        try store.delete(id: bundled.id)
        #expect(store.affirmations == [custom])
        #expect(repository.affirmations == [custom])
        #expect(notified)
    }

    @Test("An affirmation can be favorited and unfavorited")
    func toggleFavorite() throws {
        let affirmation = Affirmation(text: "Favorite")
        let store = AffirmationStore(affirmations: [affirmation])

        try store.toggleFavorite(id: affirmation.id)
        #expect(store.affirmations.first?.isFavorite == true)

        try store.toggleFavorite(id: affirmation.id)
        #expect(store.affirmations.first?.isFavorite == false)
    }

    @Test("Blank affirmation text is rejected")
    func rejectBlankText() {
        let store = AffirmationStore()

        #expect(throws: AffirmationStoreError.blankText) {
            try store.add(text: "  \n  ")
        }
        #expect(store.affirmations.isEmpty)
    }

    @Test("Duplicate affirmation text is rejected regardless of case or whitespace")
    func rejectDuplicateText() {
        let existingAffirmation = Affirmation(text: "I am capable.")
        let store = AffirmationStore(affirmations: [existingAffirmation])

        #expect(throws: AffirmationStoreError.duplicateText) {
            try store.add(text: "  i AM capable.  ")
        }

        #expect(store.affirmations == [existingAffirmation])
    }

    @Test("A blank edit leaves the original affirmation unchanged")
    func rejectBlankEdit() {
        let affirmation = Affirmation(text: "Keep me")
        let store = AffirmationStore(affirmations: [affirmation])

        #expect(throws: AffirmationStoreError.blankText) {
            try store.update(id: affirmation.id, text: "   ")
        }
        #expect(store.affirmations.first?.text == "Keep me")
    }

    @Test("An affirmation cannot be edited to duplicate another affirmation")
    func rejectDuplicateEdit() throws {
        let firstAffirmation = Affirmation(text: "First")
        let secondAffirmation = Affirmation(text: "Second")
        let store = AffirmationStore(
            affirmations: [firstAffirmation, secondAffirmation]
        )

        #expect(throws: AffirmationStoreError.duplicateText) {
            try store.update(id: secondAffirmation.id, text: " first ")
        }

        #expect(store.affirmations == [firstAffirmation, secondAffirmation])
    }

    @Test("An unchanged affirmation is valid when editing")
    func unchangedEditIsValid() throws {
        let affirmation = Affirmation(text: "I am capable.")
        let store = AffirmationStore(affirmations: [affirmation])

        try store.update(id: affirmation.id, text: affirmation.text)

        #expect(store.affirmations == [affirmation])
    }

    @Test("Saved affirmations are loaded when a store is created")
    func loadsSavedAffirmations() {
        let savedAffirmations = [Affirmation(text: "Saved", isFavorite: true)]
        let repository = InMemoryAffirmationRepository(
            affirmations: savedAffirmations
        )

        let store = AffirmationStore(
            repository: repository,
            defaultAffirmations: Affirmation.starterAffirmations
        )

        #expect(store.affirmations == savedAffirmations)
    }

    @Test("Loading preserves saved bundled content and custom messages")
    func refreshesBundledContent() throws {
        var old = Affirmation.legacyStarterAffirmations
        old[0].isFavorite = true
        var custom = old.removeLast()
        custom = Affirmation(id: custom.id, text: "My rewrite", isFavorite: true, tags: ["Mine"])
        let repository = InMemoryAffirmationRepository(affirmations: old + [custom])
        let store = AffirmationStore(repository: repository, defaultAffirmations: Affirmation.starterAffirmations)
        let updated = try #require(store.affirmations.first { $0.id == old[0].id })
        #expect(updated.tags == old[0].tags)
        #expect(updated.isFavorite)
        #expect(store.affirmations.last == custom)
        #expect(store.affirmations == old + [custom])
        #expect(repository.affirmations == store.affirmations)
        let restarted = AffirmationStore(repository: repository, defaultAffirmations: Affirmation.starterAffirmations)
        #expect(restarted.affirmations == store.affirmations)
    }

    @Test("Default affirmations are saved on first launch")
    func savesDefaultAffirmations() {
        let repository = InMemoryAffirmationRepository()

        let store = AffirmationStore(
            repository: repository,
            defaultAffirmations: Affirmation.starterAffirmations
        )

        #expect(store.affirmations == Affirmation.starterAffirmations)
        #expect(repository.affirmations == Affirmation.starterAffirmations)
    }

    @Test("A favorite survives recreating the store")
    func favoriteSurvivesRestart() throws {
        let affirmation = Affirmation(text: "Remember me")
        let repository = InMemoryAffirmationRepository(
            affirmations: [affirmation]
        )
        let firstStore = AffirmationStore(
            repository: repository,
            defaultAffirmations: []
        )

        try firstStore.toggleFavorite(id: affirmation.id)
        let restartedStore = AffirmationStore(
            repository: repository,
            defaultAffirmations: []
        )

        #expect(restartedStore.affirmations.first?.isFavorite == true)
    }

    @Test("Restoring defaults preserves personal additions and favorites")
    func restoreDefaults() throws {
        let defaults = [Affirmation(text: "Default", source: .bundled)]
        let repository = InMemoryAffirmationRepository()
        let store = AffirmationStore(
            repository: repository,
            defaultAffirmations: defaults
        )

        let custom = try store.add(text: "Custom")
        try store.toggleFavorite(id: defaults[0].id)
        try store.restoreDefaults()

        var restored = defaults[0]
        restored.isFavorite = true
        #expect(store.affirmations == [restored, custom])
        #expect(repository.affirmations == [restored, custom])
    }

    @Test("An edited affirmation survives recreating the store")
    func editSurvivesRestart() throws {
        let affirmation = Affirmation(text: "Before")
        let repository = InMemoryAffirmationRepository(
            affirmations: [affirmation]
        )
        let firstStore = AffirmationStore(
            repository: repository,
            defaultAffirmations: []
        )

        try firstStore.update(id: affirmation.id, text: "After")
        let restartedStore = AffirmationStore(
            repository: repository,
            defaultAffirmations: []
        )

        #expect(restartedStore.affirmations.first?.text == "After")
    }

    @Test("A load failure prevents saved data from being overwritten")
    func loadFailurePreventsOverwrite() {
        let repository = FailingAffirmationRepository()
        let store = AffirmationStore(
            repository: repository,
            defaultAffirmations: [Affirmation(text: "Fallback")]
        )
        let affirmation = store.affirmations[0]

        #expect(store.persistenceErrorMessage != nil)
        #expect(throws: PersistenceUnavailableError.self) {
            try store.toggleFavorite(id: affirmation.id)
        }
        #expect(store.affirmations[0].isFavorite == false)
        #expect(repository.saveCallCount == 0)
    }
}

private enum RepositoryTestError: Error {
    case loadFailed
}

private final class FailingAffirmationRepository: AffirmationRepository {
    private(set) var saveCallCount = 0

    func loadAffirmations() throws -> [Affirmation]? {
        throw RepositoryTestError.loadFailed
    }

    func saveAffirmations(_ affirmations: [Affirmation]) throws {
        saveCallCount += 1
    }
}

private final class InMemoryAffirmationRepository: AffirmationRepository {
    var affirmations: [Affirmation]?

    init(affirmations: [Affirmation]? = nil) {
        self.affirmations = affirmations
    }

    func loadAffirmations() throws -> [Affirmation]? {
        affirmations
    }

    func saveAffirmations(_ affirmations: [Affirmation]) throws {
        self.affirmations = affirmations
    }
}
