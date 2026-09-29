import Foundation
import Observation

@MainActor
@Observable
final class ScheduleStore {
    private(set) var schedule: AffirmationSchedule
    private(set) var persistenceErrorMessage: String?

    private let repository: (any ScheduleRepository)?

    init(
        schedule: AffirmationSchedule,
        repository: (any ScheduleRepository)? = nil
    ) {
        self.schedule = schedule
        self.repository = repository
    }

    convenience init() {
        self.init(schedule: AffirmationSchedule())
    }

    init(
        repository: any ScheduleRepository,
        defaultSchedule: AffirmationSchedule
    ) {
        self.repository = repository

        do {
            if let savedSchedule = try repository.loadSchedule() {
                schedule = savedSchedule
            } else {
                schedule = defaultSchedule
                try repository.saveSchedule(defaultSchedule)
            }
        } catch {
            schedule = defaultSchedule
            persistenceErrorMessage = error.localizedDescription
        }
    }

    func setEnabled(_ isEnabled: Bool) throws {
        try update { $0.isEnabled = isEnabled }
    }

    func setStartTime(_ startTime: TimeOfDay) throws {
        try update { $0.startTime = startTime }
    }

    func setEndTime(_ endTime: TimeOfDay) throws {
        try update { $0.endTime = endTime }
    }

    func setNotificationsPerDay(_ notificationsPerDay: Int) throws {
        try update { $0.notificationsPerDay = notificationsPerDay }
    }

    private func update(
        _ change: (inout AffirmationSchedule) -> Void
    ) throws {
        if let persistenceErrorMessage {
            throw PersistenceUnavailableError(reason: persistenceErrorMessage)
        }

        var updatedSchedule = schedule
        change(&updatedSchedule)

        try repository?.saveSchedule(updatedSchedule)
        schedule = updatedSchedule
    }
}
