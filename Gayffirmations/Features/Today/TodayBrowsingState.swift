import Foundation

/// Temporary browsing choices expire at the next reminder across all schedules.
struct TodayBrowsingState {
    private var manualSelection: ManualSelection?

    func affirmation(at date: Date, context: TodayAffirmationContext) -> Affirmation? {
        if let manualSelection, date < manualSelection.expiresAt,
           let affirmation = context.browsingAffirmations.first(where: { $0.id == manualSelection.id }) {
            return affirmation
        }
        return context.affirmation
    }

    @discardableResult
    mutating func cycle(by offset: Int, at date: Date, context: TodayAffirmationContext) -> Affirmation? {
        let entries = context.browsingAffirmations
        guard entries.count > 1,
              let current = affirmation(at: date, context: context),
              let index = entries.firstIndex(where: { $0.id == current.id }) else { return nil }
        let nextIndex = ((index + offset % entries.count) % entries.count + entries.count) % entries.count
        let next = entries[nextIndex]
        manualSelection = ManualSelection(id: next.id, expiresAt: context.nextChange)
        return next
    }

    mutating func reset() { manualSelection = nil }

    private struct ManualSelection {
        let id: Affirmation.ID
        let expiresAt: Date
    }
}
