import Foundation

@MainActor
final class AppDataResetCoordinator {
    private let affirmationStore: AffirmationStore
    private let scheduleStore: ScheduleStore
    private let themeStore: ThemeStore
    private let notificationCoordinator: NotificationCoordinator
    private let repository: any AppDataRepository

    init(
        affirmationStore: AffirmationStore,
        scheduleStore: ScheduleStore,
        themeStore: ThemeStore,
        notificationCoordinator: NotificationCoordinator,
        repository: any AppDataRepository
    ) {
        self.affirmationStore = affirmationStore
        self.scheduleStore = scheduleStore
        self.themeStore = themeStore
        self.notificationCoordinator = notificationCoordinator
        self.repository = repository
    }

    func resetAll() throws {
        guard !notificationCoordinator.isUpdating else {
            throw NotificationCoordinatorError.updateInProgress
        }

        let failures = [
            affirmationStore.persistenceErrorMessage,
            scheduleStore.persistenceErrorMessage,
            themeStore.persistenceErrorMessage,
            notificationCoordinator.fallbackSelectionStore.persistenceErrorMessage,
            notificationCoordinator.personalizationStore.persistenceErrorMessage
        ].compactMap { $0 }
        guard failures.isEmpty else {
            throw PersistenceUnavailableError(reason: failures.joined(separator: "\n"))
        }

        // Save every section before changing visible state or stopping reminders.
        try repository.saveAppData(
            affirmations: affirmationStore.defaultAffirmations,
            schedules: [scheduleStore.defaultSchedule],
            theme: themeStore.defaultTheme,
            selection: .all
        )
        affirmationStore.applyPersistedDefaults()
        scheduleStore.applyPersistedDefaults()
        themeStore.applyPersistedDefaults()
        notificationCoordinator.fallbackSelectionStore.applyPersistedDefaults()
        notificationCoordinator.personalizationStore.applyPersistedDefaults()
        notificationCoordinator.removePendingReminders()
    }
}
