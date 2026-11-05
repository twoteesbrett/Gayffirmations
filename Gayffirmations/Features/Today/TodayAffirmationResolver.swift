import Foundation

struct TodayAffirmationContext {
    let affirmation: Affirmation?
    let browsingAffirmations: [Affirmation]
    var theme: AppTheme? = nil
    let nextChange: Date
}

struct TodayAffirmationResolver {
    func context(
        at date: Date,
        schedules: [AffirmationSchedule],
        affirmations: [Affirmation],
        fallbackSelection: AffirmationSelection,
        name: String,
        calendar: Calendar = .current
    ) -> TodayAffirmationContext {
        let day = calendar.dateInterval(of: .day, for: date)
        let tomorrow = day?.end ?? date.addingTimeInterval(24 * 60 * 60)
        if let day {
            let days = [
                calendar.dateInterval(of: .day, for: day.start.addingTimeInterval(-1)),
                day,
                calendar.dateInterval(of: .day, for: tomorrow)
            ].compactMap { $0 }
            let occurrences = (try? NotificationPlanner().occurrences(
                for: schedules, affirmations: affirmations, name: name, on: days, calendar: calendar
            )) ?? []
            if let slot = occurrences.last(where: { $0.date <= date })?.slot,
               let schedule = schedules.first(where: { $0.id == slot.scheduleID }) {
                let currentTime = TimeOfDay(date: date, calendar: calendar)
                return TodayAffirmationContext(
                    affirmation: slot.affirmation,
                    browsingAffirmations: resolved(schedule.selection, in: affirmations, name: name),
                    theme: (schedule.startTime...schedule.endTime).contains(currentTime) ? schedule.theme : nil,
                    nextChange: occurrences.first { $0.date > date }?.date ?? tomorrow
                )
            }
        }

        let entries = resolved(fallbackSelection, in: affirmations, name: name)
        let referenceDay = calendar.startOfDay(for: Date(timeIntervalSince1970: 0))
        let index = calendar.dateComponents([.day], from: referenceDay, to: calendar.startOfDay(for: date)).day ?? 0
        let affirmation = entries.isEmpty ? nil : entries[((index % entries.count) + entries.count) % entries.count]
        return TodayAffirmationContext(affirmation: affirmation, browsingAffirmations: entries, nextChange: tomorrow)
    }

    private func resolved(_ selection: AffirmationSelection, in affirmations: [Affirmation], name: String) -> [Affirmation] {
        selection.matchingAffirmations(in: affirmations).compactMap { $0.resolved(name: name) }
    }
}
