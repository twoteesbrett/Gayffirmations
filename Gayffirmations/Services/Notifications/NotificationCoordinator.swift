import Foundation
import Observation

enum NotificationCoordinatorError: LocalizedError, Equatable {
    case permissionDenied
    case updateInProgress
    case recoveryFailed(String)

    var errorDescription: String? {
        switch self {
        case .updateInProgress:
            "Reminders are being updated. Please try again in a moment."
        case .recoveryFailed(let reason):
            "Saved settings are unchanged, but reminders could not be restored. Delivery is stopped until retry. \(reason)"
        case .permissionDenied:
            "Notifications are turned off for Gayffirmations. You can enable them in Settings."
        }
    }
}

enum NotificationDeliveryState: Equatable {
    case disabled, contentPaused, permissionBlocked, updating, failed, active
}

@MainActor
@Observable
final class NotificationCoordinator {
    private(set) var isUpdating = false
    var errorMessage: String?
    private var refreshTask: Task<Void, Never>?
    private var reconciliationTask: Task<Void, Never>?
    private var reconciliationPending = false
    private var deliveryIssue: NotificationDeliveryState?
    let fallbackSelectionStore: AffirmationSelectionStore
    let personalizationStore: PersonalizationStore
    private let affirmationStore: AffirmationStore
    let scheduleStore: ScheduleStore
    private let scheduler: any NotificationScheduling
    private let planner = NotificationPlanner()

    init(
        affirmationStore: AffirmationStore,
        scheduleStore: ScheduleStore,
        scheduler: any NotificationScheduling,
        fallbackSelectionStore: AffirmationSelectionStore? = nil,
        personalizationStore: PersonalizationStore? = nil
    ) {
        self.affirmationStore = affirmationStore
        self.scheduleStore = scheduleStore
        self.scheduler = scheduler
        self.fallbackSelectionStore = fallbackSelectionStore ?? AffirmationSelectionStore()
        self.personalizationStore = personalizationStore ?? PersonalizationStore()
        affirmationStore.willChangeAffirmations = { [weak self] _ in try self?.checkIdle() }
        affirmationStore.didChangeAffirmations = { [weak self] previous in
            guard let self, self.deliveryChanges(from: previous) else { return }
            self.refreshAfterLibraryChange()
        }
    }

    var availableTags: [String] { affirmationStore.availableTags }
    var enabledCount: Int { scheduleStore.schedules.filter(\.isEnabled).count }
    var dailyTotal: Int {
        scheduleStore.schedules.filter(\.isEnabled).reduce(0) { $0 + $1.notificationsPerDay }
    }
    var dailyPlan: [ScheduledAffirmation] {
        (try? plan(for: scheduleStore.schedules)) ?? []
    }
    var deliveryIsPaused: Bool { enabledCount > 0 && dailyPlan.isEmpty }

    var deliveryState: NotificationDeliveryState {
        if isUpdating { return .updating }
        if enabledCount == 0 { return .disabled }
        if let deliveryIssue { return deliveryIssue }
        return deliveryIsPaused ? .contentPaused : .active
    }

    var deliverySummary: String {
        switch deliveryState {
        case .disabled: "Disabled"
        case .contentPaused: "Paused · no matching content"
        case .permissionBlocked: "Blocked · permission off"
        case .updating: "Updating"
        case .failed: "Delivery failed · retry"
        case .active: "\(enabledCount) enabled"
        }
    }

    func matchingAffirmations(for schedule: AffirmationSchedule) -> [Affirmation] {
        schedule.selection.matchingAffirmations(in: affirmationStore.affirmations)
            .compactMap { $0.resolved(name: personalizationStore.name) }
    }

    func isPaused(_ schedule: AffirmationSchedule) -> Bool {
        schedule.isEnabled && matchingAffirmations(for: schedule).isEmpty
    }

    var fallbackAffirmations: [Affirmation] {
        fallbackSelectionStore.selection.matchingAffirmations(in: affirmationStore.affirmations)
            .compactMap { $0.resolved(name: personalizationStore.name) }
    }

