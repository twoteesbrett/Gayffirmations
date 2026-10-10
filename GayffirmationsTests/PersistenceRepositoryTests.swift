import Foundation
import Testing
@testable import Gayffirmations

@MainActor
struct PersistenceRepositoryTests {
    @Test("Restoration preserves legacy personal content across repeated restores and relaunches",
          arguments: [false, true])
    func restoreLegacyPersonalContent(tagsOnly: Bool) throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }
        let current = Affirmation.starterAffirmations
        let starter = try #require(Affirmation.legacyStarterAffirmations.first {
            entry in current.contains { $0.id == entry.id }
        })
        let retired = try #require(Affirmation.legacyStarterAffirmations.first {
            entry in !current.contains { $0.id == entry.id }
        })
        var objects = try #require(JSONSerialization.jsonObject(
            with: JSONEncoder().encode([starter, retired])
        ) as? [[String: Any]])
        for index in objects.indices {
            objects[index].removeValue(forKey: "source")
            objects[index]["isFavorite"] = true
            if tagsOnly {
                objects[index]["tags"] = ["Personal"]
            } else {
                objects[index]["text"] = "My rewrite \(index)"
            }
        }
        let raw = try JSONSerialization.data(withJSONObject: objects)
        fixture.userDefaults.set(raw, forKey: "gayffirmations.affirmations")
        let store = AffirmationStore(repository: fixture.repository, defaultAffirmations: current)
        let personal = store.affirmations
        #expect(personal.allSatisfy { !$0.isBundled })
        #expect(!store.canRestoreOriginal(id: starter.id))
        try store.restoreOriginal(id: starter.id)
        #expect(store.affirmations == personal)
        try store.restoreDefaults()

        let saved = store.affirmations
        let restored = try #require(saved.first { $0.id == starter.id })
        #expect(restored.isBundled)
        #expect(restored.text == current.first { $0.id == starter.id }?.text)
        #expect(!restored.isFavorite)
        #expect(store.canRestoreOriginal(id: starter.id))
        let copies = saved.filter { !$0.isBundled }
        #expect(copies.count == 2)
        for original in personal {
            let copy = try #require(copies.first { $0.text == original.text && $0.tags == original.tags })
            #expect(copy.isFavorite)
            #expect(copy.id == original.id || original.id == starter.id)
        }
        #expect(copies.allSatisfy { $0.id != starter.id })
        #expect(Set(saved.map(\.id)).count == saved.count)
        #expect(try fixture.repository.loadAffirmations() == saved)
        for _ in 0..<2 {
            let restarted = AffirmationStore(repository: fixture.repository, defaultAffirmations: current)
            #expect(restarted.affirmations == saved)
            try restarted.restoreDefaults()
            #expect(restarted.affirmations == saved)
            #expect(try fixture.repository.loadAffirmations() == saved)
        }
    }

    @Test("Denied permission preserves saved routines and delivery resumes after permission returns")
    func permissionChangesPreserveSchedules() async throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }
        let schedules = [
            AffirmationSchedule(isEnabled: true, notificationsPerDay: 2),
            AffirmationSchedule(isEnabled: true, notificationsPerDay: 3),
            AffirmationSchedule(isEnabled: false)
        ]
        try fixture.repository.saveSchedules(schedules)
        let store = ScheduleStore(repository: fixture.repository, defaultSchedule: AffirmationSchedule())
        let library = AffirmationStore(affirmations: [Affirmation(text: "Original")])
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(
            affirmationStore: library, scheduleStore: store, scheduler: scheduler
        )
        await coordinator.reconcileOnLaunch()
        #expect(scheduler.scheduledReminders.count == 5)

        scheduler.authorizationStatusValue = .denied
        await coordinator.reconcileOnLaunch()
        #expect(store.schedules == schedules)
        #expect(try fixture.repository.loadSchedules() == schedules)
        #expect(scheduler.scheduledReminders.isEmpty)
        #expect(coordinator.errorMessage == NotificationCoordinatorError.permissionDenied.localizedDescription)

        try library.update(id: library.affirmations[0].id, text: "Edited while denied")
        await coordinator.waitForLibraryRefresh()
        #expect(try fixture.repository.loadSchedules() == schedules)

        scheduler.authorizationStatusValue = .authorized
        let restartedStore = ScheduleStore(repository: fixture.repository, defaultSchedule: AffirmationSchedule())
        let restarted = NotificationCoordinator(
            affirmationStore: library, scheduleStore: restartedStore, scheduler: scheduler
        )
        await restarted.reconcileOnLaunch()
        #expect(restartedStore.schedules == schedules)
        #expect(scheduler.scheduledReminders.count == 5)
        #expect(scheduler.scheduledReminders.allSatisfy { $0.affirmationText == "Edited while denied" })
        #expect(scheduler.authorizationRequestCount == 0)
    }

    @Test("Name migration preserves user content and still upgrades bundled content",
          arguments: [false, true], [false, true])
    func nameMigrationRespectsOwnership(bundled: Bool, legacy: Bool) throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }
        let starter = try #require(Affirmation.legacyStarterAffirmations.last)
        let original = Affirmation(
            id: starter.id, text: "Stop comparing. You're the only Brett in the room.",
            isFavorite: true, tags: bundled ? starter.tags : ["Mine"],
            source: bundled ? .bundled : .user
        )
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        if legacy { object.removeValue(forKey: "source") }
        fixture.userDefaults.set(try JSONSerialization.data(withJSONObject: [object]), forKey: "gayffirmations.affirmations")

        let loaded = try #require(fixture.repository.loadAffirmations()?.first)
        var expected = original
        if bundled { expected.text = "Stop comparing. You're the only {name} in the room." }
        #expect(loaded == expected)
        #expect(try fixture.repository.loadAffirmations() == [expected])
        if !bundled { #expect(loaded.resolved(name: "") == original) }
    }

    @Test("Legacy zero-reminder schedules remain off and support updates after loading",
          arguments: [false, true])
    func legacyZeroReminderMigration(enabled: Bool) async throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }
        let data = Data("""
        {"isEnabled":\(enabled),"startTime":{"hour":8,"minute":30},
        "endTime":{"hour":19,"minute":15},"notificationsPerDay":0,
        "sound":"magic-marimba"}
        """.utf8)
        fixture.userDefaults.set(data, forKey: "gayffirmations.schedule")
        let store = ScheduleStore(repository: fixture.repository, defaultSchedule: AffirmationSchedule())
        #expect(store.persistenceErrorMessage == nil)
        #expect(store.schedule == AffirmationSchedule(
            id: store.schedule.id,
            name: "Daily affirmations",
            startTime: TimeOfDay(hour: 8, minute: 30),
            endTime: TimeOfDay(hour: 19, minute: 15),
            notificationsPerDay: 1, sound: .magicMarimba
        ))
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(
            affirmationStore: AffirmationStore(affirmations: [Affirmation(text: "Keep me")]),
            scheduleStore: store, scheduler: scheduler
        )
        await coordinator.reconcileOnLaunch()
        #expect(scheduler.replaceCallCount == 0)
        #expect(scheduler.scheduledReminders.isEmpty)
        try await coordinator.setEnabled(false)
        try await coordinator.setSound(.none)
        let restarted = ScheduleStore(repository: fixture.repository, defaultSchedule: AffirmationSchedule())
        #expect(restarted.schedule == store.schedule)
        #expect(!restarted.schedule.isEnabled)
        #expect(restarted.notificationSound == .none)
        try await coordinator.setEnabled(true)
        #expect(scheduler.scheduledReminders.count == 1)
    }

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
        #expect(try fixture.repository.loadSchedule() == store.defaultSchedule)
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
        let theme = ThemeStore(repository: repository, defaultTheme: .eden, backgroundRepository: repository)
        let selection = AffirmationSelectionStore(repository: repository)
        let reminders = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())

        #expect(library.affirmations.contains(saved[0]))
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
        #expect(loaded.count == Affirmation.starterAffirmations.count + 1)
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
        try fixture.repository.saveAppData(affirmations: affirmations, schedules: [schedule], theme: .eden, selection: .favourites)
        #expect(try fixture.repository.loadAffirmations() == affirmations)
        #expect(try fixture.repository.loadSchedule() == schedule)
        #expect(try fixture.repository.loadTheme() == .eden)
        #expect(try fixture.repository.loadAffirmationSelection() == .favourites)
    }

    @Test("Removed themes decode and load as Eden without replacing the saved value", arguments: [
        "nature", "ember", "warm", "midnight", "pop", "playful", "neutral", "paper",
        "slate", "coast", "forest", "goldenHour", "afterHours", "cherry",
        "bubblegum", "daydream", "muscle", "spectrum", "together", "fruity", "refined"
    ])
    func removedThemeMigration(name: String) throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }
        let raw = try JSONEncoder().encode(name)
        fixture.userDefaults.set(raw, forKey: "gayffirmations.theme")
        #expect(try JSONDecoder().decode(AppTheme.self, from: raw) == .eden)

        let store = ThemeStore(repository: fixture.repository)
        #expect(store.selectedTheme == .eden)
        #expect(store.persistenceErrorMessage == nil)
        #expect(fixture.userDefaults.data(forKey: "gayffirmations.theme") == raw)
        try store.select(.steel)
        #expect(try fixture.repository.loadTheme() == .steel)
    }

    @Test("Persistent theme initialization preserves unreadable bytes and blocks edits",
          arguments: ["unknown-theme", "{malformed"])
    func invalidThemeInitialization(value: String) throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }
        let raw = value == "unknown-theme" ? try JSONEncoder().encode(value) : Data(value.utf8)
        fixture.userDefaults.set(raw, forKey: "gayffirmations.theme")
        let store = ThemeStore(repository: fixture.repository)
        #expect(store.selectedTheme == .eden)
        #expect(store.persistenceErrorMessage != nil)
        #expect(throws: PersistenceUnavailableError.self) { try store.select(.steel) }
        #expect(fixture.userDefaults.data(forKey: "gayffirmations.theme") == raw)
    }

    @Test("A theme can be saved and loaded")
    func themeRoundTrip() throws {
        let fixture = RepositoryFixture()
        defer { fixture.removeSavedData() }

        try fixture.repository.saveTheme(.eden)

        #expect(try fixture.repository.loadTheme() == .eden)
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
