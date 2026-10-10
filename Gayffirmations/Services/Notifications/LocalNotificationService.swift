import UserNotifications

/// The system boundary keeps OS request submission separate from app planning.
protocol NotificationCenterClient {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removeAllPendingNotificationRequests()
}

private final class SystemNotificationCenterClient: NotificationCenterClient {
    private let center: UNUserNotificationCenter
    init(center: UNUserNotificationCenter) { self.center = center }
    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        try await center.requestAuthorization(options: options)
    }
    func add(_ request: UNNotificationRequest) async throws { try await center.add(request) }
    func removeAllPendingNotificationRequests() { center.removeAllPendingNotificationRequests() }
}

final class LocalNotificationService: NotificationScheduling {
    private let center: any NotificationCenterClient

    convenience init(center: UNUserNotificationCenter = .current()) {
        self.init(client: SystemNotificationCenterClient(center: center))
    }

    init(client: any NotificationCenterClient) { center = client }

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        switch await center.authorizationStatus() {
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
        guard (1...ScheduleValidation.dailyReminderLimit).contains(reminders.count) else {
            throw ScheduleCalculatorError.invalidReminderCount
        }
        try Task.checkCancellation()
        removePendingNotifications()

        do {
            for (index, reminder) in reminders.enumerated() {
                try Task.checkCancellation()
                try await center.add(request(for: reminder, index: index))
                try Task.checkCancellation()
            }
        } catch {
            removePendingNotifications()
            throw error
        }
    }

    func removePendingNotifications() {
        // This app owns only affirmation reminders, including legacy indexed requests.
        center.removeAllPendingNotificationRequests()
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
            identifier: reminder.identifier.isEmpty ? "gayffirmations.daily.\(index)" : reminder.identifier,
            content: content,
            trigger: trigger
        )
    }
}