    func setFallbackSelection(_ selection: AffirmationSelection) throws {
        try checkIdle()
        try fallbackSelectionStore.select(selection.usingAllWhenEmpty)
    }

    func setName(_ name: String) throws {
        try checkIdle()
        try personalizationStore.setName(name)
        refreshAfterLibraryChange()
    }

    func saveSchedule(_ schedule: AffirmationSchedule) async throws {
        var schedules = scheduleStore.schedules
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index] = schedule
        } else {
            schedules.append(schedule)
        }
        try await apply(schedules)
    }

    func setEnabled(_ enabled: Bool, for id: AffirmationSchedule.ID) async throws {
        guard var schedule = scheduleStore.schedules.first(where: { $0.id == id }) else {
            throw ScheduleValidationError.scheduleNotFound
        }
        schedule.isEnabled = enabled
        try await saveSchedule(schedule)
    }

    func deleteSchedule(id: AffirmationSchedule.ID) async throws {
        try await apply(scheduleStore.schedules.filter { $0.id != id })
    }

    func resetSchedule() throws {
        try checkIdle()
        try scheduleStore.reset()
        removePendingReminders()
    }

    func setSound(_ sound: NotificationSound) async throws {
        try checkIdle()
        try Task.checkCancellation()
        guard sound != scheduleStore.notificationSound else { return }
        isUpdating = true
        defer { finishUpdate() }
        // Sound is a saved preference even when system permission is unavailable.
        if enabledCount > 0, await scheduler.authorizationStatus() != .authorized {
            try Task.checkCancellation()
            try scheduleStore.setNotificationSound(sound)
            await reconcileSavedReminders()
            return
        }
        if enabledCount > 0 { try checkDeliveryData() }
        let reminders = try planner.plan(
            for: scheduleStore.schedules,
            affirmations: affirmationStore.affirmations,
            name: personalizationStore.name,
            sound: sound
        ).map(\.reminder)
        try await replaceRemindersAndSave(reminders) {
            try scheduleStore.setNotificationSound(sound)
        }
    }

    private func apply(_ schedules: [AffirmationSchedule]) async throws {
        try checkIdle()
        try Task.checkCancellation()
        isUpdating = true
        defer { finishUpdate() }
        try ScheduleValidation.validate(schedules)
        let oldEnabled = scheduleStore.schedules.filter(\.isEnabled)
        let newEnabled = schedules.filter(\.isEnabled)
        // Editing an inactive schedule does not disturb active delivery.
        guard oldEnabled != newEnabled else {
            try scheduleStore.replace(with: schedules)
            return
        }
        // Reductions must save even if delivery, library data, or permission is
        // unavailable. Failed delivery cannot undo a user's decision to stop it.
        let isReduction = newEnabled.allSatisfy { oldEnabled.contains($0) }
        if isReduction {
            try scheduleStore.replace(with: schedules)
            await reconcileSavedReminders()
            return
        }
        let newlyEnabled = newEnabled.contains { schedule in
            !oldEnabled.contains(where: { $0.id == schedule.id })
        }
        if newlyEnabled {
            try await ensureAuthorization()
        } else if await scheduler.authorizationStatus() != .authorized {
            try Task.checkCancellation()
            try scheduleStore.replace(with: schedules)
            await reconcileSavedReminders()
            return
        }
        try checkDeliveryData()
        let reminders = try plan(for: schedules).map(\.reminder)
        try await replaceRemindersAndSave(reminders) {
            try scheduleStore.replace(with: schedules)
        }
    }

    // Publish saved state only after delivery succeeds; recover the saved plan on either failure.
    private func replaceRemindersAndSave(
        _ reminders: [NotificationReminder],
        save: () throws -> Void
    ) async throws {
        do {
            try await replaceReminders(with: reminders)
            try Task.checkCancellation()
            try save()
            clearDeliveryIssue()
        } catch {
            do {
                try await restoreSavedReminders()
            } catch {
                recordDeliveryFailure(error)
                if (error as? NotificationCoordinatorError) == .permissionDenied { throw error }
                throw NotificationCoordinatorError.recoveryFailed(error.localizedDescription)
            }
            throw error
        }
    }

    private func ensureAuthorization() async throws {
        switch await scheduler.authorizationStatus() {
        case .authorized: return
        case .notDetermined:
            if try await scheduler.requestAuthorization() { return }
        case .denied: break
        }
        throw NotificationCoordinatorError.permissionDenied
    }

    private func plan(for schedules: [AffirmationSchedule]) throws -> [ScheduledAffirmation] {
        try planner.plan(for: schedules, affirmations: affirmationStore.affirmations,
                         name: personalizationStore.name, sound: scheduleStore.notificationSound)
    }

    private func restoreSavedReminders() async throws {
        do {
            if enabledCount > 0 { try checkDeliveryData() }
            try await replaceReminders(with: plan(for: scheduleStore.schedules).map(\.reminder))
            clearDeliveryIssue()
        } catch {
            scheduler.removePendingNotifications()
            throw error
        }
    }

    func reconcileOnLaunch() async {
        await reconcileOnForeground()
    }

    // Foreground and explicit retry use the same saved intent, without prompting.
    func reconcileOnForeground() async {
        guard !isUpdating else {
            reconciliationPending = true
            return
        }
        isUpdating = true
        defer { finishUpdate() }
        await reconcileSavedReminders()
    }

    private func reconcileSavedReminders() async {
        do {
            try await restoreSavedReminders()
        } catch {
            recordDeliveryFailure(error)
        }
    }

    private func clearDeliveryIssue() {
        deliveryIssue = nil
        errorMessage = nil
    }

    private func recordDeliveryFailure(_ error: any Error) {
        deliveryIssue = (error as? NotificationCoordinatorError) == .permissionDenied
            ? .permissionBlocked : .failed
        errorMessage = deliveryIssue == .permissionBlocked ? error.localizedDescription
            : "Saved routines are kept, but reminder delivery failed. Retry from Settings or return to the app. \(error.localizedDescription)"
    }

    private func finishUpdate() {
        isUpdating = false
        guard reconciliationPending else { return }
        reconciliationPending = false
        reconciliationTask = Task { [weak self] in
            await self?.reconcileOnForeground()
        }
    }

    private func deliveryChanges(from previous: [Affirmation]) -> Bool {
        scheduleStore.schedules.filter(\.isEnabled).contains { schedule in
            @MainActor func texts(in entries: [Affirmation]) -> [String] {
                schedule.selection.matchingAffirmations(in: entries)
                    .compactMap { $0.resolved(name: personalizationStore.name)?.text }
            }
            return texts(in: previous) != texts(in: affirmationStore.affirmations)
        }
    }

    private func replaceReminders(with reminders: [NotificationReminder]) async throws {
        try Task.checkCancellation()
        guard !reminders.isEmpty else {
            scheduler.removePendingNotifications()
            return
        }
        guard await scheduler.authorizationStatus() == .authorized else {
            throw NotificationCoordinatorError.permissionDenied
        }
        try Task.checkCancellation()
        try await scheduler.replacePendingNotifications(with: reminders)
        try Task.checkCancellation()
    }

    private func checkIdle() throws {
        guard !isUpdating else { throw NotificationCoordinatorError.updateInProgress }
    }

    private func checkDeliveryData() throws {
        let failures = [
            affirmationStore.persistenceErrorMessage,
            scheduleStore.persistenceErrorMessage,
            personalizationStore.persistenceErrorMessage
        ].compactMap { $0 }
        guard failures.isEmpty else {
            throw PersistenceUnavailableError(reason: failures.joined(separator: "\n"))
        }
    }

    private func refreshAfterLibraryChange() {
        guard enabledCount > 0 else { return }
        scheduler.removePendingNotifications()
        isUpdating = true
        refreshTask = Task { [weak self] in
            guard let self else { return }
            defer { finishUpdate() }
            await self.reconcileSavedReminders()
        }
    }

    func waitForLibraryRefresh() async { await refreshTask?.value }
    func waitForReconciliation() async { await reconciliationTask?.value }
    func removePendingReminders() {
        scheduler.removePendingNotifications()
        clearDeliveryIssue()
    }
}
