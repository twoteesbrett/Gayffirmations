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
            "Notifications are turned off for Selfsaid. You can enable them in Settings."
        }
    }
}

@MainActor
@Observable
final class NotificationCoordinator {
    private(set) var isUpdating = false
    var errorMessage: String?
    private var refreshTask: Task<Void, Never>?
    private let affirmationStore: AffirmationStore
    private let scheduleStore: ScheduleStore
    private let scheduler: any NotificationScheduling
    private let planner: NotificationPlanner

    init(
        affirmationStore: AffirmationStore,
        scheduleStore: ScheduleStore,
        scheduler: any NotificationScheduling
    ) {
        self.affirmationStore = affirmationStore
        self.scheduleStore = scheduleStore
        self.scheduler = scheduler
        planner = NotificationPlanner()
        affirmationStore.willChangeReminderText = { [weak self] in
            try self?.checkIdle()
        }
        affirmationStore.didChangeReminderText = { [weak self] in
            self?.refreshAfterLibraryChange()
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
        let reminders = try planner.reminders(
            for: scheduleStore.schedule,
            affirmations: affirmationStore.affirmations
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
            try await scheduler.replacePendingNotifications(with: reminders)
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

        let reminders = try planner.reminders(
            for: updatedSchedule,
            affirmations: affirmationStore.affirmations
        )

        do {
            try await scheduler.replacePendingNotifications(with: reminders)
            try scheduleStore.replace(with: updatedSchedule)
        } catch {
            try await refreshRemindersOrDisable()
            throw error
        }
    }

    private func refreshRemindersOrDisable() async throws {
        do {
            let reminders = try planner.reminders(
                for: scheduleStore.schedule,
                affirmations: affirmationStore.affirmations
            )
            try await scheduler.replacePendingNotifications(with: reminders)
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

    private func checkIdle() throws {
        guard !isUpdating else {
            throw NotificationCoordinatorError.updateInProgress
        }
    }

    private func refreshAfterLibraryChange() {
        guard scheduleStore.schedule.isEnabled else { return }
        // Stop old text immediately, before the asynchronous replacement begins.
        scheduler.removePendingNotifications()
        isUpdating = true
        refreshTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isUpdating = false }
            do {
                if self.affirmationStore.affirmations.isEmpty {
                    try self.disableNotifications()
                } else {
                    try await self.refreshRemindersOrDisable()
                }
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
