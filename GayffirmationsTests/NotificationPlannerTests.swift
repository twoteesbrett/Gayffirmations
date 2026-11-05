import Foundation
import Testing
@testable import Gayffirmations

@MainActor
struct NotificationPlannerTests {
    private let planner = NotificationPlanner()
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
    private let epoch = Date(timeIntervalSinceReferenceDate: 0)

    @Test("Reminder times and affirmation text are combined")
    func createsReminders() throws {
        let affirmations = [
            Affirmation(text: "First"),
            Affirmation(text: "Second")
        ]
        let schedule = AffirmationSchedule(
            isEnabled: true,
            startTime: TimeOfDay(hour: 9, minute: 0),
            endTime: TimeOfDay(hour: 13, minute: 0),
            notificationsPerDay: 2
        )

        let slots = try planner.plan(
            for: [schedule], affirmations: affirmations, name: "", on: epoch, calendar: calendar
        )
        #expect(slots.map(\.time) == [TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 12, minute: 0)])
        #expect(slots.map(\.affirmation.text) == ["First", "Second"])
        #expect(slots.map(\.id) == (0..<2).map { "gayffirmations.schedule.\(schedule.id.uuidString).\($0)" })
    }

    @Test("Affirmations repeat when there are more reminders than affirmations")
    func cyclesAffirmations() throws {
        let affirmations = [
            Affirmation(text: "First"),
            Affirmation(text: "Second")
        ]
        let schedule = AffirmationSchedule(
            isEnabled: true,
            startTime: TimeOfDay(hour: 9, minute: 0),
            endTime: TimeOfDay(hour: 15, minute: 0),
            notificationsPerDay: 3
        )

        let slots = try planner.plan(
            for: [schedule], affirmations: affirmations, name: "", on: epoch, calendar: calendar
        )
        #expect(slots.map(\.affirmation.text) == ["First", "Second", "First"])
    }

    @Test func upcomingRemindersRotateWrapAndMatchToday() throws {
        let schedule = AffirmationSchedule(isEnabled: true)
        let entries = (1...9).map { Affirmation(text: "Message \($0)") }
        let reminders = try planner.upcomingReminders(
            for: [schedule], affirmations: entries, name: "", sound: .none,
            after: epoch, calendar: calendar
        )
        #expect(reminders.count == NotificationReminder.pendingLimit)
        #expect(Set(reminders.map(\.identifier)).count == reminders.count)
        #expect(reminders.allSatisfy { $0.deliveryDate > epoch && $0.sound == .none })
        #expect(reminders.map(\.deliveryDate) == reminders.map(\.deliveryDate).sorted())
        #expect(reminders.prefix(12).map(\.affirmationText) == (Array(entries) + entries.prefix(3)).map(\.text))

        for reminder in reminders.prefix(12) {
            let context = TodayAffirmationResolver().context(
                at: reminder.deliveryDate, schedules: [schedule], affirmations: entries,
                fallbackSelection: .all, name: "", calendar: calendar
            )
            #expect(context.affirmation?.text == reminder.affirmationText)
        }
    }

    @Test func upcomingRemindersUseTheSameDaylightSavingOccurrencesAsToday() throws {
        var calendar = calendar
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        let schedule = AffirmationSchedule(
            isEnabled: true, startTime: TimeOfDay(hour: 2, minute: 7),
            endTime: TimeOfDay(hour: 3, minute: 37), notificationsPerDay: 2
        )
        let entries = [Affirmation(text: "First"), Affirmation(text: "Second")]
        for (start, first, second, firstText) in [
            ("2026-04-04T12:00:00Z", "2026-04-04T13:30:00Z", "2026-04-04T15:15:00Z", "First"),
            ("2026-09-26T13:00:00Z", "2026-09-26T14:15:00Z", "2026-09-26T14:30:00Z", "Second")
        ] {
            let reminders = try planner.upcomingReminders(
                for: [schedule], affirmations: entries, name: "", sound: .none,
                after: Date(start, strategy: .iso8601), calendar: calendar
            )
            let expected = try [first, second].map { try Date($0, strategy: .iso8601) }
            #expect(reminders.prefix(2).map(\.deliveryDate) == expected)
            #expect(reminders.first?.affirmationText == firstText)
            for reminder in reminders.prefix(2) {
                let context = TodayAffirmationResolver().context(
                    at: reminder.deliveryDate, schedules: [schedule], affirmations: entries,
                    fallbackSelection: .all, name: "", calendar: calendar
                )
                #expect(context.affirmation?.text == reminder.affirmationText)
            }
        }
    }

    @Test("An empty selection still rejects invalid reminder counts", arguments: [0, 25])
    func emptySelectionRejectsInvalidCounts(count: Int) {
        let schedule = AffirmationSchedule(isEnabled: true, notificationsPerDay: count)

        #expect(throws: ScheduleCalculatorError.invalidReminderCount) {
            try planner.plan(for: [schedule], affirmations: [], name: "")
        }
    }

    @Test("An empty selection pauses delivery")
    func emptySelectionPausesDelivery() throws {
        let schedule = AffirmationSchedule(isEnabled: true, notificationsPerDay: 1)
        #expect(try planner.plan(for: [schedule], affirmations: [], name: "").isEmpty)
    }

    @Test("An empty selection still rejects invalid reminder times")
    func emptySelectionValidatesSchedule() {
        let schedule = AffirmationSchedule(
            isEnabled: true,
            startTime: TimeOfDay(hour: 17, minute: 0),
            endTime: TimeOfDay(hour: 9, minute: 0)
        )
        #expect(throws: ScheduleCalculatorError.endMustBeAfterStart) {
            try planner.plan(for: [schedule], affirmations: [], name: "")
        }
    }
}
