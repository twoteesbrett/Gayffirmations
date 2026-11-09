import Foundation
import Testing
@testable import Gayffirmations

@MainActor
struct AffirmationStoreTests {
    @Test("A delivery observer can veto an edit before persistence")
    func observerVetoPreservesData() throws {
        let original = Affirmation(text: "Original")
        let repository = InMemoryAffirmationRepository(affirmations: [original])
        let store = AffirmationStore(repository: repository, defaultAffirmations: [])
        let observer = AffirmationChangeObserverSpy()
        observer.blocksChanges = true
        store.attachChangeObserver(observer)
        #expect(throws: NotificationCoordinatorError.updateInProgress) {
            try store.update(id: original.id, text: "Changed")
        }
        #expect(store.visibleAffirmations == [original])
        #expect(repository.saveCallCount == 0)
        #expect(observer.changeCount == 1)
    }

    @Test("The store does not retain its delivery observer")
    func observerLifetime() throws {
        let store = AffirmationStore()
        var observer: AffirmationChangeObserverSpy? = AffirmationChangeObserverSpy()
        weak let releasedObserver = observer
        store.attachChangeObserver(observer!)
        observer = nil
        #expect(releasedObserver == nil)
        let replacement = AffirmationChangeObserverSpy()
        store.attachChangeObserver(replacement)
        store.attachChangeObserver(replacement)
        try store.add(text: "Still editable")
        #expect(replacement.changeCount == 2)
    }

    @Test("Restored duplicate text remains editable after reloading")
    func editsRestoredDuplicates() throws {
        let original = Affirmation(text: "Keep this message", tags: ["Work"], source: .bundled)
        let personal = Affirmation(id: original.id, text: original.text, isFavorite: true, tags: ["Mine"])
        let repository = InMemoryAffirmationRepository(affirmations: [personal])
        let store = AffirmationStore(repository: repository, defaultAffirmations: [original])
        try store.restoreDefaults()
        let reloaded = AffirmationStore(repository: repository, defaultAffirmations: [original])
        #expect(reloaded.visibleAffirmations.count == 2)
        for entry in reloaded.visibleAffirmations {
            try reloaded.update(id: entry.id, text: entry.text)
            try reloaded.update(id: entry.id, text: entry.text, tags: ["Calm"])
        }
        let saved = AffirmationStore(repository: repository, defaultAffirmations: [original])
        #expect(saved.visibleAffirmations.allSatisfy { $0.tags == ["Calm"] && $0.text == original.text })
        #expect(saved.visibleAffirmations.first { !$0.isBundled }?.isFavorite == true)
        #expect(throws: AffirmationStoreError.duplicateText) {
            try reloaded.add(text: original.text)
        }
        let other = try reloaded.add(text: "Different text")
        #expect(throws: AffirmationStoreError.duplicateText) {
            try reloaded.update(id: other.id, text: original.text)
        }
    }

    @Test("Markup-only additions and edits are rejected without changing saved content",
          arguments: ["<small></small>", "<br>", "<small>  </small>", " <br />\n<br/> "])
    func rejectsInvisibleText(text: String) throws {
        let entry = Affirmation(text: "Keep me")
        let repository = InMemoryAffirmationRepository(affirmations: [entry])
        let store = AffirmationStore(repository: repository, defaultAffirmations: [])
        #expect(throws: AffirmationStoreError.blankText) { try store.add(text: text) }
        #expect(throws: AffirmationStoreError.blankText) { try store.update(id: entry.id, text: text) }
        #expect(store.visibleAffirmations == [entry])
        #expect(repository.affirmations == [entry])
        let literal = try store.add(text: "<small>unfinished")
        #expect(literal.text == "<small>unfinished")
    }

    @Test("Tags share spelling across entries and filtering ignores case")
    func sharedTagsAndFiltering() throws {
        let store = AffirmationStore()
        let first = try store.add(text: "First", tags: ["Work", "Calm"])
        let second = try store.add(text: "Second", tags: ["work"])
        let untagged = try store.add(text: "Third")

        #expect(second.tags == ["Work"])
        #expect(store.availableTags == ["Calm", "Work"])
        #expect(store.visibleAffirmations(tagged: "WORK") == [first, second])
        #expect(store.visibleAffirmations(tagged: "Missing").isEmpty)
        #expect(store.visibleAffirmations == [first, second, untagged])

        try store.update(id: first.id, text: first.text, tags: [])
        try store.delete(id: second.id)
        #expect(store.availableTags.isEmpty)
        #expect(store.visibleAffirmations(tagged: "Work").isEmpty)
    }

    @Test("Tags are trimmed and blanks and case-insensitive duplicates are removed")
    func normalizesTags() throws {
        let store = AffirmationStore()
        let affirmation = try store.add(
            text: "Tagged", tags: [" Work ", "", "work", "\nCalm\n"]
        )
        #expect(affirmation.tags == ["Work", "Calm"])
    }

    @Test("Tag edits persist without changing favourites and notify change observers")
    func editsTags() throws {
        let original = Affirmation(text: "Keep me", isFavorite: true, tags: ["Work"])
        let repository = InMemoryAffirmationRepository(affirmations: [original])
        let store = AffirmationStore(repository: repository, defaultAffirmations: [])
        let observer = AffirmationChangeObserverSpy()
        store.attachChangeObserver(observer)

        try store.update(id: original.id, text: original.text, tags: [" Calm ", "calm"])
        let restarted = AffirmationStore(repository: repository, defaultAffirmations: [])
        #expect(restarted.visibleAffirmations.first?.tags == ["Calm"])
        #expect(restarted.visibleAffirmations.first?.isFavorite == true)
        #expect(observer.changeCount == 2)

        try store.update(id: original.id, text: "New text")
        #expect(store.visibleAffirmations.first?.tags == ["Calm"])
        try store.update(id: original.id, text: "New text", tags: [])
        #expect(store.visibleAffirmations.first?.tags == [])
    }

    @Test("An affirmation can be added")
    func add() throws {
        let store = AffirmationStore()

        let affirmation = try store.add(text: "  I can do this.  ")

        #expect(store.visibleAffirmations == [affirmation])
        #expect(affirmation.text == "I can do this.")
    }

    @Test("An affirmation can be edited")
    func edit() throws {
        let affirmation = Affirmation(text: "Before")
        let store = AffirmationStore(affirmations: [affirmation])

        try store.update(id: affirmation.id, text: "After")

        #expect(store.visibleAffirmations.first?.text == "After")
    }

    @Test("An affirmation can be deleted")
    func delete() throws {
        let affirmation = Affirmation(text: "Temporary")
        let store = AffirmationStore(affirmations: [affirmation])

        try store.delete(id: affirmation.id)

        #expect(store.visibleAffirmations.isEmpty)
    }

    @Test("Bundled affirmations can be deleted and notify observers")
    func bundledDeletion() throws {
        let bundled = Affirmation(text: "System", source: .bundled)
        let custom = Affirmation(text: "Custom")
        let original = [bundled, custom]
        let repository = InMemoryAffirmationRepository(affirmations: original)
        let store = AffirmationStore(repository: repository, defaultAffirmations: [])
        let observer = AffirmationChangeObserverSpy()
        store.attachChangeObserver(observer)

        try store.delete(id: bundled.id)
        #expect(store.visibleAffirmations == [custom])
        #expect(repository.affirmations == [custom])
        #expect(observer.changeCount == 2)
    }

    @Test("An affirmation can be favorited and unfavorited")
    func toggleFavorite() throws {
        let affirmation = Affirmation(text: "Favorite")
        let store = AffirmationStore(affirmations: [affirmation])

        try store.toggleFavorite(id: affirmation.id)
        #expect(store.visibleAffirmations.first?.isFavorite == true)

        try store.toggleFavorite(id: affirmation.id)
        #expect(store.visibleAffirmations.first?.isFavorite == false)
    }

    @Test("Blank affirmation text is rejected")
    func rejectBlankText() {
        let store = AffirmationStore()

        #expect(throws: AffirmationStoreError.blankText) {
            try store.add(text: "  \n  ")
        }
        #expect(store.visibleAffirmations.isEmpty)
    }

    @Test("Duplicate affirmation text is rejected regardless of case or whitespace")
    func rejectDuplicateText() {
        let existingAffirmation = Affirmation(text: "I am capable.")
        let store = AffirmationStore(affirmations: [existingAffirmation])

        #expect(throws: AffirmationStoreError.duplicateText) {
            try store.add(text: "  i AM capable.  ")
        }

        #expect(store.visibleAffirmations == [existingAffirmation])
    }

    @Test("A blank edit leaves the original affirmation unchanged")
    func rejectBlankEdit() {
        let affirmation = Affirmation(text: "Keep me")
        let store = AffirmationStore(affirmations: [affirmation])

        #expect(throws: AffirmationStoreError.blankText) {
            try store.update(id: affirmation.id, text: "   ")
        }
        #expect(store.visibleAffirmations.first?.text == "Keep me")
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

        #expect(store.visibleAffirmations == [firstAffirmation, secondAffirmation])
    }

    @Test("An unchanged affirmation is valid when editing")
    func unchangedEditIsValid() throws {
        let affirmation = Affirmation(text: "I am capable.")
        let store = AffirmationStore(affirmations: [affirmation])

        try store.update(id: affirmation.id, text: affirmation.text)

        #expect(store.visibleAffirmations == [affirmation])
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

        #expect(store.visibleAffirmations == savedAffirmations)
        #expect(repository.loadCallCount == 1)
        #expect(repository.saveCallCount == 0)
    }

    @Test("Loading preserves saved bundled content and custom messages")
    func refreshesBundledContent() throws {
        var old = [
            Affirmation(text: "Bundled original", tags: ["Original"], source: .bundled),
            Affirmation(text: "Another original", tags: ["Original"], source: .bundled)
        ]
        old[0].isFavorite = true
        var custom = old.removeLast()
        custom = Affirmation(id: custom.id, text: "My rewrite", isFavorite: true, tags: ["Mine"])
        let repository = InMemoryAffirmationRepository(affirmations: old + [custom])
        let store = AffirmationStore(repository: repository, defaultAffirmations: Affirmation.starterAffirmations)
        let updated = try #require(store.visibleAffirmations.first { $0.id == old[0].id })
        #expect(updated.tags == old[0].tags)
        #expect(updated.isFavorite)
        #expect(store.visibleAffirmations.last == custom)
        #expect(store.visibleAffirmations == old + [custom])
        #expect(repository.affirmations == store.visibleAffirmations)
        let restarted = AffirmationStore(repository: repository, defaultAffirmations: Affirmation.starterAffirmations)
        #expect(restarted.visibleAffirmations == store.visibleAffirmations)
    }

    @Test("Default affirmations are saved on first launch")
    func savesDefaultAffirmations() {
        let repository = InMemoryAffirmationRepository()

        let store = AffirmationStore(
            repository: repository,
            defaultAffirmations: Affirmation.starterAffirmations
        )

        #expect(store.visibleAffirmations == Affirmation.starterAffirmations.filter(ContentAvailability.allowsAffirmation))
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

        #expect(restartedStore.visibleAffirmations.first?.isFavorite == true)
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
        #expect(store.visibleAffirmations == [restored, custom])
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

        #expect(restartedStore.visibleAffirmations.first?.text == "After")
    }

    @Test("A load failure prevents saved data from being overwritten")
    func loadFailurePreventsOverwrite() {
        let repository = FailingAffirmationRepository()
        let store = AffirmationStore(
            repository: repository,
            defaultAffirmations: [Affirmation(text: "Fallback")]
        )
        let affirmation = store.visibleAffirmations[0]

        #expect(store.persistenceErrorMessage != nil)
        #expect(throws: PersistenceUnavailableError.self) {
            try store.toggleFavorite(id: affirmation.id)
        }
        #expect(store.visibleAffirmations[0].isFavorite == false)
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
    private(set) var loadCallCount = 0
    private(set) var saveCallCount = 0

    init(affirmations: [Affirmation]? = nil) {
        self.affirmations = affirmations
    }

    func loadAffirmations() throws -> [Affirmation]? {
        loadCallCount += 1
        return affirmations
    }

    func saveAffirmations(_ affirmations: [Affirmation]) throws {
        saveCallCount += 1
        self.affirmations = affirmations
    }
}

@MainActor
private final class AffirmationChangeObserverSpy: AffirmationChangeObserver {
    var changeCount = 0
    var blocksChanges = false
    func willChangeAffirmations() throws {
        changeCount += 1
        if blocksChanges { throw NotificationCoordinatorError.updateInProgress }
    }
    func didChangeAffirmations(from previous: [Affirmation]) { changeCount += 1 }
}
