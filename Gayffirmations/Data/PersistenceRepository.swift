import Foundation

struct PersistenceUnavailableError: LocalizedError {
    let reason: String

    var errorDescription: String? {
        "Saved data is unavailable. \(reason)"
    }
}

protocol AffirmationRepository {
    func loadAffirmations() throws -> [Affirmation]?
    func saveAffirmations(_ affirmations: [Affirmation]) throws
}

protocol ScheduleRepository {
    func loadSchedule() throws -> AffirmationSchedule?
    func saveSchedule(_ schedule: AffirmationSchedule) throws
}

protocol ThemeRepository {
    func loadTheme() throws -> AppTheme?
    func saveTheme(_ theme: AppTheme) throws
}

protocol AffirmationSelectionRepository {
    func loadAffirmationSelection() throws -> AffirmationSelection?
    func saveAffirmationSelection(_ selection: AffirmationSelection) throws
}

protocol AppDataRepository {
    // A throwing save must leave every section unchanged.
    func saveAppData(affirmations: [Affirmation], schedule: AffirmationSchedule, theme: AppTheme, selection: AffirmationSelection) throws
}

final class UserDefaultsRepository: AffirmationRepository, ScheduleRepository, ThemeRepository, AffirmationSelectionRepository, AppDataRepository {
    private enum Key {
        static let affirmations = "gayffirmations.affirmations"
        static let schedule = "gayffirmations.schedule"
        static let theme = "gayffirmations.theme"
        static let affirmationSelection = "gayffirmations.affirmationSelection"
    }

    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        userDefaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
    }

    /// This deliberate content reset runs once; later launches preserve new work.
    func prepareForContentRebuild() {
        let revisionKey = "gayffirmations.contentRebuildRevision"
        guard userDefaults.integer(forKey: revisionKey) < 1 else { return }
        let contentKeys = [Key.affirmations, Key.theme, Key.affirmationSelection,
                           "gayffirmations.themePhotosEnabled"]
        var backup: [String: Any] = [:]
        for key in contentKeys {
            if let value = userDefaults.object(forKey: key) { backup[key] = value }
        }
        if !backup.isEmpty {
            userDefaults.set(backup, forKey: "gayffirmations.contentBeforeRebuild")
        }
        for key in contentKeys { userDefaults.removeObject(forKey: key) }
        userDefaults.set(1, forKey: revisionKey)
    }

    func loadAffirmations() throws -> [Affirmation]? {
        try load([Affirmation].self, forKey: Key.affirmations)
    }

    func saveAffirmations(_ affirmations: [Affirmation]) throws {
        try save(affirmations, forKey: Key.affirmations)
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
