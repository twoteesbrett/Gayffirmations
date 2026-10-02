import Foundation
import Testing
@testable import Gayffirmations

@MainActor
struct PersistenceRepositoryTests {
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

    @Test("Content rebuild clears saved content once and preserves the reminder schedule")
    func contentRebuildRunsOnce() throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }
        let old = [Affirmation(text: "Old", isFavorite: true, tags: ["Old tag"])]
        let schedule = AffirmationSchedule(notificationsPerDay: 6)
        try fixture.repository.saveAffirmations(old)
        try fixture.repository.saveTheme(.neutral)
        try fixture.repository.saveAffirmationSelection(.favourites)
        try fixture.repository.saveSchedule(schedule)
        fixture.userDefaults.set(true, forKey: "gayffirmations.themePhotosEnabled")

        fixture.repository.prepareForContentRebuild()

        #expect(try fixture.repository.loadAffirmations() == nil)
        #expect(try fixture.repository.loadTheme() == nil)
        #expect(try fixture.repository.loadAffirmationSelection() == nil)
        #expect(fixture.userDefaults.object(forKey: "gayffirmations.themePhotosEnabled") == nil)
        #expect(try fixture.repository.loadSchedule() == schedule)
        let backup = fixture.userDefaults.dictionary(forKey: "gayffirmations.contentBeforeRebuild")
        #expect(backup?["gayffirmations.affirmations"] as? Data == (try JSONEncoder().encode(old)))

        let new = [Affirmation(text: "New", tags: ["New tag"])]
        try fixture.repository.saveAffirmations(new)
        try fixture.repository.saveAffirmationSelection(.favourites)
        let restartedRepository = UserDefaultsRepository(userDefaults: fixture.userDefaults)
        restartedRepository.prepareForContentRebuild()
        #expect(try restartedRepository.loadAffirmations() == new)
        #expect(try restartedRepository.loadAffirmationSelection() == .favourites)
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
        try fixture.repository.saveAppData(affirmations: affirmations, schedule: schedule, theme: .neutral, selection: .favourites)
        #expect(try fixture.repository.loadAffirmations() == affirmations)
        #expect(try fixture.repository.loadSchedule() == schedule)
        #expect(try fixture.repository.loadTheme() == .neutral)
        #expect(try fixture.repository.loadAffirmationSelection() == .favourites)
    }

    @Test("A theme can be saved and loaded")
    func themeRoundTrip() throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }

        try fixture.repository.saveTheme(.neutral)

        #expect(try fixture.repository.loadTheme() == .neutral)
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
