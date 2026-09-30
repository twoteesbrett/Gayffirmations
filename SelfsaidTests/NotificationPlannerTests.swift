import Testing
@testable import Selfsaid

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

    @Test("A schedule with no reminders produces an empty plan")
    func emptyPlan() throws {
        let schedule = AffirmationSchedule(notificationsPerDay: 0)

        #expect(
            try planner.reminders(for: schedule, affirmations: []).isEmpty
        )
    }

    @Test("At least one affirmation is required for a non-empty plan")
    func requiresAffirmation() {
        let schedule = AffirmationSchedule(notificationsPerDay: 1)

        #expect(throws: NotificationPlannerError.noAffirmations) {
            try planner.reminders(for: schedule, affirmations: [])
        }
    }
}
