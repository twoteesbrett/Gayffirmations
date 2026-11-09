import Foundation
import Observation

/// Persists Today’s content choice when no schedule can deliver reminders.
@MainActor
@Observable
final class AffirmationSelectionStore {
    private(set) var selection: AffirmationSelection
    private(set) var persistenceErrorMessage: String?

    let defaultSelection: AffirmationSelection
    private let repository: (any AffirmationSelectionRepository)?

    init(selection: AffirmationSelection = .all) {
        self.selection = selection
        defaultSelection = .all
        repository = nil
    }

    init(repository: any AffirmationSelectionRepository, defaultSelection: AffirmationSelection = .all) {
        self.repository = repository
        self.defaultSelection = defaultSelection
        selection = defaultSelection

        do {
            if let savedSelection = try repository.loadAffirmationSelection() {
                selection = savedSelection
            } else {
                try repository.saveAffirmationSelection(defaultSelection)
            }
        } catch {
            persistenceErrorMessage = error.localizedDescription
        }
    }

    func applyPersistedDefaults() {
        selection = defaultSelection
        persistenceErrorMessage = nil
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
