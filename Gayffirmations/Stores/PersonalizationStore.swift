import Foundation
import Observation

@MainActor
@Observable
final class PersonalizationStore {
    private(set) var name: String
    private(set) var persistenceErrorMessage: String?
    private let repository: (any PersonalizationRepository)?

    init(name: String = "", repository: (any PersonalizationRepository)? = nil) {
        self.name = name
        self.repository = repository
        do {
            if let saved = try repository?.loadName() { self.name = saved }
        } catch {
            persistenceErrorMessage = error.localizedDescription
        }
    }

    func setName(_ name: String) throws {
        if let persistenceErrorMessage {
            throw PersistenceUnavailableError(reason: persistenceErrorMessage)
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        try repository?.saveName(trimmed)
        self.name = trimmed
    }

    func applyPersistedDefaults() { name = "" }
}
