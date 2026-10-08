import Foundation
import Testing
@testable import Gayffirmations

@MainActor
struct NotificationCoordinatorTests {
    @Test("Rhythm changes preserve the daily count and recover on failure")
    func rhythmChangesAndRecovery() async throws {
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let (coordinator, store) = makeCoordinator(scheduler: scheduler)
        try await coordinator.setEnabled(true)
        let original = scheduler.scheduledReminders
        try await coordinator.setRhythm(.moreLate)
        try await coordinator.setEmphasis(.strong)
        #expect(store.schedule.notificationsPerDay == original.count)
        #expect(scheduler.scheduledReminders.count == original.count)
        #expect(scheduler.scheduledReminders.map(\.time)
                == (try ScheduleCalculator().notificationTimes(for: store.schedule)))
        #expect(scheduler.scheduledReminders != original)
        let saved = store.schedule
        let reminders = scheduler.scheduledReminders
        scheduler.failuresRemaining = 1
        await #expect(throws: NotificationSchedulerTestError.self) {
            try await coordinator.setRhythm(.moreEarly)
        }
        #expect(store.schedule == saved)
        #expect(scheduler.scheduledReminders == reminders)
        #expect(!coordinator.isUpdating)
    }

    @Test("Disabled rhythm changes save without scheduling notifications")
    func disabledRhythmChanges() async throws {
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let (coordinator, store) = makeCoordinator(scheduler: scheduler)
        try await coordinator.setRhythm(.moreEarly)
        try await coordinator.setEmphasis(.gentle)
        #expect(store.schedule.rhythm == .moreEarly)
        #expect(store.schedule.emphasis == .gentle)
        #expect(scheduler.replaceCallCount == 0)
        #expect(scheduler.authorizationRequestCount == 0)
    }

    @Test("Invalid clustering preserves an enabled schedule and its pending reminders")
    func invalidEmphasisPreservesDelivery() async throws {
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let (coordinator, store) = makeCoordinator(scheduler: scheduler)
        try await coordinator.setEndTime(TimeOfDay(hour: 9, minute: 5))
        try await coordinator.setNotificationsPerDay(5)
        try await coordinator.setRhythm(.moreLate)
        try await coordinator.setEmphasis(.gentle)
        try await coordinator.setEnabled(true)
        let previousSchedule = store.schedule
        let previousReminders = scheduler.scheduledReminders
        let previousReplacements = scheduler.replaceCallCount
        await #expect(throws: ScheduleCalculatorError.remindersTooClose) {
            try await coordinator.setEmphasis(.strong)
        }
        #expect(store.schedule == previousSchedule)
        #expect(scheduler.scheduledReminders == previousReminders)
        #expect(scheduler.replaceCallCount == previousReplacements)
    }

    @Test("Opening Library preserves the shared coordinator and its reminder hooks")
    func libraryUsesSharedCoordinator() async throws {
        let entry = Affirmation(text: "Selected", tags: ["confidence"])
        let library = AffirmationStore(affirmations: [entry, Affirmation(text: "Other")])
        let schedule = ScheduleStore()
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(
            affirmationStore: library, scheduleStore: schedule, scheduler: scheduler
        )
        try await coordinator.setScheduleSelection(.tag("confidence"))
        try await coordinator.setEnabled(true)

        _ = LibraryView(store: library, notificationCoordinator: coordinator)
        try library.update(id: entry.id, text: "Edited", tags: entry.tags)
        await coordinator.waitForLibraryRefresh()
        #expect(scheduler.scheduledReminders.allSatisfy { $0.affirmationText == "Edited" })
        #expect(!scheduler.scheduledReminders.isEmpty)

        try library.update(id: entry.id, text: "Edited", tags: [])
        await coordinator.waitForLibraryRefresh()
        #expect(coordinator.firstScheduleAffirmations.isEmpty)
        #expect(coordinator.deliveryIsPaused)
        #expect(scheduler.scheduledReminders.isEmpty)
    }

    @Test("An unreadable schedule does not block saving a healthy Today selection")
    func corruptScheduleAllowsSelectionChanges() async throws {
        let suiteName = "DeliveryRecoveryTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let corruptData = Data("invalid".utf8)
        defaults.set(corruptData, forKey: "gayffirmations.schedule")
        let repository = UserDefaultsRepository(userDefaults: defaults)
        let selection = AffirmationSelectionStore(repository: repository)
        let favourite = Affirmation(text: "Favourite", isFavorite: true)
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(
            affirmationStore: AffirmationStore(affirmations: [favourite, Affirmation(text: "Other")]),
            scheduleStore: ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule()),
            scheduler: scheduler, selectionStore: selection
        )

        try await coordinator.setSelection(.favourites)

        #expect(selection.selection == .favourites)
        #expect(coordinator.selectedAffirmations == [favourite])
        #expect(try repository.loadAffirmationSelection() == .favourites)
        #expect(defaults.data(forKey: "gayffirmations.schedule") == corruptData)
        #expect(scheduler.replaceCallCount == 0)
    }

    @Test("Library edits still refresh independent schedules after a failed browsing selection load")
    func corruptSelectionPreservesScheduleDuringLibraryEdit() async throws {
        let suiteName = "DeliveryRecoveryTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let repository = UserDefaultsRepository(userDefaults: defaults)
        let corruptData = Data("invalid".utf8)
        defaults.set(corruptData, forKey: "gayffirmations.affirmationSelection")
        let originalSchedule = AffirmationSchedule(isEnabled: true)
        try repository.saveSchedule(originalSchedule)
        let schedule = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())
        let library = AffirmationStore(affirmations: [Affirmation(text: "One")])
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(
            affirmationStore: library, scheduleStore: schedule, scheduler: scheduler,
            selectionStore: AffirmationSelectionStore(repository: repository)
        )
        await coordinator.reconcileOnLaunch()
        try library.add(text: "Two")
        await coordinator.waitForLibraryRefresh()

        #expect(schedule.schedule == originalSchedule)
        #expect(try repository.loadSchedule() == originalSchedule)
        #expect(defaults.data(forKey: "gayffirmations.affirmationSelection") == corruptData)
        #expect(scheduler.scheduledReminders.count == 4)
        #expect(scheduler.replaceCallCount == 2)
        #expect(coordinator.errorMessage == nil)
    }

    @Test("Combined delivery uses both sources and removing one preserves the other")
    func combinedDelivery() async throws {
        let favourite = Affirmation(text: "Favourite", isFavorite: true)
        let tagged = Affirmation(text: "Tagged", tags: ["Confidence"])
        let library = AffirmationStore(affirmations: [favourite, tagged, Affirmation(text: "Other")])
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(
            affirmationStore: library, scheduleStore: ScheduleStore(), scheduler: scheduler
        )
        try await coordinator.setScheduleSelection(.sources(favourites: true, tags: ["Confidence"]))
        try await coordinator.setEnabled(true)
        #expect(coordinator.firstScheduleAffirmations == [favourite, tagged])
        #expect(Set(scheduler.scheduledReminders.map(\.affirmationText)) == ["Favourite", "Tagged"])
        try library.toggleFavorite(id: favourite.id)
        await coordinator.waitForLibraryRefresh()
        #expect(!coordinator.deliveryIsPaused)
        #expect(coordinator.firstScheduleAffirmations == [tagged])
        #expect(scheduler.scheduledReminders.allSatisfy { $0.affirmationText == "Tagged" })
    }

    @Test("A failed source save restores delivery from the previous saved selection")
    func sourceSaveFailureRestoresDelivery() async throws {
        let repository = DeliverySelectionRepository()
        let library = AffirmationStore(affirmations: [
            Affirmation(text: "Favourite", isFavorite: true), Affirmation(text: "Other")
        ])
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(
            affirmationStore: library, scheduleStore: ScheduleStore(), scheduler: scheduler,
            selectionStore: AffirmationSelectionStore(repository: repository)
        )
        try await coordinator.setEnabled(true)
        let previous = scheduler.scheduledReminders
        repository.failSaves = true
        await #expect(throws: NotificationSchedulerTestError.self) {
            try await coordinator.setSelection(.favourites)
        }
        #expect(coordinator.selectionStore.selection == .all)
        #expect(repository.selection == .all)
        #expect(scheduler.scheduledReminders == previous)
    }

    @Test("Unreadable browsing selection does not block independent schedule delivery")
    func unreadableSourceDoesNotBlockDelivery() async throws {
        let repository = DeliverySelectionRepository()
        repository.failLoads = true
        let schedule = ScheduleStore(schedule: AffirmationSchedule(isEnabled: true))
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(
            affirmationStore: AffirmationStore(affirmations: [Affirmation(text: "Scheduled")]),
            scheduleStore: schedule, scheduler: scheduler,
            selectionStore: AffirmationSelectionStore(repository: repository)
        )
        await coordinator.reconcileOnLaunch()
        #expect(scheduler.scheduledReminders.count == 4)
        #expect(schedule.schedule.isEnabled)
    }

    @Test("Favourite delivery pauses and resumes as matching entries change")
    func favouritesPauseAndResume() async throws {
        let first = Affirmation(text: "First", isFavorite: true)
        let library = AffirmationStore(affirmations: [first, Affirmation(text: "Second")])
        let schedule = ScheduleStore()
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(
            affirmationStore: library, scheduleStore: schedule, scheduler: scheduler
        )
        try await coordinator.setScheduleSelection(.favourites)
        try await coordinator.setEnabled(true)
        #expect(scheduler.scheduledReminders.allSatisfy { $0.affirmationText == "First" })
        try library.toggleFavorite(id: first.id)
        #expect(scheduler.scheduledReminders.isEmpty)
        await coordinator.waitForLibraryRefresh()
        #expect(coordinator.deliveryIsPaused)
        #expect(schedule.schedule.isEnabled)
        try library.toggleFavorite(id: first.id)
        await coordinator.waitForLibraryRefresh()
        #expect(!coordinator.deliveryIsPaused)
        #expect(!scheduler.scheduledReminders.isEmpty)
        #expect(scheduler.scheduledReminders.allSatisfy { $0.affirmationText == "First" })
    }

    @Test("Tag edits affect delivery and restoring defaults preserves the source")
    func tagDeliveryTracksEditsAndRestores() async throws {
        let first = Affirmation(text: "First", tags: ["Work"])
        let library = AffirmationStore(affirmations: [first])
        let schedule = ScheduleStore()
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(
            affirmationStore: library, scheduleStore: schedule, scheduler: scheduler
        )
        try await coordinator.setScheduleSelection(.tag("work"))
        try await coordinator.setEnabled(true)
        try library.update(id: first.id, text: first.text, tags: [])
        await coordinator.waitForLibraryRefresh()
        #expect(coordinator.deliveryIsPaused)
        #expect(coordinator.scheduleStore.schedules[0].selection == .tag("work"))
        try library.restoreDefaults()
        await coordinator.waitForLibraryRefresh()
        #expect(coordinator.scheduleStore.schedules[0].selection == .tag("work"))
        #expect(scheduler.scheduledReminders.allSatisfy { $0.affirmationText == "First" })
        #expect(!scheduler.scheduledReminders.isEmpty)
    }

    @Test("All delivery ignores metadata edits that do not change reminder text")
    func unrelatedMetadataDoesNotRefresh() async throws {
        let first = Affirmation(text: "First")
        let library = AffirmationStore(affirmations: [first])
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(
            affirmationStore: library, scheduleStore: ScheduleStore(), scheduler: scheduler
        )
        try await coordinator.setEnabled(true)
        let replacements = scheduler.replaceCallCount
        try library.toggleFavorite(id: first.id)
        try library.update(id: first.id, text: first.text, tags: ["Work"])
        #expect(scheduler.replaceCallCount == replacements)
        #expect(!coordinator.isUpdating)
    }

    @Test("Changing source replaces delivery and failed scheduling restores the old source")
    func sourceChangeRecoversOnFailure() async throws {
        let first = Affirmation(text: "First", isFavorite: true)
        let library = AffirmationStore(affirmations: [first, Affirmation(text: "Second")])
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(
            affirmationStore: library, scheduleStore: ScheduleStore(), scheduler: scheduler
        )
        try await coordinator.setEnabled(true)
        try await coordinator.setScheduleSelection(.favourites)
        let previous = scheduler.scheduledReminders
        scheduler.failuresRemaining = 1
        await #expect(throws: NotificationSchedulerTestError.self) {
            try await coordinator.setScheduleSelection(.all)
        }
        #expect(coordinator.scheduleStore.schedules[0].selection == .favourites)
        #expect(scheduler.scheduledReminders == previous)
    }

    @Test("Launch reconciles an empty saved source and later entries resume delivery")
    func launchReconcilesSelection() async throws {
        let library = AffirmationStore()
        let schedule = ScheduleStore(schedule: AffirmationSchedule(isEnabled: true))
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(
            affirmationStore: library, scheduleStore: schedule, scheduler: scheduler,
            selectionStore: AffirmationSelectionStore(selection: .tag("Work"))
        )
        await coordinator.reconcileOnLaunch()
        #expect(schedule.schedule.isEnabled)
        #expect(scheduler.scheduledReminders.isEmpty)
        try library.add(text: "New", tags: ["Work"])
        await coordinator.waitForLibraryRefresh()
        #expect(!scheduler.scheduledReminders.isEmpty)
        #expect(scheduler.authorizationRequestCount == 0)
    }

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

    @Test("Enabling an empty source preserves the preference and pauses delivery")
    func emptyLibraryPausesReminders() async throws {
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let (coordinator, scheduleStore) = makeCoordinator(scheduler: scheduler, affirmations: [])
        try await coordinator.setEnabled(true)
        #expect(scheduler.replaceCallCount == 0)
        #expect(scheduleStore.schedule.isEnabled)
        #expect(coordinator.deliveryIsPaused)
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
        #expect(schedule.schedule.isEnabled)
        #expect(coordinator.deliveryIsPaused)
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
        #expect(throws: NotificationCoordinatorError.updateInProgress) {
            try library.toggleFavorite(id: library.affirmations[0].id)
        }
        await #expect(throws: NotificationCoordinatorError.updateInProgress) {
            try await coordinator.setSelection(.favourites)
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
        authorizationStatusValue = authorizationRequestResult ? .authorized : .denied
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

    func loadSchedules() throws -> [AffirmationSchedule]? {
        schedule.map { [$0] }
    }

    func saveSchedules(_ schedules: [AffirmationSchedule]) throws {
        self.schedule = schedules.first
    }
}

private final class DeliverySelectionRepository: AffirmationSelectionRepository {
    var selection: AffirmationSelection = .all
    var failSaves = false
    var failLoads = false

    func loadAffirmationSelection() throws -> AffirmationSelection? {
        if failLoads { throw NotificationSchedulerTestError.failed }
        return selection
    }

    func saveAffirmationSelection(_ selection: AffirmationSelection) throws {
        if failSaves { throw NotificationSchedulerTestError.failed }
        self.selection = selection
    }
}
