import Foundation
import Testing
@testable import Gayffirmations

@MainActor
struct AppDataResetCoordinatorTests {
    @Test("Corruption is protected until confirmed recovery, including failed recovery and relaunch",
          arguments: ["affirmations", "schedules", "schedule", "notificationSound", "theme",
                      "themeBackgrounds", "affirmationSelection", "name"], [false, true])
    func recoveryAcrossSections(section: String, wrongType: Bool) throws {
        let suite = "ResetRecoveryTests.\(UUID())"
        let preferences = try #require(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsRepository(userDefaults: preferences)
        let bundled = [Affirmation(text: "Default", source: .bundled)]
        try repository.saveAffirmations([Affirmation(text: "Personal", isFavorite: true)])
        try repository.saveSchedules([AffirmationSchedule(isEnabled: true)])
        try repository.saveNotificationSound(.none)
        try repository.saveTheme(.steel)
        try repository.saveThemeBackgrounds(["steel": ThemeBackgroundChoice(usesPhoto: false)])
        try repository.saveAffirmationSelection(.favourites)
        try repository.saveName("Saved name")
        let key = "gayffirmations.\(section)"
        if section == "schedule" { preferences.removeObject(forKey: "gayffirmations.schedules") }
        if wrongType {
            preferences.set("unexpected value", forKey: key)
        } else {
            preferences.set(Data("invalid JSON".utf8), forKey: key)
        }
        let beforeLoad = try #require(preferences.persistentDomain(forName: suite))
        let library = AffirmationStore(repository: repository, defaultAffirmations: bundled)
        let schedules = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())
        let theme = ThemeStore(repository: repository, defaultTheme: .eden, backgroundRepository: repository)
        let selection = AffirmationSelectionStore(repository: repository)
        let name = PersonalizationStore(repository: repository)
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(
            affirmationStore: library, scheduleStore: schedules, scheduler: scheduler,
            fallbackSelectionStore: selection, personalizationStore: name
        )
        let reset = AppDataResetCoordinator(affirmationStore: library, scheduleStore: schedules,
                                           themeStore: theme, notificationCoordinator: coordinator,
                                           repository: repository)
        #expect(!reset.unreadableSections.isEmpty)
        switch section {
        case "affirmations":
            #expect(throws: PersistenceUnavailableError.self) { try library.add(text: "Blocked") }
        case "schedules", "schedule", "notificationSound":
            #expect(throws: PersistenceUnavailableError.self) { try schedules.reset() }
        case "theme", "themeBackgrounds":
            #expect(throws: PersistenceUnavailableError.self) { try theme.select(.disco) }
        case "affirmationSelection":
            #expect(throws: PersistenceUnavailableError.self) { try selection.select(.all) }
        default:
            #expect(throws: PersistenceUnavailableError.self) { try name.setName("Blocked") }
        }
        #expect(NSDictionary(dictionary: beforeLoad).isEqual(to: preferences.persistentDomain(forName: suite)!))
        let originalLibrary = library.affirmations
        let originalSchedules = schedules.schedules
        let originalTheme = theme.selectedTheme
        let originalSections = reset.unreadableSections
        let failedRepository = UserDefaultsRepository(userDefaults: preferences, encoder: RecoveryFailingEncoder())
        let failedReset = AppDataResetCoordinator(affirmationStore: library, scheduleStore: schedules,
                                                 themeStore: theme, notificationCoordinator: coordinator,
                                                 repository: failedRepository)
        #expect(throws: RecoveryEncodingError.failed) { try failedReset.resetAll() }
        #expect(NSDictionary(dictionary: beforeLoad).isEqual(to: preferences.persistentDomain(forName: suite)!))
        #expect(library.affirmations == originalLibrary)
        #expect(schedules.schedules == originalSchedules)
        #expect(theme.selectedTheme == originalTheme)
        #expect(reset.unreadableSections == originalSections)
        #expect(scheduler.removeCallCount == 0)
        try reset.resetAll()
        #expect(reset.unreadableSections.isEmpty)
        #expect(library.affirmations == bundled)
        #expect(schedules.schedules == [schedules.defaultSchedule])
        #expect(schedules.notificationSound == .systemDefault)
        #expect(theme.selectedTheme == .eden)
        #expect(theme.backgrounds.isEmpty)
        #expect(selection.selection == .all)
        #expect(name.name.isEmpty)
        let backups = try #require(preferences.array(forKey: "gayffirmations.recoveryBackups") as? [[String: Any]])
        #expect(backups.count == 1)
        let values = try #require(backups[0]["values"] as? [String: Any])
        #expect(NSDictionary(dictionary: beforeLoad).isEqual(to: values))

