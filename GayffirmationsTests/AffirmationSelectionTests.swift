import Foundation
import Testing
@testable import Gayffirmations

@MainActor
struct AffirmationSelectionTests {
    @Test("Clearing the final Library filter returns to All while active filters remain selected")
    func emptyLibraryFiltersDefaultToAll() {
        #expect(AffirmationSelection.sources(favourites: false, tags: []).usingAllWhenEmpty == .all)
        #expect(AffirmationSelection.all.usingAllWhenEmpty == .all)
        for selection: AffirmationSelection in [
            .favourites, .tag("Work"), .sources(favourites: true, tags: ["Work"])
        ] {
            #expect(selection.usingAllWhenEmpty == selection)
        }
        let cleared = AffirmationSelection.favourites.selectingFavourites(false)
        #expect(cleared.usingAllWhenEmpty == .all)
        // Empty selections remain available to the editor and existing saved data.
        #expect(cleared.matchingAffirmations(in: [Affirmation(text: "Example", isFavorite: true, tags: ["Example tag"])]).isEmpty)
    }

    @Test("Combined choices include favourites or any selected tag, without duplicates")
    func combinesSources() {
        let favourite = Affirmation(text: "Favourite", isFavorite: true)
        let overlap = Affirmation(text: "Both", isFavorite: true, tags: ["Confidence", "Work"])
        let tagged = Affirmation(text: "Tagged", tags: ["confidence"])
        let work = Affirmation(text: "Work", tags: ["Work"])
        let other = Affirmation(text: "Other")
        let selection = AffirmationSelection.sources(favourites: true, tags: ["Confidence", "Work"])
        #expect(selection.matchingAffirmations(in: [favourite, overlap, tagged, work, other])
            == [favourite, overlap, tagged, work])
    }

    @Test("Changing individual choices preserves the other choices")
    func changesIndividualChoices() {
        let selection = AffirmationSelection.favourites.selectingTag("Confidence", included: true)
        #expect(selection.includesFavourites)
        #expect(selection.containsTag("confidence"))
        let tagsOnly = selection.selectingFavourites(false)
        #expect(tagsOnly.selectedTags == ["Confidence"])
        let empty = tagsOnly.selectingTag("CONFIDENCE", included: false)
        #expect(empty.matchingAffirmations(in: [Affirmation(text: "Example", isFavorite: true, tags: ["Example tag"])]).isEmpty)
        #expect(empty.name == "None selected")
        let fromAll = AffirmationSelection.all.selectingTag("Work", included: true)
        #expect(fromAll.selectedTags == ["Work"])
        #expect(!fromAll.includesFavourites)
    }

    @Test("Selections saved before multiple choices still decode")
    func loadsPreviousSelectionFormat() throws {
        let decoder = JSONDecoder()
        #expect(try decoder.decode(AffirmationSelection.self, from: Data(#"{"all":{}}"#.utf8)) == .all)
        #expect(try decoder.decode(AffirmationSelection.self, from: Data(#"{"favourites":{}}"#.utf8)) == .favourites)
        #expect(try decoder.decode(AffirmationSelection.self, from: Data(#"{"tag":{"_0":"Work"}}"#.utf8)) == .tag("Work"))
    }

    @Test("Selections preserve library order and match tags regardless of case")
    func matchesEntries() {
        let first = Affirmation(text: "First", tags: ["Work", "Calm"])
        let second = Affirmation(text: "Second", isFavorite: true, tags: ["work"])
        let third = Affirmation(text: "Third")
        let entries = [first, second, third]

        #expect(AffirmationSelection.all.matchingAffirmations(in: entries) == entries)
        #expect(AffirmationSelection.favourites.matchingAffirmations(in: entries) == [second])
        #expect(AffirmationSelection.tag("WORK").matchingAffirmations(in: entries) == [first, second])
        #expect(AffirmationSelection.tag("Missing").matchingAffirmations(in: entries).isEmpty)
        #expect(AffirmationSelection.all.matchingAffirmations(in: []).isEmpty)
        #expect(AffirmationSelection.favourites.matchingAffirmations(in: [third]).isEmpty)
    }

    @Test("Matching reflects favourite changes and removal of the last tagged entry")
    func matchesUpdatedLibrary() {
        var entry = Affirmation(text: "First", isFavorite: true, tags: ["Work"])
        let selection = AffirmationSelection.tag("Work")
        entry.isFavorite = false
        #expect(AffirmationSelection.favourites.matchingAffirmations(in: [entry]).isEmpty)
        entry.tags = []
        #expect(selection.matchingAffirmations(in: [entry]).isEmpty)
        #expect(selection == .tag("Work"))
    }

    @Test("Existing saved libraries default to all without changing entry data")
    func defaultsToAll() throws {
        let fixture = SelectionRepositoryFixture()
        defer { fixture.removeSavedData() }
        let entries = [Affirmation(text: "Keep me", isFavorite: true, tags: ["Work"])]
        try fixture.repository.saveAffirmations(entries)
        #expect(try fixture.repository.loadAffirmationSelection() == nil)

        let store = AffirmationSelectionStore(repository: fixture.repository)
        #expect(store.selection == .all)
        #expect(try fixture.repository.loadAffirmationSelection() == .all)
        #expect(try fixture.repository.loadAffirmations() == entries)
    }

    @Test("Every selection survives recreating the store")
    func selectionSurvivesRestart() throws {
        let fixture = SelectionRepositoryFixture()
        defer { fixture.removeSavedData() }
        let store = AffirmationSelectionStore(repository: fixture.repository)

        for selection: AffirmationSelection in [
            .favourites, .tag("Work"), .all,
            .sources(favourites: true, tags: ["Confidence", "Work"]),
            .sources(favourites: false, tags: [])
        ] {
            try store.select(selection)
            let restarted = AffirmationSelectionStore(repository: fixture.repository)
            #expect(restarted.selection == selection)
            #expect(restarted.persistenceErrorMessage == nil)
        }
    }

    @Test("Unreadable selection data is preserved and further saves are blocked")
    func preservesUnreadableData() {
        let fixture = SelectionRepositoryFixture()
        defer { fixture.removeSavedData() }
        let corruptData = Data("unreadable".utf8)
        fixture.userDefaults.set(corruptData, forKey: "gayffirmations.affirmationSelection")

        let store = AffirmationSelectionStore(repository: fixture.repository)
        #expect(store.selection == .all)
        #expect(store.persistenceErrorMessage != nil)
        #expect(throws: PersistenceUnavailableError.self) {
            try store.select(.favourites)
        }
        #expect(fixture.userDefaults.data(forKey: "gayffirmations.affirmationSelection") == corruptData)
    }

    @Test("A failed save leaves the current selection unchanged")
    func failedSavePreservesSelection() {
        let store = AffirmationSelectionStore(repository: FailingSelectionRepository())
        #expect(store.selection == .tag("Work"))
        #expect(throws: SelectionSaveError.failed) {
            try store.select(.favourites)
        }
        #expect(store.selection == .tag("Work"))
    }
}

private struct SelectionRepositoryFixture {
    let suiteName = "AffirmationSelectionTests.\(UUID().uuidString)"
    let userDefaults: UserDefaults
    let repository: UserDefaultsRepository

    init() {
        let userDefaults = UserDefaults(suiteName: suiteName)!
        self.userDefaults = userDefaults
        repository = UserDefaultsRepository(userDefaults: userDefaults)
    }

    func removeSavedData() {
        userDefaults.removePersistentDomain(forName: suiteName)
    }
}

private enum SelectionSaveError: Error, Equatable {
    case failed
}

private final class FailingSelectionRepository: AffirmationSelectionRepository {
    func loadAffirmationSelection() throws -> AffirmationSelection? {
        .tag("Work")
    }

    func saveAffirmationSelection(_ selection: AffirmationSelection) throws {
        throw SelectionSaveError.failed
    }
}
