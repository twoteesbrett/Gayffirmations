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
    func schedulingFailureDoesNotPersist() async {
        let scheduler = NotificationSchedulerSpy(
            authorizationStatus: .authorized,
            replacementError: NotificationSchedulerTestError.failed
        )
        let (coordinator, scheduleStore) = makeCoordinator(
            scheduler: scheduler,
            isEnabled: true
        )
        let originalSchedule = scheduleStore.schedule

        await #expect(throws: NotificationSchedulerTestError.failed) {
            try await coordinator.setNotificationsPerDay(6)
        }

        #expect(scheduleStore.schedule == originalSchedule)
    }

    private func makeCoordinator(
        scheduler: NotificationSchedulerSpy,
        isEnabled: Bool = false
    ) -> (NotificationCoordinator, ScheduleStore) {
        let affirmationStore = AffirmationStore(
            affirmations: [
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
private final class NotificationSchedulerSpy: NotificationScheduling {
    var authorizationStatusValue: NotificationAuthorizationStatus
    var authorizationRequestResult: Bool
    private(set) var authorizationRequestCount = 0
    private(set) var scheduledReminders: [NotificationReminder] = []
    private(set) var removeCallCount = 0
    private(set) var replaceCallCount = 0
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

private enum NotificationSchedulerTestError: Error {
    case failed
}
