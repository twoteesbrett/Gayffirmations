import Testing
@testable import Gayffirmations

@MainActor
struct ScheduleCalculatorTests {
    private let calculator = ScheduleCalculator()

    @Test("A narrow period cannot deliver several reminders at the same minute")
    func rejectsDuplicateTimes() {
        let schedule = AffirmationSchedule(
            startTime: TimeOfDay(hour: 9, minute: 0),
            endTime: TimeOfDay(hour: 9, minute: 1),
            notificationsPerDay: 4
        )
        #expect(throws: ScheduleCalculatorError.remindersTooClose) {
            try calculator.notificationTimes(for: schedule)
        }
    }

    @Test("Four reminders are centered in equal sections")
    func commonSchedule() throws {
        let schedule = AffirmationSchedule(
            startTime: TimeOfDay(hour: 9, minute: 0),
            endTime: TimeOfDay(hour: 17, minute: 0),
            notificationsPerDay: 4
        )

        let times = try calculator.notificationTimes(for: schedule)

        #expect(times == [
            TimeOfDay(hour: 10, minute: 0),
            TimeOfDay(hour: 12, minute: 0),
            TimeOfDay(hour: 14, minute: 0),
            TimeOfDay(hour: 16, minute: 0)
        ])
    }

    @Test("One reminder is placed at the period midpoint")
    func oneReminder() throws {
        let schedule = AffirmationSchedule(
            startTime: TimeOfDay(hour: 8, minute: 30),
            endTime: TimeOfDay(hour: 10, minute: 30),
            notificationsPerDay: 1
        )

        #expect(
            try calculator.notificationTimes(for: schedule)
                == [TimeOfDay(hour: 9, minute: 30)]
        )
    }

    @Test("Uneven periods are distributed to the nearest minute")
    func unevenSchedule() throws {
        let schedule = AffirmationSchedule(
            startTime: TimeOfDay(hour: 9, minute: 0),
            endTime: TimeOfDay(hour: 10, minute: 0),
            notificationsPerDay: 4
        )

        #expect(try calculator.notificationTimes(for: schedule) == [
            TimeOfDay(hour: 9, minute: 8),
            TimeOfDay(hour: 9, minute: 23),
            TimeOfDay(hour: 9, minute: 38),
            TimeOfDay(hour: 9, minute: 53)
        ])
    }

    @Test("Zero reminders produces no times")
    func zeroReminders() throws {
        let schedule = AffirmationSchedule(notificationsPerDay: 0)

        #expect(try calculator.notificationTimes(for: schedule).isEmpty)
    }

    @Test("An end time before the start time is rejected")
    func endBeforeStart() {
        let schedule = AffirmationSchedule(
            startTime: TimeOfDay(hour: 17, minute: 0),
            endTime: TimeOfDay(hour: 9, minute: 0)
        )

        #expect(throws: ScheduleCalculatorError.endMustBeAfterStart) {
            try calculator.notificationTimes(for: schedule)
        }
    }

    @Test("Matching start and end times are rejected")
    func matchingTimes() {
        let schedule = AffirmationSchedule(
            startTime: TimeOfDay(hour: 9, minute: 0),
            endTime: TimeOfDay(hour: 9, minute: 0)
        )

        #expect(throws: ScheduleCalculatorError.endMustBeAfterStart) {
            try calculator.notificationTimes(for: schedule)
        }
    }
}
