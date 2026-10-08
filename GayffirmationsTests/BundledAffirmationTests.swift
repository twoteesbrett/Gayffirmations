import Foundation
import Testing
@testable import Gayffirmations

@MainActor
struct BundledAffirmationTests {
    @Test func bundledTextAndTagsAreProtectedWhileFavouritesRemainAvailable() throws {
        let entry = try #require(Affirmation.starterAffirmations.last)
        let store = AffirmationStore(affirmations: [entry])
        #expect(entry.isBundled)
        #expect(throws: AffirmationStoreError.bundledMessage) {
            try store.update(id: entry.id, text: "Changed")
        }
        #expect(store.affirmations == [entry])
        #expect(throws: AffirmationStoreError.bundledMessage) {
            try store.update(id: entry.id, text: entry.text, tags: ["Mine"])
        }
        #expect(store.affirmations == [entry])
        try store.toggleFavorite(id: entry.id)
        #expect(store.affirmations[0].text == entry.text)
        #expect(store.affirmations[0].tags == entry.tags)
        #expect(store.affirmations[0].isFavorite)
        #expect(store.affirmations[0].isBundled)
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
        let starter = try #require(Affirmation.starterAffirmations.first)
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
            ? Affirmation.starterAffirmations.last : Affirmation.starterAffirmations.first)
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
        let starter = try #require(Affirmation.starterAffirmations.last)
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(starter)) as? [String: Any])
        object.removeValue(forKey: "source")
        object["text"] = "Stop comparing. You're the only Brett in the room."
        let migrated = try JSONDecoder().decode(Affirmation.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(migrated.isBundled)
    }
}
