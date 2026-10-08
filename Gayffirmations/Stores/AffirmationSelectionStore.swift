import Foundation
import Observation

/// Persists Today’s content choice when no schedule can deliver reminders.
@MainActor
@Observable
final class AffirmationSelectionStore {
    private(set) var selection: AffirmationSelection
    private(set) var persistenceErrorMessage: String?

    private let repository: (any AffirmationSelectionRepository)?

    init(selection: AffirmationSelection = .all) {
        self.selection = selection
        repository = nil
    }

    init(repository: any AffirmationSelectionRepository) {
        self.repository = repository
        selection = .all

        do {
            if let savedSelection = try repository.loadAffirmationSelection() {
                selection = savedSelection
            } else {
                // Existing installations keep using the full library.
                try repository.saveAffirmationSelection(.all)
            }
        } catch {
            persistenceErrorMessage = error.localizedDescription
        }
    }

    func applyPersistedDefaults() {
        selection = .all
    }

    func select(_ selection: AffirmationSelection) throws {
        if let persistenceErrorMessage {
            throw PersistenceUnavailableError(reason: persistenceErrorMessage)
        }

        // Change observable state only after the save succeeds.
        try repository?.saveAffirmationSelection(selection)
        self.selection = selection
    }
}
