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

final class UserDefaultsRepository: AffirmationRepository, ScheduleRepository {
    private enum Key {
        static let affirmations = "Selfsaid.affirmations"
        static let schedule = "Selfsaid.schedule"
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

    private func load<Value: Decodable>(
        _ type: Value.Type,
        forKey key: String
    ) throws -> Value? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
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
