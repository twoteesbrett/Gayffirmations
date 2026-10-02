import Foundation
import Observation

@MainActor
@Observable
final class ThemeStore {
    private(set) var selectedTheme: AppTheme
    private(set) var persistenceErrorMessage: String?

    private let repository: (any ThemeRepository)?
    let defaultTheme: AppTheme

    init(
        selectedTheme: AppTheme = .neutral,
        repository: (any ThemeRepository)? = nil
    ) {
        self.selectedTheme = selectedTheme
        self.defaultTheme = selectedTheme
        self.repository = repository
    }

    init(
        repository: any ThemeRepository,
        defaultTheme: AppTheme
    ) {
        self.repository = repository
        self.defaultTheme = defaultTheme

        do {
            if let savedTheme = try repository.loadTheme() {
                selectedTheme = savedTheme
            } else {
                selectedTheme = defaultTheme
                try repository.saveTheme(defaultTheme)
            }
        } catch {
            selectedTheme = defaultTheme
            persistenceErrorMessage = error.localizedDescription
        }
    }

    func select(_ theme: AppTheme) throws {
        try persist(theme)
    }

    func reset() throws {
        try persist(defaultTheme)
    }

    func applyPersistedDefaults() {
        selectedTheme = defaultTheme
    }

    private func persist(_ theme: AppTheme) throws {
        if let persistenceErrorMessage {
            throw PersistenceUnavailableError(reason: persistenceErrorMessage)
        }

        try repository?.saveTheme(theme)
        selectedTheme = theme
    }
}
