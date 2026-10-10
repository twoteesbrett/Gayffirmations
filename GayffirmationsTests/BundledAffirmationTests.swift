import Foundation
import Testing
@testable import Gayffirmations

@MainActor
struct BundledAffirmationTests {
    @Test func failedRestorationPreservesPersonalContentUntilRetry() throws {
        let original = try #require(Affirmation.starterAffirmations.first)
        let personal = Affirmation(
            id: original.id, text: "My rewrite", isFavorite: true, tags: ["Mine"]
        )
        let repository = BundledMessageRepository()
        repository.affirmations = [personal]
        let store = AffirmationStore(repository: repository, defaultAffirmations: [original])
        repository.failSave = true
        #expect(throws: RestorationTestError.saveFailed) { try store.restoreDefaults() }
        #expect(store.affirmations == [personal])
        #expect(repository.affirmations == [personal])
        repository.failSave = false
        try store.restoreDefaults()
        let saved = store.affirmations
        #expect(saved.count == 2)
        #expect(saved.first == original)
        let copy = try #require(saved.last)
        #expect(copy.id != original.id)
        #expect(copy.text == personal.text)
        #expect(copy.tags == personal.tags)
        #expect(copy.isFavorite)
        #expect(copy.source == .user)
        try store.restoreDefaults()
        #expect(store.affirmations == saved)
        #expect(repository.affirmations == saved)
    }

    @Test func bundledEditsAndDeletionSurviveReloadAndCanBeRestored() throws {
        let entry = try #require(Affirmation.legacyStarterAffirmations.last)
        let repository = BundledMessageRepository()
        let store = AffirmationStore(repository: repository, defaultAffirmations: [entry])
        try store.update(id: entry.id, text: "Changed", tags: ["Mine"])
        try store.toggleFavorite(id: entry.id)
        let restarted = AffirmationStore(repository: repository, defaultAffirmations: [entry])
        #expect(restarted.affirmations[0].text == "Changed")
        #expect(restarted.affirmations[0].tags == ["Mine"])
        try restarted.restoreOriginal(id: entry.id)
        #expect(restarted.affirmations[0].text == entry.text)
        #expect(restarted.affirmations[0].tags == entry.tags)
        #expect(restarted.affirmations[0].isFavorite)
        try restarted.delete(id: entry.id)
        let deleted = AffirmationStore(repository: repository, defaultAffirmations: [entry])
        #expect(deleted.affirmations.isEmpty)
        let personal = try deleted.add(text: "Personal")
        try deleted.restoreDefaults()
        #expect(deleted.affirmations == [entry, personal])
    }

    @Test func userMessagesRemainEditableAfterReload() throws {
        let store = AffirmationStore()
        let entry = try store.add(text: "My message")
        try store.update(id: entry.id, text: "My edited message")
        let reloaded = try JSONDecoder().decode([Affirmation].self, from: JSONEncoder().encode(store.affirmations))
        #expect(reloaded[0].source == .user)
        #expect(reloaded[0].text == "My edited message")
    }

    @Test func legacySourcesPreserveCustomisations() throws {
        let starter = try #require(Affirmation.legacyStarterAffirmations.first)
        func legacy(_ entry: Affirmation) throws -> Affirmation {
            var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(entry)) as? [String: Any])
            object.removeValue(forKey: "source")
            return try JSONDecoder().decode(Affirmation.self, from: JSONSerialization.data(withJSONObject: object))
        }
        #expect(try legacy(starter).isBundled)
        var customised = starter
        customised.text = "My rewrite"
        customised.isFavorite = true
        customised.tags = ["Mine"]
        let migrated = try legacy(customised)
        #expect(migrated.source == .user)
        #expect(migrated.text == customised.text)
        #expect(migrated.isFavorite)
        #expect(migrated.tags == ["Mine"])
        #expect(try legacy(Affirmation(text: starter.text)).source == .user)
        #expect(try JSONDecoder().decode(Affirmation.self, from: JSONEncoder().encode(starter)) == starter)
    }

    @Test("Legacy tag-only customisations remain editable and deletable",
          arguments: [false, true], [["Mine"], []] as [[String]])
    func legacyTagCustomisations(useOriginalNameMessage: Bool, tags: [String]) throws {
        let starter = try #require(useOriginalNameMessage
            ? Affirmation.legacyStarterAffirmations.last : Affirmation.legacyStarterAffirmations.first)
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(starter)) as? [String: Any])
        object.removeValue(forKey: "source")
        if useOriginalNameMessage {
            object["text"] = "Stop comparing. You're the only Brett in the room."
        }
        object["tags"] = tags
        object["isFavorite"] = true
        let migrated = try JSONDecoder().decode(Affirmation.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(migrated.source == .user)
        #expect(migrated.id == starter.id)
        #expect(migrated.tags == tags)
        #expect(migrated.isFavorite)

        let reloaded = try JSONDecoder().decode(Affirmation.self, from: JSONEncoder().encode(migrated))
        #expect(reloaded == migrated)
        let store = AffirmationStore(affirmations: [reloaded])
        try store.update(id: reloaded.id, text: reloaded.text, tags: ["Updated"])
        #expect(store.affirmations[0].tags == ["Updated"])
        try store.delete(id: reloaded.id)
        #expect(store.affirmations.isEmpty)
    }

    @Test func originalLegacyNameMessageRemainsBundled() throws {
        let starter = try #require(Affirmation.legacyStarterAffirmations.last)
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(starter)) as? [String: Any])
        object.removeValue(forKey: "source")
        object["text"] = "Stop comparing. You're the only Brett in the room."
        let migrated = try JSONDecoder().decode(Affirmation.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(migrated.isBundled)
    }
}

private final class BundledMessageRepository: AffirmationRepository {
    var affirmations: [Affirmation]?
    var failSave = false

    func loadAffirmations() throws -> [Affirmation]? { affirmations }

    func saveAffirmations(_ affirmations: [Affirmation]) throws {
        if failSave { throw RestorationTestError.saveFailed }
        self.affirmations = affirmations
    }
}

private enum RestorationTestError: Error {
    case saveFailed
}
