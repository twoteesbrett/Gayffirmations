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
    func delete() {
        let affirmation = Affirmation(text: "Temporary")
        let store = AffirmationStore(affirmations: [affirmation])

        store.delete(id: affirmation.id)

        #expect(store.affirmations.isEmpty)
    }

    @Test("An affirmation can be favorited and unfavorited")
    func toggleFavorite() {
        let affirmation = Affirmation(text: "Favorite")
        let store = AffirmationStore(affirmations: [affirmation])

        store.toggleFavorite(id: affirmation.id)
        #expect(store.affirmations.first?.isFavorite == true)

        store.toggleFavorite(id: affirmation.id)
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

    @Test("A blank edit leaves the original affirmation unchanged")
    func rejectBlankEdit() {
        let affirmation = Affirmation(text: "Keep me")
        let store = AffirmationStore(affirmations: [affirmation])

        #expect(throws: AffirmationStoreError.blankText) {
            try store.update(id: affirmation.id, text: "   ")
        }
        #expect(store.affirmations.first?.text == "Keep me")
    }
}
