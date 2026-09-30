import Testing
@testable import Selfsaid

@MainActor
struct AffirmationStoreTests {
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
            defaultAffirmations: Affirmation.samples
        )

        #expect(store.affirmations == savedAffirmations)
    }

    @Test("Default affirmations are saved on first launch")
    func savesDefaultAffirmations() {
        let repository = InMemoryAffirmationRepository()

        let store = AffirmationStore(
            repository: repository,
            defaultAffirmations: Affirmation.samples
        )

        #expect(store.affirmations == Affirmation.samples)
        #expect(repository.affirmations == Affirmation.samples)
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
            defaultAffirmations: Affirmation.samples
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
