import Foundation
import Testing
@testable import Gayffirmations

@MainActor
struct FallbackSelectionTests {
    private let body = Affirmation(text: "Body", tags: ["Body"])
    private let food = Affirmation(text: "Food", tags: ["Food"])

    @Test("Fallback changes affect Today only without deliverable reminders", arguments: [false, true])
    func fallbackDoesNotChangeDelivery(enabled: Bool) throws {
        let schedule = AffirmationSchedule(selection: .tag("Body"), isEnabled: enabled)
        let schedules = ScheduleStore(schedule: schedule)
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .notDetermined)
        let coordinator = NotificationCoordinator(
            affirmationStore: AffirmationStore(affirmations: [body, food]),
            scheduleStore: schedules, scheduler: scheduler
        )
        let previousPlan = coordinator.dailyPlan
        try coordinator.setFallbackSelection(.tag("Food"))
        let context = TodayAffirmationResolver().context(
            at: .now, schedules: schedules.schedules, affirmations: [body, food],
            fallbackSelection: coordinator.fallbackSelectionStore.selection, name: ""
        )
        #expect(context.affirmation == (enabled ? body : food))
        #expect(context.browsingAffirmations == (enabled ? [body] : [food]))
        #expect(coordinator.dailyPlan == previousPlan)
        #expect(scheduler.replaceCallCount == 0)
        #expect(scheduler.removeCallCount == 0)
        #expect(scheduler.authorizationRequestCount == 0)
    }

    @Test("Fresh installs use All; existing fallback choices survive restart")
    func defaultsAndExistingChoicesPersist() throws {
        let suite = "FallbackSelectionTests.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsRepository(userDefaults: defaults)
        let store = AffirmationSelectionStore(repository: repository)
        #expect(store.selection == .all)

        // Keep using the old selection key so upgrading preserves the fallback.
        try repository.saveAffirmationSelection(.tag("Food"))
        let restarted = AffirmationSelectionStore(repository: repository)
        #expect(restarted.selection == .tag("Food"))
        let context = TodayAffirmationResolver().context(
            at: .now, schedules: [], affirmations: [body, food],
            fallbackSelection: restarted.selection, name: ""
        )
        #expect(context.affirmation == food)
    }

    @Test("Clearing the fallback choices returns to All and persists")
    func clearingChoicesReturnsToAll() throws {
        let suite = "FallbackSelectionTests.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsRepository(userDefaults: defaults)
        let coordinator = NotificationCoordinator(
            affirmationStore: AffirmationStore(affirmations: [body, food]),
            scheduleStore: ScheduleStore(), scheduler: NotificationSchedulerSpy(authorizationStatus: .notDetermined),
            fallbackSelectionStore: AffirmationSelectionStore(repository: repository)
        )
        try coordinator.setFallbackSelection(.tag("Food"))
        try coordinator.setFallbackSelection(.sources(favourites: false, tags: []))
        #expect(coordinator.fallbackSelectionStore.selection == .all)
        #expect(AffirmationSelectionStore(repository: repository).selection == .all)
    }
}
