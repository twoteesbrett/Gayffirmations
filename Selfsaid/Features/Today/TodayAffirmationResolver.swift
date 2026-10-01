import Foundation

/// Uses the same slot order as recurring reminders; without reminders, rotates daily.
struct TodayAffirmationResolver {
    func affirmation(
        at date: Date,
        schedule: AffirmationSchedule,
        affirmations: [Affirmation],
        calendar: Calendar = .current
    ) -> Affirmation? {
        guard !affirmations.isEmpty else { return nil }

        let index: Int
        if let times = scheduledTimes(for: schedule),
           !times.isEmpty {
            let currentTime = TimeOfDay(date: date, calendar: calendar)
            // Before today's first reminder, yesterday's final slot remains current.
            index = times.lastIndex(where: { $0 <= currentTime }) ?? times.count - 1
        } else {
            let referenceDay = calendar.startOfDay(for: Date(timeIntervalSince1970: 0))
            let day = calendar.startOfDay(for: date)
            index = calendar.dateComponents([.day], from: referenceDay, to: day).day ?? 0
        }

        let wrappedIndex = ((index % affirmations.count) + affirmations.count) % affirmations.count
        return affirmations[wrappedIndex]
    }

    func nextChange(
        after date: Date,
        schedule: AffirmationSchedule,
        calendar: Calendar = .current
    ) -> Date {
        let tomorrow = calendar.dateInterval(of: .day, for: date)?.end
            ?? date.addingTimeInterval(24 * 60 * 60)
        guard let times = scheduledTimes(for: schedule),
              let firstTime = times.first else {
            return tomorrow
        }

        return times.map { $0.date(on: date, calendar: calendar) }.first { $0 > date }
            ?? firstTime.date(on: tomorrow, calendar: calendar)
    }

    private func scheduledTimes(for schedule: AffirmationSchedule) -> [TimeOfDay]? {
        guard schedule.isEnabled else { return nil }
        return try? ScheduleCalculator().notificationTimes(for: schedule)
    }
}
