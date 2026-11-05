import Foundation

/// A single source of truth for notification content, previews, and Today.
struct ScheduledAffirmation: Identifiable, Equatable {
    let scheduleID: UUID
    let slot: Int
    let time: TimeOfDay
    let affirmation: Affirmation
    let sound: NotificationSound

    var id: String { "gayffirmations.schedule.\(scheduleID.uuidString).\(slot)" }
}

struct DatedAffirmation {
    let date: Date
    let slot: ScheduledAffirmation

    var reminder: NotificationReminder {
        NotificationReminder(
            deliveryDate: date,
            affirmationText: MessageMarkup(slot.affirmation.text).plainText,
            sound: slot.sound,
            identifier: "\(slot.id).\(Int(date.timeIntervalSince1970))"
        )
    }
}

struct NotificationPlanner {
    private let calculator = ScheduleCalculator()

    func plan(
        for schedules: [AffirmationSchedule],
        affirmations: [Affirmation],
        name: String,
        sound: NotificationSound = .systemDefault,
        on date: Date = .now,
        calendar: Calendar = .current
    ) throws -> [ScheduledAffirmation] {
        let routines = try prepare(schedules, affirmations: affirmations, name: name)
        return slots(for: routines, dayIndex: dayIndex(for: date, calendar: calendar), sound: sound)
            .sorted { $0.time < $1.time }
    }

    func occurrences(
        for schedules: [AffirmationSchedule],
        affirmations: [Affirmation],
        name: String,
        on days: [DateInterval],
        calendar: Calendar
    ) throws -> [DatedAffirmation] {
        let routines = try prepare(schedules, affirmations: affirmations, name: name)
        return days.flatMap { occurrences(for: routines, in: $0, calendar: calendar, sound: .systemDefault) }
    }

    func upcomingReminders(
        for schedules: [AffirmationSchedule],
        affirmations: [Affirmation],
        name: String,
        sound: NotificationSound,
        after date: Date,
        calendar: Calendar
    ) throws -> [NotificationReminder] {
        let routines = try prepare(schedules, affirmations: affirmations, name: name)
        guard !routines.isEmpty else { return [] }

        var reminders: [NotificationReminder] = []
        var day = calendar.dateInterval(of: .day, for: date)
        while let interval = day, reminders.count < NotificationReminder.pendingLimit {
            let remaining = NotificationReminder.pendingLimit - reminders.count
            reminders += occurrences(for: routines, in: interval, calendar: calendar, sound: sound)
                .lazy.filter { $0.date > date }.prefix(remaining).map(\.reminder)
            day = calendar.dateInterval(of: .day, for: interval.end)
        }
        return reminders
    }

    private struct Routine {
        let id: UUID
        let times: [TimeOfDay]
        let entries: [Affirmation]
    }

    private func prepare(
        _ schedules: [AffirmationSchedule],
        affirmations: [Affirmation],
        name: String
    ) throws -> [Routine] {
        try ScheduleValidation.validate(schedules)
        return try schedules.filter(\.isEnabled).compactMap { schedule in
            let entries = schedule.selection.matchingAffirmations(in: affirmations)
                .compactMap { $0.resolved(name: name) }
            guard !entries.isEmpty else { return nil }
            return Routine(id: schedule.id, times: try calculator.notificationTimes(for: schedule), entries: entries)
        }
    }

    private func occurrences(
        for routines: [Routine],
        in day: DateInterval,
        calendar: Calendar,
        sound: NotificationSound
    ) -> [DatedAffirmation] {
        slots(for: routines, dayIndex: dayIndex(for: day.start, calendar: calendar), sound: sound)
            .compactMap { slot in
                slot.time.occurrence(in: day, calendar: calendar).map { DatedAffirmation(date: $0, slot: slot) }
            }
            .sorted { $0.date < $1.date } // Stable sort retains saved schedule order for ties.
    }

    private func slots(for routines: [Routine], dayIndex: Int, sound: NotificationSound) -> [ScheduledAffirmation] {
        routines.flatMap { routine in
            let count = routine.entries.count
            let day = ((dayIndex % count) + count) % count
            let offset = day * routine.times.count
            return routine.times.enumerated().map { index, time in
                ScheduledAffirmation(
                    scheduleID: routine.id, slot: index, time: time,
                    affirmation: routine.entries[(offset + index) % count], sound: sound
                )
            }
        }
    }

    private func dayIndex(for date: Date, calendar: Calendar) -> Int {
        var civilCalendar = Calendar(identifier: .gregorian)
        civilCalendar.timeZone = calendar.timeZone
        let epoch = civilCalendar.date(from: DateComponents(year: 2001, month: 1, day: 1))!
        return civilCalendar.dateComponents([.day], from: epoch, to: civilCalendar.startOfDay(for: date)).day ?? 0
    }
}
