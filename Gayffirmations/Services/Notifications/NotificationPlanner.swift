import Foundation

/// A single source of truth for notification content, previews, and Today.
struct ScheduledAffirmation: Identifiable, Equatable {
    let scheduleID: UUID
    let slot: Int
    let time: TimeOfDay
    let affirmation: Affirmation
    let sound: NotificationSound

    var id: String { "gayffirmations.schedule.\(scheduleID.uuidString).\(slot)" }
    var reminder: NotificationReminder {
        NotificationReminder(time: time, affirmationText: affirmation.text, sound: sound, identifier: id)
    }
}

struct NotificationPlanner {
    private let calculator = ScheduleCalculator()

    func plan(
        for schedules: [AffirmationSchedule],
        affirmations: [Affirmation],
        name: String,
        sound: NotificationSound = .systemDefault
    ) throws -> [ScheduledAffirmation] {
        try ScheduleValidation.validate(schedules)
        var result: [ScheduledAffirmation] = []
        for schedule in schedules where schedule.isEnabled {
            let entries = schedule.selection.matchingAffirmations(in: affirmations)
                .compactMap { $0.resolved(name: name) }
            result += try slots(for: schedule, affirmations: entries, sound: sound)
        }
        // Ties follow the saved schedule order. Today consistently shows the last one.
        return result.enumerated().sorted {
            $0.element.time == $1.element.time
                ? $0.offset < $1.offset : $0.element.time < $1.element.time
        }.map(\.element)
    }

    private func slots(
        for schedule: AffirmationSchedule,
        affirmations: [Affirmation],
        sound: NotificationSound
    ) throws -> [ScheduledAffirmation] {
        let times = try calculator.notificationTimes(for: schedule)
        guard !affirmations.isEmpty else { return [] }
        return times.enumerated().map { index, time in
            ScheduledAffirmation(
                scheduleID: schedule.id, slot: index, time: time,
                affirmation: affirmations[index % affirmations.count], sound: sound
            )
        }
    }
}
