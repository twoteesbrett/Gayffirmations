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
        let plan = (try? NotificationPlanner().plan(for: schedules, affirmations: affirmations, name: name)) ?? []
        let dayInterval = calendar.dateInterval(of: .day, for: date)
        let tomorrow = dayInterval?.end ?? date.addingTimeInterval(24 * 60 * 60)
        if let day = dayInterval, !plan.isEmpty {
            let today = occurrences(in: day, plan: plan, calendar: calendar)
            let latest = today.last { $0.date <= date }
                ?? calendar.dateInterval(of: .day, for: day.start.addingTimeInterval(-1)).flatMap {
                    occurrences(in: $0, plan: plan, calendar: calendar).last
                }
            let next = today.first { $0.date > date }
                ?? calendar.dateInterval(of: .day, for: tomorrow).flatMap {
                    occurrences(in: $0, plan: plan, calendar: calendar).first
                }
            if let slot = latest?.slot,
               let schedule = schedules.first(where: { $0.id == slot.scheduleID }) {
                let currentTime = TimeOfDay(date: date, calendar: calendar)
                return TodayAffirmationContext(
                    affirmation: slot.affirmation,
                    browsingAffirmations: resolved(schedule.selection, in: affirmations, name: name),
                    theme: (schedule.startTime...schedule.endTime).contains(currentTime) ? schedule.theme : nil,
                    nextChange: next?.date ?? tomorrow
                )
            }
        }

        let entries = resolved(fallbackSelection, in: affirmations, name: name)
        let referenceDay = calendar.startOfDay(for: Date(timeIntervalSince1970: 0))
        let day = calendar.startOfDay(for: date)
        let index = calendar.dateComponents([.day], from: referenceDay, to: day).day ?? 0
        let affirmation = entries.isEmpty ? nil : entries[((index % entries.count) + entries.count) % entries.count]
        return TodayAffirmationContext(affirmation: affirmation, browsingAffirmations: entries, nextChange: tomorrow)
    }

    private func occurrences(
        in day: DateInterval,
        plan: [ScheduledAffirmation],
        calendar: Calendar
    ) -> [(date: Date, slot: ScheduledAffirmation)] {
        plan.compactMap { slot in
            slot.time.occurrence(in: day, calendar: calendar).map { (date: $0, slot: slot) }
        }.sorted { $0.date < $1.date }
    }

    private func resolved(_ selection: AffirmationSelection, in affirmations: [Affirmation], name: String) -> [Affirmation] {
        selection.matchingAffirmations(in: affirmations).compactMap { $0.resolved(name: name) }
    }
}
