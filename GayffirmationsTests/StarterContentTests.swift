import Foundation
import Testing
@testable import Gayffirmations

struct StarterContentTests {
    @Test("A fresh catalogue has one neutral theme and no starter content")
    func cleanCatalogue() {
        #expect(AppTheme.allCases == [.neutral])
        #expect(Affirmation.starterAffirmations.isEmpty)
    }

    @Test("Retired themes load as neutral", arguments: [
        "ember", "warm", "midnight", "pop", "playful", "refined", "paper",
        "slate", "coast", "forest", "goldenHour", "afterHours", "cherry",
        "bubblegum", "daydream", "steel", "muscle", "disco", "spectrum"
    ])
    func migratesRetiredTheme(name: String) throws {
        let data = try JSONEncoder().encode(name)
        #expect(try JSONDecoder().decode(AppTheme.self, from: data) == .neutral)
    }

    @Test("Unknown theme data still reports corruption")
    func unknownTheme() throws {
        let data = try JSONEncoder().encode("unknown-theme")
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(AppTheme.self, from: data) }
    }
}
