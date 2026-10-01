import Foundation

enum ScheduleCalculatorError: LocalizedError, Equatable {
    case endMustBeAfterStart
    case remindersTooClose

    var errorDescription: String? {
        switch self {
        case .endMustBeAfterStart:
            "End time must be later than start time."
        case .remindersTooClose:
            "Choose a longer daily period or fewer reminders so each reminder has a different delivery time."
        }
    }
}

struct ScheduleCalculator {
    func notificationTimes(
        for schedule: AffirmationSchedule
    ) throws -> [TimeOfDay] {
        guard schedule.notificationsPerDay > 0 else {
            return []
        }

        guard schedule.endTime > schedule.startTime else {
            throw ScheduleCalculatorError.endMustBeAfterStart
        }

        let start = schedule.startTime.minutesSinceMidnight
        let duration = schedule.endTime.minutesSinceMidnight - start
        let count = schedule.notificationsPerDay

        let times = (0..<count).map { index in
            let position = (Double(index) + 0.5) / Double(count)
            let minutes = Double(start) + Double(duration) * position
            return TimeOfDay(minutesSinceMidnight: Int(minutes.rounded()))
        }
        guard Set(times.map(\.minutesSinceMidnight)).count == times.count else {
            throw ScheduleCalculatorError.remindersTooClose
        }
        return times
    }
}
