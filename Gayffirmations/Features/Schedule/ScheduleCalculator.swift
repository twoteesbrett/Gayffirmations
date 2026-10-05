import Foundation

enum ScheduleCalculatorError: LocalizedError, Equatable {
    case invalidReminderCount
    case endMustBeAfterStart
    case remindersTooClose

    var errorDescription: String? {
        switch self {
        case .invalidReminderCount:
            "Choose between \(AffirmationSchedule.notificationCountRange.lowerBound) and \(AffirmationSchedule.notificationCountRange.upperBound) reminders per day."
        case .endMustBeAfterStart:
            "End time must be later than start time."
        case .remindersTooClose:
            "Choose a longer daily period, fewer reminders, or gentler emphasis so each reminder has a different delivery time."
        }
    }
}

struct ScheduleCalculator {
    func notificationTimes(
        for schedule: AffirmationSchedule
    ) throws -> [TimeOfDay] {
        guard AffirmationSchedule.notificationCountRange.contains(schedule.notificationsPerDay) else {
            throw ScheduleCalculatorError.invalidReminderCount
        }

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
            // Blend linear positions with mirrored quadratic curves. Keeping the
            // weight below one avoids collapsing delivery at either boundary.
            let weightedPosition: Double
            switch schedule.rhythm {
            case .evenlySpaced:
                weightedPosition = position
            case .moreEarly:
                weightedPosition = position + schedule.emphasis.weight * (position * position - position)
            case .moreLate:
                weightedPosition = position + schedule.emphasis.weight * (position - position * position)
            }
            let minutes = Double(start) + Double(duration) * weightedPosition
            return TimeOfDay(minutesSinceMidnight: Int(minutes.rounded()))
        }
        guard Set(times.map(\.minutesSinceMidnight)).count == times.count else {
            throw ScheduleCalculatorError.remindersTooClose
        }
        return times
    }
}
