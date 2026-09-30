import Testing
@testable import Selfsaid

@MainActor
struct AffirmationDeckTests {
    @Test("Changing the delivery source preserves a matching entry and handles empty sources")
    func changesDeliverySource() {
        let first = Affirmation(text: "First", tags: ["Work"])
        let second = Affirmation(text: "Second", isFavorite: true, tags: ["Work"])
        let library = [first, second]
        var deck = AffirmationDeck(affirmations: library)
        deck.showNext()
        deck.replaceAffirmations(with: AffirmationSelection.favourites.matchingAffirmations(in: library))
        #expect(deck.currentAffirmation == second)
        #expect(!deck.canNavigate)
        deck.replaceAffirmations(with: AffirmationSelection.tag("Missing").matchingAffirmations(in: library))
        #expect(deck.currentAffirmation == nil)
        deck.showNext()
        deck.replaceAffirmations(with: AffirmationSelection.tag("Work").matchingAffirmations(in: library))
        #expect(deck.currentAffirmation == first)
        #expect(deck.canNavigate)
    }

    private let affirmations = [
        Affirmation(text: "First"),
        Affirmation(text: "Second"),
        Affirmation(text: "Third")
    ]

    @Test("A new deck starts with its first affirmation")
    func startsWithFirstAffirmation() {
        let deck = AffirmationDeck(affirmations: affirmations)

        #expect(deck.currentAffirmation?.text == "First")
    }

    @Test("Next moves forward and wraps to the beginning")
    func nextWrapsToBeginning() {
        var deck = AffirmationDeck(affirmations: affirmations)

        deck.showNext()
        #expect(deck.currentAffirmation?.text == "Second")

        deck.showNext()
        #expect(deck.currentAffirmation?.text == "Third")

        deck.showNext()
        #expect(deck.currentAffirmation?.text == "First")
    }

    @Test("Previous moves backward and wraps to the end")
    func previousWrapsToEnd() {
        var deck = AffirmationDeck(affirmations: affirmations)

        deck.showPrevious()

        #expect(deck.currentAffirmation?.text == "Third")
    }

    @Test("An empty deck is safe to navigate")
    func emptyDeckIsSafe() {
        var deck = AffirmationDeck(affirmations: [])

        deck.showNext()
        deck.showPrevious()

        #expect(deck.currentAffirmation == nil)
        #expect(!deck.canNavigate)
    }

    @Test("A deck needs multiple affirmations before it can navigate")
    func navigationAvailability() {
        let singleAffirmationDeck = AffirmationDeck(
            affirmations: [Affirmation(text: "Only one")]
        )
        let multipleAffirmationDeck = AffirmationDeck(
            affirmations: affirmations
        )

        #expect(!singleAffirmationDeck.canNavigate)
        #expect(multipleAffirmationDeck.canNavigate)
    }

    @Test("Replacing affirmations keeps the current selection when possible")
    func replaceAffirmationsKeepsSelection() {
        var deck = AffirmationDeck(affirmations: affirmations)
        deck.showNext()

        var updatedAffirmations = affirmations
        updatedAffirmations[1].text = "Updated second"
        deck.replaceAffirmations(with: updatedAffirmations)

        #expect(deck.currentAffirmation?.id == affirmations[1].id)
        #expect(deck.currentAffirmation?.text == "Updated second")
    }

    @Test("Replacing affirmations chooses a safe selection after deletion")
    func replaceAffirmationsAfterDeletion() {
        var deck = AffirmationDeck(affirmations: affirmations)
        deck.showPrevious()

        deck.replaceAffirmations(with: Array(affirmations.prefix(2)))

        #expect(deck.currentAffirmation?.id == affirmations[1].id)
    }
}
