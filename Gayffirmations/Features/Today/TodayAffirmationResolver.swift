import Foundation

struct TodayAffirmationContext {
    let affirmation: Affirmation?
    let browsingAffirmations: [Affirmation]
    var scheduleName: String? = nil
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
        var nextChange = tomorrow
        var current: (schedule: AffirmationSchedule, affirmation: Affirmation, changedAt: Date)?

        if let day {
            let occurrences = (try? NotificationPlanner().occurrences(
                for: schedules, affirmations: affirmations, name: name, on: [day], calendar: calendar
            )) ?? []
            let slotsBySchedule = Dictionary(grouping: occurrences, by: \.slot.scheduleID)
            for schedule in schedules {
                guard let slots = slotsBySchedule[schedule.id], let first = slots.first,
                      let startTime = schedule.startTime.occurrence(in: day, calendar: calendar),
                      let endTime = schedule.endTime.occurrence(in: day, calendar: calendar) else { continue }

                // A clock change can reorder a shifted boundary and a reminder.
                let start = min(startTime, first.date)
                // Keep the final minute in the window so a reminder rounded to the end can appear.
                let end = endTime.addingTimeInterval(60)
                if date < start {
                    nextChange = min(nextChange, start)
                    continue
                }
                guard date < end else { continue }

                nextChange = min(nextChange, end)
                if let nextSlot = slots.first(where: { $0.date > date }) {
                    nextChange = min(nextChange, nextSlot.date)
                }
                let latestSlot = slots.last { $0.date <= date }
                let changedAt = latestSlot?.date ?? start
                // Later entries in saved schedule order win ties.
                if current.map({ changedAt >= $0.changedAt }) ?? true {
                    current = (schedule, (latestSlot ?? first).slot.affirmation, changedAt)
                }
            }
        }

        if let current {
            let schedule = current.schedule
            return TodayAffirmationContext(
                affirmation: current.affirmation,
                browsingAffirmations: resolved(schedule.selection, in: affirmations, name: name),
                scheduleName: schedule.name.isEmpty ? schedule.summary : schedule.name,
                theme: schedule.theme,
                nextChange: nextChange
            )
        }

        let entries = resolved(fallbackSelection, in: affirmations, name: name)
        let referenceDay = calendar.startOfDay(for: Date(timeIntervalSince1970: 0))
        let index = calendar.dateComponents([.day], from: referenceDay, to: calendar.startOfDay(for: date)).day ?? 0
        let affirmation = entries.isEmpty ? nil : entries[((index % entries.count) + entries.count) % entries.count]
        return TodayAffirmationContext(affirmation: affirmation, browsingAffirmations: entries, nextChange: nextChange)
    }

    private func resolved(_ selection: AffirmationSelection, in affirmations: [Affirmation], name: String) -> [Affirmation] {
        selection.matchingAffirmations(in: affirmations).compactMap { $0.resolved(name: name) }
    }
}
