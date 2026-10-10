import Foundation
import Testing
import UserNotifications
@testable import Gayffirmations

@MainActor
struct LocalNotificationServiceTests {
    @Test("System authorization states map to app delivery states",
          arguments: [UNAuthorizationStatus.notDetermined, .denied, .authorized, .provisional, .ephemeral])
    func authorizationMapping(status: UNAuthorizationStatus) async {
        let center = NotificationCenterFake()
        center.status = status
        let service = LocalNotificationService(client: center)
        let expected: NotificationAuthorizationStatus = switch status {
        case .notDetermined: .notDetermined
        case .denied: .denied
        default: .authorized
        }
        #expect(await service.authorizationStatus() == expected)
        #expect(center.statusCallCount == 1)
        #expect(center.authorizationOptions.isEmpty)
    }

    @Test("Authorization requests forward alert and sound and return the OS result", arguments: [false, true])
    func authorizationRequest(granted: Bool) async throws {
        let center = NotificationCenterFake()
        center.granted = granted
        let service = LocalNotificationService(client: center)
        #expect(try await service.requestAuthorization() == granted)
        #expect(center.authorizationOptions == [[.alert, .sound]])
        center.authorizationError = CenterTestError.authorizationFailed
        await #expect(throws: CenterTestError.authorizationFailed) { try await service.requestAuthorization() }
        #expect(center.authorizationOptions.count == 2)
        #expect(center.events.isEmpty)
    }

    @Test("Submitted requests preserve identifiers, text, exact time components, and daily repetition")
    func requestContract() async throws {
        let center = NotificationCenterFake()
        let service = LocalNotificationService(client: center)
        let reminders = [
            NotificationReminder(time: TimeOfDay(hour: 0, minute: 0), affirmationText: "Midnight", sound: .none, identifier: "schedule-A.0"),
            NotificationReminder(time: TimeOfDay(hour: 23, minute: 59), affirmationText: "Late", sound: .systemDefault, identifier: "schedule-B.0"),
            NotificationReminder(time: TimeOfDay(hour: 12, minute: 34), affirmationText: "Legacy", sound: .none)
        ]
        try await service.replacePendingNotifications(with: reminders)
        #expect(center.events == ["remove", "add:schedule-A.0", "add:schedule-B.0", "add:gayffirmations.daily.2"])
        #expect(center.requests.count == 3)
        for (request, reminder) in zip(center.requests, reminders) {
            #expect(request.content.title == "Gayffirmations")
            #expect(request.content.body == reminder.affirmationText)
            let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
            #expect(trigger.dateComponents == DateComponents(hour: reminder.time.hour, minute: reminder.time.minute))
            #expect(trigger.repeats)
        }
        #expect(center.requests[0].content.sound == nil)
        #expect(center.requests[1].content.sound == UNNotificationSound.default)
        #expect(center.requests[2].content.sound == nil)
        service.removePendingNotifications()
        #expect(center.requests.isEmpty)
        #expect(center.events.last == "remove")
    }

    @Test("Every custom sound maps to its exact bundled filename", arguments: [
        (NotificationSound.upliftingFlute, "uplifting-flute.caf"),
        (.magicMarimba, "magic-marimba.caf"),
        (.choirHarpBless, "choir-harp-bless.caf"),
        (.relaxingHarpSweep, "relaxing-harp-sweep.caf"),
        (.clearingTheThroat, "clearing-the-throat.caf")
    ])
    func customSound(mapping: (NotificationSound, String)) async throws {
        let center = NotificationCenterFake()
        let service = LocalNotificationService(client: center)
        try await service.replacePendingNotifications(with: [
            NotificationReminder(time: TimeOfDay(hour: 9, minute: 0), affirmationText: "Hello", sound: mapping.0)
        ])
        let request = try #require(center.requests.first)
        #expect(request.content.sound == UNNotificationSound(named: UNNotificationSoundName(mapping.1)))
    }

