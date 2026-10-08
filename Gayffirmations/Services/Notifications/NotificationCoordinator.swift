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
            "Reminders could not be restored and have been stopped. \(reason)"
        case .permissionDenied:
            "Notifications are turned off for Gayffirmations. You can enable them in Settings."
        }
    }
}

@MainActor
@Observable
final class NotificationCoordinator {
    private(set) var isUpdating = false
    var errorMessage: String?
    private var refreshTask: Task<Void, Never>?
    let selectionStore: AffirmationSelectionStore
    let personalizationStore: PersonalizationStore
    private let affirmationStore: AffirmationStore
    let scheduleStore: ScheduleStore
    private let scheduler: any NotificationScheduling
    private let planner = NotificationPlanner()

    init(
        affirmationStore: AffirmationStore,
        scheduleStore: ScheduleStore,
        scheduler: any NotificationScheduling,
        selectionStore: AffirmationSelectionStore? = nil,
        personalizationStore: PersonalizationStore? = nil
    ) {
        self.affirmationStore = affirmationStore
        self.scheduleStore = scheduleStore
        self.scheduler = scheduler
        self.selectionStore = selectionStore ?? AffirmationSelectionStore()
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

    func matchingAffirmations(for schedule: AffirmationSchedule) -> [Affirmation] {
        schedule.selection.matchingAffirmations(in: affirmationStore.affirmations)
            .compactMap { $0.resolved(name: personalizationStore.name) }
    }

    func isPaused(_ schedule: AffirmationSchedule) -> Bool {
        schedule.isEnabled && matchingAffirmations(for: schedule).isEmpty
    }

    var selectedAffirmations: [Affirmation] {
        selectionStore.selection.matchingAffirmations(in: affirmationStore.affirmations)
            .compactMap { $0.resolved(name: personalizationStore.name) }
    }

    func setSelection(_ selection: AffirmationSelection) async throws {
        try checkIdle()
        try selectionStore.select(selection)
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
        scheduler.removePendingNotifications()
    }

    func setSound(_ sound: NotificationSound) async throws {
        try checkIdle()
        guard sound != scheduleStore.notificationSound else { return }
        isUpdating = true
        defer { isUpdating = false }
        try checkDeliveryData()
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
        isUpdating = true
        defer { isUpdating = false }
        try ScheduleValidation.validate(schedules)
        let oldEnabled = scheduleStore.schedules.filter(\.isEnabled)
        let newEnabled = schedules.filter(\.isEnabled)
        // Editing an inactive schedule does not disturb active delivery.
        guard oldEnabled != newEnabled else {
            try scheduleStore.replace(with: schedules)
            return
        }
        let reminders: [NotificationReminder]
        if newEnabled.isEmpty {
            reminders = []
        } else {
            try checkDeliveryData()
            reminders = try plan(for: schedules).map(\.reminder)
            let newlyEnabled = newEnabled.contains { schedule in
                !oldEnabled.contains(where: { $0.id == schedule.id })
            }
            if newlyEnabled { try await ensureAuthorization() }
        }
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
            try save()
        } catch {
            try await restoreSavedReminders()
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
            try checkDeliveryData()
        } catch {
            scheduler.removePendingNotifications()
            throw error
        }
        do {
            try await replaceReminders(with: plan(for: scheduleStore.schedules).map(\.reminder))
        } catch {
            scheduler.removePendingNotifications()
            var disabled = scheduleStore.schedules
            for index in disabled.indices { disabled[index].isEnabled = false }
            do {
                try scheduleStore.replace(with: disabled)
            } catch {
                throw NotificationCoordinatorError.recoveryFailed("The saved enabled settings could not be changed: \(error.localizedDescription)")
            }
            throw NotificationCoordinatorError.recoveryFailed(error.localizedDescription)
        }
    }

    func reconcileOnLaunch() async {
        guard !isUpdating else { return }
        isUpdating = true
        defer { isUpdating = false }
        do {
            try await restoreSavedReminders()
        } catch {
            errorMessage = error.localizedDescription
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
        guard !reminders.isEmpty else {
            scheduler.removePendingNotifications()
            return
        }
        guard await scheduler.authorizationStatus() == .authorized else {
            throw NotificationCoordinatorError.permissionDenied
        }
        try await scheduler.replacePendingNotifications(with: reminders)
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
            defer { isUpdating = false }
            do {
                try await self.restoreSavedReminders()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func waitForLibraryRefresh() async { await refreshTask?.value }
    func removePendingReminders() { scheduler.removePendingNotifications() }
}
