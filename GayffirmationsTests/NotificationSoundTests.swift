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
        #expect(reloaded.schedule.sound == sound)
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
        #expect(store.schedule.sound == sound)
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
        #expect(store.schedule.sound == .magicMarimba)
        #expect(repository.schedule?.sound == .magicMarimba)
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
        #expect(store.schedule.sound == .choirHarpBless)
        #expect(coordinator.deliveryIsPaused)
        #expect(scheduler.scheduledReminders.isEmpty)
    }

    @Test("Resetting the schedule restores the default sound and cancels delivery")
    func resetsSound() async throws {
        let store = ScheduleStore()
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = makeCoordinator(store: store, scheduler: scheduler)
        try await coordinator.setSound(.relaxingHarpSweep)
        try await coordinator.setEnabled(true)
        try coordinator.resetSchedule()
        #expect(store.schedule.sound == .systemDefault)
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
    var failSave = false

    func loadSchedule() throws -> AffirmationSchedule? { schedule }

    func saveSchedule(_ schedule: AffirmationSchedule) throws {
        if failSave { throw NotificationSchedulerTestError.failed }
        self.schedule = schedule
    }
}