    @Test("Invalid counts leave previously submitted requests untouched", arguments: [0, 25])
    func invalidCounts(count: Int) async throws {
        let center = NotificationCenterFake()
        let service = LocalNotificationService(client: center)
        let reminder = NotificationReminder(time: TimeOfDay(hour: 9, minute: 0), affirmationText: "Saved", identifier: "saved")
        try await service.replacePendingNotifications(with: [reminder])
        let previous = center.requests
        let events = center.events
        await #expect(throws: ScheduleCalculatorError.invalidReminderCount) {
            try await service.replacePendingNotifications(with: Array(repeating: reminder, count: count))
        }
        #expect(center.requests == previous)
        #expect(center.events == events)
    }

    @Test("Partial add failures remove every new request and a later retry replaces the whole plan",
          arguments: [0, 1, 2])
    func partialFailure(index: Int) async throws {
        let center = NotificationCenterFake()
        let service = LocalNotificationService(client: center)
        let reminders = (0..<3).map {
            NotificationReminder(time: TimeOfDay(hour: 9 + $0, minute: 0), affirmationText: "Message \($0)", identifier: "new.\($0)")
        }
        try await service.replacePendingNotifications(with: [reminders[0]])
        center.failAtAddIndex = center.addCallCount + index
        let eventCount = center.events.count
        await #expect(throws: CenterTestError.addFailed) {
            try await service.replacePendingNotifications(with: reminders)
        }
        #expect(center.requests.isEmpty)
        #expect(Array(center.events.dropFirst(eventCount)) == ["remove"] + (0...index).map { "add:new.\($0)" } + ["remove"])
        center.failAtAddIndex = nil
        try await service.replacePendingNotifications(with: reminders)
        #expect(center.requests.map(\.identifier) == reminders.map(\.identifier))
    }

    @Test("Cancellation during add clears partial requests and stops the submission loop", .timeLimit(.minutes(1)))
    func cancellationDuringAdd() async throws {
        let center = NotificationCenterFake()
        let gate = NotificationSuspension()
        defer { gate.resume() }
        center.suspension = gate
        let service = LocalNotificationService(client: center)
        let reminders = (0..<3).map {
            NotificationReminder(time: TimeOfDay(hour: 9 + $0, minute: 0), affirmationText: "Message", identifier: "new.\($0)")
        }
        let replacement = Task { try await service.replacePendingNotifications(with: reminders) }
        await gate.waitUntilSuspended()
        replacement.cancel()
        gate.resume()
        await #expect(throws: CancellationError.self) { try await replacement.value }
        #expect(center.addCallCount == 1)
        #expect(center.requests.isEmpty)
        #expect(center.events == ["remove", "add:new.0", "remove"])
    }

    @Test("Coordinator rollback through the real adapter restores the previous request collection")
    func coordinatorRecovery() async throws {
        let center = NotificationCenterFake()
        let service = LocalNotificationService(client: center)
        let store = ScheduleStore(schedule: AffirmationSchedule(isEnabled: true, notificationsPerDay: 2))
        let coordinator = NotificationCoordinator(
            affirmationStore: AffirmationStore(affirmations: [Affirmation(text: "Saved")]),
            scheduleStore: store, scheduler: service
        )
        await coordinator.reconcileOnLaunch()
        let saved = store.schedules
        let previous = center.requests
        center.failAtAddIndex = center.addCallCount + 1
        var edited = saved[0]
        edited.notificationsPerDay = 3
        await #expect(throws: CenterTestError.addFailed) { try await coordinator.saveSchedule(edited) }
        #expect(store.schedules == saved)
        #expect(center.requests == previous)
        #expect(coordinator.deliveryState == .active)
    }
}

@MainActor
private final class NotificationCenterFake: NotificationCenterClient {
    var status: UNAuthorizationStatus = .authorized
    var granted = false
    var authorizationError: CenterTestError?
    var failAtAddIndex: Int?
    var suspension: NotificationSuspension?
    private(set) var statusCallCount = 0
    private(set) var authorizationOptions: [UNAuthorizationOptions] = []
    private(set) var requests: [UNNotificationRequest] = []
    private(set) var events: [String] = []
    private(set) var addCallCount = 0

    func authorizationStatus() async -> UNAuthorizationStatus {
        statusCallCount += 1
        return status
    }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        authorizationOptions.append(options)
        if let authorizationError { throw authorizationError }
        return granted
    }
    func add(_ request: UNNotificationRequest) async throws {
        let index = addCallCount
        addCallCount += 1
        events.append("add:\(request.identifier)")
        if let gate = suspension {
            suspension = nil
            await gate.pause()
        }
        if index == failAtAddIndex { throw CenterTestError.addFailed }
        requests.append(request)
    }
    func removeAllPendingNotificationRequests() {
        events.append("remove")
        requests = []
    }
}

private enum CenterTestError: Error { case authorizationFailed, addFailed }
