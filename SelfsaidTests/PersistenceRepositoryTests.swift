import Foundation
import Testing
@testable import Selfsaid

@MainActor
struct PersistenceRepositoryTests {
    @Test("Missing saved data is reported as absent")
    func missingData() throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }

        #expect(try fixture.repository.loadAffirmations() == nil)
        #expect(try fixture.repository.loadSchedule() == nil)
        #expect(try fixture.repository.loadTheme() == nil)
    }

    @Test("Affirmations retain their identity, text, and favorite state")
    func affirmationRoundTrip() throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }
        let affirmations = [
            Affirmation(text: "First", isFavorite: true),
            Affirmation(text: "Second")
        ]

        try fixture.repository.saveAffirmations(affirmations)

        #expect(try fixture.repository.loadAffirmations() == affirmations)
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
        try fixture.repository.saveAppData(affirmations: affirmations, schedule: schedule, theme: .warm)
        #expect(try fixture.repository.loadAffirmations() == affirmations)
        #expect(try fixture.repository.loadSchedule() == schedule)
        #expect(try fixture.repository.loadTheme() == .warm)
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
