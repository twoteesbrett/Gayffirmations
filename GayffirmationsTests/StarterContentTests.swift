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
        #expect(AffirmationTag.allCases.allSatisfy { tag in entries.filter { $0.tags.contains(tag.rawValue) }.count == 10 })
        #expect(entries.first?.text == "You've got this, bitch.")
        #expect(entries.last?.text == "Let your kindness do the talking.")
    }

    @Test("Retired themes load as Out & About", arguments: [
        "eden", "disco", "concrete", "nature", "ember", "warm", "midnight", "pop", "playful", "neutral", "paper",
        "slate", "coast", "forest", "goldenHour", "afterHours", "cherry",
        "bubblegum", "daydream", "muscle", "spectrum"
    ])
    func migratesRetiredTheme(name: String) throws {
        let data = try JSONEncoder().encode(name)
        #expect(try JSONDecoder().decode(AppTheme.self, from: data) == .outAndAbout)
    }

    @Test("Schedules with newly retired themes retain their settings", arguments: ["eden", "disco", "concrete"])
    @MainActor
    func migratesScheduledTheme(name: String) throws {
        let original = AffirmationSchedule(theme: .steel, isEnabled: true, notificationsPerDay: 7)
        let data = try JSONEncoder().encode(original)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object["theme"] = name
        let migrated = try JSONDecoder().decode(AffirmationSchedule.self,
                                                from: JSONSerialization.data(withJSONObject: object))
        var expected = original
        expected.theme = .outAndAbout
        #expect(migrated == expected)
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
