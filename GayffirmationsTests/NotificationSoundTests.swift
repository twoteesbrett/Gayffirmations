import AVFAudio
import Foundation
import Testing
import UserNotifications
@testable import Gayffirmations

@MainActor
struct NotificationSoundTests {
    @Test("Old schedules retain all settings and gain the default sound")
    func migratesOldSchedule() throws {
        let data = Data("""
        {"isEnabled":true,"startTime":{"hour":10,"minute":15},
        "endTime":{"hour":20,"minute":45},"notificationsPerDay":7}
        """.utf8)
        let schedule = try JSONDecoder().decode(AffirmationSchedule.self, from: data)
        #expect(schedule == AffirmationSchedule(
            id: schedule.id,
            name: "Daily affirmations",
            isEnabled: true,
            startTime: TimeOfDay(hour: 10, minute: 15),
            endTime: TimeOfDay(hour: 20, minute: 45),
            notificationsPerDay: 7
        ))
    }

    @Test("Sound preferences survive a repository reload", arguments: NotificationSound.allCases)
    func persistsSound(sound: NotificationSound) async throws {
        let suite = "NotificationSoundTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsRepository(userDefaults: defaults)
        let store = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .notDetermined)
        let coordinator = makeCoordinator(store: store, scheduler: scheduler)
        try await coordinator.setSound(sound)
        let reloaded = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())
        #expect(reloaded.notificationSound == sound)
        #expect(!reloaded.schedule.isEnabled)
        #expect(scheduler.authorizationRequestCount == 0)
        #expect(scheduler.replaceCallCount == 0)
    }

    @Test("Sound changes update every reminder without changing delivery times or text",
          arguments: NotificationSound.allCases)
    func updatesReminders(sound: NotificationSound) async throws {
        let store = ScheduleStore()
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = makeCoordinator(store: store, scheduler: scheduler)
        try await coordinator.setEnabled(true)
        let original = scheduler.scheduledReminders
        try await coordinator.setSound(sound)
        #expect(store.notificationSound == sound)
        #expect(scheduler.scheduledReminders.map(\.time) == original.map(\.time))
        #expect(scheduler.scheduledReminders.map(\.affirmationText) == original.map(\.affirmationText))
        #expect(scheduler.scheduledReminders.allSatisfy { $0.sound == sound })
    }

    @Test("Failed sound saves or scheduling restore the previous preference and delivery",
          arguments: [true, false])
    func recoversPreviousSound(failSave: Bool) async throws {
        let repository = SoundScheduleRepository()
        let store = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = makeCoordinator(store: store, scheduler: scheduler)
        try await coordinator.setSound(.magicMarimba)
        try await coordinator.setEnabled(true)
        let previous = scheduler.scheduledReminders
        repository.failSave = failSave
        scheduler.failuresRemaining = failSave ? 0 : 1
        await #expect(throws: NotificationSchedulerTestError.self) {
            try await coordinator.setSound(.none)
        }
        #expect(store.notificationSound == .magicMarimba)
        #expect(repository.sound == .magicMarimba)
        #expect(store.schedule.isEnabled)
        #expect(scheduler.scheduledReminders == previous)
        #expect(!coordinator.isUpdating)
    }

    @Test("Changing sound while delivery is paused keeps delivery paused")
    func pausedSoundChange() async throws {
        let store = ScheduleStore()
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(
            affirmationStore: AffirmationStore(affirmations: []),
            scheduleStore: store, scheduler: scheduler
        )
        try await coordinator.setEnabled(true)
        try await coordinator.setSound(.choirHarpBless)
        #expect(store.notificationSound == .choirHarpBless)
        #expect(coordinator.deliveryIsPaused)
        #expect(scheduler.scheduledReminders.isEmpty)
    }

    @Test("Resetting schedules keeps the global sound and cancels delivery")
    func resetsSound() async throws {
        let store = ScheduleStore()
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = makeCoordinator(store: store, scheduler: scheduler)
        try await coordinator.setSound(.relaxingHarpSweep)
        try await coordinator.setEnabled(true)
        try coordinator.resetSchedule()
        #expect(store.notificationSound == .relaxingHarpSweep)
        #expect(!store.schedule.isEnabled)
        #expect(scheduler.scheduledReminders.isEmpty)
    }

    @Test("Notification requests omit sound only for None", arguments: NotificationSound.allCases)
    func requestSound(sound: NotificationSound) {
        let request = LocalNotificationService().request(
            for: NotificationReminder(time: TimeOfDay(hour: 9, minute: 0), affirmationText: "Hello", sound: sound),
            index: 0
        )
        #expect((request.content.sound == nil) == (sound == .none))
    }

    @Test func globalSoundMigratesUpdatesAllSchedulesAndSurvivesDeletingThem() async throws {
        let suite = "GlobalSoundTests.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsRepository(userDefaults: defaults)
        let first = AffirmationSchedule(isEnabled: true, notificationsPerDay: 2, sound: .magicMarimba)
        let second = AffirmationSchedule(isEnabled: true, notificationsPerDay: 3, sound: .none)
        try repository.saveSchedules([first, second])
        let store = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())
        #expect(store.notificationSound == .magicMarimba)
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = makeCoordinator(store: store, scheduler: scheduler)
        await coordinator.reconcileOnLaunch()
        #expect(scheduler.scheduledReminders.count == 5)
        #expect(scheduler.scheduledReminders.allSatisfy { $0.sound == .magicMarimba })
        let previous = scheduler.scheduledReminders
        try await coordinator.setSound(.choirHarpBless)
        #expect(scheduler.scheduledReminders.map(\.identifier) == previous.map(\.identifier))
        #expect(scheduler.scheduledReminders.map(\.time) == previous.map(\.time))
        #expect(scheduler.scheduledReminders.allSatisfy { $0.sound == .choirHarpBless })
        try await coordinator.deleteSchedule(id: first.id)
        try await coordinator.deleteSchedule(id: second.id)
        let restarted = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())
        #expect(restarted.schedules.isEmpty)
        #expect(restarted.notificationSound == .choirHarpBless)
        let restartedCoordinator = makeCoordinator(store: restarted, scheduler: scheduler)
        try await restartedCoordinator.saveSchedule(AffirmationSchedule(isEnabled: true))
        #expect(scheduler.scheduledReminders.allSatisfy { $0.sound == .choirHarpBless })
    }

    @Test func resettingAllDataRestoresGlobalDefaultSound() async throws {
        let suite = "ResetGlobalSoundTests.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsRepository(userDefaults: defaults)
        let store = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())
        let library = AffirmationStore(affirmations: [Affirmation(text: "Hello")])
        let coordinator = NotificationCoordinator(affirmationStore: library, scheduleStore: store,
                                                  scheduler: NotificationSchedulerSpy(authorizationStatus: .authorized))
        try await coordinator.setSound(.none)
        let reset = AppDataResetCoordinator(affirmationStore: library, scheduleStore: store,
                                           themeStore: ThemeStore(), notificationCoordinator: coordinator,
                                           repository: repository)
        try reset.resetAll()
        #expect(store.notificationSound == .systemDefault)
        let restarted = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())
        #expect(restarted.notificationSound == .systemDefault)
    }

    @Test("All custom sounds are bundled and decodable within the notification duration limit")
    func bundledSounds() throws {
        for sound in NotificationSound.allCases where sound.filename != nil {
            let filename = try #require(sound.filename)
            let url = try #require(Bundle.main.url(forResource: filename, withExtension: nil))
            let player = try AVAudioPlayer(contentsOf: url)
            #expect(player.duration > 0 && player.duration < 30)
            #expect(player.numberOfChannels == 1)
        }
    }

    private func makeCoordinator(store: ScheduleStore, scheduler: NotificationSchedulerSpy) -> NotificationCoordinator {
        NotificationCoordinator(
            affirmationStore: AffirmationStore(affirmations: [Affirmation(text: "Hello")]),
            scheduleStore: store, scheduler: scheduler
        )
    }
}

private final class SoundScheduleRepository: ScheduleRepository {
    var schedule: AffirmationSchedule?
    var sound: NotificationSound?
    var failSave = false

    func loadSchedules() throws -> [AffirmationSchedule]? { schedule.map { [$0] } }

    func loadNotificationSound() throws -> NotificationSound? { sound }

    func saveNotificationSound(_ sound: NotificationSound) throws {
        if failSave { throw NotificationSchedulerTestError.failed }
        self.sound = sound
    }

    func saveSchedules(_ schedules: [AffirmationSchedule]) throws {
        if failSave { throw NotificationSchedulerTestError.failed }
        self.schedule = schedules.first
    }
}
