import Foundation

struct TodayAffirmationContext {
    let affirmation: Affirmation?
    let browsingAffirmations: [Affirmation]
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
        let plan = (try? NotificationPlanner().plan(for: schedules, affirmations: affirmations, name: name)) ?? []
        let tomorrow = calendar.dateInterval(of: .day, for: date)?.end
            ?? date.addingTimeInterval(24 * 60 * 60)
        let currentTime = TimeOfDay(date: date, calendar: calendar)
        if let slot = plan.last(where: { $0.time <= currentTime }) ?? plan.last,
           let schedule = schedules.first(where: { $0.id == slot.scheduleID }),
           let first = plan.first {
            let nextChange = plan.map { $0.time.date(on: date, calendar: calendar) }.first { $0 > date }
                ?? first.time.date(on: tomorrow, calendar: calendar)
            return TodayAffirmationContext(
                affirmation: slot.affirmation,
                browsingAffirmations: resolved(schedule.selection, in: affirmations, name: name),
                nextChange: nextChange
            )
        }

        let entries = resolved(fallbackSelection, in: affirmations, name: name)
        let referenceDay = calendar.startOfDay(for: Date(timeIntervalSince1970: 0))
        let day = calendar.startOfDay(for: date)
        let index = calendar.dateComponents([.day], from: referenceDay, to: day).day ?? 0
        let affirmation = entries.isEmpty ? nil : entries[((index % entries.count) + entries.count) % entries.count]
        return TodayAffirmationContext(affirmation: affirmation, browsingAffirmations: entries, nextChange: tomorrow)
    }

    private func resolved(_ selection: AffirmationSelection, in affirmations: [Affirmation], name: String) -> [Affirmation] {
        selection.matchingAffirmations(in: affirmations).compactMap { $0.resolved(name: name) }
    }
}
