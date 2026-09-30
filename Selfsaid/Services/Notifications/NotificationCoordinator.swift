import Foundation

enum NotificationCoordinatorError: LocalizedError, Equatable {
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Notifications are turned off for Selfsaid. You can enable them in Settings."
        }
    }
}

@MainActor
final class NotificationCoordinator {
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
    }

    func setEnabled(_ isEnabled: Bool) async throws {
        if isEnabled {
            try await enableNotifications()
        } else {
            try disableNotifications()
        }
    }

    func setStartTime(_ startTime: TimeOfDay) async throws {
        var updatedSchedule = scheduleStore.schedule
        updatedSchedule.startTime = startTime
        try await apply(updatedSchedule)
    }

    func setEndTime(_ endTime: TimeOfDay) async throws {
        var updatedSchedule = scheduleStore.schedule
        updatedSchedule.endTime = endTime
        try await apply(updatedSchedule)
    }

    func setNotificationsPerDay(_ notificationsPerDay: Int) async throws {
        var updatedSchedule = scheduleStore.schedule
        updatedSchedule.notificationsPerDay = notificationsPerDay
        try await apply(updatedSchedule)
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

        try await scheduler.replacePendingNotifications(with: reminders)

        do {
            try scheduleStore.setEnabled(true)
        } catch {
            scheduler.removePendingNotifications()
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

        try await scheduler.replacePendingNotifications(with: reminders)

        do {
            try scheduleStore.replace(with: updatedSchedule)
        } catch {
            await restorePendingNotifications()
            throw error
        }
    }

    private func restorePendingNotifications() async {
        guard let reminders = try? planner.reminders(
            for: scheduleStore.schedule,
            affirmations: affirmationStore.affirmations
        ) else {
            return
        }

        try? await scheduler.replacePendingNotifications(with: reminders)
    }
}
