import Foundation

enum ScheduleRhythm: String, Codable, CaseIterable, Identifiable {
    case evenlySpaced, moreEarly, moreLate

    var id: Self { self }

    var title: String {
        switch self {
        case .evenlySpaced: "Evenly spaced"
        case .moreEarly: "More early"
        case .moreLate: "More late"
        }
    }

    var explanation: String {
        switch self {
        case .evenlySpaced: "Your reminders are evenly spaced throughout the day."
        case .moreEarly: "Same daily total, more reminders toward the start of your daily period."
        case .moreLate: "Same daily total, more reminders toward the end of your daily period."
        }
    }
}

enum ScheduleEmphasis: String, Codable, CaseIterable, Identifiable {
    case gentle, balanced, strong

    var id: Self { self }

    var title: String {
        switch self {
        case .gentle: "Gentle"
        case .balanced: "Balanced"
        case .strong: "Strong"
        }
    }

    var weight: Double {
        switch self {
        case .gentle: 0.3
        case .balanced: 0.6
        case .strong: 0.9
        }
    }
}

struct AffirmationSchedule: Codable, Equatable, Identifiable {
    static let notificationCountRange = 1...24

    var id: UUID
    // Retained for compatibility with previously saved schedules.
    var name: String
    var selection: AffirmationSelection
    var isEnabled: Bool
    var startTime: TimeOfDay
    var endTime: TimeOfDay
    var notificationsPerDay: Int
    // Legacy per-schedule preference, used only when migrating the global sound.
    var sound: NotificationSound
    var rhythm: ScheduleRhythm
    var emphasis: ScheduleEmphasis

    init(
        id: UUID = UUID(),
        name: String = "",
        selection: AffirmationSelection = .all,
        isEnabled: Bool = false,
        startTime: TimeOfDay = TimeOfDay(hour: 9, minute: 0),
        endTime: TimeOfDay = TimeOfDay(hour: 17, minute: 0),
        notificationsPerDay: Int = 4,
        sound: NotificationSound = .systemDefault,
        rhythm: ScheduleRhythm = .evenlySpaced,
        emphasis: ScheduleEmphasis = .balanced
    ) {
        self.id = id
        self.name = name
        self.selection = selection
        self.isEnabled = isEnabled
        self.startTime = startTime
        self.endTime = endTime
        self.notificationsPerDay = notificationsPerDay
        self.sound = sound
        self.rhythm = rhythm
        self.emphasis = emphasis
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, selection, isEnabled, startTime, endTime, notificationsPerDay, sound, rhythm, emphasis
    }

    var timeRangeDescription: String {
        "\(startTime.date().formatted(date: .omitted, time: .shortened)) – \(endTime.date().formatted(date: .omitted, time: .shortened))"
    }

    var summary: String {
        "\(timeRangeDescription) · \(selection.name)"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Daily affirmations"
        selection = try container.decodeIfPresent(AffirmationSelection.self, forKey: .selection) ?? .all
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        startTime = try container.decode(TimeOfDay.self, forKey: .startTime)
        endTime = try container.decode(TimeOfDay.self, forKey: .endTime)
        notificationsPerDay = try container.decode(Int.self, forKey: .notificationsPerDay)
        // Schedules saved before sound selection keep their existing behaviour.
        sound = try container.decodeIfPresent(NotificationSound.self, forKey: .sound) ?? .systemDefault
        // Existing schedules retain their exact evenly spaced delivery times.
        rhythm = try container.decodeIfPresent(ScheduleRhythm.self, forKey: .rhythm) ?? .evenlySpaced
        emphasis = try container.decodeIfPresent(ScheduleEmphasis.self, forKey: .emphasis) ?? .balanced
        // Zero was previously valid and meant no delivery, even when enabled.
        // Keep delivery off while giving the current controls a valid count.
        if notificationsPerDay == 0 {
            notificationsPerDay = Self.notificationCountRange.lowerBound
            isEnabled = false
        }
    }
}

struct TimeOfDay: Codable, Equatable, Comparable {
    let hour: Int
    let minute: Int

    init(hour: Int, minute: Int) {
        precondition((0..<24).contains(hour))
        precondition((0..<60).contains(minute))

        self.hour = hour
        self.minute = minute
    }

    private enum CodingKeys: String, CodingKey {
        case hour, minute
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let hour = try container.decode(Int.self, forKey: .hour)
        let minute = try container.decode(Int.self, forKey: .minute)
        guard (0..<24).contains(hour), (0..<60).contains(minute) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Saved time is outside the valid hour or minute range.")
            )
        }
        self.init(hour: hour, minute: minute)
    }

    init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        self.init(hour: components.hour ?? 0, minute: components.minute ?? 0)
    }

    static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool {
        lhs.minutesSinceMidnight < rhs.minutesSinceMidnight
    }

    func date(on date: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: date
        ) ?? date
    }

    var minutesSinceMidnight: Int {
        hour * 60 + minute
    }

    init(minutesSinceMidnight: Int) {
        self.init(
            hour: minutesSinceMidnight / 60,
            minute: minutesSinceMidnight % 60
        )
    }
}
