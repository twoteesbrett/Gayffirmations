import Foundation

final class UserDefaultsRepository:
    AffirmationRepository,
    ScheduleRepository,
    ThemeRepository,
    ThemeBackgroundRepository,
    AffirmationSelectionRepository,
    PersonalizationRepository,
    AppDataRepository
{
    private enum Key {
        static let name = "gayffirmations.name"
        static let affirmations = "gayffirmations.affirmations"
        static let schedules = "gayffirmations.schedules"
        static let notificationSound = "gayffirmations.notificationSound"
        static let schedule = "gayffirmations.schedule"
        static let themeBackgrounds = "gayffirmations.themeBackgrounds"
        static let theme = "gayffirmations.theme"
        static let affirmationSelection = "gayffirmations.affirmationSelection"
        static let initialAffirmationsSeeded = "gayffirmations.initialAffirmationsSeeded"
        static let recoveryBackups = "gayffirmations.recoveryBackups"
    }

    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let initialAffirmations: [Affirmation]

    init(
        userDefaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        initialAffirmations: [Affirmation] = []
    ) {
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
        self.initialAffirmations = initialAffirmations
    }

    func loadAffirmations() throws -> [Affirmation]? {
        var saved = try load([Affirmation].self, forKey: Key.affirmations)
        // Reject invalid collections before name migration or first-launch seeding
        // can overwrite the bytes needed for deliberate recovery.
        if let saved { try AffirmationValidation.validate(saved) }
        try AffirmationValidation.validate(initialAffirmations)
        if let index = saved?.firstIndex(where: {
            $0.isBundled
                && $0.id == UUID(uuidString: "B7E77000-0000-4000-8000-000000000015")
                && $0.text == "Stop comparing. You're the only Brett in the room."
        }) {
            saved?[index].text = "Stop comparing. You're the only {name} in the room."
            if let saved { try saveAffirmations(saved) }
        }
        guard !initialAffirmations.isEmpty,
              !userDefaults.bool(forKey: Key.initialAffirmationsSeeded) else { return saved }

        let existing = saved ?? []
        let additions = initialAffirmations.filter { starter in
            !existing.contains { affirmation in
                affirmation.id == starter.id || affirmation.text
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .compare(starter.text, options: .caseInsensitive) == .orderedSame
            }
        }
        let seeded = existing + additions
        try saveAffirmations(seeded)
        userDefaults.set(true, forKey: Key.initialAffirmationsSeeded)
        return seeded
    }

    func saveAffirmations(_ affirmations: [Affirmation]) throws {
        try AffirmationValidation.validate(affirmations)
        try save(affirmations, forKey: Key.affirmations)
    }

    func loadName() throws -> String? {
        try load(String.self, forKey: Key.name)
    }

    func saveName(_ name: String) throws {
        try save(name, forKey: Key.name)
    }

    func loadSchedules() throws -> [AffirmationSchedule]? {
        if let schedules = try load([AffirmationSchedule].self, forKey: Key.schedules) {
            return schedules
        }
        guard var legacy = try load(AffirmationSchedule.self, forKey: Key.schedule) else {
            return nil
        }
        // Capture the old shared source once. Browsing changes are independent afterward.
        legacy.selection = try loadAffirmationSelection() ?? .all
        try ScheduleValidation.validate([legacy])
        try saveSchedules([legacy])
        return [legacy]
    }

    func saveSchedules(_ schedules: [AffirmationSchedule]) throws {
        try save(schedules, forKey: Key.schedules)
        userDefaults.removeObject(forKey: Key.schedule)
    }

    func loadNotificationSound() throws -> NotificationSound? {
        try load(NotificationSound.self, forKey: Key.notificationSound)
    }

    func saveNotificationSound(_ sound: NotificationSound) throws {
        try save(sound, forKey: Key.notificationSound)
    }

    func loadTheme() throws -> AppTheme? {
        try load(AppTheme.self, forKey: Key.theme)
    }

    func saveTheme(_ theme: AppTheme) throws {
        try save(theme, forKey: Key.theme)
    }

    func loadThemeBackgrounds() throws -> [String: ThemeBackgroundChoice] {
        try load([String: ThemeBackgroundChoice].self, forKey: Key.themeBackgrounds) ?? [:]
    }

    func saveThemeBackgrounds(_ backgrounds: [String: ThemeBackgroundChoice]) throws {
        try save(backgrounds, forKey: Key.themeBackgrounds)
    }

    func loadAffirmationSelection() throws -> AffirmationSelection? {
        try load(AffirmationSelection.self, forKey: Key.affirmationSelection)
    }

    func saveAffirmationSelection(_ selection: AffirmationSelection) throws {
        try save(selection, forKey: Key.affirmationSelection)
    }

    func saveAppData(
        affirmations: [Affirmation],
        schedules: [AffirmationSchedule],
        theme: AppTheme,
        selection: AffirmationSelection,
        preservingExistingData: Bool
    ) throws {
        // Complete every throwing operation before changing any saved data.
        try AffirmationValidation.validate(affirmations)
        let affirmationData = try encoder.encode(affirmations)
        let scheduleData = try encoder.encode(schedules)
        let themeData = try encoder.encode(theme)
        let selectionData = try encoder.encode(selection)
        if preservingExistingData {
            let keys = [Key.affirmations, Key.schedules, Key.schedule, Key.theme,
                        Key.affirmationSelection, Key.themeBackgrounds, Key.name,
                        Key.notificationSound, Key.initialAffirmationsSeeded]
            var values: [String: Any] = [:]
            for key in keys { values[key] = userDefaults.object(forKey: key) }
            var backups = userDefaults.array(forKey: Key.recoveryBackups) ?? []
            backups.append(["savedAt": Date(), "values": values])
            userDefaults.set(backups, forKey: Key.recoveryBackups)
        } else {
            userDefaults.removeObject(forKey: Key.recoveryBackups)
        }
        userDefaults.set(affirmationData, forKey: Key.affirmations)
        userDefaults.set(scheduleData, forKey: Key.schedules)
        userDefaults.removeObject(forKey: Key.schedule)
        userDefaults.set(themeData, forKey: Key.theme)
        userDefaults.set(selectionData, forKey: Key.affirmationSelection)
        userDefaults.removeObject(forKey: Key.themeBackgrounds)
        userDefaults.removeObject(forKey: Key.name)
        userDefaults.removeObject(forKey: Key.notificationSound)
    }

    private func load<Value: Decodable>(
        _ type: Value.Type,
        forKey key: String
    ) throws -> Value? {
        guard let savedValue = userDefaults.object(forKey: key) else {
            return nil
        }
        guard let data = savedValue as? Data else {
            throw PersistenceUnavailableError(reason: "Saved data has an unexpected format.")
        }

        return try decoder.decode(type, from: data)
    }

    private func save<Value: Encodable>(
        _ value: Value,
        forKey key: String
    ) throws {
        userDefaults.set(try encoder.encode(value), forKey: key)
    }
}
