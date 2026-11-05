import Foundation

enum NotificationAuthorizationStatus: Equatable {
    case notDetermined
    case denied
    case authorized
}

struct NotificationReminder: Equatable {
    static let pendingLimit = 64

    let deliveryDate: Date
    let affirmationText: String
    let sound: NotificationSound
    let identifier: String
}

protocol NotificationScheduling {
    func authorizationStatus() async -> NotificationAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func replacePendingNotifications(
        with reminders: [NotificationReminder]
    ) async throws
    func removePendingNotifications()
}
