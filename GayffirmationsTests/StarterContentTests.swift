import Foundation
import Testing
@testable import Gayffirmations

struct StarterContentTests {
    @Test("Initial affirmations match the supplied text and tag combinations")
    func initialContent() {
        let entries = Affirmation.starterAffirmations
        #expect(entries.count == 50)
        #expect(Set(entries.map(\.id)).count == 50)
        #expect(entries.allSatisfy { $0.isBundled && !$0.isFavorite && !$0.text.isEmpty && !$0.tags.isEmpty })
        #expect(Set(entries.flatMap(\.tags)) == Set(AffirmationTag.allCases.map(\.rawValue)))
        #expect(entries.first?.text == "You've got this. Yes, you, gorgeous.")
        #expect(entries.last?.text == "Be gentle with yourself. The world has enough critics already.")
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
