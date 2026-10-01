import Foundation

enum NotificationAuthorizationStatus: Equatable {
    case notDetermined
    case denied
    case authorized
}

struct NotificationReminder: Equatable {
    let time: TimeOfDay
    let affirmationText: String
}

protocol NotificationScheduling {
    func authorizationStatus() async -> NotificationAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func replacePendingNotifications(
        with reminders: [NotificationReminder]
    ) async throws
    func removePendingNotifications()
}
