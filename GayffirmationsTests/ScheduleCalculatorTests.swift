import Testing
@testable import Gayffirmations

@MainActor
struct ScheduleCalculatorTests {
    private let calculator = ScheduleCalculator()

    @Test("Every rhythm preserves counts and stays inside the daily period",
          arguments: ScheduleRhythm.allCases, ScheduleEmphasis.allCases)
    func weightedSchedules(rhythm: ScheduleRhythm, emphasis: ScheduleEmphasis) throws {
        for count in 0...12 {
            let schedule = AffirmationSchedule(
                startTime: TimeOfDay(hour: 9, minute: 0),
                endTime: TimeOfDay(hour: 23, minute: 0),
                notificationsPerDay: count, rhythm: rhythm, emphasis: emphasis
            )
            let times = try calculator.notificationTimes(for: schedule)
            #expect(times.count == count)
            #expect(times == times.sorted())
            #expect(Set(times.map(\.minutesSinceMidnight)).count == count)
            #expect(times.allSatisfy { $0 >= schedule.startTime && $0 <= schedule.endTime })
        }
    }

    @Test("Evening gaps shrink, morning gaps grow, and emphasis increases the shift")
    func weightedGaps() throws {
        var previousLateTotal = 0
        for emphasis in ScheduleEmphasis.allCases {
            let early = try calculator.notificationTimes(for: AffirmationSchedule(
                notificationsPerDay: 6, rhythm: .moreEarly, emphasis: emphasis
            )).map(\.minutesSinceMidnight)
            let late = try calculator.notificationTimes(for: AffirmationSchedule(
                notificationsPerDay: 6, rhythm: .moreLate, emphasis: emphasis
            )).map(\.minutesSinceMidnight)
            let earlyGaps = zip(early, early.dropFirst()).map { $1 - $0 }
            let lateGaps = zip(late, late.dropFirst()).map { $1 - $0 }
            #expect(zip(earlyGaps, earlyGaps.dropFirst()).allSatisfy { $0 < $1 })
            #expect(zip(lateGaps, lateGaps.dropFirst()).allSatisfy { $0 > $1 })
            #expect(late.reduce(0, +) > previousLateTotal)
            previousLateTotal = late.reduce(0, +)
            #expect(zip(early, late.reversed()).allSatisfy { $0 + $1 == 26 * 60 })
        }
    }

    @Test("Balanced evening times match the approved preview")
    func eveningExample() throws {
        let schedule = AffirmationSchedule(
            startTime: TimeOfDay(hour: 9, minute: 0),
            endTime: TimeOfDay(hour: 23, minute: 0),
            notificationsPerDay: 6, rhythm: .moreLate
        )
        #expect(try calculator.notificationTimes(for: schedule).map(\.minutesSinceMidnight)
                == [649, 845, 1013, 1153, 1265, 1349])
    }

    @Test("One weighted reminder moves toward the chosen end")
    func oneWeightedReminder() throws {
        for rhythm in [ScheduleRhythm.moreEarly, .moreLate] {
            let times = try calculator.notificationTimes(for: AffirmationSchedule(
                notificationsPerDay: 1, rhythm: rhythm
            ))
            #expect(times.count == 1)
            #expect(rhythm == .moreEarly ? times[0].hour < 13 : times[0].hour > 13)
        }
    }

    @Test("Clustering that rounds to duplicate minutes is rejected")
    func weightedDuplicates() {
        let schedule = AffirmationSchedule(
            startTime: TimeOfDay(hour: 9, minute: 0),
            endTime: TimeOfDay(hour: 9, minute: 5),
            notificationsPerDay: 5, rhythm: .moreLate, emphasis: .strong
        )
        #expect(throws: ScheduleCalculatorError.remindersTooClose) {
            try calculator.notificationTimes(for: schedule)
        }
    }

    @Test("Invalid reminder counts are rejected before calculating times", arguments: [-1, 13, Int.max])
    func rejectsInvalidReminderCounts(count: Int) {
        #expect(throws: ScheduleCalculatorError.invalidReminderCount) {
            try calculator.notificationTimes(for: AffirmationSchedule(notificationsPerDay: count))
        }
    }

    @Test("The maximum supported reminder count produces distinct times")
    func maximumReminderCount() throws {
        let times = try calculator.notificationTimes(for: AffirmationSchedule(notificationsPerDay: 12))
        #expect(times.count == 12)
        #expect(Set(times.map(\.minutesSinceMidnight)).count == 12)
    }

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
