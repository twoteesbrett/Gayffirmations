#if DEBUG
import Foundation

/// Keeps SwiftUI previews independent of device permissions and pending reminders.
struct PreviewNotificationScheduler: NotificationScheduling {
    func authorizationStatus() async -> NotificationAuthorizationStatus { .authorized }
    func requestAuthorization() async throws -> Bool { true }
    func replacePendingNotifications(with reminders: [NotificationReminder]) async throws {}
    func removePendingNotifications() {}
}
#endif