        // New store instances exercise the persistent loading paths after repair.
        let reloadedLibrary = AffirmationStore(repository: repository, defaultAffirmations: bundled)
        let reloadedSchedules = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())
        let reloadedTheme = ThemeStore(repository: repository, defaultTheme: .eden, backgroundRepository: repository)
        #expect(reloadedLibrary.affirmations == bundled)
        #expect(reloadedLibrary.persistenceErrorMessage == nil)
        #expect(reloadedSchedules.schedules == [schedules.defaultSchedule])
        #expect(reloadedSchedules.persistenceErrorMessage == nil)
        #expect(reloadedTheme.selectedTheme == .eden)
        #expect(reloadedTheme.persistenceErrorMessage == nil)
        #expect(AffirmationSelectionStore(repository: repository).persistenceErrorMessage == nil)
        #expect(PersonalizationStore(repository: repository).persistenceErrorMessage == nil)
        try reset.resetAll()
        #expect(preferences.object(forKey: "gayffirmations.recoveryBackups") == nil)
        // Load-error guards must also clear for edits in this same session.
        try library.add(text: "After recovery")
        try schedules.setNotificationSound(.magicMarimba)
        try theme.select(.disco)
        try selection.select(.favourites)
        try name.setName("After recovery")
    }

    @Test("Reset all publishes defaults only after the complete save succeeds")
    func resetAllIsAllOrNothing() async throws {
        let repository = ResetRepositorySpy()
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let defaults = [Affirmation(text: "Default")]
        let library = AffirmationStore(affirmations: defaults)
        let schedule = ScheduleStore()
        let theme = ThemeStore()
        let coordinator = NotificationCoordinator(
            affirmationStore: library, scheduleStore: schedule, scheduler: scheduler
        )
        let resetCoordinator = AppDataResetCoordinator(
            affirmationStore: library,
            scheduleStore: schedule,
            themeStore: theme,
            notificationCoordinator: coordinator,
            repository: repository
        )
        try library.add(text: "Custom")
        try theme.select(.steel)
        try await coordinator.setEnabled(true)
        try await coordinator.setSound(.choirHarpBless)
        try coordinator.setFallbackSelection(.tag("Work"))
        let originalLibrary = library.affirmations
        let originalSchedule = schedule.schedule
        let originalReminders = scheduler.scheduledReminders
        repository.shouldFail = true
        #expect(throws: NotificationSchedulerTestError.self) {
            try resetCoordinator.resetAll()
        }
        #expect(library.affirmations == originalLibrary)
        #expect(schedule.schedule == originalSchedule)
        #expect(theme.selectedTheme == .steel)
        #expect(coordinator.fallbackSelectionStore.selection == .tag("Work"))
        #expect(scheduler.scheduledReminders == originalReminders)
        repository.shouldFail = false
        try resetCoordinator.resetAll()
        #expect(library.affirmations == defaults)
        #expect(schedule.schedule == schedule.defaultSchedule)
        #expect(theme.selectedTheme == .eden)
        #expect(coordinator.fallbackSelectionStore.selection == .all)
        #expect(scheduler.scheduledReminders.isEmpty)
        #expect(repository.didSave)
    }

    @Test("Reset all survives reloading every store")
    func resetAllSurvivesRestart() async throws {
        let suiteName = "ResetAllTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let repository = UserDefaultsRepository(userDefaults: userDefaults)
        let defaults = [Affirmation(text: "Default")]
        let library = AffirmationStore(repository: repository, defaultAffirmations: defaults)
        let schedule = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())
        let theme = ThemeStore(repository: repository, defaultTheme: .eden)
        let coordinator = NotificationCoordinator(
            affirmationStore: library, scheduleStore: schedule,
            scheduler: NotificationSchedulerSpy(authorizationStatus: .authorized),
            fallbackSelectionStore: AffirmationSelectionStore(repository: repository)
        )
        let resetCoordinator = AppDataResetCoordinator(
            affirmationStore: library,
            scheduleStore: schedule,
            themeStore: theme,
            notificationCoordinator: coordinator,
            repository: repository
        )
        try library.add(text: "Custom")
        try theme.select(.steel)
        try await coordinator.setEnabled(true)
        try coordinator.setFallbackSelection(.favourites)
        try resetCoordinator.resetAll()
        #expect(try repository.loadAffirmationSelection() == .all)
        #expect(try repository.loadAffirmations() == defaults)
        #expect(try repository.loadSchedule() == schedule.defaultSchedule)
        #expect(try repository.loadTheme() == .eden)
    }

    @Test("Confirmed reset repairs a corrupt section and keeps its original bytes in a backup")
    func corruptSectionCanBeReset() throws {
        let suiteName = "ResetAllTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let repository = UserDefaultsRepository(userDefaults: userDefaults)
        let custom = [Affirmation(text: "Custom")]
        try repository.saveAffirmations(custom)
        try repository.saveTheme(.eden)
        let corruptData = Data("invalid JSON".utf8)
        userDefaults.set(corruptData, forKey: "gayffirmations.schedule")
        let library = AffirmationStore(repository: repository, defaultAffirmations: [])
        let schedule = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())
        let theme = ThemeStore(repository: repository, defaultTheme: .eden)
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(
            affirmationStore: library, scheduleStore: schedule, scheduler: scheduler
        )
        let resetCoordinator = AppDataResetCoordinator(
            affirmationStore: library,
            scheduleStore: schedule,
            themeStore: theme,
            notificationCoordinator: coordinator,
            repository: repository
        )
        #expect(schedule.persistenceErrorMessage != nil)
        #expect(throws: PersistenceUnavailableError.self) { try schedule.reset() }
        #expect(userDefaults.data(forKey: "gayffirmations.schedule") == corruptData)
        try resetCoordinator.resetAll()
        #expect(try repository.loadAffirmations() == [])
        #expect(try repository.loadTheme() == .eden)
        #expect(userDefaults.data(forKey: "gayffirmations.schedule") == nil)
        #expect(schedule.persistenceErrorMessage == nil)
        let backups = try #require(userDefaults.array(forKey: "gayffirmations.recoveryBackups") as? [[String: Any]])
        let values = try #require(backups.first?["values"] as? [String: Any])
        #expect(values["gayffirmations.schedule"] as? Data == corruptData)
        #expect(scheduler.removeCallCount == 1)
    }
}

private final class ResetRepositorySpy: AppDataRepository {
    var shouldFail = false
    var didSave = false

    func saveAppData(affirmations: [Affirmation], schedules: [AffirmationSchedule], theme: AppTheme, selection: AffirmationSelection, preservingExistingData: Bool) throws {
        if shouldFail { throw NotificationSchedulerTestError.failed }
        didSave = true
    }
}

private enum RecoveryEncodingError: Error { case failed }

private final class RecoveryFailingEncoder: JSONEncoder, @unchecked Sendable {
    override func encode<T: Encodable>(_ value: T) throws -> Data {
        // Fail after two encodings to prove no backup or reset write happened early.
        if value is AppTheme { throw RecoveryEncodingError.failed }
        return try super.encode(value)
    }
}
