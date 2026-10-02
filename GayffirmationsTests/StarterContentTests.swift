import Foundation
import Testing
@testable import Gayffirmations

struct StarterContentTests {
    @Test("Initial affirmations match the supplied text and tag combinations")
    func initialContent() {
        let entries = Affirmation.starterAffirmations
        let expected: [(String, [String])] = [
            ("Hey handsome, the pantry isn't going anywhere.", ["food", "self-kindness"]),
            ("A craving called. You don't have to answer.", ["food", "confidence"]),
            ("Your body deserves kindness, not another guilt trip.", ["body", "food", "self-kindness"]),
            ("One treat is a treat. It doesn't need a sequel.", ["food", "self-kindness"]),
            ("You've got this. Yes, even with biscuits in the house.", ["food", "confidence"]),
            ("Gay looks good on you.", ["gay", "confidence"]),
            ("You don't have to follow the straight instruction manual.", ["gay", "confidence"]),
            ("There's no dress code for being a gay man.", ["gay", "self-kindness"]),
            ("You like men. Excellent taste.", ["gay", "confidence"]),
            ("Be as gay as you damn well please.", ["gay", "confidence"]),
            ("Hey handsome. Yes, I'm talking to you.", ["body", "confidence"]),
            ("Your body isn't auditioning for anyone.", ["body", "confidence", "self-kindness"]),
            ("You don't need a six-pack to be a whole snack.", ["body", "confidence", "self-kindness"]),
            ("Grey hairs? You've earned the highlights.", ["body", "confidence", "self-kindness"]),
            ("Stop comparing. You're the only Brett in the room.", ["confidence", "self-kindness"]),
        ]
        #expect(entries.count == expected.count)
        for (entry, expectedEntry) in zip(entries, expected) {
            #expect(entry.text == expectedEntry.0)
            #expect(entry.tags == expectedEntry.1)
            #expect(!entry.isFavorite)
        }
        #expect(Set(entries.map(\.id)).count == 15)
        #expect(Set(entries.flatMap(\.tags)) == Set(AffirmationTag.allCases.map(\.rawValue)))
        #expect(entries.first?.id.uuidString == "B7E77000-0000-4000-8000-000000000001")
        #expect(entries.last?.id.uuidString == "B7E77000-0000-4000-8000-000000000015")
    }

    @Test("Retired themes load as Nature", arguments: [
        "ember", "warm", "midnight", "pop", "playful", "neutral", "paper",
        "slate", "coast", "forest", "goldenHour", "afterHours", "cherry",
        "bubblegum", "daydream", "muscle", "spectrum"
    ])
    func migratesRetiredTheme(name: String) throws {
        let data = try JSONEncoder().encode(name)
        #expect(try JSONDecoder().decode(AppTheme.self, from: data) == .nature)
    }

    @Test("Current themes preserve their identity", arguments: AppTheme.allCases)
    func themeRoundTrip(theme: AppTheme) throws {
        let data = try JSONEncoder().encode(theme)
        #expect(try JSONDecoder().decode(AppTheme.self, from: data) == theme)
    }

    @Test("Unknown theme data still reports corruption")
    func unknownTheme() throws {
        let data = try JSONEncoder().encode("unknown-theme")
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(AppTheme.self, from: data) }
    }
}
