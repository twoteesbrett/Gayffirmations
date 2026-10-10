import Foundation
import Observation

@MainActor
@Observable
final class ScheduleStore {
    private(set) var schedules: [AffirmationSchedule]
    private(set) var notificationSound: NotificationSound = .systemDefault
    private(set) var persistenceErrorMessage: String?
    private let repository: (any ScheduleRepository)?
    let defaultSchedule: AffirmationSchedule

    convenience init() { self.init(schedule: AffirmationSchedule()) }

    init(schedule: AffirmationSchedule) {
        schedules = [schedule]
        notificationSound = schedule.sound
        defaultSchedule = AffirmationSchedule()
        repository = nil
    }

    init(repository: any ScheduleRepository, defaultSchedule: AffirmationSchedule) {
        self.repository = repository
        self.defaultSchedule = defaultSchedule
        schedules = [defaultSchedule]
        do {
            if let saved = try repository.loadSchedules() {
                try ScheduleValidation.validate(saved)
                schedules = saved
            } else {
                try repository.saveSchedules(schedules)
            }
            // Preserve the first saved schedule's sound when migrating to one preference.
            if let savedSound = try repository.loadNotificationSound() {
                notificationSound = savedSound
            } else {
                let migratedSound = schedules.first?.sound ?? .systemDefault
                try repository.saveNotificationSound(migratedSound)
                notificationSound = migratedSound
            }
        } catch {
            persistenceErrorMessage = error.localizedDescription
        }
    }

    func replace(with schedules: [AffirmationSchedule]) throws {
        if let persistenceErrorMessage {
            throw PersistenceUnavailableError(reason: persistenceErrorMessage)
        }
        try ScheduleValidation.validate(schedules)
        try repository?.saveSchedules(schedules)
        self.schedules = schedules
    }

    func reset() throws {
        try replace(with: [defaultSchedule])
    }

    func setNotificationSound(_ sound: NotificationSound) throws {
        if let persistenceErrorMessage {
            throw PersistenceUnavailableError(reason: persistenceErrorMessage)
        }
        try repository?.saveNotificationSound(sound)
        notificationSound = sound
    }

    func applyPersistedDefaults() {
        schedules = [defaultSchedule]
        notificationSound = .systemDefault
        persistenceErrorMessage = nil
    }
}
