import Foundation

/// Creates the shared stores and wires their persistence and reminder services.
@MainActor
final class AppDependencies {
    let affirmationStore: AffirmationStore
    let scheduleStore: ScheduleStore
    let themeStore: ThemeStore
    let notificationCoordinator: NotificationCoordinator
    let resetCoordinator: AppDataResetCoordinator

    init() {
        let repository = UserDefaultsRepository(initialAffirmations: Affirmation.starterAffirmations)
        let affirmationStore = AffirmationStore(
            repository: repository,
            defaultAffirmations: Affirmation.starterAffirmations
        )
        let scheduleStore = ScheduleStore(
            repository: repository,
            defaultSchedule: AffirmationSchedule()
        )
        let themeStore = ThemeStore(
            repository: repository,
            defaultTheme: .nature,
            backgroundRepository: repository
        )

        self.affirmationStore = affirmationStore
        self.scheduleStore = scheduleStore
        self.themeStore = themeStore
        let notificationCoordinator = NotificationCoordinator(
            affirmationStore: affirmationStore,
            scheduleStore: scheduleStore,
            scheduler: LocalNotificationService(),
            selectionStore: AffirmationSelectionStore(repository: repository),
            personalizationStore: PersonalizationStore(repository: repository)
        )
        self.notificationCoordinator = notificationCoordinator
        resetCoordinator = AppDataResetCoordinator(
            affirmationStore: affirmationStore,
            scheduleStore: scheduleStore,
            themeStore: themeStore,
            notificationCoordinator: notificationCoordinator,
            repository: repository
        )
    }
}
