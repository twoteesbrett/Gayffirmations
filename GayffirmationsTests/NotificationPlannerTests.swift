import Testing
@testable import Gayffirmations

@MainActor
struct NotificationPlannerTests {
    private let planner = NotificationPlanner()

    @Test("Reminder times and affirmation text are combined")
    func createsReminders() throws {
        let affirmations = [
            Affirmation(text: "First"),
            Affirmation(text: "Second")
        ]
        let schedule = AffirmationSchedule(
            startTime: TimeOfDay(hour: 9, minute: 0),
            endTime: TimeOfDay(hour: 13, minute: 0),
            notificationsPerDay: 2
        )

        let reminders = try planner.reminders(
            for: schedule,
            affirmations: affirmations
        )

        #expect(reminders == [
            NotificationReminder(
                time: TimeOfDay(hour: 10, minute: 0),
                affirmationText: "First"
            ),
            NotificationReminder(
                time: TimeOfDay(hour: 12, minute: 0),
                affirmationText: "Second"
            )
        ])
    }

    @Test("Affirmations repeat when there are more reminders than affirmations")
    func cyclesAffirmations() throws {
        let affirmations = [
            Affirmation(text: "First"),
            Affirmation(text: "Second")
        ]
        let schedule = AffirmationSchedule(
            startTime: TimeOfDay(hour: 9, minute: 0),
            endTime: TimeOfDay(hour: 15, minute: 0),
            notificationsPerDay: 3
        )

        let reminders = try planner.reminders(
            for: schedule,
            affirmations: affirmations
        )

        #expect(reminders.map(\.affirmationText) == [
            "First", "Second", "First"
        ])
    }

    @Test("An empty selection still rejects invalid reminder counts", arguments: [0, 25])
    func emptySelectionRejectsInvalidCounts(count: Int) {
        let schedule = AffirmationSchedule(notificationsPerDay: count)

        #expect(throws: ScheduleCalculatorError.invalidReminderCount) {
            try planner.reminders(for: schedule, affirmations: [])
        }
    }

    @Test("An empty selection pauses delivery")
    func emptySelectionPausesDelivery() throws {
        let schedule = AffirmationSchedule(notificationsPerDay: 1)
        #expect(try planner.reminders(for: schedule, affirmations: []).isEmpty)
    }

    @Test("An empty selection still rejects invalid reminder times")
    func emptySelectionValidatesSchedule() {
        let schedule = AffirmationSchedule(
            startTime: TimeOfDay(hour: 17, minute: 0),
            endTime: TimeOfDay(hour: 9, minute: 0)
        )
        #expect(throws: ScheduleCalculatorError.endMustBeAfterStart) {
            try planner.reminders(for: schedule, affirmations: [])
        }
    }
}
