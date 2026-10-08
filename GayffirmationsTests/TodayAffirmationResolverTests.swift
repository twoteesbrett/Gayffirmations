import Foundation
import Testing
@testable import Gayffirmations

struct TodayAffirmationResolverTests {
    private let resolver = TodayAffirmationResolver()
    private let affirmations = (0..<3).map { Affirmation(text: "Affirmation \($0)") }
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(day: Int = 1, hour: Int, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    @Test func retainsLatestSlotBetweenRemindersAndOvernight() {
        let schedule = AffirmationSchedule(isEnabled: true, notificationsPerDay: 2)
        for date in [date(hour: 15), date(hour: 23), date(day: 2, hour: 0), date(day: 2, hour: 10, minute: 59)] {
            #expect(resolver.affirmation(at: date, schedule: schedule, affirmations: affirmations, calendar: calendar)?.id == affirmations[1].id)
        }
        #expect(resolver.affirmation(at: date(hour: 11), schedule: schedule, affirmations: affirmations, calendar: calendar)?.id == affirmations[0].id)
    }

    @Test func dailyFallbackIsStableAndChangesAtMidnight() {
        let schedule = AffirmationSchedule()
        let first = resolver.affirmation(at: date(hour: 0), schedule: schedule, affirmations: affirmations, calendar: calendar)
        #expect(first != nil)
        #expect(first == resolver.affirmation(at: date(hour: 23, minute: 59), schedule: schedule, affirmations: affirmations, calendar: calendar))
        #expect(first != resolver.affirmation(at: date(day: 2, hour: 0), schedule: schedule, affirmations: affirmations, calendar: calendar))
    }

    @Test func handlesEmptyAndSingleCollections() {
        for enabled in [false, true] {
            let schedule = AffirmationSchedule(isEnabled: enabled)
            #expect(resolver.affirmation(at: date(hour: 12), schedule: schedule, affirmations: [], calendar: calendar) == nil)
            #expect(resolver.affirmation(at: date(hour: 12), schedule: schedule, affirmations: [affirmations[0]], calendar: calendar) == affirmations[0])
        }
    }

    @Test func manualSelectionExpiresAtNextReminderIncludingOvernight() {
        let schedule = AffirmationSchedule(isEnabled: true, notificationsPerDay: 2)
        #expect(resolver.nextChange(after: date(hour: 10), schedule: schedule, calendar: calendar) == date(hour: 11))
        #expect(resolver.nextChange(after: date(hour: 11), schedule: schedule, calendar: calendar) == date(hour: 15))
        #expect(resolver.nextChange(after: date(hour: 23), schedule: schedule, calendar: calendar) == date(day: 2, hour: 11))
    }

    @Test func manualSelectionExpiresAtMidnightWithoutReminders() {
        #expect(resolver.nextChange(after: date(hour: 12), schedule: AffirmationSchedule(), calendar: calendar) == date(day: 2, hour: 0))
    }


    @Test func dailyExpiryUsesLocalMidnightAcrossDaylightSaving() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Pacific/Auckland")!
        let start = calendar.date(from: DateComponents(year: 2026, month: 9, day: 27))!
        let nextMidnight = calendar.date(from: DateComponents(year: 2026, month: 9, day: 28))!

        let expiry = resolver.nextChange(after: start, schedule: AffirmationSchedule(), calendar: calendar)
        #expect(expiry == nextMidnight)
        #expect(expiry.timeIntervalSince(start) == 23 * 60 * 60)
    }

}
