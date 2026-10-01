import Foundation
import Testing
@testable import gayaffirmations

@MainActor
struct PersistenceRepositoryTests {
    @Test("Unexpected saved value types are preserved instead of replaced with defaults")
    func preservesUnexpectedValueTypes() {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }
        fixture.userDefaults.set("unexpected saved content", forKey: "gayaffirmations.affirmations")

        let store = AffirmationStore(repository: fixture.repository, defaultAffirmations: Affirmation.samples)

        #expect(store.persistenceErrorMessage != nil)
        #expect(fixture.userDefaults.string(forKey: "gayaffirmations.affirmations") == "unexpected saved content")
        #expect(throws: PersistenceUnavailableError.self) {
            try store.restoreDefaults()
        }
        #expect(fixture.userDefaults.string(forKey: "gayaffirmations.affirmations") == "unexpected saved content")
    }

    @Test("Missing saved data is reported as absent")
    func missingData() throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }

        #expect(try fixture.repository.loadAffirmations() == nil)
        #expect(try fixture.repository.loadSchedule() == nil)
        #expect(try fixture.repository.loadTheme() == nil)
    }

    @Test("Affirmations retain their identity, text, favorite state, and tags")
    func affirmationRoundTrip() throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }
        let affirmations = [
            Affirmation(text: "First", isFavorite: true, tags: ["Work", "Confidence"]),
            Affirmation(text: "Second")
        ]

        try fixture.repository.saveAffirmations(affirmations)

        #expect(try fixture.repository.loadAffirmations() == affirmations)
    }

    @Test("Saved entries from before tags load without losing existing data")
    func loadsLegacyAffirmations() throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }
        let id = UUID()
        let data = Data("""
        [{"id":"\(id.uuidString)","text":"Keep me","isFavorite":true}]
        """.utf8)
        fixture.userDefaults.set(data, forKey: "gayaffirmations.affirmations")

        let loaded = try fixture.repository.loadAffirmations()
        #expect(loaded == [Affirmation(id: id, text: "Keep me", isFavorite: true)])
        try fixture.repository.saveAffirmations(loaded!)
        #expect(try fixture.repository.loadAffirmations() == loaded)
    }

    @Test("A schedule can be saved and loaded")
    func scheduleRoundTrip() throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }
        let schedule = AffirmationSchedule(
            isEnabled: true,
            startTime: TimeOfDay(hour: 8, minute: 30),
            endTime: TimeOfDay(hour: 19, minute: 15),
            notificationsPerDay: 6
        )

        try fixture.repository.saveSchedule(schedule)

        #expect(try fixture.repository.loadSchedule() == schedule)
    }

    @Test("Saving all app data persists every section together")
    func appDataRoundTrip() throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }
        let affirmations = [Affirmation(text: "Reset")]
        let schedule = AffirmationSchedule()
        try fixture.repository.saveAppData(affirmations: affirmations, schedule: schedule, theme: .warm, selection: .favourites)
        #expect(try fixture.repository.loadAffirmations() == affirmations)
        #expect(try fixture.repository.loadSchedule() == schedule)
        #expect(try fixture.repository.loadTheme() == .warm)
        #expect(try fixture.repository.loadAffirmationSelection() == .favourites)
    }

    @Test("A theme can be saved and loaded")
    func themeRoundTrip() throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }

        try fixture.repository.saveTheme(.midnight)

        #expect(try fixture.repository.loadTheme() == .midnight)
    }
}

private struct RepositoryFixture {
    let suiteName = "PersistenceRepositoryTests.\(UUID().uuidString)"
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
