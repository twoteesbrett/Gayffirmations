import Foundation
@testable import Gayffirmations

// Keep the original single-schedule regression cases concise while exercising
// the collection APIs used by the app. Multi-schedule cases use those APIs directly.
@MainActor
extension ScheduleStore {
    var schedule: AffirmationSchedule { schedules[0] }

    func editFirst(_ change: (inout AffirmationSchedule) -> Void) throws {
        var updated = schedules
        change(&updated[0])
        try replace(with: updated)
    }
    func setEnabled(_ value: Bool) throws { try editFirst { $0.isEnabled = value } }
    func setStartTime(_ value: TimeOfDay) throws { try editFirst { $0.startTime = value } }
    func setEndTime(_ value: TimeOfDay) throws { try editFirst { $0.endTime = value } }
    func setNotificationsPerDay(_ value: Int) throws { try editFirst { $0.notificationsPerDay = value } }
}

@MainActor
extension NotificationCoordinator {
    func editFirst(_ change: (inout AffirmationSchedule) -> Void) async throws {
        var updated = scheduleStore.schedules[0]
        change(&updated)
        try await saveSchedule(updated)
    }
    func setEnabled(_ value: Bool) async throws { try await editFirst { $0.isEnabled = value } }
    func setStartTime(_ value: TimeOfDay) async throws { try await editFirst { $0.startTime = value } }
    func setEndTime(_ value: TimeOfDay) async throws { try await editFirst { $0.endTime = value } }
    func setNotificationsPerDay(_ value: Int) async throws { try await editFirst { $0.notificationsPerDay = value } }
    func setRhythm(_ value: ScheduleRhythm) async throws { try await editFirst { $0.rhythm = value } }
    func setEmphasis(_ value: ScheduleEmphasis) async throws { try await editFirst { $0.emphasis = value } }
    func setScheduleSelection(_ value: AffirmationSelection) async throws { try await editFirst { $0.selection = value } }
    var firstScheduleAffirmations: [Affirmation] { matchingAffirmations(for: scheduleStore.schedules[0]) }
}

extension ScheduleRepository {
    func loadNotificationSound() throws -> NotificationSound? { nil }
    func saveNotificationSound(_ sound: NotificationSound) throws {}
    func loadSchedule() throws -> AffirmationSchedule? { try loadSchedules()?.first }
    func saveSchedule(_ schedule: AffirmationSchedule) throws { try saveSchedules([schedule]) }
}

extension TodayAffirmationResolver {
    func affirmation(at date: Date, schedule: AffirmationSchedule, affirmations: [Affirmation], calendar: Calendar) -> Affirmation? {
        context(at: date, schedules: [schedule], affirmations: affirmations, fallbackSelection: .all, name: "", calendar: calendar).affirmation
    }
    func nextChange(after date: Date, schedule: AffirmationSchedule, calendar: Calendar) -> Date {
        context(at: date, schedules: [schedule], affirmations: [Affirmation(text: "Example")], fallbackSelection: .all, name: "", calendar: calendar).nextChange
    }
}

extension TodayBrowsingState {
    func affirmation(at date: Date, schedule: AffirmationSchedule, affirmations: [Affirmation], calendar: Calendar) -> Affirmation? {
        affirmation(at: date, context: TodayAffirmationResolver().context(
            at: date, schedules: [schedule], affirmations: affirmations, fallbackSelection: .all, name: "", calendar: calendar
        ))
    }
    @discardableResult
    mutating func cycle(by offset: Int, at date: Date, schedule: AffirmationSchedule, affirmations: [Affirmation], calendar: Calendar) -> Affirmation? {
        cycle(by: offset, at: date, context: TodayAffirmationResolver().context(
            at: date, schedules: [schedule], affirmations: affirmations, fallbackSelection: .all, name: "", calendar: calendar
        ))
    }
}
