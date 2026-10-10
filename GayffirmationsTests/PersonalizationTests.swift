import Foundation
import Testing
@testable import Gayffirmations

@MainActor
struct PersonalizationTests {
    @Test func resolutionPreservesTemplatesAndIdentity() {
        let entry = Affirmation(text: "Hello, {name}. Go {name}!", isFavorite: true, tags: ["Joy"])
        let resolved = entry.resolved(name: "  Brett \n")
        #expect(resolved?.text == "Hello, Brett. Go Brett!")
        #expect(resolved?.id == entry.id)
        #expect(resolved?.isFavorite == true)
        #expect(resolved?.tags == entry.tags)
        #expect(entry.text.contains("{name}"))
        #expect(entry.resolved(name: " \n") == nil)
        #expect(Affirmation(text: "Hello {name}").resolved(name: "") == nil)
        #expect(Affirmation(text: "Stay proud").resolved(name: "")?.text == "Stay proud")
    }

    @Test func legacyDecodingIgnoresRemovedAlternativeMessage() throws {
        let old = Data("{\"id\":\"B7E77000-0000-4000-8000-000000000015\",\"text\":\"Hi {name}\",\"isFavorite\":false,\"fallbackText\":\"Hi there\"}".utf8)
        let entry = try JSONDecoder().decode(Affirmation.self, from: old)
        #expect(entry.resolved(name: "") == nil)
        #expect(entry.resolved(name: "Alex")?.text == "Hi Alex")
        let encoded = try JSONEncoder().encode(entry)
        #expect(try JSONDecoder().decode(Affirmation.self, from: encoded) == entry)
        #expect(!String(decoding: encoded, as: UTF8.self).contains("fallbackText"))
    }

    @Test func userMessagesWithLiteralNamesNeedNoSavedName() throws {
        let store = AffirmationStore()
        let added = try store.add(text: "Alex, you can do this.")
        #expect(added.resolved(name: "") == added)
        try store.update(id: added.id, text: "Alex, you belong here.")
        #expect(store.affirmations.first?.resolved(name: "")?.text == "Alex, you belong here.")
    }

    @Test func namePersistenceMigrationAndReset() throws {
        let suite = "PersonalizationTests.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsRepository(userDefaults: defaults)
        var original = try #require(Affirmation.legacyStarterAffirmations.last)
        original.text = "Stop comparing. You're the only Brett in the room."
        original.isFavorite = true
        let custom = Affirmation(text: "Brett is great")
        try repository.saveAffirmations([original, custom])
        let migrated = try #require(try repository.loadAffirmations())
        #expect(migrated[0].usesName)
        #expect(migrated[0].isFavorite)
        #expect(migrated[0].tags == original.tags)
        #expect(migrated[0].resolved(name: "") == nil)
        #expect(migrated[1] == custom)
        let profile = PersonalizationStore(repository: repository)
        try profile.setName("  Alex  ")
        #expect(PersonalizationStore(repository: repository).name == "Alex")
        try repository.saveAppData(affirmations: [], schedules: [AffirmationSchedule()], theme: .eden, selection: .all)
        #expect(try repository.loadName() == nil)
    }

    @Test func resetAllClearsVisibleAndSavedName() throws {
        let suite = "PersonalizationReset.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsRepository(userDefaults: defaults)
        let profile = PersonalizationStore(repository: repository)
        try profile.setName("Alex")
        let library = AffirmationStore()
        let schedule = ScheduleStore()
        let coordinator = NotificationCoordinator(
            affirmationStore: library, scheduleStore: schedule,
            scheduler: NotificationSchedulerSpy(authorizationStatus: .authorized),
            personalizationStore: profile
        )
        let reset = AppDataResetCoordinator(
            affirmationStore: library, scheduleStore: schedule, themeStore: ThemeStore(),
            notificationCoordinator: coordinator, repository: repository
        )
        try reset.resetAll()
        #expect(profile.name.isEmpty)
        #expect(try repository.loadName() == nil)
    }

    @Test func corruptNamePausesDeliveryAndPreservesSavedData() async throws {
        let suite = "PersonalizationCorruption.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let corrupt = Data("invalid".utf8)
        defaults.set(corrupt, forKey: "gayffirmations.name")
        let profile = PersonalizationStore(repository: UserDefaultsRepository(userDefaults: defaults))
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let schedule = ScheduleStore(schedule: AffirmationSchedule(isEnabled: true))
        let coordinator = NotificationCoordinator(
            affirmationStore: AffirmationStore(affirmations: [Affirmation(text: "Hi {name}")]),
            scheduleStore: schedule, scheduler: scheduler, personalizationStore: profile
        )
        await coordinator.reconcileOnLaunch()
        #expect(profile.persistenceErrorMessage != nil)
        #expect(scheduler.scheduledReminders.isEmpty)
        #expect(throws: PersistenceUnavailableError.self) { try coordinator.setName("Alex") }
        #expect(defaults.data(forKey: "gayffirmations.name") == corrupt)
    }

    @Test func nameChangesRefreshDelivery() async throws {
        let entry = Affirmation(text: "Hi {name}", tags: ["Personal"])
        let library = AffirmationStore(affirmations: [entry])
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(affirmationStore: library, scheduleStore: ScheduleStore(), scheduler: scheduler)
        try await coordinator.setEnabled(true)
        #expect(coordinator.deliveryIsPaused)
        #expect(scheduler.scheduledReminders.isEmpty)
        try coordinator.setName("Alex")
        await coordinator.waitForLibraryRefresh()
        #expect(!scheduler.scheduledReminders.isEmpty)
        #expect(scheduler.scheduledReminders.allSatisfy { $0.affirmationText == "Hi Alex" })
        try coordinator.setFallbackSelection(.tag("Personal"))
        #expect(scheduler.scheduledReminders.allSatisfy { $0.affirmationText == "Hi Alex" })
        try coordinator.setName("")
        await coordinator.waitForLibraryRefresh()
        #expect(coordinator.fallbackAffirmations.isEmpty)
        #expect(scheduler.scheduledReminders.isEmpty)
        try library.update(id: entry.id, text: "Hi there")
        await coordinator.waitForLibraryRefresh()
        #expect(!scheduler.scheduledReminders.isEmpty)
        #expect(scheduler.scheduledReminders.allSatisfy { $0.affirmationText == "Hi there" })
    }
}

@MainActor
struct PersonalizationSelectionRecoveryTests {
    @Test func unreadableNameAllowsHealthySelectionChanges() async throws {
        let suite = "PersonalizationSelectionRecovery.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let corrupt = Data("invalid".utf8)
        defaults.set(corrupt, forKey: "gayffirmations.name")
        let repository = UserDefaultsRepository(userDefaults: defaults)
        let selection = AffirmationSelectionStore(repository: repository)
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(
            affirmationStore: AffirmationStore(affirmations: [Affirmation(text: "Favourite", isFavorite: true)]),
            scheduleStore: ScheduleStore(schedule: AffirmationSchedule(isEnabled: true)),
            scheduler: scheduler,
            fallbackSelectionStore: selection,
            personalizationStore: PersonalizationStore(repository: repository)
        )
        await coordinator.reconcileOnLaunch()
        try coordinator.setFallbackSelection(.favourites)
        #expect(selection.selection == .favourites)
        #expect(try repository.loadAffirmationSelection() == .favourites)
        #expect(defaults.data(forKey: "gayffirmations.name") == corrupt)
        #expect(scheduler.scheduledReminders.isEmpty)
        #expect(scheduler.replaceCallCount == 0)
    }
}
