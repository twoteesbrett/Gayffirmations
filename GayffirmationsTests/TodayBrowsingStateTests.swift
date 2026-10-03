import Foundation
import Testing
@testable import Gayffirmations

struct TodayBrowsingStateTests {
    private let entries = (0..<3).map { Affirmation(text: "Affirmation \($0)") }
    private let schedule = AffirmationSchedule(isEnabled: true, notificationsPerDay: 2)
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: hour))!
    }

    @Test func browsingWrapsInBothDirections() {
        var state = TodayBrowsingState()
        let now = date(hour: 12)
        #expect(state.cycle(by: -1, at: now, schedule: schedule, affirmations: entries, calendar: calendar) == entries[2])
        #expect(state.cycle(by: 1, at: now, schedule: schedule, affirmations: entries, calendar: calendar) == entries[0])
    }

    @Test func manualChoiceExpiresAtReminderBoundary() {
        var state = TodayBrowsingState()
        let now = date(hour: 12)
        state.cycle(by: -1, at: now, schedule: schedule, affirmations: entries, calendar: calendar)
        #expect(state.affirmation(at: now, schedule: schedule, affirmations: entries, calendar: calendar) == entries[2])
        #expect(state.affirmation(at: date(hour: 15), schedule: schedule, affirmations: entries, calendar: calendar) == entries[1])
    }

    @Test func resetAndRemovedEntryReturnToScheduledChoice() {
        var state = TodayBrowsingState()
        let now = date(hour: 12)
        state.cycle(by: -1, at: now, schedule: schedule, affirmations: entries, calendar: calendar)
        #expect(state.affirmation(at: now, schedule: schedule, affirmations: Array(entries.prefix(2)), calendar: calendar) == entries[0])
        state.reset()
        #expect(state.affirmation(at: now, schedule: schedule, affirmations: entries, calendar: calendar) == entries[0])
    }

    @Test func dailyBrowsingExpiresAtMidnight() {
        var state = TodayBrowsingState()
        let schedule = AffirmationSchedule()
        let now = date(hour: 12)
        let midnight = calendar.date(byAdding: .day, value: 1, to: date(hour: 0))!
        let resolver = TodayAffirmationResolver()
        let chosen = state.cycle(by: -1, at: now, schedule: schedule, affirmations: entries, calendar: calendar)
        #expect(state.affirmation(at: now, schedule: schedule, affirmations: entries, calendar: calendar) == chosen)
        #expect(state.affirmation(at: midnight, schedule: schedule, affirmations: entries, calendar: calendar)
                == resolver.affirmation(at: midnight, schedule: schedule, affirmations: entries, calendar: calendar))
    }

    @Test func emptyAndSingleLibrariesCannotCycle() {
        var state = TodayBrowsingState()
        for entries in [[], [entries[0]]] {
            #expect(state.cycle(by: 1, at: date(hour: 12), schedule: schedule, affirmations: entries, calendar: calendar) == nil)
        }
    }
}
