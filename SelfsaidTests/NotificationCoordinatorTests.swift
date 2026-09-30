import Foundation
import Testing
@testable import Selfsaid

@MainActor
struct NotificationCoordinatorTests {
    @Test("Enabling requests undecided permission and schedules reminders")
    func enableRequestsPermissionAndSchedules() async throws {
        let scheduler = NotificationSchedulerSpy(
            authorizationStatus: .notDetermined,
            authorizationRequestResult: true
        )
        let (coordinator, scheduleStore) = makeCoordinator(scheduler: scheduler)

        try await coordinator.setEnabled(true)

        #expect(scheduler.authorizationRequestCount == 1)
        #expect(scheduler.scheduledReminders.count == 2)
        #expect(scheduleStore.schedule.isEnabled)
    }

    @Test("Existing permission is not requested again")
    func existingPermissionIsNotRequestedAgain() async throws {
        let scheduler = NotificationSchedulerSpy(
            authorizationStatus: .authorized
        )
        let (coordinator, _) = makeCoordinator(scheduler: scheduler)

        try await coordinator.setEnabled(true)

        #expect(scheduler.authorizationRequestCount == 0)
        #expect(scheduler.scheduledReminders.count == 2)
    }

    @Test("Denied permission leaves reminders disabled")
    func deniedPermissionLeavesRemindersDisabled() async {
        let scheduler = NotificationSchedulerSpy(
            authorizationStatus: .denied
        )
        let (coordinator, scheduleStore) = makeCoordinator(scheduler: scheduler)

        await #expect(throws: NotificationCoordinatorError.permissionDenied) {
            try await coordinator.setEnabled(true)
        }

