import Foundation
import Testing
@testable import Gayffirmations

@MainActor
struct NotificationRecoveryTests {
    @Test("Permission changes between edit preflight and replacement preserve the saved plan")
    func permissionChangesDuringEdit() async throws {
        let fixture = RecoveryFixture()
        defer { fixture.cleanup() }
        let saved = AffirmationSchedule(isEnabled: true, notificationsPerDay: 2)
        try fixture.repository.saveSchedules([saved])
        let store = fixture.store()
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = fixture.coordinator(store: store, scheduler: scheduler)
        await coordinator.reconcileOnLaunch()
        scheduler.authorizationStatusResults = [.authorized, .denied]
        scheduler.authorizationStatusValue = .denied
        var updated = saved
        updated.notificationsPerDay = 3
        await #expect(throws: NotificationCoordinatorError.permissionDenied) {
            try await coordinator.saveSchedule(updated)
        }
        #expect(fixture.store().schedules == [saved])
        #expect(scheduler.scheduledReminders.isEmpty)
        #expect(coordinator.deliveryState == .permissionBlocked)
        scheduler.authorizationStatusValue = .authorized
        await coordinator.reconcileOnForeground()
        #expect(scheduler.scheduledReminders.count == 2)
        #expect(coordinator.errorMessage == nil)
        #expect(scheduler.authorizationRequestCount == 0)
    }

    @Test("Blocked preferences save and only remaining routines resume without prompting",
          arguments: [NotificationAuthorizationStatus.denied, .notDetermined])
    func blockedPreferences(status: NotificationAuthorizationStatus) async throws {
        let fixture = RecoveryFixture()
        defer { fixture.cleanup() }
        let schedules = (0..<3).map { _ in AffirmationSchedule(isEnabled: true, notificationsPerDay: 2) }
        try fixture.repository.saveSchedules(schedules)
        let store = fixture.store()
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = fixture.coordinator(store: store, scheduler: scheduler)
        await coordinator.reconcileOnLaunch()
        #expect(scheduler.scheduledReminders.count == 6)
        scheduler.authorizationStatusValue = status
        await coordinator.reconcileOnForeground()
        #expect(coordinator.deliveryState == .permissionBlocked)
        try await coordinator.setEnabled(false, for: schedules[0].id)
        try await coordinator.deleteSchedule(id: schedules[1].id)
        var edited = schedules[2]
        edited.notificationsPerDay = 3
        try await coordinator.saveSchedule(edited)
        try await coordinator.setSound(.none)
        var disabled = schedules[0]
        disabled.isEnabled = false
        let reloaded = fixture.store()
        #expect(reloaded.schedules == [disabled, edited])
        #expect(reloaded.notificationSound == .none)
        #expect(scheduler.scheduledReminders.isEmpty)
        #expect(scheduler.authorizationRequestCount == 0)
        scheduler.authorizationStatusValue = .authorized
        await coordinator.reconcileOnForeground()
        #expect(coordinator.deliveryState == .active)
        #expect(coordinator.errorMessage == nil)
        #expect(scheduler.scheduledReminders.count == 3)
        #expect(scheduler.scheduledReminders.allSatisfy {
            $0.identifier.contains(edited.id.uuidString) && $0.sound == .none
        })
        scheduler.authorizationStatusValue = status
        try coordinator.resetSchedule()
        #expect(fixture.store().schedules == [store.defaultSchedule])
        #expect(coordinator.deliveryState == .disabled)
        #expect(scheduler.scheduledReminders.isEmpty)
        #expect(scheduler.authorizationRequestCount == 0)
    }

    @Test("Reducing schedules succeeds when library or name data is unreadable",
          arguments: ["gayffirmations.affirmations", "gayffirmations.name"])
    func unreadableDeliveryData(key: String) async throws {
        let fixture = RecoveryFixture()
        defer { fixture.cleanup() }
        let schedules = (0..<3).map { _ in AffirmationSchedule(isEnabled: true, notificationsPerDay: 2) }
        try fixture.repository.saveSchedules(schedules)
        let raw = Data("invalid".utf8)
        fixture.defaults.set(raw, forKey: key)
        let store = fixture.store()
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = fixture.coordinator(store: store, scheduler: scheduler, loadLibrary: true)
        try await coordinator.setEnabled(false, for: schedules[0].id)
        try await coordinator.deleteSchedule(id: schedules[1].id)
        #expect(fixture.store().schedules.filter(\.isEnabled) == [schedules[2]])
        #expect(coordinator.deliveryState == .failed)
        #expect(scheduler.scheduledReminders.isEmpty)
        #expect(fixture.defaults.data(forKey: key) == raw)
        try coordinator.resetSchedule()
        #expect(coordinator.deliveryState == .disabled)
        #expect(fixture.defaults.data(forKey: key) == raw)
        #expect(scheduler.authorizationRequestCount == 0)
    }

    @Test("A safe reduction persists even when replacement fails")
    func reductionFailureKeepsReducedIntent() async throws {
        let fixture = RecoveryFixture()
        defer { fixture.cleanup() }
        let first = AffirmationSchedule(isEnabled: true, notificationsPerDay: 2)
        let second = AffirmationSchedule(isEnabled: true, notificationsPerDay: 2)
        try fixture.repository.saveSchedules([first, second])
        let store = fixture.store()
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = fixture.coordinator(store: store, scheduler: scheduler)
        await coordinator.reconcileOnLaunch()
        scheduler.failuresRemaining = 1
        try await coordinator.deleteSchedule(id: first.id)
        #expect(fixture.store().schedules == [second])
        #expect(coordinator.deliveryState == .failed)
        #expect(scheduler.scheduledReminders.isEmpty)
        await coordinator.reconcileOnForeground()
        #expect(coordinator.deliveryState == .active)
        #expect(scheduler.scheduledReminders.count == 2)
    }

    @Test("Transient failures preserve intent and recover on foreground",
          arguments: ["launch", "library", "name", "sound", "schedule"])
    func transientFailure(operation: String) async throws {
        let fixture = RecoveryFixture()
        defer { fixture.cleanup() }
        let saved = AffirmationSchedule(isEnabled: true, notificationsPerDay: 2)
        try fixture.repository.saveSchedules([saved])
        try fixture.repository.saveName("Before")
        let entry = Affirmation(text: "Hello {name}")
        try fixture.repository.saveAffirmations([entry])
        let library = AffirmationStore(repository: fixture.repository, defaultAffirmations: [])
        let store = fixture.store()
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(
            affirmationStore: library, scheduleStore: store, scheduler: scheduler,
            personalizationStore: PersonalizationStore(repository: fixture.repository)
        )
        if operation != "launch" { await coordinator.reconcileOnLaunch() }
        scheduler.failuresRemaining = 1
        switch operation {
        case "launch": await coordinator.reconcileOnLaunch()
        case "library":
            try library.update(id: entry.id, text: "Edited {name}")
            await coordinator.waitForLibraryRefresh()
        case "name":
            try coordinator.setName("After")
            await coordinator.waitForLibraryRefresh()
        case "sound":
            await #expect(throws: NotificationSchedulerTestError.self) { try await coordinator.setSound(.none) }
            #expect(store.notificationSound == .systemDefault)
        default:
            var updated = saved
            updated.notificationsPerDay = 3
            await #expect(throws: NotificationSchedulerTestError.self) { try await coordinator.saveSchedule(updated) }
        }
        #expect(fixture.store().schedules == [saved])
        if ["launch", "library", "name"].contains(operation) {
            #expect(scheduler.scheduledReminders.isEmpty)
            #expect(coordinator.deliveryState == .failed)
        }
        await coordinator.reconcileOnForeground()
        #expect(coordinator.deliveryState == .active)
        #expect(coordinator.errorMessage == nil)
        #expect(scheduler.scheduledReminders.count == 2)
        let expected = operation == "library" ? "Edited Before" : operation == "name" ? "Hello After" : "Hello Before"
        #expect(scheduler.scheduledReminders.allSatisfy { $0.affirmationText == expected })
        #expect(scheduler.authorizationRequestCount == 0)
    }

    @Test("Foreground activation during a suspended save is coalesced after it finishes", .timeLimit(.minutes(1)))
    func activationDuringSave() async throws {
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let store = ScheduleStore(schedule: AffirmationSchedule(isEnabled: true, notificationsPerDay: 2))
        let coordinator = NotificationCoordinator(
            affirmationStore: AffirmationStore(affirmations: [Affirmation(text: "Hello")]),
            scheduleStore: store, scheduler: scheduler
        )
        await coordinator.reconcileOnLaunch()
        let gate = NotificationSuspension()
        defer { gate.resume() }
        scheduler.replacementSuspension = gate
        var updated = store.schedules[0]
        updated.notificationsPerDay = 3
        let save = Task { try await coordinator.saveSchedule(updated) }
        await gate.waitUntilSuspended()
        #expect(coordinator.deliveryState == .updating)
        await coordinator.reconcileOnForeground()
        await coordinator.reconcileOnForeground()
        await #expect(throws: NotificationCoordinatorError.updateInProgress) {
            try await coordinator.deleteSchedule(id: updated.id)
        }
        gate.resume()
        try await save.value
        await coordinator.waitForReconciliation()
        #expect(store.schedules == [updated])
        #expect(scheduler.scheduledReminders.count == 3)
        #expect(scheduler.replaceCallCount == 3)
        #expect(coordinator.deliveryState == .active)
    }

    @Test("Cancellation clears partial delivery and preserves saved intent", .timeLimit(.minutes(1)))
    func cancelledSave() async throws {
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let saved = AffirmationSchedule(isEnabled: true, notificationsPerDay: 2)
        let store = ScheduleStore(schedule: saved)
        let coordinator = NotificationCoordinator(
            affirmationStore: AffirmationStore(affirmations: [Affirmation(text: "Hello")]),
            scheduleStore: store, scheduler: scheduler
        )
        await coordinator.reconcileOnLaunch()
        let gate = NotificationSuspension()
        defer { gate.resume() }
        scheduler.replacementSuspension = gate
        var updated = saved
        updated.notificationsPerDay = 3
        let save = Task { try await coordinator.saveSchedule(updated) }
        await gate.waitUntilSuspended()
        save.cancel()
        gate.resume()
        await #expect(throws: NotificationCoordinatorError.self) { try await save.value }
        #expect(store.schedules == [saved])
        #expect(scheduler.scheduledReminders.isEmpty)
        #expect(coordinator.deliveryState == .failed)
        await coordinator.reconcileOnForeground()
        #expect(scheduler.scheduledReminders.count == 2)
        #expect(coordinator.errorMessage == nil)
    }

    @Test("Persistent failures keep saved routines and stop partial delivery without retry loops")
    func persistentFailure() async throws {
        let fixture = RecoveryFixture()
        defer { fixture.cleanup() }
        let saved = AffirmationSchedule(isEnabled: true, notificationsPerDay: 2)
        try fixture.repository.saveSchedules([saved])
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        scheduler.replacementError = NotificationSchedulerTestError.failed
        let coordinator = fixture.coordinator(store: fixture.store(), scheduler: scheduler)
        for count in 1...2 {
            await coordinator.reconcileOnForeground()
            #expect(fixture.store().schedules == [saved])
            #expect(scheduler.scheduledReminders.isEmpty)
            #expect(coordinator.deliveryState == .failed)
            #expect(scheduler.replaceCallCount == count)
        }
        #expect(scheduler.authorizationRequestCount == 0)
        scheduler.replacementError = nil
        await coordinator.reconcileOnForeground()
        #expect(coordinator.deliveryState == .active)
        #expect(coordinator.errorMessage == nil)
    }
}

