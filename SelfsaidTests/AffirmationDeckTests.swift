import Testing
@testable import Selfsaid

@MainActor
struct AffirmationDeckTests {
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
}
