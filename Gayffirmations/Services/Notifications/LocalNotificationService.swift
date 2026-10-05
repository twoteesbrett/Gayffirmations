import UserNotifications

final class LocalNotificationService: NotificationScheduling {
    private enum Identifier {
        static let prefix = "gayffirmations.daily."

        static func reminder(at index: Int) -> String {
            prefix + String(index)
        }

        static var allReminders: [String] {
            (0..<AffirmationSchedule.notificationCountRange.upperBound).map { reminder(at: $0) }
        }
    }

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized, .provisional, .ephemeral:
            return .authorized
        @unknown default:
            return .denied
        }
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    func replacePendingNotifications(
        with reminders: [NotificationReminder]
    ) async throws {
        guard AffirmationSchedule.notificationCountRange.contains(reminders.count) else {
            throw ScheduleCalculatorError.invalidReminderCount
        }
        removePendingNotifications()

        do {
            for (index, reminder) in reminders.enumerated() {
                try await center.add(request(for: reminder, index: index))
            }
        } catch {
            removePendingNotifications()
            throw error
        }
    }

    func removePendingNotifications() {
        center.removePendingNotificationRequests(
            withIdentifiers: Identifier.allReminders
        )
    }

    func request(
        for reminder: NotificationReminder,
        index: Int
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Gayffirmations"
        content.body = reminder.affirmationText
        switch reminder.sound {
        case .systemDefault:
            content.sound = .default
        case .none:
            content.sound = nil
        default:
            if let filename = reminder.sound.filename {
                content.sound = UNNotificationSound(named: UNNotificationSoundName(filename))
            }
        }

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(
                hour: reminder.time.hour,
                minute: reminder.time.minute
            ),
            repeats: true
        )

        return UNNotificationRequest(
            identifier: Identifier.reminder(at: index),
            content: content,
            trigger: trigger
        )
    }
}
