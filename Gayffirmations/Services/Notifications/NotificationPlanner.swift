import Foundation

struct NotificationPlanner {
    private let calculator = ScheduleCalculator()

    func reminders(
        for schedule: AffirmationSchedule,
        affirmations: [Affirmation]
    ) throws -> [NotificationReminder] {
        let times = try calculator.notificationTimes(for: schedule)

        // An empty selected library pauses delivery, but still validates the schedule.
        guard !affirmations.isEmpty else { return [] }

        return times.enumerated().map { index, time in
            NotificationReminder(
                time: time,
                affirmationText: affirmations[index % affirmations.count].text,
                sound: schedule.sound
            )
        }
    }
}
