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

    var unreadableSections: [String] {
        [
            affirmationStore.persistenceErrorMessage.map { _ in "Affirmations" },
            scheduleStore.persistenceErrorMessage.map { _ in "Schedules and sound" },
            themeStore.persistenceErrorMessage.map { _ in "Theme and backgrounds" },
            notificationCoordinator.fallbackSelectionStore.persistenceErrorMessage.map { _ in "Today fallback" },
            notificationCoordinator.personalizationStore.persistenceErrorMessage.map { _ in "Name" }
        ].compactMap { $0 }
    }

    // Only the explicitly confirmed Reset All action bypasses load-error guards.
    func resetAll() throws {
        guard !notificationCoordinator.isUpdating else {
            throw NotificationCoordinatorError.updateInProgress
        }

        // Save every section before changing visible state or stopping reminders.
        try repository.saveAppData(
            affirmations: affirmationStore.defaultAffirmations,
            schedules: [scheduleStore.defaultSchedule],
            theme: themeStore.defaultTheme,
            selection: .all,
            preservingExistingData: !unreadableSections.isEmpty
        )
        affirmationStore.applyPersistedDefaults()
        scheduleStore.applyPersistedDefaults()
        themeStore.applyPersistedDefaults()
        notificationCoordinator.fallbackSelectionStore.applyPersistedDefaults()
        notificationCoordinator.personalizationStore.applyPersistedDefaults()
        notificationCoordinator.removePendingReminders()
    }
}
