import Foundation

enum NotificationPlannerError: LocalizedError, Equatable {
    case noAffirmations

    var errorDescription: String? {
        switch self {
        case .noAffirmations:
            "Add at least one affirmation before enabling reminders."
        }
    }
}

struct NotificationPlanner {
    private let calculator = ScheduleCalculator()

    func reminders(
        for schedule: AffirmationSchedule,
        affirmations: [Affirmation]
    ) throws -> [NotificationReminder] {
        let times = try calculator.notificationTimes(for: schedule)

        guard !times.isEmpty else {
            return []
        }

        guard !affirmations.isEmpty else {
            throw NotificationPlannerError.noAffirmations
        }

        return times.enumerated().map { index, time in
            NotificationReminder(
                time: time,
                affirmationText: affirmations[index % affirmations.count].text
            )
        }
    }
}
