import Foundation
import Testing
@testable import Gayffirmations

@MainActor
struct AppDataResetCoordinatorTests {
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
        try theme.select(.nature)
        try await coordinator.setEnabled(true)
        try await coordinator.setSound(.choirHarpBless)
        try await coordinator.setSelection(.tag("Work"))
        let originalLibrary = library.affirmations
        let originalSchedule = schedule.schedule
        let originalReminders = scheduler.scheduledReminders
        repository.shouldFail = true
        #expect(throws: NotificationSchedulerTestError.self) {
            try resetCoordinator.resetAll()
        }
        #expect(library.affirmations == originalLibrary)
        #expect(schedule.schedule == originalSchedule)
        #expect(theme.selectedTheme == .nature)
        #expect(coordinator.selectionStore.selection == .tag("Work"))
        #expect(scheduler.scheduledReminders == originalReminders)
        repository.shouldFail = false
        try resetCoordinator.resetAll()
        #expect(library.affirmations == defaults)
        #expect(schedule.schedule == AffirmationSchedule())
        #expect(theme.selectedTheme == .nature)
        #expect(coordinator.selectionStore.selection == .all)
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
        let theme = ThemeStore(repository: repository, defaultTheme: .nature)
        let coordinator = NotificationCoordinator(
            affirmationStore: library, scheduleStore: schedule,
            scheduler: NotificationSchedulerSpy(authorizationStatus: .authorized),
            selectionStore: AffirmationSelectionStore(repository: repository)
        )
        let resetCoordinator = AppDataResetCoordinator(
            affirmationStore: library,
            scheduleStore: schedule,
            themeStore: theme,
            notificationCoordinator: coordinator,
            repository: repository
        )
        try library.add(text: "Custom")
        try theme.select(.nature)
        try await coordinator.setEnabled(true)
        try await coordinator.setSelection(.favourites)
        try resetCoordinator.resetAll()
        #expect(try repository.loadAffirmationSelection() == .all)
        #expect(try repository.loadAffirmations() == defaults)
        #expect(try repository.loadSchedule() == AffirmationSchedule())
        #expect(try repository.loadTheme() == .nature)
    }

    @Test("A corrupt section blocks reset all without altering healthy sections")
    func corruptSectionBlocksResetAll() throws {
        let suiteName = "ResetAllTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let repository = UserDefaultsRepository(userDefaults: userDefaults)
        let custom = [Affirmation(text: "Custom")]
        try repository.saveAffirmations(custom)
        try repository.saveTheme(.nature)
        let corruptData = Data("invalid JSON".utf8)
        userDefaults.set(corruptData, forKey: "gayffirmations.schedule")
        let library = AffirmationStore(repository: repository, defaultAffirmations: [])
        let schedule = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())
        let theme = ThemeStore(repository: repository, defaultTheme: .nature)
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
        #expect(throws: PersistenceUnavailableError.self) {
            try resetCoordinator.resetAll()
        }
        #expect(try repository.loadAffirmations() == custom)
        #expect(try repository.loadTheme() == .nature)
        #expect(userDefaults.data(forKey: "gayffirmations.schedule") == corruptData)
        #expect(scheduler.removeCallCount == 0)
    }
}

private final class ResetRepositorySpy: AppDataRepository {
    var shouldFail = false
    var didSave = false

    func saveAppData(affirmations: [Affirmation], schedule: AffirmationSchedule, theme: AppTheme, selection: AffirmationSelection) throws {
        if shouldFail { throw NotificationSchedulerTestError.failed }
        didSave = true
    }
}
