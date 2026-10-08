import Foundation

enum ScheduleValidationError: LocalizedError, Equatable {
    case duplicateIdentity
    case dailyLimit
    case scheduleNotFound

    var errorDescription: String? {
        switch self {
        case .duplicateIdentity: "Each schedule must have its own identity."
        case .dailyLimit: "Choose no more than 24 reminders per day across enabled schedules."
        case .scheduleNotFound: "This schedule is no longer available."
        }
    }
}

struct ScheduleValidation {
    static let dailyReminderLimit = 24

    static func validate(_ schedules: [AffirmationSchedule]) throws {
        guard Set(schedules.map(\.id)).count == schedules.count else {
            throw ScheduleValidationError.duplicateIdentity
        }
        var dailyTotal = 0
        for schedule in schedules {
            _ = try ScheduleCalculator().notificationTimes(for: schedule)
            if schedule.isEnabled { dailyTotal += schedule.notificationsPerDay }
            guard dailyTotal <= dailyReminderLimit else { throw ScheduleValidationError.dailyLimit }
        }
    }
}
