import Foundation

/// Temporary browsing choices expire when the next scheduled affirmation begins.
struct TodayBrowsingState {
    private var manualSelection: ManualSelection?
    private let resolver = TodayAffirmationResolver()

    func affirmation(
        at date: Date,
        schedule: AffirmationSchedule,
        affirmations: [Affirmation],
        calendar: Calendar = .current
    ) -> Affirmation? {
        if let manualSelection, date < manualSelection.expiresAt,
           let affirmation = affirmations.first(where: { $0.id == manualSelection.id }) {
            return affirmation
        }
        return resolver.affirmation(
            at: date, schedule: schedule, affirmations: affirmations, calendar: calendar
        )
    }

    @discardableResult
    mutating func cycle(
        by offset: Int,
        at date: Date,
        schedule: AffirmationSchedule,
        affirmations: [Affirmation],
        calendar: Calendar = .current
    ) -> Affirmation? {
        guard affirmations.count > 1,
              let current = affirmation(at: date, schedule: schedule, affirmations: affirmations, calendar: calendar),
              let index = affirmations.firstIndex(where: { $0.id == current.id }) else { return nil }

        let count = affirmations.count
        let nextIndex = ((index + offset % count) % count + count) % count
        let next = affirmations[nextIndex]
        manualSelection = ManualSelection(
            id: next.id,
            expiresAt: resolver.nextChange(after: date, schedule: schedule, calendar: calendar)
        )
        return next
    }

    mutating func reset() {
        manualSelection = nil
    }

    /// Schedule edits affect future rotation without replacing the visible message.
    mutating func updateSchedule(
        from oldSchedule: AffirmationSchedule,
        to newSchedule: AffirmationSchedule,
        at date: Date,
        affirmations: [Affirmation],
        calendar: Calendar = .current
    ) {
        guard let current = affirmation(
            at: date, schedule: oldSchedule, affirmations: affirmations, calendar: calendar
        ) else { return }
        manualSelection = ManualSelection(
            id: current.id,
            expiresAt: resolver.nextChange(after: date, schedule: newSchedule, calendar: calendar)
        )
    }

    private struct ManualSelection {
        let id: Affirmation.ID
        let expiresAt: Date
    }
}
