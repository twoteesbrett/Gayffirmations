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

    private func date(day: Int = 2, hour: Int, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    @Test func switchesContentAndThemeAtScheduleBoundaries() {
        let fallback = Affirmation(text: "Fallback", tags: ["Fallback"])
        let schedule = AffirmationSchedule(name: "Daytime", selection: .tag("Scheduled"), theme: .steel,
                                           isEnabled: true, notificationsPerDay: 2)
        let entries = affirmations.map { Affirmation(text: $0.text, tags: ["Scheduled"]) }
        func context(_ date: Date) -> TodayAffirmationContext {
            resolver.context(at: date, schedules: [schedule], affirmations: entries + [fallback],
                             fallbackSelection: .tag("Fallback"), name: "", calendar: calendar)
        }

        for instant in [date(hour: 8, minute: 59), date(hour: 17, minute: 1), date(day: 3, hour: 8)] {
            #expect(context(instant).affirmation == fallback)
            #expect(context(instant).scheduleName == nil)
            #expect(context(instant).theme == nil)
        }
        #expect(context(date(hour: 9)).affirmation == entries[0])
        #expect(context(date(hour: 9)).scheduleName == "Daytime")
        #expect(context(date(hour: 9)).theme == .steel)
        #expect(context(date(hour: 15)).affirmation == entries[1])
    }

    @Test func dailyFallbackIsStableAndChangesAtMidnight() {
        let schedule = AffirmationSchedule()
        let first = resolver.affirmation(at: date(hour: 0), schedule: schedule, affirmations: affirmations, calendar: calendar)
        #expect(first != nil)
        #expect(first == resolver.affirmation(at: date(hour: 23, minute: 59), schedule: schedule, affirmations: affirmations, calendar: calendar))
        #expect(first != resolver.affirmation(at: date(day: 3, hour: 0), schedule: schedule, affirmations: affirmations, calendar: calendar))
    }

    @Test func handlesEmptyAndSingleCollections() {
        for enabled in [false, true] {
            let schedule = AffirmationSchedule(isEnabled: enabled)
            #expect(resolver.affirmation(at: date(hour: 12), schedule: schedule, affirmations: [], calendar: calendar) == nil)
            #expect(resolver.affirmation(at: date(hour: 12), schedule: schedule, affirmations: [affirmations[0]], calendar: calendar) == affirmations[0])
        }
    }

    @Test func manualSelectionExpiresAtScheduleBoundariesAndReminders() {
        let schedule = AffirmationSchedule(isEnabled: true, notificationsPerDay: 2)
        #expect(resolver.nextChange(after: date(hour: 8), schedule: schedule, calendar: calendar) == date(hour: 9))
        #expect(resolver.nextChange(after: date(hour: 11), schedule: schedule, calendar: calendar) == date(hour: 15))
        #expect(resolver.nextChange(after: date(hour: 15), schedule: schedule, calendar: calendar) == date(hour: 17, minute: 1))
        #expect(resolver.nextChange(after: date(hour: 23), schedule: schedule, calendar: calendar) == date(day: 3, hour: 0))
    }

    @Test func manualSelectionExpiresAtMidnightWithoutReminders() {
        #expect(resolver.nextChange(after: date(hour: 12), schedule: AffirmationSchedule(), calendar: calendar) == date(day: 3, hour: 0))
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

    @Test func repeatedHourKeepsTheFirstOccurrenceWithoutExpiringBrowsingTwice() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        let schedule = AffirmationSchedule(
            isEnabled: true,
            startTime: TimeOfDay(hour: 2, minute: 7),
            endTime: TimeOfDay(hour: 3, minute: 37),
            notificationsPerDay: 2
        )
        let first0230 = try Date("2026-04-04T13:30:00Z", strategy: .iso8601)
        let second0210 = try Date("2026-04-04T14:10:00Z", strategy: .iso8601)
        let next0315 = try Date("2026-04-04T15:15:00Z", strategy: .iso8601)

        #expect(resolver.nextChange(after: first0230.addingTimeInterval(-1), schedule: schedule, calendar: calendar) == first0230)
        for instant in [first0230, second0210] {
            let context = resolver.context(at: instant, schedules: [schedule], affirmations: affirmations,
                                           fallbackSelection: .all, name: "", calendar: calendar)
            #expect(context.affirmation == affirmations[0])
            #expect(context.nextChange == next0315)
        }
    }

    @Test func missingHourShiftsTheReminderForwardAndOrdersItByTheResultingTime() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        let schedule = AffirmationSchedule(
            isEnabled: true,
            startTime: TimeOfDay(hour: 2, minute: 7),
            endTime: TimeOfDay(hour: 3, minute: 37),
            notificationsPerDay: 2
        )
        let normal0315 = try Date("2026-09-26T14:15:00Z", strategy: .iso8601)
        let shifted0330 = try Date("2026-09-26T14:30:00Z", strategy: .iso8601)

        #expect(resolver.nextChange(after: normal0315.addingTimeInterval(-1), schedule: schedule, calendar: calendar) == normal0315)
        let context = resolver.context(at: normal0315, schedules: [schedule], affirmations: affirmations,
                                       fallbackSelection: .all, name: "", calendar: calendar)
        #expect(context.affirmation == affirmations[0])
        #expect(context.nextChange == shifted0330)
        #expect(resolver.affirmation(at: shifted0330, schedule: schedule, affirmations: affirmations, calendar: calendar) == affirmations[2])
    }

    @Test func themeFollowsTheActiveSchedule() {
        let morning = AffirmationSchedule(
            isEnabled: true, startTime: TimeOfDay(hour: 8, minute: 0),
            endTime: TimeOfDay(hour: 10, minute: 0), notificationsPerDay: 1
        )
        var evening = AffirmationSchedule(
            isEnabled: true, startTime: TimeOfDay(hour: 18, minute: 0),
            endTime: TimeOfDay(hour: 20, minute: 0), notificationsPerDay: 1
        )
        evening.theme = .steel
        func context(hour: Int) -> TodayAffirmationContext {
            resolver.context(at: date(hour: hour), schedules: [morning, evening],
                             affirmations: affirmations, fallbackSelection: .all, name: "", calendar: calendar)
        }
        #expect(context(hour: 12).theme == nil)
        #expect(context(hour: 18).theme == .steel)
        #expect(context(hour: 19).theme == .steel)
        #expect(context(hour: 21).theme == nil)
        #expect(context(hour: 6).theme == nil)
        evening.isEnabled = false
        #expect(context(hour: 21).theme == nil)
    }

    @Test func themeAppliesToReminderRoundedToScheduleEnd() {
        let schedule = AffirmationSchedule(
            theme: .steel,
            isEnabled: true,
            startTime: TimeOfDay(hour: 9, minute: 0),
            endTime: TimeOfDay(hour: 9, minute: 1),
            notificationsPerDay: 1
        )
        func context(minute: Int) -> TodayAffirmationContext {
            resolver.context(at: date(hour: 9, minute: minute), schedules: [schedule],
                             affirmations: affirmations, fallbackSelection: .all, name: "", calendar: calendar)
        }

        #expect(context(minute: 0).nextChange == date(hour: 9, minute: 1))
        #expect(context(minute: 1).theme == .steel)
        #expect(context(minute: 2).theme == nil)
    }

    @Test func schedulesWithoutReadyAffirmationsUseTheDefaultTheme() {
        let schedule = AffirmationSchedule(selection: .tag("Missing"), theme: .steel, isEnabled: true)
        let context = resolver.context(at: date(hour: 12), schedules: [schedule],
                                       affirmations: affirmations, fallbackSelection: .all, name: "", calendar: calendar)
        #expect(context.theme == nil)
    }

    @MainActor
    @Test func scheduleThemePersistsAndOlderSchedulesInheritTheDefault() throws {
        let schedule = AffirmationSchedule(theme: .steel)
        let encoded = try JSONEncoder().encode(schedule)
        #expect(try JSONDecoder().decode(AffirmationSchedule.self, from: encoded).theme == .steel)
        var legacy = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        legacy.removeValue(forKey: "theme")
        let legacyData = try JSONSerialization.data(withJSONObject: legacy)
        #expect(try JSONDecoder().decode(AffirmationSchedule.self, from: legacyData).theme == nil)
    }

}