        #expect(scheduler.scheduledReminders.isEmpty)
        #expect(!scheduleStore.schedule.isEnabled)
    }

    @Test("An empty affirmation library cannot enable reminders")
    func emptyLibraryLeavesRemindersDisabled() async {
        let scheduler = NotificationSchedulerSpy(
            authorizationStatus: .authorized
        )
        let (coordinator, scheduleStore) = makeCoordinator(
            scheduler: scheduler,
            affirmations: []
        )

        await #expect(throws: NotificationPlannerError.noAffirmations) {
            try await coordinator.setEnabled(true)
        }

        #expect(scheduler.replaceCallCount == 0)
        #expect(!scheduleStore.schedule.isEnabled)
    }

    @Test("Disabling removes pending reminders")
    func disablingRemovesPendingReminders() async throws {
        let scheduler = NotificationSchedulerSpy(
            authorizationStatus: .authorized
        )
        let (coordinator, scheduleStore) = makeCoordinator(
            scheduler: scheduler,
            isEnabled: true
        )

        try await coordinator.setEnabled(false)

        #expect(!scheduleStore.schedule.isEnabled)
        #expect(scheduler.removeCallCount == 1)
    }

    @Test("Resetting restores the default schedule and removes reminders")
    func resettingScheduleRemovesPendingReminders() throws {
        let scheduler = NotificationSchedulerSpy(
            authorizationStatus: .authorized
        )
        let affirmationStore = AffirmationStore(
            affirmations: [Affirmation(text: "One")]
        )
        let defaultSchedule = AffirmationSchedule()
        let repository = NotificationTestScheduleRepository()
        let scheduleStore = ScheduleStore(
            repository: repository,
            defaultSchedule: defaultSchedule
        )
        try scheduleStore.setEnabled(true)
        let coordinator = NotificationCoordinator(
            affirmationStore: affirmationStore,
            scheduleStore: scheduleStore,
            scheduler: scheduler
        )

        try coordinator.resetSchedule()

        #expect(scheduleStore.schedule == defaultSchedule)
        #expect(repository.schedule == defaultSchedule)
        #expect(scheduler.removeCallCount == 1)
    }

    @Test("Changing an enabled schedule replaces pending reminders")
    func enabledScheduleChangeReplacesReminders() async throws {
        let scheduler = NotificationSchedulerSpy(
            authorizationStatus: .authorized
        )
        let (coordinator, scheduleStore) = makeCoordinator(
            scheduler: scheduler,
            isEnabled: true
        )

        try await coordinator.setStartTime(TimeOfDay(hour: 8, minute: 0))
        try await coordinator.setNotificationsPerDay(3)

        #expect(scheduleStore.schedule.startTime == TimeOfDay(hour: 8, minute: 0))
        #expect(scheduleStore.schedule.notificationsPerDay == 3)
        #expect(scheduler.replaceCallCount == 2)
        #expect(scheduler.scheduledReminders.count == 3)
    }

    @Test("Changing a disabled schedule does not schedule reminders")
    func disabledScheduleChangeOnlyPersists() async throws {
        let scheduler = NotificationSchedulerSpy(
            authorizationStatus: .authorized
        )
        let (coordinator, scheduleStore) = makeCoordinator(scheduler: scheduler)

        try await coordinator.setEndTime(TimeOfDay(hour: 19, minute: 0))

        #expect(scheduleStore.schedule.endTime == TimeOfDay(hour: 19, minute: 0))
        #expect(scheduler.replaceCallCount == 0)
    }

    @Test("A scheduling failure does not save the changed schedule")
    func schedulingFailureDoesNotPersist() async throws {
        let scheduler = NotificationSchedulerSpy(
            authorizationStatus: .authorized
        )
        let (coordinator, scheduleStore) = makeCoordinator(
            scheduler: scheduler,
            isEnabled: true
        )
        try await coordinator.setEnabled(true)
        let originalReminders = scheduler.scheduledReminders
        scheduler.failuresRemaining = 1
        let originalSchedule = scheduleStore.schedule

        await #expect(throws: NotificationSchedulerTestError.failed) {
            try await coordinator.setNotificationsPerDay(6)
        }

        #expect(scheduleStore.schedule == originalSchedule)
        #expect(scheduler.scheduledReminders == originalReminders)
    }

    @Test("Library edits, deletions, and restores refresh reminder text")
    func libraryChangesRefreshReminders() async throws {
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let defaults = [Affirmation(text: "Default")]
        let library = AffirmationStore(affirmations: defaults)
        let schedule = ScheduleStore()
        let coordinator = NotificationCoordinator(
            affirmationStore: library, scheduleStore: schedule, scheduler: scheduler
        )
        try await coordinator.setEnabled(true)
        try library.update(id: defaults[0].id, text: "Edited")
        #expect(scheduler.scheduledReminders.isEmpty)
        await coordinator.waitForLibraryRefresh()
        #expect(scheduler.scheduledReminders.allSatisfy { $0.affirmationText == "Edited" })
        try library.add(text: "Added")
        await coordinator.waitForLibraryRefresh()
        #expect(scheduler.scheduledReminders.contains { $0.affirmationText == "Added" })
        try library.restoreDefaults()
        await coordinator.waitForLibraryRefresh()
        #expect(scheduler.scheduledReminders.allSatisfy { $0.affirmationText == "Default" })
        try library.delete(id: defaults[0].id)
        await coordinator.waitForLibraryRefresh()
        #expect(scheduler.scheduledReminders.isEmpty)
        #expect(!schedule.schedule.isEnabled)
    }

    @Test("Failed recovery stops reminders and disables the saved schedule")
    func failedRecoveryDisablesReminders() async throws {
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let (coordinator, schedule) = makeCoordinator(scheduler: scheduler)
        try await coordinator.setEnabled(true)
        scheduler.replacementError = NotificationSchedulerTestError.failed
        await #expect(throws: NotificationCoordinatorError.self) {
            try await coordinator.setNotificationsPerDay(6)
        }
        #expect(!schedule.schedule.isEnabled)
        #expect(scheduler.scheduledReminders.isEmpty)
    }

    @Test("A library refresh failure is visible and stops reminders")
    func libraryRefreshFailureIsVisible() async throws {
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let library = AffirmationStore(affirmations: [Affirmation(text: "Original")])
        let schedule = ScheduleStore()
        let coordinator = NotificationCoordinator(
            affirmationStore: library, scheduleStore: schedule, scheduler: scheduler
        )
        try await coordinator.setEnabled(true)
        scheduler.replacementError = NotificationSchedulerTestError.failed
        try library.update(id: library.affirmations[0].id, text: "Edited")
        await coordinator.waitForLibraryRefresh()
        #expect(coordinator.errorMessage != nil)
        #expect(!schedule.schedule.isEnabled)
        #expect(scheduler.scheduledReminders.isEmpty)
    }

    @Test("Overlapping library and reset changes are rejected during a refresh")
    func overlappingChangesAreRejected() async throws {
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let library = AffirmationStore(affirmations: [Affirmation(text: "Original")])
        let schedule = ScheduleStore()
        let coordinator = NotificationCoordinator(
            affirmationStore: library, scheduleStore: schedule, scheduler: scheduler
        )
        try await coordinator.setEnabled(true)
        try library.add(text: "Added")
        #expect(throws: NotificationCoordinatorError.updateInProgress) {
            try library.restoreDefaults()
        }
        #expect(throws: NotificationCoordinatorError.updateInProgress) {
            try coordinator.resetSchedule()
        }
        await coordinator.waitForLibraryRefresh()
        #expect(!coordinator.isUpdating)
    }

    private func makeCoordinator(
        scheduler: NotificationSchedulerSpy,
        isEnabled: Bool = false,
        affirmations: [Affirmation]? = nil
    ) -> (NotificationCoordinator, ScheduleStore) {
        let affirmationStore = AffirmationStore(
            affirmations: affirmations ?? [
                Affirmation(text: "One"),
                Affirmation(text: "Two")
            ]
        )
        let scheduleStore = ScheduleStore(
            schedule: AffirmationSchedule(
                isEnabled: isEnabled,
                startTime: TimeOfDay(hour: 9, minute: 0),
                endTime: TimeOfDay(hour: 17, minute: 0),
                notificationsPerDay: 2
            )
        )
        let coordinator = NotificationCoordinator(
            affirmationStore: affirmationStore,
            scheduleStore: scheduleStore,
            scheduler: scheduler
        )

        return (coordinator, scheduleStore)
    }
}