@MainActor
final class NotificationSuspension {
    private var suspended: CheckedContinuation<Void, Never>?
    private var arrival: CheckedContinuation<Void, Never>?
    private var cancelled = false

    func pause() async {
        if cancelled { return }
        await withCheckedContinuation { continuation in
            suspended = continuation
            arrival?.resume()
            arrival = nil
        }
    }

    func waitUntilSuspended() async {
        if suspended != nil || cancelled { return }
        await withTaskCancellationHandler {
            await withCheckedContinuation { arrival = $0 }
        } onCancel: {
            Task { @MainActor in
                self.cancelled = true
                self.arrival?.resume()
                self.arrival = nil
                self.resume()
            }
        }
    }

    func resume() {
        suspended?.resume()
        suspended = nil
    }
}

@MainActor
private struct RecoveryFixture {
    let suite = "NotificationRecoveryTests.\(UUID())"
    let defaults: UserDefaults
    let repository: UserDefaultsRepository

    init() {
        defaults = UserDefaults(suiteName: suite)!
        repository = UserDefaultsRepository(userDefaults: defaults)
    }

    func cleanup() { defaults.removePersistentDomain(forName: suite) }
    func store() -> ScheduleStore { ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule()) }
    func coordinator(store: ScheduleStore, scheduler: NotificationSchedulerSpy, loadLibrary: Bool = false) -> NotificationCoordinator {
        NotificationCoordinator(
            affirmationStore: loadLibrary
                ? AffirmationStore(repository: repository, defaultAffirmations: [Affirmation(text: "Hello")])
                : AffirmationStore(affirmations: [Affirmation(text: "Hello")]),
            scheduleStore: store, scheduler: scheduler,
            personalizationStore: PersonalizationStore(repository: repository)
        )
    }
}
