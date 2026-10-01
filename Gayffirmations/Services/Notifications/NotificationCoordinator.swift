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
    private let affirmationStore: AffirmationStore
    private let scheduleStore: ScheduleStore
    private let scheduler: any NotificationScheduling
    private let planner: NotificationPlanner

    init(
        affirmationStore: AffirmationStore,
        scheduleStore: ScheduleStore,
        scheduler: any NotificationScheduling,
        selectionStore: AffirmationSelectionStore? = nil
    ) {
        self.affirmationStore = affirmationStore
        self.scheduleStore = scheduleStore
        self.scheduler = scheduler
        self.selectionStore = selectionStore ?? AffirmationSelectionStore()
        planner = NotificationPlanner()
        affirmationStore.willChangeAffirmations = { [weak self] _ in
            // A pending source change may depend on tags or favourites too.
            try self?.checkIdle()
        }
        affirmationStore.didChangeAffirmations = { [weak self] previous in
            guard let self, self.deliveryChanges(from: previous, to: self.affirmationStore.affirmations) else { return }
            self.refreshAfterLibraryChange()
        }
    }

    func setEnabled(_ isEnabled: Bool) async throws {
        try checkIdle()
        isUpdating = true
        defer { isUpdating = false }
        if isEnabled {
            try await enableNotifications()
        } else {
            try disableNotifications()
        }
    }

    func setStartTime(_ startTime: TimeOfDay) async throws {
        try checkIdle()
        isUpdating = true
        defer { isUpdating = false }
        var updatedSchedule = scheduleStore.schedule
        updatedSchedule.startTime = startTime
        try await apply(updatedSchedule)
    }

    func setEndTime(_ endTime: TimeOfDay) async throws {
        try checkIdle()
        isUpdating = true
        defer { isUpdating = false }
        var updatedSchedule = scheduleStore.schedule
        updatedSchedule.endTime = endTime
        try await apply(updatedSchedule)
    }

    func setNotificationsPerDay(_ notificationsPerDay: Int) async throws {
        try checkIdle()
        isUpdating = true
        defer { isUpdating = false }
        var updatedSchedule = scheduleStore.schedule
        updatedSchedule.notificationsPerDay = notificationsPerDay
        try await apply(updatedSchedule)
    }

    func resetSchedule() throws {
        try checkIdle()
        isUpdating = true
        defer { isUpdating = false }
        try scheduleStore.reset()
        scheduler.removePendingNotifications()
    }

    private func enableNotifications() async throws {
        try checkDeliveryData()
        let reminders = try plannedReminders(
            for: scheduleStore.schedule,
            affirmations: selectedAffirmations
        )

        switch await scheduler.authorizationStatus() {
        case .authorized:
            break
        case .notDetermined:
            guard try await scheduler.requestAuthorization() else {
                throw NotificationCoordinatorError.permissionDenied
            }
        case .denied:
            throw NotificationCoordinatorError.permissionDenied
        }

        do {
            try await replaceReminders(with: reminders)
            try scheduleStore.setEnabled(true)
        } catch {
            if scheduleStore.schedule.isEnabled {
                try await refreshRemindersOrDisable()
            } else {
                scheduler.removePendingNotifications()
            }
            throw error
        }
    }

    private func disableNotifications() throws {
        try scheduleStore.setEnabled(false)
        scheduler.removePendingNotifications()
    }

    private func apply(_ updatedSchedule: AffirmationSchedule) async throws {
        guard scheduleStore.schedule.isEnabled else {
            try scheduleStore.replace(with: updatedSchedule)
            return
        }

        try checkDeliveryData()
        let reminders = try plannedReminders(
            for: updatedSchedule,
            affirmations: selectedAffirmations
        )

        do {
            try await replaceReminders(with: reminders)
            try scheduleStore.replace(with: updatedSchedule)
        } catch {
            try await refreshRemindersOrDisable()
            throw error
        }
    }

    private func refreshRemindersOrDisable() async throws {
        do {
            try checkDeliveryData()
        } catch {
            // Unreadable data pauses delivery without changing healthy settings.
            scheduler.removePendingNotifications()
            throw error
        }

        do {
            let reminders = try plannedReminders(
                for: scheduleStore.schedule,
                affirmations: selectedAffirmations
            )
            try await replaceReminders(with: reminders)
        } catch {
            scheduler.removePendingNotifications()
            do {
                try scheduleStore.setEnabled(false)
            } catch {
                throw NotificationCoordinatorError.recoveryFailed(
                    "The saved enabled setting could not be changed: \(error.localizedDescription)"
                )
            }
            throw NotificationCoordinatorError.recoveryFailed(error.localizedDescription)
        }
    }

    var selectedAffirmations: [Affirmation] {
        selectionStore.selection.matchingAffirmations(in: affirmationStore.affirmations)
    }

    var deliveryIsPaused: Bool {
        scheduleStore.schedule.isEnabled && selectedAffirmations.isEmpty
    }

    func setSelection(_ selection: AffirmationSelection) async throws {
        try checkIdle()
        guard selection != selectionStore.selection else { return }
        isUpdating = true
        defer { isUpdating = false }

        // Today can use a healthy selection even when delivery data is unavailable.
        guard scheduleStore.schedule.isEnabled,
              scheduleStore.persistenceErrorMessage == nil,
              affirmationStore.persistenceErrorMessage == nil else {
            try selectionStore.select(selection)
            scheduler.removePendingNotifications()
            return
        }

        try checkDeliveryData()
        let entries = selection.matchingAffirmations(in: affirmationStore.affirmations)
        let reminders = try plannedReminders(for: scheduleStore.schedule, affirmations: entries)
        do {
            try await replaceReminders(with: reminders)
            try selectionStore.select(selection)
        } catch {
            // The previous selection is still saved; restore its reminders.
            try await refreshRemindersOrDisable()
            throw error
        }
    }

    func reconcileOnLaunch() async {
        guard !isUpdating else { return }
        // Never schedule fallback data after a failed load.
        guard affirmationStore.persistenceErrorMessage == nil,
              scheduleStore.persistenceErrorMessage == nil,
              selectionStore.persistenceErrorMessage == nil else {
            scheduler.removePendingNotifications()
            return
        }
        guard scheduleStore.schedule.isEnabled else {
            scheduler.removePendingNotifications()
            return
        }
        isUpdating = true
        defer { isUpdating = false }
        do {
            try await refreshRemindersOrDisable()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deliveryChanges(from previous: [Affirmation], to updated: [Affirmation]) -> Bool {
        let selection = selectionStore.selection
        return selection.matchingAffirmations(in: previous).map(\.text)
            != selection.matchingAffirmations(in: updated).map(\.text)
    }

    private func plannedReminders(
        for schedule: AffirmationSchedule,
        affirmations: [Affirmation]
    ) throws -> [NotificationReminder] {
        // Validate times even while the selected collection is empty.
        _ = try ScheduleCalculator().notificationTimes(for: schedule)
        guard !affirmations.isEmpty else { return [] }
        return try planner.reminders(for: schedule, affirmations: affirmations)
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
        guard !isUpdating else {
            throw NotificationCoordinatorError.updateInProgress
        }
    }

    private func checkDeliveryData() throws {
        let failures = [
            affirmationStore.persistenceErrorMessage,
            scheduleStore.persistenceErrorMessage,
            selectionStore.persistenceErrorMessage
        ].compactMap { $0 }
        guard failures.isEmpty else {
            throw PersistenceUnavailableError(reason: failures.joined(separator: "\n"))
        }
    }

    private func refreshAfterLibraryChange() {
        guard scheduleStore.schedule.isEnabled else { return }
        // Remove outdated delivery immediately, before asynchronous replacement.
        scheduler.removePendingNotifications()
        isUpdating = true
        refreshTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isUpdating = false }
            do {
                try await self.refreshRemindersOrDisable()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func waitForLibraryRefresh() async {
        await refreshTask?.value
    }

    func removePendingReminders() {
        scheduler.removePendingNotifications()
    }
}