@MainActor
final class NotificationSchedulerSpy: NotificationScheduling {
    var authorizationStatusValue: NotificationAuthorizationStatus
    var authorizationRequestResult: Bool
    private(set) var authorizationRequestCount = 0
    private(set) var scheduledReminders: [NotificationReminder] = []
    private(set) var removeCallCount = 0
    private(set) var replaceCallCount = 0
    var failuresRemaining = 0
    var replacementError: (any Error)?

    init(
        authorizationStatus: NotificationAuthorizationStatus,
        authorizationRequestResult: Bool = false,
        replacementError: (any Error)? = nil
    ) {
        authorizationStatusValue = authorizationStatus
        self.authorizationRequestResult = authorizationRequestResult
        self.replacementError = replacementError
    }

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        authorizationStatusValue
    }

    func requestAuthorization() async throws -> Bool {
        authorizationRequestCount += 1
        return authorizationRequestResult
    }

    func replacePendingNotifications(
        with reminders: [NotificationReminder]
    ) async throws {
        replaceCallCount += 1

        scheduledReminders = []
        if failuresRemaining > 0 {
            failuresRemaining -= 1
            throw NotificationSchedulerTestError.failed
        }
        if let replacementError {
            throw replacementError
        }

        scheduledReminders = reminders
    }

    func removePendingNotifications() {
        removeCallCount += 1
        scheduledReminders = []
    }
}

enum NotificationSchedulerTestError: Error {
    case failed
}

private final class NotificationTestScheduleRepository: ScheduleRepository {
    var schedule: AffirmationSchedule?

    func loadSchedule() throws -> AffirmationSchedule? {
        schedule
    }

    func saveSchedule(_ schedule: AffirmationSchedule) throws {
        self.schedule = schedule
    }
}
