import Foundation
import Testing
@testable import Gayffirmations

@MainActor
struct PersistenceRepositoryTests {
    @Test("Legacy schedules keep evenly spaced times")
    func legacyRhythmMigration() throws {
        let data = Data("""
        {"isEnabled":true,"startTime":{"hour":9,"minute":0},
        "endTime":{"hour":17,"minute":0},"notificationsPerDay":4}
        """.utf8)
        let schedule = try JSONDecoder().decode(AffirmationSchedule.self, from: data)
        #expect(schedule.rhythm == .evenlySpaced)
        #expect(schedule.emphasis == .balanced)
        #expect(try ScheduleCalculator().notificationTimes(for: schedule).map(\.hour) == [10, 12, 14, 16])
    }

    @Test("Rhythm and emphasis survive saving, restarting, and resetting")
    func rhythmPersistence() throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }
        let schedule = AffirmationSchedule(notificationsPerDay: 6, rhythm: .moreLate, emphasis: .strong)
        try fixture.repository.saveSchedule(schedule)
        let store = ScheduleStore(repository: fixture.repository, defaultSchedule: AffirmationSchedule())
        #expect(store.schedule == schedule)
        try store.reset()
        #expect(try fixture.repository.loadSchedule() == AffirmationSchedule())
    }

    @Test("Invalid saved times preserve the original data and block schedule updates",
          arguments: [(-1, 0), (24, 0), (9, -1), (9, 60)])
    func invalidSavedTime(hour: Int, minute: Int) throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }
        let data = Data("""
        {"isEnabled":true,"startTime":{"hour":\(hour),"minute":\(minute)},
        "endTime":{"hour":17,"minute":0},"notificationsPerDay":4}
        """.utf8)
        fixture.userDefaults.set(data, forKey: "gayffirmations.schedule")
        #expect(throws: DecodingError.self) {
            try fixture.repository.loadSchedule()
        }
        let store = ScheduleStore(repository: fixture.repository, defaultSchedule: AffirmationSchedule())
        #expect(store.persistenceErrorMessage != nil)
        #expect(!store.schedule.isEnabled)
        #expect(throws: PersistenceUnavailableError.self) {
            try store.setEnabled(true)
        }
        #expect(fixture.userDefaults.data(forKey: "gayffirmations.schedule") == data)
    }

    @Test("Unexpected saved value types are preserved instead of replaced with defaults")
    func preservesUnexpectedValueTypes() {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }
        fixture.userDefaults.set("unexpected saved content", forKey: "gayffirmations.affirmations")

        let store = AffirmationStore(repository: fixture.repository, defaultAffirmations: Affirmation.starterAffirmations)

        #expect(store.persistenceErrorMessage != nil)
        #expect(fixture.userDefaults.string(forKey: "gayffirmations.affirmations") == "unexpected saved content")
        #expect(throws: PersistenceUnavailableError.self) {
            try store.restoreDefaults()
        }
        #expect(fixture.userDefaults.string(forKey: "gayffirmations.affirmations") == "unexpected saved content")
    }

    @Test("Launching preserves saved content and preferences with or without an old rebuild marker",
          arguments: [0, 1])
    func launchPreservesSavedData(rebuildRevision: Int) throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }
        let saved = [Affirmation(text: "My custom affirmation", isFavorite: true, tags: ["Work"])]
        let schedule = AffirmationSchedule(isEnabled: true, notificationsPerDay: 6)
        let backgrounds = [AppTheme.steel.rawValue: ThemeBackgroundChoice(usesPhoto: false)]
        try fixture.repository.saveAffirmations(saved)
        try fixture.repository.saveTheme(.steel)
        try fixture.repository.saveThemeBackgrounds(backgrounds)
        try fixture.repository.saveAffirmationSelection(.favourites)
        try fixture.repository.saveSchedule(schedule)
        fixture.userDefaults.set(rebuildRevision, forKey: "gayffirmations.contentRebuildRevision")

        // Use the same repository configuration and store loading as app startup.
        let repository = UserDefaultsRepository(
            userDefaults: fixture.userDefaults,
            initialAffirmations: Affirmation.starterAffirmations
        )
        let library = AffirmationStore(repository: repository, defaultAffirmations: Affirmation.starterAffirmations)
        let theme = ThemeStore(repository: repository, defaultTheme: .nature, backgroundRepository: repository)
        let selection = AffirmationSelectionStore(repository: repository)
        let reminders = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())

        #expect(library.affirmations.first == saved[0])
        #expect(theme.selectedTheme == .steel)
        #expect(theme.backgrounds == backgrounds)
        #expect(selection.selection == .favourites)
        #expect(reminders.schedule == schedule)
        #expect(fixture.userDefaults.object(forKey: "gayffirmations.contentBeforeRebuild") == nil)

        let restarted = UserDefaultsRepository(
            userDefaults: fixture.userDefaults,
            initialAffirmations: Affirmation.starterAffirmations
        )
        #expect(try restarted.loadAffirmations() == library.affirmations)
        #expect(try restarted.loadTheme() == .steel)
        #expect(try restarted.loadAffirmationSelection() == .favourites)
    }

    @Test("Initial content seeds the empty baseline once and preserves edits and deletions")
    func seedsInitialContentOnce() throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }
        try fixture.repository.saveAffirmations([])
        let seeded = UserDefaultsRepository(userDefaults: fixture.userDefaults,
                                           initialAffirmations: Affirmation.starterAffirmations)
        #expect(try seeded.loadAffirmations() == Affirmation.starterAffirmations)

        var edited = Affirmation.starterAffirmations[0]
        edited.text = "Edited"
        edited.isFavorite = true
        try seeded.saveAffirmations([edited])
        let restarted = UserDefaultsRepository(userDefaults: fixture.userDefaults,
                                               initialAffirmations: Affirmation.starterAffirmations)
        #expect(try restarted.loadAffirmations() == [edited])
        try restarted.saveAffirmations([])
        #expect(try restarted.loadAffirmations() == [])
    }

    @Test("Initial seeding preserves custom content and does not duplicate existing starters")
    func seedingPreservesExistingContent() throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }
        let custom = Affirmation(text: "Custom", isFavorite: true, tags: ["Custom tag"])
        var edited = Affirmation.starterAffirmations[0]
        edited.text = "Edited starter"
        let sameText = Affirmation(text: Affirmation.starterAffirmations[1].text)
        try fixture.repository.saveAffirmations([custom, edited, sameText])
        let seeded = UserDefaultsRepository(userDefaults: fixture.userDefaults,
                                           initialAffirmations: Affirmation.starterAffirmations)
        let saved = try seeded.loadAffirmations()
        let loaded = try #require(saved)
        #expect(Array(loaded.prefix(3)) == [custom, edited, sameText])
        #expect(loaded.count == 16)
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
        fixture.userDefaults.set(data, forKey: "gayffirmations.affirmations")

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
        try fixture.repository.saveAppData(affirmations: affirmations, schedule: schedule, theme: .nature, selection: .favourites)
        #expect(try fixture.repository.loadAffirmations() == affirmations)
        #expect(try fixture.repository.loadSchedule() == schedule)
        #expect(try fixture.repository.loadTheme() == .nature)
        #expect(try fixture.repository.loadAffirmationSelection() == .favourites)
    }

    @Test("Removed themes fall back to Nature and allow subsequent selections", arguments: ["together", "fruity"])
    func removedThemeMigration(name: String) throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }
        fixture.userDefaults.set(try JSONEncoder().encode(name), forKey: "gayffirmations.theme")

        let store = ThemeStore(repository: fixture.repository)
        #expect(store.selectedTheme == .nature)
        #expect(store.persistenceErrorMessage == nil)
        try store.select(.steel)
        #expect(try fixture.repository.loadTheme() == .steel)
    }

    @Test("A theme can be saved and loaded")
    func themeRoundTrip() throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }

        try fixture.repository.saveTheme(.nature)

        #expect(try fixture.repository.loadTheme() == .nature)
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
