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
        static let schedule = "gayffirmations.schedule"
        static let themeBackgrounds = "gayffirmations.themeBackgrounds"
        static let theme = "gayffirmations.theme"
        static let affirmationSelection = "gayffirmations.affirmationSelection"
        static let initialAffirmationsSeeded = "gayffirmations.initialAffirmationsSeeded"
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
        if let index = saved?.firstIndex(where: {
            $0.id == UUID(uuidString: "B7E77000-0000-4000-8000-000000000015")
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
        try save(affirmations, forKey: Key.affirmations)
    }

    func loadName() throws -> String? {
        try load(String.self, forKey: Key.name)
    }

    func saveName(_ name: String) throws {
        try save(name, forKey: Key.name)
    }

    func loadSchedule() throws -> AffirmationSchedule? {
        try load(AffirmationSchedule.self, forKey: Key.schedule)
    }

    func saveSchedule(_ schedule: AffirmationSchedule) throws {
        try save(schedule, forKey: Key.schedule)
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
        schedule: AffirmationSchedule,
        theme: AppTheme,
        selection: AffirmationSelection
    ) throws {
        // Complete every throwing operation before changing any saved data.
        let affirmationData = try encoder.encode(affirmations)
        let scheduleData = try encoder.encode(schedule)
        let themeData = try encoder.encode(theme)
        let selectionData = try encoder.encode(selection)
        userDefaults.set(affirmationData, forKey: Key.affirmations)
        userDefaults.set(scheduleData, forKey: Key.schedule)
        userDefaults.set(themeData, forKey: Key.theme)
        userDefaults.set(selectionData, forKey: Key.affirmationSelection)
        userDefaults.removeObject(forKey: Key.themeBackgrounds)
        userDefaults.removeObject(forKey: Key.name)
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
