import Foundation
import Testing
@testable import Gayffirmations

@MainActor
struct AffirmationValidationTests {
    @Test("Invalid persisted collections are preserved before migrations and recover only after confirmation",
          arguments: ["duplicate", "duplicate-identical", "blank", "blank-tag", "padded-tag",
                      "duplicate-tag", "unknown-source", "null-source", "null-tags", "malformed-tags"],
          [false, true])
    func invalidSavedCollection(kind: String, seeded: Bool) async throws {
        let suite = "AffirmationValidationTests.\(UUID())"
        let preferences = try #require(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        let starter = try #require(Affirmation.legacyStarterAffirmations.last)
        var nameMessage = try #require(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(starter)
        ) as? [String: Any])
        nameMessage.removeValue(forKey: "source")
        nameMessage["text"] = "Stop comparing. You're the only Brett in the room."
        var invalid = try #require(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(Affirmation(text: "Keep this personal message", isFavorite: true, tags: ["Mine"]))
        ) as? [String: Any])
        switch kind {
        case "duplicate": invalid["id"] = nameMessage["id"]
        case "duplicate-identical": invalid = nameMessage
        case "blank": invalid["text"] = " \n\t "
        case "blank-tag": invalid["tags"] = ["Mine", " \n"]
        case "padded-tag": invalid["tags"] = [" Mine "]
        case "duplicate-tag": invalid["tags"] = ["Mine", "mine"]
        case "unknown-source": invalid["source"] = "unknown"
        case "null-source": invalid["source"] = NSNull()
        case "null-tags": invalid["tags"] = NSNull()
        default: invalid["tags"] = [42]
        }
        let raw = try JSONSerialization.data(withJSONObject: [nameMessage, invalid])
        preferences.set(raw, forKey: "gayffirmations.affirmations")
        preferences.set(seeded, forKey: "gayffirmations.initialAffirmationsSeeded")
        let repository = UserDefaultsRepository(userDefaults: preferences,
                                               initialAffirmations: Affirmation.starterAffirmations)
        let expectedError: AffirmationValidationError? = switch kind {
        case "duplicate", "duplicate-identical": .duplicateIdentity
        case "blank": .blankText
        case "blank-tag", "padded-tag", "duplicate-tag": .invalidTags
        default: nil
        }
        if let expectedError {
            #expect(throws: expectedError) { try repository.loadAffirmations() }
        } else {
            #expect(throws: DecodingError.self) { try repository.loadAffirmations() }
        }
        #expect(preferences.data(forKey: "gayffirmations.affirmations") == raw)
        #expect(preferences.bool(forKey: "gayffirmations.initialAffirmationsSeeded") == seeded)
        let store = AffirmationStore(repository: repository, defaultAffirmations: Affirmation.starterAffirmations)
        #expect(store.persistenceErrorMessage != nil)
        #expect(store.affirmations == Affirmation.starterAffirmations)
        #expect(Set(store.affirmations.map(\.id)).count == store.affirmations.count)
        #expect(throws: PersistenceUnavailableError.self) { try store.add(text: "Blocked") }
        #expect(throws: PersistenceUnavailableError.self) { try store.restoreDefaults() }
        #expect(preferences.data(forKey: "gayffirmations.affirmations") == raw)
        let schedule = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())
        try schedule.replace(with: [AffirmationSchedule(isEnabled: true)])
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(affirmationStore: store, scheduleStore: schedule,
                                                  scheduler: scheduler)
        await coordinator.reconcileOnLaunch()
        #expect(coordinator.deliveryState == .failed)
        #expect(scheduler.scheduledReminders.isEmpty)
        let reset = AppDataResetCoordinator(affirmationStore: store, scheduleStore: schedule,
                                           themeStore: ThemeStore(), notificationCoordinator: coordinator,
                                           repository: repository)
        #expect(reset.unreadableSections == ["Affirmations"])
        try reset.resetAll()
        #expect(store.persistenceErrorMessage == nil)
        #expect(try repository.loadAffirmations() == Affirmation.starterAffirmations)
        let backups = try #require(preferences.array(forKey: "gayffirmations.recoveryBackups") as? [[String: Any]])
        let values = try #require(backups.first?["values"] as? [String: Any])
        #expect(values["gayffirmations.affirmations"] as? Data == raw)
        let restarted = AffirmationStore(repository: repository, defaultAffirmations: Affirmation.starterAffirmations)
        #expect(restarted.persistenceErrorMessage == nil)
        #expect(restarted.affirmations == store.affirmations)
        try store.add(text: "After recovery")
    }

    @Test("Alternate repositories cannot publish invalid collections or silently overwrite them",
          arguments: [true, false])
    func storeValidatesRepository(duplicate: Bool) {
        let first = Affirmation(text: "First")
        let invalid = duplicate ? [first, first] : [Affirmation(text: " \n ")]
        let repository = InvalidCollectionRepository(affirmations: invalid)
        let fallback = [Affirmation(text: "Fallback")]
        let store = AffirmationStore(repository: repository, defaultAffirmations: fallback)
        #expect(store.affirmations == fallback)
        #expect(store.persistenceErrorMessage != nil)
        #expect(throws: PersistenceUnavailableError.self) { try store.restoreDefaults() }
        #expect(repository.affirmations == invalid)
        #expect(repository.saveCallCount == 0)
    }

    @Test("Historical formatting, duplicate text, and different tag spelling across entries remain intact")
    func preservesValidHistoricalContent() throws {
        let suite = "AffirmationValidationTests.\(UUID())"
        let preferences = try #require(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        let saved = [
            Affirmation(text: "  Same message\n", isFavorite: true, tags: ["Work"]),
            Affirmation(text: "  Same message\n", tags: ["work"])
        ]
        let raw = try JSONEncoder().encode(saved)
        preferences.set(raw, forKey: "gayffirmations.affirmations")
        let repository = UserDefaultsRepository(userDefaults: preferences)
        let store = AffirmationStore(repository: repository, defaultAffirmations: [])
        #expect(store.persistenceErrorMessage == nil)
        #expect(store.affirmations == saved)
        #expect(preferences.data(forKey: "gayffirmations.affirmations") == raw)

        var legacy = try #require(JSONSerialization.jsonObject(with: raw) as? [[String: Any]])
        for index in legacy.indices {
            legacy[index].removeValue(forKey: "source")
            legacy[index].removeValue(forKey: "tags")
        }
        let legacyRaw = try JSONSerialization.data(withJSONObject: legacy)
        preferences.set(legacyRaw, forKey: "gayffirmations.affirmations")
        let loaded = try #require(try repository.loadAffirmations())
        #expect(loaded.map(\.id) == saved.map(\.id))
        #expect(loaded.map(\.text) == saved.map(\.text))
        #expect(loaded.allSatisfy { $0.source == .user && $0.tags.isEmpty })
        #expect(preferences.data(forKey: "gayffirmations.affirmations") == legacyRaw)
    }

    @Test("Invalid saves are rejected before any persisted values or recovery backups change")
    func invalidSavesPreserveData() throws {
        let suite = "AffirmationValidationTests.\(UUID())"
        let preferences = try #require(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsRepository(userDefaults: preferences)
        let saved = [Affirmation(text: "Healthy")]
        try repository.saveAffirmations(saved)
        try repository.saveTheme(.steel)
        let before = try #require(preferences.persistentDomain(forName: suite))
        #expect(throws: AffirmationValidationError.duplicateIdentity) {
            try repository.saveAffirmations([saved[0], saved[0]])
        }
        #expect(throws: AffirmationValidationError.blankText) {
            try repository.saveAppData(affirmations: [Affirmation(text: "")],
                                       schedules: [AffirmationSchedule()], theme: .eden,
                                       selection: .all, preservingExistingData: true)
        }
        let after = try #require(preferences.persistentDomain(forName: suite))
        #expect(NSDictionary(dictionary: before).isEqual(to: after))
    }
}

private final class InvalidCollectionRepository: AffirmationRepository {
    var affirmations: [Affirmation]
    private(set) var saveCallCount = 0
    init(affirmations: [Affirmation]) { self.affirmations = affirmations }
    func loadAffirmations() throws -> [Affirmation]? { affirmations }
    func saveAffirmations(_ affirmations: [Affirmation]) throws {
        saveCallCount += 1
        self.affirmations = affirmations
    }
}
