import Foundation

struct AffirmationSchedule: Codable, Equatable {
    var isEnabled: Bool
    var startTime: TimeOfDay
    var endTime: TimeOfDay
    var notificationsPerDay: Int

    init(
        isEnabled: Bool = false,
        startTime: TimeOfDay = TimeOfDay(hour: 9, minute: 0),
        endTime: TimeOfDay = TimeOfDay(hour: 17, minute: 0),
        notificationsPerDay: Int = 4
    ) {
        self.isEnabled = isEnabled
        self.startTime = startTime
        self.endTime = endTime
        self.notificationsPerDay = notificationsPerDay
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
